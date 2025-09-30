#!/usr/bin/env python3
"""
us_climbing_gyms_v2.py

Scrappy pipeline to collect active US climbing gym listings from:
  1) OpenStreetMap (Overpass) — wide, free baseline
  2) USA Climbing partner directory (Sport:80 widget) — member gyms

Then normalize, dedupe, and persist to SQLite + JSON.

Run:
  python us_climbing_gyms_v2.py --sqlite gyms.sqlite --json gyms.json

What’s new vs v1:
- Robust rate limiting + retries (429/5xx + Retry-After) with exponential backoff & jitter
- USA Climbing partner directory ingestion via Sport:80 public widget
- Same normalized schema; drop-in replacement for v1 outputs

Notes:
- Overpass etiquette: be gentle; one fat US query is fine but back off if throttled.
- USA Climbing widget is JS-driven; we try 3 tactics in order of “cheap → heavier”:
    A) Known unauthenticated JSON endpoints (if present; many Sport:80 widgets expose these)
    B) Basic HTML scrape (if the page server-renders any entries)
    C) Headless render (Playwright) and DOM-scrape
  If all fail, we skip USAC to keep the script runnable in restricted environments.
- Licenses: OSM data is ODbL; attribute “© OpenStreetMap contributors” in your app.
"""

import argparse
import datetime as dt
import json
import math
import os
import random
import re
import sqlite3
import sys
import time
from typing import Any, Dict, Iterable, List, Optional, Tuple
from urllib.parse import quote

import urllib.request
import urllib.error

# ------------------------- Config -------------------------

OVERPASS_URL = "https://overpass-api.de/api/interpreter"

# One-shot US query: sports centres & indoor-ish climbing
OVERPASS_QUERY = r"""
[out:json][timeout:180];
area["ISO3166-1"="US"][admin_level=2]->.searchArea;

(
  node["leisure"="sports_centre"]["sport"~"(^|;)\s*climbing\s*(;|$)"](area.searchArea);
  way["leisure"="sports_centre"]["sport"~"(^|;)\s*climbing\s*(;|$)"](area.searchArea);
  relation["leisure"="sports_centre"]["sport"~"(^|;)\s*climbing\s*(;|$)"](area.searchArea);

  node["sport"="climbing"]["indoor"~"yes|true|1"](area.searchArea);
  way["sport"="climbing"]["indoor"~"yes|true|1"](area.searchArea);
  relation["sport"="climbing"]["indoor"~"yes|true|1"](area.searchArea);

  node["sport"="climbing"]["climbing:gym"~"yes|true|1"](area.searchArea);
  way["sport"="climbing"]["climbing:gym"~"yes|true|1"](area.searchArea);
  relation["sport"="climbing"]["climbing:gym"~"yes|true|1"](area.searchArea);
);
out center tags;
"""

USAC_WIDGET_URL = "https://usaclimbing.sport80.com/public/widget/1"  # public “Find a Gym Near You”
USER_AGENT = "crakt-gym-scraper/0.2 (+https://example.com) python-urllib"

# --------------------- Rate-limit / Retry ---------------------

class RateLimiter:
    """Simple token bucket for N requests/interval (defaults: ~1 rps)."""
    def __init__(self, rate_per_sec: float = 1.0, burst: int = 2):
        self.rate = rate_per_sec
        self.capacity = float(burst)
        self.tokens = float(burst)
        self.timestamp = time.monotonic()

    def take(self, tokens: float = 1.0):
        now = time.monotonic()
        elapsed = now - self.timestamp
        self.timestamp = now
        self.tokens = min(self.capacity, self.tokens + elapsed * self.rate)
        if self.tokens < tokens:
            need = tokens - self.tokens
            sleep_for = need / self.rate
            time.sleep(sleep_for)
            self.tokens = max(0.0, self.tokens - tokens + sleep_for * self.rate)
        else:
            self.tokens -= tokens

def _backoff_sleep(attempt: int, retry_after: Optional[float] = None):
    # respect Retry-After if present; else exp backoff with jitter
    if retry_after is not None and retry_after > 0:
        time.sleep(retry_after)
        return
    base = min(60, 2 ** attempt)  # cap at 60s
    jitter = random.uniform(0, 1.0)
    time.sleep(base + jitter)

