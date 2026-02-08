# Validation Script Changelog

## v2.0 - Updated to Places API (New)

### Major Changes

**Migrated from Legacy Places API to Places API (New)**

The script now uses Google's [Places API (New) v1](https://developers.google.com/maps/documentation/places/web-service/op-overview) instead of the legacy API. This provides:

#### API Endpoint Changes

**Old (Legacy API):**
- `https://maps.googleapis.com/maps/api/place/textsearch/json`
- `https://maps.googleapis.com/maps/api/place/details/json`
- GET requests with query parameters

**New (Places API v1):**
- `https://places.googleapis.com/v1/places:searchText`
- `https://places.googleapis.com/v1/places/{PLACE_ID}`
- POST requests with JSON bodies
- Uses `X-Goog-Api-Key` header for authentication
- Uses `X-Goog-FieldMask` to specify returned fields

#### Response Format Changes

| Field | Legacy API | New API (v1) |
|-------|-----------|-------------|
| Name | `name` | `displayName.text` |
| Address | `formatted_address` | `formattedAddress` |
| Phone | `formatted_phone_number` | `internationalPhoneNumber` |
| Website | `website` | `websiteUri` |
| Location | `geometry.location.lat/lng` | `location.latitude/longitude` |
| Status | `business_status` | `businessStatus` |

#### Improvements in New API

1. **Better Data Quality**
   - More accurate business status (open/closed)
   - Consistent international phone formatting
   - Enhanced location data

2. **Enhanced Features**
   - AI-powered place summaries (optional)
   - More accessibility information
   - Better attribute coverage (outdoor seating, etc.)
   - Improved search relevance

3. **Future-Proof**
   - Active development and support
   - New features regularly added
   - Better documentation

#### Code Changes

**Text Search:**
```python
# Old
url = f"{base_url}/textsearch/json?query={query}&key={key}"
response = requests.get(url)

# New
url = f"{base_url}/places:searchText"
body = {"textQuery": query, "maxResultCount": 1}
headers = {"X-Goog-Api-Key": key, "X-Goog-FieldMask": "places.id,..."}
response = requests.post(url, json=body, headers=headers)
```

**Place Details:**
```python
# Old
url = f"{base_url}/details/json?place_id={id}&key={key}&fields=..."
response = requests.get(url)

# New
url = f"{base_url}/places/{id}"
headers = {"X-Goog-Api-Key": key, "X-Goog-FieldMask": "displayName,..."}
response = requests.get(url, headers=headers)
```

#### Migration Impact

**For Users:**
- ✅ No changes to command-line usage
- ✅ Same API key works (just enable Places API New)
- ✅ Better accuracy in results
- ✅ Same pricing structure (covered by free tier)

**For Developers:**
- Updated all API calls to new format
- Updated response parsing for new field names
- Added proper field masks for efficiency
- Updated documentation and examples

#### Testing

```bash
# Verify the new API works
python3 validate_gyms.py --api-key YOUR_KEY --limit 5 --dry-run
```

Expected behavior:
- Should successfully search and find gyms
- Phone numbers now in international format
- More accurate closed/moved detection

#### Documentation Updates

All documentation files updated to reference Places API (New):
- ✅ `validate_gyms.py` - docstring and code
- ✅ `README.md` - setup instructions
- ✅ `VALIDATION_GUIDE.md` - detailed guide
- ✅ `QUICK_START.md` - quick reference
- ✅ `config.example.txt` - example commands

#### References

- [Places API (New) Overview](https://developers.google.com/maps/documentation/places/web-service/op-overview)
- [Text Search (New)](https://developers.google.com/maps/documentation/places/web-service/text-search)
- [Place Details (New)](https://developers.google.com/maps/documentation/places/web-service/place-details)
- [Migration Guide](https://developers.google.com/maps/documentation/places/web-service/migrate-places)

#### Backward Compatibility

The legacy API endpoints are **deprecated** but still work. However, Google recommends migrating to the new API:
- Better data quality
- Active support and updates
- New features (AI summaries, etc.)
- Same pricing/free tier

#### What's Next

Future enhancements possible with new API:
- [ ] Add AI-powered place summaries
- [ ] Include review summaries
- [ ] Add accessibility information validation
- [ ] Support for EV charging station details
- [ ] Enhanced amenity detection

---

## v1.0 - Initial Release

- Cross-reference validation against Google Places API (legacy)
- OpenStreetMap Nominatim support
- Rate limiting with token bucket
- Automatic retry with exponential backoff
- Database update capabilities
- Dry-run mode
- Comprehensive reporting

