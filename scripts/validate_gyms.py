#!/usr/bin/env python3
"""
validate_gyms.py

Cross-reference climbing gyms in the SQLite database against a search API
to validate and update information. Handles rate limiting carefully to avoid
API throttling.

Usage:
  python validate_gyms.py --api-key YOUR_API_KEY --sqlite gyms.sqlite

Supports multiple APIs:
  - Google Places API (New) - default, most comprehensive
    Uses the new Places API (v1) with enhanced data fields
    https://developers.google.com/maps/documentation/places/web-service/op-overview
  - OpenStreetMap Nominatim (free, but rate-limited to 1 req/s)

The script will:
  1. Read all gyms from the database
  2. Search for each gym using name + location
  3. Compare returned data with existing data
  4. Flag discrepancies (closed, moved, phone/website changed)
  5. Optionally update the database with fresh information
"""

import argparse
import json
import sqlite3
import sys
import time
import urllib.request
import urllib.parse
import urllib.error
from typing import Dict, List, Optional, Tuple, Any
from dataclasses import dataclass, asdict
from datetime import datetime
import math
import re

# ----------------------- Configuration -----------------------

USER_AGENT = "crakt-gym-validator/1.0 (+https://example.com)"

# Rate limiting defaults (can be overridden per API)
DEFAULT_REQUESTS_PER_SECOND = 10  # Conservative default
DEFAULT_BURST = 5

# ----------------------- Rate Limiter -----------------------

class RateLimiter:
    """Token bucket rate limiter"""
    def __init__(self, rate_per_sec: float = DEFAULT_REQUESTS_PER_SECOND, burst: int = DEFAULT_BURST):
        self.rate = rate_per_sec
        self.capacity = float(burst)
        self.tokens = float(burst)
        self.timestamp = time.monotonic()
        self.request_count = 0
        self.start_time = time.monotonic()

    def take(self, tokens: float = 1.0):
        """Take tokens from the bucket, sleeping if necessary"""
        now = time.monotonic()
        elapsed = now - self.timestamp
        self.timestamp = now
        
        # Refill tokens based on elapsed time
        self.tokens = min(self.capacity, self.tokens + elapsed * self.rate)
        
        if self.tokens < tokens:
            need = tokens - self.tokens
            sleep_for = need / self.rate
            time.sleep(sleep_for)
            self.tokens = max(0.0, self.tokens - tokens + sleep_for * self.rate)
        else:
            self.tokens -= tokens
        
        self.request_count += 1

    def get_stats(self) -> Dict[str, float]:
        """Get rate limiter statistics"""
        elapsed = time.monotonic() - self.start_time
        return {
            "total_requests": self.request_count,
            "elapsed_seconds": elapsed,
            "average_rps": self.request_count / elapsed if elapsed > 0 else 0
        }

# ----------------------- HTTP Utilities -----------------------

def http_request_with_retry(
    url: str,
    headers: Optional[Dict[str, str]] = None,
    data: Optional[bytes] = None,
    method: str = "GET",
    timeout: int = 30,
    max_retries: int = 3
) -> bytes:
    """Make HTTP request with exponential backoff retry"""
    if headers is None:
        headers = {}
    if "User-Agent" not in headers:
        headers["User-Agent"] = USER_AGENT
    
    req = urllib.request.Request(url=url, data=data, headers=headers, method=method)
    
    for attempt in range(max_retries + 1):
        try:
            with urllib.request.urlopen(req, timeout=timeout) as resp:
                return resp.read()
        except urllib.error.HTTPError as e:
            if e.code == 429:  # Too Many Requests
                # Check for Retry-After header
                retry_after = e.headers.get("Retry-After")
                if retry_after:
                    wait_time = float(retry_after)
                else:
                    wait_time = min(60, 2 ** attempt)  # Exponential backoff
                
                if attempt < max_retries:
                    print(f"  Rate limited (429), waiting {wait_time:.1f}s before retry {attempt + 1}/{max_retries}")
                    time.sleep(wait_time)
                    continue
                raise
            elif e.code in (500, 502, 503, 504):  # Server errors
                if attempt < max_retries:
                    wait_time = min(30, 2 ** attempt)
                    print(f"  Server error ({e.code}), waiting {wait_time:.1f}s before retry {attempt + 1}/{max_retries}")
                    time.sleep(wait_time)
                    continue
            raise
        except Exception as e:
            if attempt < max_retries:
                wait_time = min(10, 2 ** attempt)
                print(f"  Request failed ({type(e).__name__}), retrying in {wait_time:.1f}s")
                time.sleep(wait_time)
                continue
            raise
    
    raise RuntimeError("http_request_with_retry: max retries exceeded")

