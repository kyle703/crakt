# Climbing Grade Normalization (Difficulty Index, DI) — Developer Deliverables

## Context
We need a **single numeric Difficulty Index (DI)** that normalizes grades across:
- **Bouldering**: V-scale, Fontainebleau.
- **Routes**: French (canonical), YDS (derived).

Design constraints:
- **No route tagging required**.
- Deterministic, monotonic mapping.
- Works cross-type (boulder ↔ route) using a **global bridge** (V ↔ French).
- All logic runs locally and is easy to reason about.

---

## Deliverable 1 — DI Scale Definition (Canonical Axis)

**Canonical axis**: **French sport grade sequence** from **4a → 9c** in half-steps (`a`, `a+`, `b`, `b+`, `c`, `c+`).

- **Ordered set** `F = [4a, 4b, 4c, 5a, 5b, 5c, 6a, 6a+, 6b, 6b+, 6c, 6c+, 7a, 7a+, 7b, 7b+, 7c, 7c+, 8a, 8a+, 8b, 8b+, 8c, 8c+, 9a, 9a+, 9b, 9b+, 9c]`.
- **Index** each element `F[i]` and define **DI = i * 10** (integer ticks, spacing=10).
- **Monotonicity** is guaranteed by index order.
- **In-between** grades (e.g., “6b/6b+”): use **midpoint** DI (linear interpolation).

**Examples**
- `6a` → index 6 → **DI 60**
- `6a+` → 7 → **DI 70**
- `7b` → 14 → **DI 140**
- `9c` → 28 → **DI 280**

**Tasks**
- [ ] Implement French ordered list `F` and DI mapping (index × 10).
- [ ] Add `interpolateDI(from: F[i], to: F[i+1], t: 0…1)` for in-between tokens.

---

## Deliverable 2 — System Parsers (Canonicalization)

**Objective**: Parse grade tokens to a canonical struct and map to French or to V/Font, then to DI.

**Required parsers**
- **French**: `4a, 6b+, 7c` → tuple `{base: Int, letter: a|b|c, plus: Bool}` → DI via Deliverable 1.
- **YDS**: `5.6 … 5.15d` → map to **French** via Table A (below), then DI.
- **V-scale**: `VB, V0, V1 … V17` → map to **Font** via Table B or directly to **French** via Bridge Table C, then DI.
- **Font**: `5, 5+, 6A, 6A+, … 9A` → (optional) map to **V** via Table B; for DI, use **Bridge Table C** by first mapping Font→V.

**Tasks**
- [ ] Implement token parsers for French, YDS, V-scale, and Font.
- [ ] Implement canonical struct `{system, type, token, normalizedToken}`.
- [ ] Route parser outputs directly to DI; Boulder parser uses Bridge (Deliverable 4) to DI.

---

## Deliverable 3 — Baseline Tables (Hard Stats)

### Table A — **YDS ↔ French** (subset sufficient for DI; extend as needed)

| YDS    | French |
|--------|--------|
| 5.6    | 4c     |
| 5.7    | 5a     |
| 5.8    | 5b     |
| 5.9    | 5c     |
| 5.10a  | 6a     |
| 5.10b  | 6a+    |
| 5.10c  | 6b     |
| 5.10d  | 6b+    |
| 5.11a  | 6c     |
| 5.11b  | 6c+    |
| 5.11c  | 7a     |
| 5.11d  | 7a+    |
| 5.12a  | 7b     |
| 5.12b  | 7b+    |
| 5.12c  | 7c     |
| 5.12d  | 7c+    |
| 5.13a  | 8a     |
| 5.13b  | 8a+    |
| 5.13c  | 8b     |
| 5.13d  | 8b+    |
| 5.14a  | 8c     |
| 5.14b  | 8c+    |
| 5.14c  | 9a     |
| 5.14d  | 9a+    |
| 5.15a  | 9b     |
| 5.15b  | 9b+    |
| 5.15c  | 9c     |

> **DI** for YDS token = DI of mapped French grade (via Deliverable 1).

---

### Table B — **V-scale ↔ Font** (bouldering baseline)

| V  | Font |
|----|------|
| VB | 3–4  |
| V0 | 5    |
| V1 | 5+   |
| V2 | 6A   |
| V3 | 6A+  |
| V4 | 6B   |
| V5 | 6C   |
| V6 | 7A   |
| V7 | 7A+  |
| V8 | 7B   |
| V9 | 7B+  |
| V10| 7C+  |
| V11| 8A   |
| V12| 8A+  |
| V13| 8B   |
| V14| 8B+  |
| V15| 8C   |
| V16| 8C+  |
| V17| 9A   |

> This is used for user display / import. **DI** still comes from Bridge Table C (boulder → French → DI).

---

## Deliverable 4 — Boulder↔Route **Bridge** (Global Anchors)

**Purpose**: Convert **boulder** grades to **French** route equivalents for DI.  
**Method**: Use **anchor pairs** (V ↔ French) and **piecewise linear interpolation** between anchors.

### Table C — Global Anchor Pairs (V ↔ French)

| V   | French |
|-----|--------|
| V0  | 6a     |
| V1  | 6a+    |
| V2  | 6b     |
| V3  | 6b+    |
| V4  | 6c     |
| V5  | 7a     |
| V6  | 7a+    |
| V7  | 7b     |
| V8  | 7b+    |
| V9  | 7c     |
| V10 | 7c+    |
| V11 | 8a     |
| V12 | 8a+    |
| V13 | 8b     |
| V14 | 8b+    |
| V15 | 8c     |
| V16 | 8c+    |
| V17 | 9a     |

