# Additional Fields Available from Places API (New)

The Places API (New) provides many more fields that we're currently **requesting but not storing** in the database. Here's what's available and recommended additions:

## Currently Stored Fields ✅

- name
- houseNumber, street, city, state, postcode, country
- phone
- website  
- hours
- latitude, longitude
- isIndoor
- source, source_id
- createdAt, updatedAt

## Fields We're Now Requesting But NOT Storing 🔥

### High Priority - Should Add

| Field | Type | Description | Use Case |
|-------|------|-------------|----------|
| **rating** | float | Google rating (1-5 stars) | Sort gyms by quality, show ratings to users |
| **userRatingCount** | int | Number of reviews | Quality indicator, trust metric |
| **priceLevel** | string | Price level ($ to $$$$) | Help users find affordable gyms |
| **googleMapsUri** | string | Link to Google Maps | Deep link for directions |
| **types** | array | Place types/categories | Verify it's actually a gym |

### Medium Priority - Nice to Have

| Field | Type | Description | Use Case |
|-------|------|-------------|----------|
| **addressComponents** | array | Structured address parts | Better address parsing, search |
| **primaryType** | string | Primary category | Main classification |
| **editorialSummary** | string | Short description | Show users what to expect |
| **generativeSummary** | string | AI-generated summary | Rich gym description |

## Fields Available But Not Currently Requested 🤔

### Worth Adding to Request

| Field | Type | Description | Use Case |
|-------|------|-------------|----------|
| **accessibilityOptions** | object | Wheelchair access info | Accessibility filtering |
| **parkingOptions** | object | Parking availability | Important for gym selection |
| **paymentOptions** | object | Accepted payment types | User convenience |
| **goodForChildren** | boolean | Kid-friendly | Family filtering |
| **allowsDogs** | boolean | Pet-friendly | Convenience |
| **restroom** | boolean | Has restrooms | Basic amenity |
| **goodForGroups** | boolean | Group-friendly | Team/class filtering |
| **photos** | array | Photo references | Visual content |
| **reviews** | array | User reviews | Social proof, quality indicator |
| **outdoorSeating** | boolean | Outdoor area | Amenity (outdoor climbing?) |

## Recommended Database Schema Changes

### Add to `gyms` table:

```sql
ALTER TABLE gyms ADD COLUMN rating REAL;
ALTER TABLE gyms ADD COLUMN rating_count INTEGER;
ALTER TABLE gyms ADD COLUMN price_level TEXT;
ALTER TABLE gyms ADD COLUMN google_maps_uri TEXT;
ALTER TABLE gyms ADD COLUMN primary_type TEXT;
ALTER TABLE gyms ADD COLUMN editorial_summary TEXT;
ALTER TABLE gyms ADD COLUMN has_parking INTEGER DEFAULT 0;
ALTER TABLE gyms ADD COLUMN wheelchair_accessible INTEGER DEFAULT 0;
ALTER TABLE gyms ADD COLUMN good_for_children INTEGER DEFAULT 0;
```

### Create new `gym_amenities` table:

```sql
CREATE TABLE gym_amenities (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    gym_id INTEGER NOT NULL,
    amenity_type TEXT NOT NULL,
    amenity_value TEXT,
    FOREIGN KEY (gym_id) REFERENCES gyms(id),
    UNIQUE(gym_id, amenity_type)
);
```

Store things like:
- parking_options
- payment_options
- accessibility_options
- etc.

### Create `gym_photos` table:

```sql
CREATE TABLE gym_photos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    gym_id INTEGER NOT NULL,
    photo_reference TEXT NOT NULL,
    width INTEGER,
    height INTEGER,
    attribution TEXT,
    FOREIGN KEY (gym_id) REFERENCES gyms(id)
);
```

## Implementation Priority

### Phase 1: Quick Wins (5 min)
Add these to the database schema and validation script:
- ✅ **hours** - Already added!
- ⭐ **rating** - Critical for sorting
- ⭐ **ratingCount** - Trust indicator
- ⭐ **priceLevel** - User filtering
- ⭐ **googleMapsUri** - Navigation

### Phase 2: Enhanced Data (15 min)
- **types** - Verify gym classification
- **addressComponents** - Better address handling
- **editorialSummary** - Rich descriptions

### Phase 3: Full Feature Set (30 min)
- **accessibilityOptions** - Wheelchair access
- **parkingOptions** - Parking info
- **photos** - Visual content
- **reviews** - Social proof

## Code Changes Needed

### 1. Update Field Mask (Done! ✅)
```python
"X-Goog-FieldMask": "displayName,formattedAddress,internationalPhoneNumber,nationalPhoneNumber,websiteUri,location,businessStatus,currentOpeningHours,regularOpeningHours,rating,userRatingCount,priceLevel,googleMapsUri,types,addressComponents"
```

### 2. Extract Fields from Response
```python
# In _compare_details method
found_rating = details.get("rating")
found_rating_count = details.get("userRatingCount")
found_price_level = details.get("priceLevel")
found_google_maps_uri = details.get("googleMapsUri")
found_types = details.get("types", [])
```

### 3. Update ValidationResult dataclass
```python
found_rating: Optional[float] = None
found_rating_count: Optional[int] = None
found_price_level: Optional[str] = None
found_google_maps_uri: Optional[str] = None
found_types: Optional[List[str]] = None
```

### 4. Update Database Operations
- Save to validation_results table
- Update gyms table in update_gyms_from_validation

## Example Enhanced Gym Record

```json
{
  "name": "Planet Granite",
  "address": "123 Main St, San Francisco, CA 94110",
  "phone": "+1 415-555-0100",
  "website": "https://planetgranite.com",
  "latitude": 37.7749,
  "longitude": -122.4194,
  "hours": "Monday: 6:00 AM – 11:00 PM; Tuesday: 6:00 AM – 11:00 PM...",
  "rating": 4.6,
  "rating_count": 1247,
  "price_level": "$$",
  "google_maps_uri": "https://maps.google.com/?cid=12345",
  "types": ["gym", "health", "point_of_interest"],
  "has_parking": true,
  "wheelchair_accessible": true,
  "good_for_children": true
}
```

## Benefits of Additional Fields

1. **Better User Experience**
   - Filter by rating, price, amenities
   - Show rich information cards
   - Direct navigation links

2. **Quality Metrics**
   - Rating and review counts
   - Price transparency
   - Verified amenities

3. **Accessibility**
   - Wheelchair access info
   - Parking availability
   - Kid-friendly indicators

4. **Discovery**
   - Photos for visual appeal
   - Summaries for quick info
   - Categories for filtering

## Recommendation

**Start with Phase 1** (rating, ratingCount, priceLevel, googleMapsUri) - these are high-value, low-effort additions that significantly improve the gym database utility.

The current update addresses the immediate issue (coordinates not being updated), but adding these fields would make the database much more valuable for your climbing app.