# ----------------------- Data Models -----------------------

@dataclass
class GymRecord:
    """Gym record from database"""
    id: int
    name: str
    houseNumber: Optional[str]
    street: Optional[str]
    city: Optional[str]
    state: Optional[str]
    postcode: Optional[str]
    country: Optional[str]
    phone: Optional[str]
    website: Optional[str]
    hours: Optional[str]
    latitude: Optional[float]
    longitude: Optional[float]
    isIndoor: bool
    source: str
    source_id: str
    createdAt: str
    updatedAt: str

    @property
    def full_address(self) -> str:
        """Construct full address string"""
        parts = []
        if self.houseNumber and self.street:
            parts.append(f"{self.houseNumber} {self.street}")
        elif self.street:
            parts.append(self.street)
        if self.city:
            parts.append(self.city)
        if self.state:
            parts.append(self.state)
        if self.postcode:
            parts.append(self.postcode)
        return ", ".join(parts)

@dataclass
class ValidationResult:
    """Result of validating a gym against search API"""
    gym_id: int
    status: str  # "valid", "updated", "closed", "moved", "not_found", "error"
    confidence: float  # 0.0 to 1.0
    found_name: Optional[str] = None
    found_address: Optional[str] = None
    found_phone: Optional[str] = None
    found_website: Optional[str] = None
    found_latitude: Optional[float] = None
    found_longitude: Optional[float] = None
    found_hours: Optional[str] = None
    is_permanently_closed: Optional[bool] = None
    changes: List[str] = None
    error_message: Optional[str] = None
    api_source: Optional[str] = None

    def __post_init__(self):
        if self.changes is None:
            self.changes = []

# ----------------------- API Clients -----------------------