def http_request(
    url: str,
    data: Optional[bytes] = None,
    headers: Optional[Dict[str, str]] = None,
    method: str = "GET",
    retries: int = 6,
    rl: Optional[RateLimiter] = None,
    timeout: int = 60
) -> bytes:
    if headers is None:
        headers = {}
    if "User-Agent" not in headers:
        headers["User-Agent"] = USER_AGENT

    req = urllib.request.Request(url=url, data=data, headers=headers, method=method)
    last_err = None

    for attempt in range(retries + 1):
        try:
            if rl:
                rl.take()
            with urllib.request.urlopen(req, timeout=timeout) as resp:
                return resp.read()
        except urllib.error.HTTPError as e:
            last_err = e
            status = e.code
            # backoff on 429, 408, 500-504
            if status in (408, 429, 500, 502, 503, 504):
                retry_after = None
                if e.headers and "Retry-After" in e.headers:
                    try:
                        retry_after = float(e.headers["Retry-After"])
                    except Exception:
                        retry_after = None
                if attempt < retries:
                    _backoff_sleep(attempt + 1, retry_after)
                    continue
            # otherwise, propagate
            raise
        except Exception as e:
            last_err = e
            if attempt < retries:
                _backoff_sleep(attempt + 1, None)
                continue
            raise
    if last_err:
        raise last_err
    raise RuntimeError("http_request: unknown failure")

# ------------------------- Utils -------------------------

def _now_iso() -> str:
    return dt.datetime.utcnow().replace(microsecond=0).isoformat() + "Z"

def haversine_km(lat1, lon1, lat2, lon2) -> float:
    R = 6371.0
    to_rad = math.radians
    dlat = to_rad(lat2 - lat1)
    dlon = to_rad(lon2 - lon1)
    a = (math.sin(dlat/2)**2 +
         math.cos(to_rad(lat1)) * math.cos(to_rad(lat2)) * math.sin(dlon/2)**2)
    return R * (2*math.atan2(math.sqrt(a), math.sqrt(1-a)))

def safe_get(d: Dict[str, Any], *keys, default=None):
    for k in keys:
        if k in d and d[k]:
            return d[k]
    return default

# --------------------- OSM / Overpass ---------------------

def normalize_osm_element(el: Dict[str, Any]) -> Dict[str, Any]:
    tags = el.get("tags", {}) or {}
    lat = el.get("lat") or (el.get("center") or {}).get("lat")
    lon = el.get("lon") or (el.get("center") or {}).get("lon")

    record = {
        "source": "OSM_OVERPASS",
        "source_id": f"{el.get('type','')}:{el.get('id','')}",
        "name": safe_get(tags, "name", default=None),
        "houseNumber": safe_get(tags, "addr:housenumber", default=None),
        "street": safe_get(tags, "addr:street", default=None),
        "city": safe_get(tags, "addr:city", default=None),
        "state": safe_get(tags, "addr:state", default=None),
        "postcode": safe_get(tags, "addr:postcode", default=None),
        "country": safe_get(tags, "addr:country", default="US"),
        "phone": safe_get(tags, "phone", "contact:phone", default=None),
        "website": safe_get(tags, "website", "contact:website", default=None),
        "hours": safe_get(tags, "opening_hours", "opening_hours:covid19", default=None),
        "latitude": lat,
        "longitude": lon,
        "createdAt": _now_iso(),
        "updatedAt": _now_iso(),
        "isIndoor": bool(str(tags.get("indoor", "")).lower() in ("yes","true","1")),
        "rawTags": tags
    }
    return record

def fetch_from_osm() -> List[Dict[str, Any]]:
    print("Fetching from Overpass/OSM…")
    rl = RateLimiter(rate_per_sec=0.9, burst=2)  # polite; Overpass slots fill quickly
    payload = "data=" + quote(OVERPASS_QUERY)
    data = http_request(
        OVERPASS_URL,
        data=payload.encode("utf-8"),
        headers={"Content-Type": "application/x-www-form-urlencoded; charset=UTF-8"},
        method="POST",
        rl=rl,
        timeout=300
    )
    obj = json.loads(data.decode("utf-8"))
    elements = obj.get("elements", [])
    records = [normalize_osm_element(el) for el in elements if (el.get("tags") or {}).get("name")]
    print(f"OSM raw: {len(elements)}  named gyms: {len(records)}")
    return records

# ---------------- USA Climbing (Sport:80 widget) ----------------

ZIP_RE = re.compile(r"\b\d{5}(?:-\d{4})?\b")
PHONE_RE = re.compile(r"(\+?1[\s\-\.]?)?\(?\d{3}\)?[\s\-\.]?\d{3}[\s\-\.]?\d{4}")

