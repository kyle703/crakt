# Troubleshooting Guide

## Testing the API

If you're getting errors, first test that your API key is working correctly:

```bash
# Test your API key with a simple search
python3 test_places_api.py YOUR_API_KEY
```

This will:
1. Test Text Search with a known climbing gym
2. Test Place Details retrieval
3. Show you the exact API responses

## Common Errors

### HTTP Error 404: Not Found

**Cause**: API endpoint not found or incorrect resource name format

**Solutions**:
1. Verify you enabled "Places API (New)" not the legacy "Places API"
2. Check that your API key has Places API enabled
3. Run the test script to verify API access

### HTTP Error 403: Forbidden

**Cause**: API key invalid or not authorized for Places API

**Solutions**:
1. Verify API key is correct
2. Check API key restrictions (should allow Places API)
3. Enable "Places API (New)" in Google Cloud Console
4. Check billing is enabled (required even for free tier)

### HTTP Error 429: Too Many Requests

**Cause**: Rate limit exceeded

**Solutions**:
1. Reduce rate limit: `--rate-limit 5.0`
2. The script will auto-retry with backoff
3. Check your quota in Google Cloud Console

### HTTP Error 400: Bad Request

**Cause**: Invalid request format

**Solutions**:
1. Update to latest version of script
2. Check field mask syntax
3. Verify request body format

## Enabling Places API (New)

1. Go to https://console.cloud.google.com/
2. Select your project (or create new one)
3. Go to "APIs & Services" > "Library"
4. Search for "Places API (New)"
5. Click "Enable"
6. Create API key in "Credentials" section

**Important**: You need the NEW Places API, not the legacy one!

## API Field Masks

The new Places API uses field masks to specify which data to return.

### Text Search Field Mask
```
places.name,places.displayName,places.formattedAddress,places.location
```

### Place Details Field Mask
```
displayName,formattedAddress,internationalPhoneNumber,websiteUri,location,businessStatus
```

## Response Format

### Text Search Response
```json
{
  "places": [
    {
      "name": "places/ChIJxxxxx",  // Resource name
      "displayName": {
        "text": "Pacific Edge",
        "languageCode": "en"
      }
    }
  ]
}
```

### Place Details Response
```json
{
  "name": "places/ChIJxxxxx",
  "displayName": {
    "text": "Pacific Edge"
  },
  "formattedAddress": "123 Main St, Santa Cruz, CA 95060",
  "internationalPhoneNumber": "+1 831-454-9254",
  "websiteUri": "https://example.com",
  "location": {
    "latitude": 36.974,
    "longitude": -122.027
  },
  "businessStatus": "OPERATIONAL"
}
```

## Debug Mode

To see detailed API responses, you can temporarily add debug logging:

1. Edit `validate_gyms.py`
2. Add after API calls:
   ```python
   print(f"DEBUG: Response = {json.dumps(data, indent=2)}")
   ```

## Checking Quota

Monitor your API usage:
1. Go to Google Cloud Console
2. Navigate to "APIs & Services" > "Dashboard"
3. Click on "Places API (New)"
4. View "Metrics" tab

## Alternative: Use Nominatim (Free)

If you can't get Google API working, use the free alternative:

```bash
python3 validate_gyms.py --api-type nominatim --rate-limit 1.0 --limit 5
```

Note: Nominatim is:
- ✓ Free
- ✓ No API key needed
- ✗ Less accurate
- ✗ Slower (1 req/s max)
- ✗ Less detailed data

## Getting Help

1. Run `python3 test_places_api.py YOUR_KEY` first
2. Check the error message details
3. Verify Places API (New) is enabled
4. Check billing is set up in Google Cloud
5. Review API quota limits

## Useful Links

- [Places API (New) Overview](https://developers.google.com/maps/documentation/places/web-service/op-overview)
- [Text Search Documentation](https://developers.google.com/maps/documentation/places/web-service/text-search)
- [Place Details Documentation](https://developers.google.com/maps/documentation/places/web-service/place-details)
- [Google Cloud Console](https://console.cloud.google.com/)
- [API Pricing](https://developers.google.com/maps/billing-and-pricing/pricing)