class GooglePlacesAPI:
    """Google Places API (New) client"""
    
    def __init__(self, api_key: str, rate_limiter: RateLimiter):
        self.api_key = api_key
        self.rate_limiter = rate_limiter
        self.base_url = "https://places.googleapis.com/v1"
    
    def search_gym(self, gym: GymRecord) -> Optional[ValidationResult]:
        """Search for gym and validate information"""
        try:
            # Step 1: Text search to find place
            place_id = self._text_search(gym)
            if not place_id:
                return ValidationResult(
                    gym_id=gym.id,
                    status="not_found",
                    confidence=0.0,
                    api_source="google_places"
                )
            
            # Step 2: Get place details
            details = self._get_place_details(place_id)
            if not details:
                return ValidationResult(
                    gym_id=gym.id,
                    status="error",
                    confidence=0.0,
                    error_message="Failed to fetch place details",
                    api_source="google_places"
                )
            
            # Step 3: Compare and build result
            return self._compare_details(gym, details)
            
        except Exception as e:
            return ValidationResult(
                gym_id=gym.id,
                status="error",
                confidence=0.0,
                error_message=str(e),
                api_source="google_places"
            )
    
    def _text_search(self, gym: GymRecord) -> Optional[str]:
        """Search for place by text query using Places API (New)"""
        # Build search query
        query_parts = [gym.name, "climbing gym"]
        if gym.city and gym.state:
            query_parts.append(f"{gym.city}, {gym.state}")
        elif gym.city:
            query_parts.append(gym.city)
        
        text_query = " ".join(query_parts)
        
        # Build request body for new API
        request_body = {
            "textQuery": text_query
        }
        
        # Add location bias if we have coordinates
        if gym.latitude and gym.longitude:
            request_body["locationBias"] = {
                "circle": {
                    "center": {
                        "latitude": gym.latitude,
                        "longitude": gym.longitude
                    },
                    "radius": 5000.0  # 5km radius
                }
            }
        
        url = f"{self.base_url}/places:searchText"
        
        headers = {
            "Content-Type": "application/json",
            "X-Goog-Api-Key": self.api_key,
            "X-Goog-FieldMask": "places.name,places.displayName"
        }
        
        self.rate_limiter.take()
        try:
            response = http_request_with_retry(
                url, 
                headers=headers,
                data=json.dumps(request_body).encode('utf-8'),
                method="POST"
            )
            data = json.loads(response.decode('utf-8'))
            
            if not data.get("places"):
                return None
            
            # The new API returns resource name in "name" field, not "id"
            # Format: "places/ChIJ..."
            place = data["places"][0]
            resource_name = place.get("name") or place.get("id")
            return resource_name
        except Exception as e:
            print(f"  Text search error: {e}")
            return None
    
    def _get_place_details(self, place_id: str) -> Optional[Dict[str, Any]]:
        """Get detailed information about a place using Places API (New)"""
        # The new API uses resource name format: places/{PLACE_ID}
        # If place_id already includes "places/", use it directly, otherwise add it
        if not place_id.startswith("places/"):
            place_id = f"places/{place_id}"
        
        url = f"{self.base_url}/{place_id}"
        
        headers = {
            "Content-Type": "application/json",
            "X-Goog-Api-Key": self.api_key,
            "X-Goog-FieldMask": "displayName,formattedAddress,internationalPhoneNumber,nationalPhoneNumber,websiteUri,location,businessStatus,currentOpeningHours,regularOpeningHours,rating,userRatingCount,priceLevel,googleMapsUri,types,addressComponents"
        }
        
        self.rate_limiter.take()
        try:
            response = http_request_with_retry(url, headers=headers, method="GET")
            data = json.loads(response.decode('utf-8'))
            
            # New API returns the place directly (no wrapper)
            return data if data else None
        except Exception as e:
            print(f"  Place details error for {place_id}: {e}")
            return None
    
    def _compare_details(self, gym: GymRecord, details: Dict[str, Any]) -> ValidationResult:
        """Compare gym record with API details (New API format)"""
        changes = []
        confidence = 0.0
        
        # Check if permanently closed (New API format)
        business_status = details.get("businessStatus", "OPERATIONAL")
        is_closed = business_status == "CLOSED_PERMANENTLY"
        
        # Extract name from new API format
        display_name = details.get("displayName", {})
        found_name = display_name.get("text") if isinstance(display_name, dict) else display_name
        
        if is_closed:
            return ValidationResult(
                gym_id=gym.id,
                status="closed",
                confidence=1.0,
                found_name=found_name,
                is_permanently_closed=True,
                api_source="google_places"
            )
        
        # Name comparison
        if found_name:
            name_similarity = self._string_similarity(gym.name.lower(), found_name.lower())
            confidence = max(confidence, name_similarity)
            if name_similarity < 0.7:
                changes.append(f"Name mismatch: '{gym.name}' vs '{found_name}'")
        
        # Address comparison (New API format)
        found_address = details.get("formattedAddress")
        if found_address and gym.full_address:
            addr_similarity = self._string_similarity(
                gym.full_address.lower(),
                found_address.lower()
            )
            confidence = max(confidence, addr_similarity)
            if addr_similarity < 0.7:
                changes.append(f"Address changed: '{gym.full_address}' vs '{found_address}'")
        elif found_address and not gym.full_address:
            changes.append(f"Address added: {found_address}")
        
        # Coordinates (New API format) - ALWAYS update if we have better data
        location = details.get("location", {})
        found_lat = location.get("latitude")
        found_lng = location.get("longitude")
        
        if found_lat and found_lng:
            if gym.latitude and gym.longitude:
                distance = self._haversine_km(gym.latitude, gym.longitude, found_lat, found_lng)
                if distance > 0.5:  # More than 500m away
                    changes.append(f"Coordinates updated (moved {distance:.2f}km)")
                elif distance > 0.01:  # More precise coordinates available
                    changes.append(f"Coordinates refined ({distance*1000:.0f}m more precise)")
            else:
                changes.append(f"Coordinates added: {found_lat:.6f}, {found_lng:.6f}")
        
        # Phone (New API format uses internationalPhoneNumber or nationalPhoneNumber)
        found_phone = details.get("internationalPhoneNumber") or details.get("nationalPhoneNumber")
        if found_phone and gym.phone:
            if self._normalize_phone(found_phone) != self._normalize_phone(gym.phone):
                changes.append(f"Phone changed: {gym.phone} -> {found_phone}")
        elif found_phone and not gym.phone:
            changes.append(f"Phone added: {found_phone}")
        
        # Website (New API format uses websiteUri)
        found_website = details.get("websiteUri")
        if found_website and gym.website:
            if self._normalize_url(found_website) != self._normalize_url(gym.website):
                changes.append(f"Website changed: {gym.website} -> {found_website}")
        elif found_website and not gym.website:
            changes.append(f"Website added: {found_website}")
        
        # Opening Hours (New fields!)
        found_hours = None
        opening_hours = details.get("currentOpeningHours") or details.get("regularOpeningHours")
        if opening_hours:
            # Extract weekday text
            weekday_descriptions = opening_hours.get("weekdayDescriptions", [])
            if weekday_descriptions:
                found_hours = "; ".join(weekday_descriptions)
                if not gym.hours:
                    changes.append(f"Hours added")
                elif gym.hours != found_hours:
                    changes.append(f"Hours updated")
        
        # Determine status - be more aggressive about marking as "updated" if we have new data
        if confidence < 0.5:
            status = "not_found"
        elif changes:
            status = "updated"
        else:
            status = "valid"
        
        return ValidationResult(
            gym_id=gym.id,
            status=status,
            confidence=confidence,
            found_name=found_name,
            found_address=found_address,
            found_phone=found_phone,
            found_website=found_website,
            found_latitude=found_lat,
            found_longitude=found_lng,
            found_hours=found_hours,
            is_permanently_closed=is_closed,
            changes=changes,
            api_source="google_places"
        )
    
    @staticmethod
    def _string_similarity(s1: str, s2: str) -> float:
        """Simple string similarity using Levenshtein-like approach"""
        if not s1 or not s2:
            return 0.0
        
        # Simple word overlap similarity
        words1 = set(re.findall(r'\w+', s1.lower()))
        words2 = set(re.findall(r'\w+', s2.lower()))
        
        if not words1 or not words2:
            return 0.0
        
        intersection = words1 & words2
        union = words1 | words2
        
        return len(intersection) / len(union)
    
    @staticmethod
    def _haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        """Calculate distance between two coordinates in km"""
        R = 6371.0
        lat1, lon1, lat2, lon2 = map(math.radians, [lat1, lon1, lat2, lon2])
        dlat = lat2 - lat1
        dlon = lon2 - lon1
        a = math.sin(dlat/2)**2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon/2)**2
        return R * 2 * math.asin(math.sqrt(a))
    
    @staticmethod
    def _normalize_phone(phone: str) -> str:
        """Normalize phone number for comparison"""
        return re.sub(r'\D', '', phone)
    
    @staticmethod
    def _normalize_url(url: str) -> str:
        """Normalize URL for comparison"""
        url = url.lower().strip()
        url = re.sub(r'^https?://', '', url)
        url = re.sub(r'^www\.', '', url)
        url = url.rstrip('/')
        return url