def _parse_city_state_zip(s: str) -> Tuple[Optional[str], Optional[str], Optional[str]]:
    # naive “City, ST 12345” pull
    m = re.search(r",\s*([A-Z]{2})\s+(\d{5}(?:-\d{4})?)", s)
    state, zipc = (m.group(1), m.group(2)) if m else (None, None)
    city = None
    if m:
        city_part = s[:m.start()]
        if "," in city_part:
            city = city_part.split(",")[-1].strip()
        else:
            city = city_part.strip()
    return (city, state, zipc)

def normalize_usac_item(name: str, address: str, website: Optional[str], phone: Optional[str]) -> Dict[str, Any]:
    city, state, zipc = _parse_city_state_zip(address)
    house_no = None
    street = None
    # quick split "123 Main St" → (123, Main St)
    m = re.match(r"\s*(\d+[A-Za-z\-]*)\s+(.*)", address or "")
    if m:
        house_no, street = m.group(1), m.group(2)
    lat = None
    lon = None

    return {
        "source": "USAC_SPORT80",
        "source_id": f"USAC::{name}",
        "name": name or None,
        "houseNumber": house_no,
        "street": street,
        "city": city,
        "state": state,
        "postcode": zipc,
        "country": "US",
        "phone": phone,
        "website": website,
        "hours": None,
        "latitude": lat,
        "longitude": lon,
        "createdAt": _now_iso(),
        "updatedAt": _now_iso(),
        "isIndoor": True,
    }