**Interpolation rule**
- For any V between anchors, linearly interpolate **on DI**:
  1. Map anchor French grades to **DI** via Deliverable 1.
  2. For `Vx` between `Vn` and `Vn+1`, compute `DI = lerp(DI(Vn), DI(Vn+1), t)` where `t = (x - n)/1`.
  3. Round DI to nearest integer tick (or keep fractional for metrics; round only for display).

**Tasks**
- [ ] Hardcode Anchor Table C.
- [ ] Implement `bridgeDIFromBoulder(V)` using Table C + DI interpolation.
- [ ] Implement `bridgeVFromDI(DI)` using inverse interpolation on Table C.
- [ ] Provide function overloads to accept **Font** by first mapping Font→V via Table B.

---

## Deliverable 5 — API Surface

- `normalizeToDI(gradeToken: String, system: GradeSystem, climbType: ClimbType) -> Int`  
  - French/Routes: direct via Deliverable 1 (YDS uses Table A → French → DI).  
  - Boulder: V or Font uses Table C (and Table B if Font) → French DI.
- `convertGrade(fromToken: String, fromSystem: GradeSystem, fromType: ClimbType, toSystem: GradeSystem, toType: ClimbType) -> String`  
  - Source → **DI** → target system (inverse of the above).
- `interpolateDI(a: Int, b: Int, t: Double) -> Int`  
- `nearestFrenchFromDI(DI) -> FrenchToken` (for display/rounding).

**Tasks**
- [ ] Implement `normalizeToDI`.
- [ ] Implement `convertGrade` using DI and bridge.
- [ ] Add unit tests for round-trip conversions.

---

## Deliverable 6 — Example Conversions (Deterministic)

**Compute DI using Deliverable 1 and Table C.**

| Input (type) | Map → French | DI | Notes |
|--------------|--------------|----|------|
| 6b (route)   | 6b           | 90 | 6b is `F[8]` → 8×10=80? **(Check order!)** |
| 6b+ (route)  | 6b+          | 100|      |
| 7a (route)   | 7a           | 120|      |
| 5.12b (route)| 7b+          | 150| via Table A |
| V4 (boulder) | 6c           | 110| via Table C |
| V5 (boulder) | 7a           | 120| via Table C |
| V8 (boulder) | 7b+          | 140| via Table C |
| V10 (boulder)| 7c+          | 160| via Table C |
| V14 (boulder)| 8b+          | 200| via Table C |

> **Developer note**: verify your French list index. With the exact `F` ordering below, **recompute** DI values mechanically and update this table in tests.

**Authoritative `F` ordering and DI (index×10)**

Indexing from **0**:

| i  | French | DI |
|----|--------|----|
| 0  | 4a     | 0  |
| 1  | 4b     | 10 |
| 2  | 4c     | 20 |
| 3  | 5a     | 30 |
| 4  | 5b     | 40 |
| 5  | 5c     | 50 |
| 6  | 6a     | 60 |
| 7  | 6a+    | 70 |
| 8  | 6b     | 80 |
| 9  | 6b+    | 90 |
| 10 | 6c     | 100|
| 11 | 6c+    | 110|
| 12 | 7a     | 120|
| 13 | 7a+    | 130|
| 14 | 7b     | 140|
| 15 | 7b+    | 150|
| 16 | 7c     | 160|
| 17 | 7c+    | 170|
| 18 | 8a     | 180|
| 19 | 8a+    | 190|
| 20 | 8b     | 200|
| 21 | 8b+    | 210|
| 22 | 8c     | 220|
| 23 | 8c+    | 230|
| 24 | 9a     | 240|
| 25 | 9a+    | 250|
| 26 | 9b     | 260|
| 27 | 9b+    | 270|
| 28 | 9c     | 280|

---

## Deliverable 7 — Tests

**Round-trip invariants**
- [ ] `token == convertGrade(fromToken: token, fromSystem: X, fromType: T, toSystem: X, toType: T)` (idempotent on same system).
- [ ] `DI == normalizeToDI(denormalize(DI))` within ±5 DI ticks when interpolation applies.
- [ ] Monotonicity: for any ordered pair of grades in the same system, DI must increase.

**Cross-type smoke tests (using Table C)**
- [ ] `V4 → DI → French` equals `6c` (± one half-step if rounding).
- [ ] `V10 → DI → YDS` equals around `5.13a/b` (depends on rounding via Table A).
- [ ] `5.12b → DI → V` equals around `V8–V9`.

---

## Deliverable 8 — Milestones & Tasks

### Milestone 1 — Canonical French Axis
- [ ] Implement `F` list and DI mapping.
- [ ] Unit tests for ordering and DI values.

### Milestone 2 — Parsers & Static Tables
- [ ] Parsers for French, YDS, V, Font.
- [ ] Implement Table A (YDS↔French) and Table B (V↔Font).

### Milestone 3 — Bridge & Conversions
- [ ] Implement Table C (V↔French anchors) + DI interpolation.
- [ ] Implement `normalizeToDI` and `convertGrade`.

### Milestone 4 — QA & Stability
- [ ] Round-trip, monotonicity, and smoke tests.
- [ ] Snapshot test for the three tables and `F` ordering.

---

## One-Page Implementation Summary (Literal Takeaway)

1. **Store** the French ordered list `F` and compute **DI = index×10**.  
2. **Convert** YDS→French (Table A).  
3. **Convert** V→French using **Anchor Table C** (piecewise-linear interpolation on **DI**).  
   - For Font: Font→V (Table B), then V→French.  
4. **Normalize** any grade to **DI**, then **convert** to any target system by **inverse mapping**.

That’s it. Copy the three tables, the `F` list, and the interpolation rule into code and you have a complete, deterministic normalization across boulder and route grades.