class NominatimAPI:
    """OpenStreetMap Nominatim API client (free, rate-limited)"""
    
    def __init__(self, rate_limiter: RateLimiter):
        self.rate_limiter = rate_limiter
        self.base_url = "https://nominatim.openstreetmap.org"
    
    def search_gym(self, gym: GymRecord) -> Optional[ValidationResult]:
        """Search for gym using Nominatim"""
        try:
            # Build search query
            query_parts = [gym.name, "climbing gym"]
            if gym.city:
                query_parts.append(gym.city)
            if gym.state:
                query_parts.append(gym.state)
            
            query = " ".join(query_parts)
            
            params = {
                "q": query,
                "format": "json",
                "limit": "1",
                "addressdetails": "1"
            }
            
            url = f"{self.base_url}/search?" + urllib.parse.urlencode(params)
            
            headers = {
                "User-Agent": USER_AGENT,
                "Accept": "application/json"
            }
            
            self.rate_limiter.take()
            response = http_request_with_retry(url, headers=headers)
            data = json.loads(response.decode('utf-8'))
            
            if not data:
                return ValidationResult(
                    gym_id=gym.id,
                    status="not_found",
                    confidence=0.0,
                    api_source="nominatim"
                )
            
            result = data[0]
            found_name = result.get("display_name", "").split(",")[0]
            found_lat = float(result.get("lat", 0))
            found_lng = float(result.get("lon", 0))
            
            changes = []
            confidence = 0.5  # Nominatim is less reliable
            
            # Check distance if we have coordinates
            if gym.latitude and gym.longitude:
                distance = GooglePlacesAPI._haversine_km(
                    gym.latitude, gym.longitude, found_lat, found_lng
                )
                if distance < 0.5:
                    confidence = 0.8
                elif distance > 2.0:
                    changes.append(f"Location differs by {distance:.2f}km")
                    confidence = 0.3
            
            status = "valid" if confidence > 0.6 and not changes else "updated"
            
            return ValidationResult(
                gym_id=gym.id,
                status=status,
                confidence=confidence,
                found_name=found_name,
                found_latitude=found_lat,
                found_longitude=found_lng,
                changes=changes,
                api_source="nominatim"
            )
            
        except Exception as e:
            return ValidationResult(
                gym_id=gym.id,
                status="error",
                confidence=0.0,
                error_message=str(e),
                api_source="nominatim"
            )