def fetch_from_usac() -> List[Dict[str, Any]]:
    """
    Best-effort scraper for USA Climbing's partner gym locator (Sport:80).
    We try:
      1) Unofficial JSON feeds common to Sport:80 widgets (cheap, fast)
      2) Plain GET of the widget page and regex scrape for server-rendered entries
      3) Optional: Playwright headless to render & query DOM (heavier; optional dependency)
    On failure, returns [] to keep pipeline resilient.
    """
    print("Fetching USA Climbing partner directory (Sport:80)…")
    rl = RateLimiter(rate_per_sec=1.0, burst=2)

    candidates = [
        # These endpoints vary by tenant/deployment. We probe a few common patterns.
        # If one returns JSON with clubs/gyms, parse and return.
        "https://usaclimbing.sport80.com/public/widget/1/data",          # pattern A
        "https://usaclimbing.sport80.com/public/widget/1.json",          # pattern B
        "https://usaclimbing.sport80.com/api/public/widgets/1",          # pattern C
        "https://usaclimbing.sport80.com/api/public/widgets/1/locations" # pattern D
    ]

    headers = {"User-Agent": USER_AGENT, "Accept": "application/json, */*"}
    for url in candidates:
        try:
            raw = http_request(url, headers=headers, rl=rl, timeout=30)
            txt = raw.decode("utf-8", errors="ignore")
            obj = json.loads(txt)
            # Try some common shapes
            items = []
            if isinstance(obj, dict):
                for key in ("clubs", "gyms", "locations", "data", "results"):
                    val = obj.get(key)
                    if isinstance(val, list):
                        items = val
                        break
            elif isinstance(obj, list):
                items = obj
            if items:
                out = []
                for it in items:
                    name = safe_get(it, "name", "club_name", "title", default=None)
                    website = safe_get(it, "website", "url", "link", default=None)
                    phone = safe_get(it, "phone", "telephone", default=None)
                    address = None
                    # Common address shapes
                    addr = it.get("address") if isinstance(it, dict) else None
                    if isinstance(addr, dict):
                        parts = [addr.get(k) for k in ("line1","line2","city","state","postcode") if addr.get(k)]
                        address = ", ".join([p for p in parts if p])
                    elif isinstance(addr, str):
                        address = addr
                    else:
                        # compose if separate fields exist
                        parts = [it.get(k) for k in ("address1","address2","city","state","postcode") if it.get(k)]
                        if parts:
                            address = ", ".join([p for p in parts if p])
                    if name and address:
                        out.append(normalize_usac_item(name, address, website, phone))
                if out:
                    print(f"USAC (JSON endpoint): {len(out)}")
                    return out
        except Exception:
            # probe next
            pass

    # Fallback B: naive HTML scrape of the widget page (if any SSR text exists)
    try:
        raw = http_request(USAC_WIDGET_URL, headers={"User-Agent": USER_AGENT}, rl=rl, timeout=30)
        html = raw.decode("utf-8", errors="ignore")
        # very loose parsing — look for "Gym Name. 123 Some St, City, ST 12345"
        # Many widgets render list items or cards; capture "Name" then an address-like line.
        candidates = re.findall(r">([^<]{2,120})<\/(?:h\d|strong|span)>.*?([\w\.\-#\s,]{10,120}\b\d{5}(?:-\d{4})?\b)", html, flags=re.I|re.S)
        out = []
        for name, addr in candidates:
            name = re.sub(r"\s+", " ", name).strip(" ·\n\r\t")
            addr = re.sub(r"\s+", " ", addr).strip()
            if len(name) < 2 or len(addr) < 8:
                continue
            # Try to detect phone & website near the address
            phone = None
            m = PHONE_RE.search(html)
            if m:
                phone = m.group(0)
            web = None
            m2 = re.search(r'href="(https?://[^"]+)"[^>]*>\s*(Website|Visit|Learn More)', html, flags=re.I)
            if m2:
                web = m2.group(1)
            out.append(normalize_usac_item(name, addr, web, phone))
        if out:
            # de-dupe by name + zip
            seen = set()
            uniq = []
            for r in out:
                key = (r["name"], r.get("postcode"))
                if key not in seen:
                    seen.add(key)
                    uniq.append(r)
            print(f"USAC (HTML fallback): {len(uniq)}")
            return uniq
    except Exception:
        pass

    # Fallback C: Optional headless render with Playwright
    try:
        from playwright.sync_api import sync_playwright  # type: ignore
        gyms = []
        with sync_playwright() as p:
            browser = p.chromium.launch(headless=True)
            page = browser.new_page(user_agent=USER_AGENT)
            page.goto(USAC_WIDGET_URL, wait_until="networkidle", timeout=45000)
            # Heuristic selectors — update as needed if widget markup changes
            # Try common list/card containers
            selectors = [
                "[class*='locator'] li",
                "[class*='gym'] li",
                "[class*='card']",
                "li",
            ]
            seen = set()
            for sel in selectors:
                for el in page.query_selector_all(sel):
                    text = (el.inner_text() or "").strip()
                    if ZIP_RE.search(text) and len(text) > 10:
                        lines = [ln.strip() for ln in text.split("\n") if ln.strip()]
                        if not lines:
                            continue
                        name = lines[0][:120]
                        address_line = None
                        for ln in lines[1:]:
                            if ZIP_RE.search(ln):
                                address_line = ln
                                break
                        if not address_line:
                            continue
                        website = None
                        link = el.query_selector("a[href^='http']")
                        if link:
                            href = link.get_attribute("href")
                            if href and "usaclimbing" not in href:
                                website = href
                        phone = None
                        m = PHONE_RE.search(text)
                        if m:
                            phone = m.group(0)
                        rec = normalize_usac_item(name, address_line, website, phone)
                        key = (rec["name"], rec.get("postcode"))
                        if key not in seen:
                            seen.add(key)
                            gyms.append(rec)
            browser.close()
        if gyms:
            print(f"USAC (Playwright rendered): {len(gyms)}")
            return gyms
    except Exception as e:
        print(f"[WARN] USAC headless fallback not available or failed: {e}")

    print("USAC directory not reachable; continuing without it.")
    return []

# --------------------- Dedupe & Persist ---------------------