# ----------------------- Database Operations -----------------------

def load_gyms_from_db(sqlite_path: str) -> List[GymRecord]:
    """Load all gyms from SQLite database"""
    conn = sqlite3.connect(sqlite_path)
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()
    
    cur.execute("""
        SELECT id, name, houseNumber, street, city, state, postcode, country,
               phone, website, hours, latitude, longitude, isIndoor,
               source, source_id, createdAt, updatedAt
        FROM gyms
        ORDER BY id
    """)
    
    gyms = []
    for row in cur.fetchall():
        gyms.append(GymRecord(
            id=row["id"],
            name=row["name"],
            houseNumber=row["houseNumber"],
            street=row["street"],
            city=row["city"],
            state=row["state"],
            postcode=row["postcode"],
            country=row["country"],
            phone=row["phone"],
            website=row["website"],
            hours=row["hours"],
            latitude=row["latitude"],
            longitude=row["longitude"],
            isIndoor=bool(row["isIndoor"]),
            source=row["source"],
            source_id=row["source_id"],
            createdAt=row["createdAt"],
            updatedAt=row["updatedAt"]
        ))
    
    conn.close()
    return gyms


def save_validation_results(sqlite_path: str, results: List[ValidationResult]):
    """Save validation results to database"""
    conn = sqlite3.connect(sqlite_path)
    cur = conn.cursor()
    
    # Create validation results table if not exists
    cur.execute("""
        CREATE TABLE IF NOT EXISTS validation_results (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            gym_id INTEGER NOT NULL,
            validation_date TEXT NOT NULL,
            status TEXT NOT NULL,
            confidence REAL,
            found_name TEXT,
            found_address TEXT,
            found_phone TEXT,
            found_website TEXT,
            found_latitude REAL,
            found_longitude REAL,
            found_hours TEXT,
            is_permanently_closed INTEGER,
            changes TEXT,
            error_message TEXT,
            api_source TEXT,
            FOREIGN KEY (gym_id) REFERENCES gyms(id)
        )
    """)
    
    # Insert results
    now = datetime.utcnow().isoformat() + "Z"
    for result in results:
        cur.execute("""
            INSERT INTO validation_results (
                gym_id, validation_date, status, confidence,
                found_name, found_address, found_phone, found_website,
                found_latitude, found_longitude, found_hours, is_permanently_closed,
                changes, error_message, api_source
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            result.gym_id,
            now,
            result.status,
            result.confidence,
            result.found_name,
            result.found_address,
            result.found_phone,
            result.found_website,
            result.found_latitude,
            result.found_longitude,
            result.found_hours,
            1 if result.is_permanently_closed else 0,
            json.dumps(result.changes) if result.changes else None,
            result.error_message,
            result.api_source
        ))
    
    conn.commit()
    conn.close()


def update_gyms_from_validation(sqlite_path: str, results: List[ValidationResult], dry_run: bool = True):
    """Update gym records based on validation results - AGGRESSIVELY fill in missing data"""
    if dry_run:
        print("\n[DRY RUN] Would update the following gyms:")
    
    conn = sqlite3.connect(sqlite_path)
    cur = conn.cursor()
    
    now = datetime.utcnow().isoformat() + "Z"
    updated_count = 0
    
    for result in results:
        # Skip errors and low confidence matches
        if result.status == "error" or (result.status == "not_found" and result.confidence < 0.5):
            continue
        
        # For closed gyms
        if result.status == "closed" and result.is_permanently_closed:
            if dry_run:
                print(f"  Gym ID {result.gym_id}: PERMANENTLY CLOSED - {result.found_name}")
            else:
                cur.execute("""
                    INSERT OR REPLACE INTO gym_metadata (gym_id, key, value)
                    VALUES (?, 'permanently_closed', 'true')
                """, (result.gym_id,))
                updated_count += 1
            continue
        
        # For ALL other gyms with decent confidence, update fields we have data for
        if result.confidence >= 0.6:  # Lower threshold - trust the API more
            # Get current gym data to see what's missing
            cur.execute("SELECT name, phone, website, hours, latitude, longitude FROM gyms WHERE id = ?", 
                       (result.gym_id,))
            current = cur.fetchone()
            if not current:
                continue
                
            current_name, current_phone, current_website, current_hours, current_lat, current_lng = current
            
            updates = []
            params = []
            update_reasons = []
            
            # Update name if significantly different AND we have high confidence
            if result.found_name and result.confidence > 0.8:
                if not current_name or current_name != result.found_name:
                    updates.append("name = ?")
                    params.append(result.found_name)
                    update_reasons.append(f"name: '{current_name}' -> '{result.found_name}'")
            
            # ALWAYS update coordinates if we have them (Google's are more accurate)
            if result.found_latitude and result.found_longitude:
                updates.append("latitude = ?")
                updates.append("longitude = ?")
                params.extend([result.found_latitude, result.found_longitude])
                if current_lat != result.found_latitude or current_lng != result.found_longitude:
                    update_reasons.append(f"coordinates: ({current_lat:.6f}, {current_lng:.6f}) -> ({result.found_latitude:.6f}, {result.found_longitude:.6f})")
            
            # Fill in missing phone or update if changed
            if result.found_phone:
                if not current_phone:
                    updates.append("phone = ?")
                    params.append(result.found_phone)
                    update_reasons.append(f"phone added: {result.found_phone}")
                elif current_phone != result.found_phone:
                    updates.append("phone = ?")
                    params.append(result.found_phone)
                    update_reasons.append(f"phone: {current_phone} -> {result.found_phone}")
            
            # Fill in missing website or update if changed
            if result.found_website:
                if not current_website:
                    updates.append("website = ?")
                    params.append(result.found_website)
                    update_reasons.append(f"website added: {result.found_website}")
                elif current_website != result.found_website:
                    updates.append("website = ?")
                    params.append(result.found_website)
                    update_reasons.append(f"website: {current_website} -> {result.found_website}")
            
            # Fill in missing hours or update if changed
            if result.found_hours:
                if not current_hours:
                    updates.append("hours = ?")
                    params.append(result.found_hours)
                    update_reasons.append(f"hours added")
                elif current_hours != result.found_hours:
                    updates.append("hours = ?")
                    params.append(result.found_hours)
                    update_reasons.append(f"hours updated")
            
            if updates:
                updates.append("updatedAt = ?")
                params.append(now)
                params.append(result.gym_id)
                
                sql = f"UPDATE gyms SET {', '.join(updates)} WHERE id = ?"
                
                if dry_run:
                    print(f"  Gym ID {result.gym_id}: {'; '.join(update_reasons)}")
                else:
                    cur.execute(sql, params)
                    updated_count += 1
    
    if not dry_run:
        conn.commit()
        print(f"\nUpdated {updated_count} gym records")
    
    conn.close()


# ----------------------- Main Validation Logic -----------------------

def validate_gyms(
    sqlite_path: str,
    api_key: Optional[str] = None,
    api_type: str = "google",
    limit: Optional[int] = None,
    rate_limit: float = 10.0,
    dry_run: bool = True,
    auto_update: bool = False
):
    """Main validation function"""
    print(f"Loading gyms from {sqlite_path}...")
    gyms = load_gyms_from_db(sqlite_path)
    print(f"Loaded {len(gyms)} gyms")
    
    if limit:
        gyms = gyms[:limit]
        print(f"Limited to first {limit} gyms for testing")
    
    # Initialize API client and rate limiter
    rate_limiter = RateLimiter(rate_per_sec=rate_limit, burst=max(2, int(rate_limit / 2)))
    
    if api_type == "google":
        if not api_key:
            print("ERROR: Google Places API requires --api-key")
            sys.exit(1)
        api_client = GooglePlacesAPI(api_key, rate_limiter)
    elif api_type == "nominatim":
        # Nominatim requires max 1 request per second
        rate_limiter = RateLimiter(rate_per_sec=1.0, burst=1)
        api_client = NominatimAPI(rate_limiter)
    else:
        print(f"ERROR: Unknown API type '{api_type}'")
        sys.exit(1)
    
    print(f"\nValidating gyms using {api_type} API (rate limit: {rate_limit} req/s)...")
    print("=" * 80)
    
    results = []
    stats = {
        "valid": 0,
        "updated": 0,
        "closed": 0,
        "moved": 0,
        "not_found": 0,
        "error": 0
    }
    
    for i, gym in enumerate(gyms):
        print(f"\n[{i+1}/{len(gyms)}] Validating: {gym.name} ({gym.city}, {gym.state})")
        
        result = api_client.search_gym(gym)
        results.append(result)
        
        stats[result.status] = stats.get(result.status, 0) + 1
        
        # Print result
        status_emoji = {
            "valid": "✓",
            "updated": "⟳",
            "closed": "✗",
            "moved": "→",
            "not_found": "?",
            "error": "!"
        }
        emoji = status_emoji.get(result.status, "?")
        
        print(f"  {emoji} Status: {result.status.upper()} (confidence: {result.confidence:.2f})")
        
        if result.changes:
            for change in result.changes:
                print(f"    - {change}")
        
        if result.error_message:
            print(f"    ERROR: {result.error_message}")
        
        # Progress indicator
        if (i + 1) % 10 == 0:
            limiter_stats = rate_limiter.get_stats()
            print(f"\n  Progress: {i+1}/{len(gyms)} ({(i+1)/len(gyms)*100:.1f}%)")
            print(f"  Rate: {limiter_stats['average_rps']:.2f} req/s")
    
    # Print summary
    print("\n" + "=" * 80)
    print("VALIDATION SUMMARY")
    print("=" * 80)
    print(f"Total gyms validated: {len(gyms)}")
    for status, count in sorted(stats.items()):
        percentage = (count / len(gyms) * 100) if gyms else 0
        print(f"  {status.capitalize()}: {count} ({percentage:.1f}%)")
    
    limiter_stats = rate_limiter.get_stats()
    print(f"\nAPI requests: {limiter_stats['total_requests']}")
    print(f"Time elapsed: {limiter_stats['elapsed_seconds']:.1f}s")
    print(f"Average rate: {limiter_stats['average_rps']:.2f} req/s")
    
    # Save results
    print(f"\nSaving validation results to database...")
    save_validation_results(sqlite_path, results)
    
    # Update gyms if requested
    if auto_update:
        update_gyms_from_validation(sqlite_path, results, dry_run=dry_run)
    
    # Export problematic gyms to JSON
    problem_gyms = [r for r in results if r.status in ("closed", "not_found", "moved")]
    if problem_gyms:
        output_file = sqlite_path.replace(".sqlite", "_problems.json")
        with open(output_file, "w") as f:
            json.dump([asdict(r) for r in problem_gyms], f, indent=2)
        print(f"\nExported {len(problem_gyms)} problematic gyms to {output_file}")
    
    print("\nValidation complete!")


# ----------------------- CLI -----------------------

def main():
    parser = argparse.ArgumentParser(
        description="Validate climbing gym data against search APIs"
    )
    parser.add_argument(
        "--sqlite",
        default="gyms.sqlite",
        help="Path to SQLite database (default: gyms.sqlite)"
    )
    parser.add_argument(
        "--api-key",
        help="API key for the search service (required for Google Places)"
    )
    parser.add_argument(
        "--api-type",
        choices=["google", "nominatim"],
        default="google",
        help="Which API to use (default: google, uses Places API New)"
    )
    parser.add_argument(
        "--rate-limit",
        type=float,
        default=10.0,
        help="Requests per second (default: 10.0)"
    )
    parser.add_argument(
        "--limit",
        type=int,
        help="Limit number of gyms to validate (for testing)"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Don't actually update the database"
    )
    parser.add_argument(
        "--auto-update",
        action="store_true",
        help="Automatically update gym records with validated data"
    )
    
    args = parser.parse_args()
    
    validate_gyms(
        sqlite_path=args.sqlite,
        api_key=args.api_key,
        api_type=args.api_type,
        limit=args.limit,
        rate_limit=args.rate_limit,
        dry_run=args.dry_run,
        auto_update=args.auto_update
    )


if __name__ == "__main__":
    main()