def dedupe(records: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """
    Deduplicate by:
      1) exact match on (normalized name, city, state), else
      2) spatial match within 0.25 km if names similar (for OSM vs OSM/USAC merges)
    """
    out: List[Dict[str, Any]] = []
    seen_keys = set()
    def norm(s): return (s or "").strip().lower()

    for r in records:
        key = (norm(r.get("name")), norm(r.get("city")), norm(r.get("state")))
        if key[0] and key in seen_keys:
            continue

        merged = False
        for i, ex in enumerate(out):
            if not r.get("name") or not ex.get("name"):
                continue
            nm_a = norm(r["name"])
            nm_b = norm(ex["name"])
            # If we have coordinates, merge by spatial proximity
            if r.get("latitude") and ex.get("latitude"):
                dist = haversine_km(r["latitude"], r["longitude"], ex["latitude"], ex["longitude"])
                if dist <= 0.25 and (nm_a in nm_b or nm_b in nm_a):
                    for k, v in r.items():
                        if ex.get(k) in (None, "", []):
                            ex[k] = v
                    out[i] = ex
                    merged = True
                    break
            else:
                # no coords (USAC) — merge on name+city+state overlap
                if (nm_a in nm_b or nm_b in nm_a) and norm(r.get("city")) == norm(ex.get("city")) and norm(r.get("state")) == norm(ex.get("state")):
                    for k, v in r.items():
                        if ex.get(k) in (None, "", []):
                            ex[k] = v
                    out[i] = ex
                    merged = True
                    break

        if not merged:
            out.append(r)
            if key[0]:
                seen_keys.add(key)
    return out

SCHEMA_SQL = """
CREATE TABLE IF NOT EXISTS gyms (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT,
    houseNumber TEXT,
    street TEXT,
    city TEXT,
    state TEXT,
    postcode TEXT,
    country TEXT,
    phone TEXT,
    website TEXT,
    hours TEXT,
    latitude REAL,
    longitude REAL,
    isIndoor INTEGER,
    source TEXT,
    source_id TEXT UNIQUE,
    createdAt TEXT,
    updatedAt TEXT
);

CREATE TABLE IF NOT EXISTS gym_metadata (
    gym_id INTEGER NOT NULL,
    key TEXT NOT NULL,
    value TEXT,
    FOREIGN KEY (gym_id) REFERENCES gyms(id)
);
"""

def save_sqlite(sqlite_path: str, records: List[Dict[str, Any]]):
    conn = sqlite3.connect(sqlite_path)
    conn.executescript(SCHEMA_SQL)
    cur = conn.cursor()
    upsert = """
    INSERT INTO gyms (
      name, houseNumber, street, city, state, postcode, country, phone, website,
      hours, latitude, longitude, isIndoor, source, source_id, createdAt, updatedAt
    )
    VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
    ON CONFLICT(source_id) DO UPDATE SET
      name=excluded.name,
      houseNumber=excluded.houseNumber,
      street=excluded.street,
      city=excluded.city,
      state=excluded.state,
      postcode=excluded.postcode,
      country=excluded.country,
      phone=excluded.phone,
      website=excluded.website,
      hours=excluded.hours,
      latitude=excluded.latitude,
      longitude=excluded.longitude,
      isIndoor=excluded.isIndoor,
      updatedAt=excluded.updatedAt;
    """
    for r in records:
        cur.execute(upsert, (
            r.get("name"),
            r.get("houseNumber"),
            r.get("street"),
            r.get("city"),
            r.get("state"),
            r.get("postcode"),
            r.get("country"),
            r.get("phone"),
            r.get("website"),
            r.get("hours"),
            r.get("latitude"),
            r.get("longitude"),
            1 if r.get("isIndoor") else 0,
            r.get("source"),
            r.get("source_id"),
            r.get("createdAt"),
            r.get("updatedAt"),
        ))
    conn.commit()
    conn.close()

def save_json(json_path: str, records: List[Dict[str, Any]]):
    whitelisted = [
        "name","houseNumber","street","city","state","postcode","country",
        "phone","website","hours","latitude","longitude","isIndoor",
        "source","source_id","createdAt","updatedAt"
    ]
    clean = [{k: r.get(k) for k in whitelisted} for r in records]
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(clean, f, indent=2, ensure_ascii=False)

# --------------------------- Main ---------------------------

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--sqlite", default="gyms.sqlite")
    parser.add_argument("--json", default="gyms.json")
    parser.add_argument("--skip-usac", action="store_true", help="Skip USA Climbing directory (for CI or no-headless envs)")
    args = parser.parse_args()

    all_records: List[Dict[str, Any]] = []

    try:
        all_records.extend(fetch_from_osm())
    except Exception as e:
        print(f"[WARN] OSM fetch failed: {e}", file=sys.stderr)

    if not args.skip_usac:
        try:
            all_records.extend(fetch_from_usac())
        except Exception as e:
            print(f"[WARN] USAC fetch failed: {e}", file=sys.stderr)

    print(f"Total records before dedupe: {len(all_records)}")
    deduped = dedupe(all_records)
    print(f"After dedupe: {len(deduped)}")

    save_sqlite(args.sqlite, deduped)
    save_json(args.json, deduped)
    print(f"Wrote {args.sqlite} and {args.json}")
    print("Attribution: Contains information © OpenStreetMap contributors (ODbL).")

if __name__ == "__main__":
    main()
