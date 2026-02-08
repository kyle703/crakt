# Climbing Gym Database Scripts

This directory contains scripts for managing and validating the climbing gym database.

## Files

- `usa_climbing_gyms.py` - Original script to scrape and populate gym database
- `validate_gyms.py` - Validation script to cross-reference and update gym data
- `gyms.sqlite` - SQLite database containing gym information
- `gyms.json` - JSON export of gym data

## Validating Gym Data

The `validate_gyms.py` script cross-references your gym database against search APIs to ensure information is up-to-date.

### Quick Start

#### Using Google Places API (New) - Recommended

Google Places API (New) provides the most comprehensive and accurate data using the latest v1 API:

```bash
# Test with first 10 gyms
python validate_gyms.py --api-key YOUR_GOOGLE_API_KEY --limit 10

# Validate all gyms (dry run - won't modify database)
python validate_gyms.py --api-key YOUR_GOOGLE_API_KEY --dry-run

# Validate and auto-update database
python validate_gyms.py --api-key YOUR_GOOGLE_API_KEY --auto-update
```

**Getting a Google Places API Key:**
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable "Places API (New)" 
4. Create credentials → API Key
5. Restrict the key to Places API for security

**About the New API:**  
This script uses the [Places API (New)](https://developers.google.com/maps/documentation/places/web-service/op-overview) with enhanced features:
- More accurate business status (closed/moved detection)
- Better formatted addresses and phone numbers
- Enhanced accessibility and amenity information
- AI-powered place summaries (optional)

**Pricing:** Google Places API has a free tier with $200/month credit (~17,000 requests/month free). Each gym requires 2 requests, so ~8,500 gyms free per month.

#### Using OpenStreetMap Nominatim (Free)

For a free alternative (less detailed results):

```bash
# Nominatim is rate-limited to 1 request/second
python validate_gyms.py --api-type nominatim --rate-limit 1.0 --limit 10
```

### Rate Limiting

The script includes smart rate limiting to avoid hitting API limits:

- **Google Places API**: Default 10 req/s (adjustable with `--rate-limit`)
- **Nominatim**: Max 1 req/s (enforced by API)
- Automatic exponential backoff on 429 (rate limit) errors
- Respects `Retry-After` headers
- Token bucket algorithm prevents bursts

### What Gets Validated

The script checks:

- ✓ **Name** - Is the gym name still correct?
- ✓ **Address** - Has the gym moved?
- ✓ **Phone** - Is the phone number current?
- ✓ **Website** - Has the website changed?
- ✓ **Location** - Are coordinates accurate?
- ✓ **Status** - Is the gym permanently closed?

### Validation Statuses

- `valid` - All information matches, no changes needed
- `updated` - Information has changed (phone, website, etc.)
- `moved` - Gym has relocated to a new address
- `closed` - Gym is permanently closed
- `not_found` - Could not find gym in API results
- `error` - API error occurred during validation

### Output

The script produces:

1. **Console output** - Real-time progress and results
2. **Database table** - `validation_results` table with full history
3. **JSON report** - `gyms_problems.json` with gyms needing attention

### Example Output

```
[1/432] Validating: Pacific Edge (Santa Cruz, CA)
  ✓ Status: VALID (confidence: 0.95)

[2/432] Validating: Momentum Indoor Climbing Millcreek (Salt Lake City, UT)
  ⟳ Status: UPDATED (confidence: 0.87)
    - Phone changed: (801) 555-0100 -> (801) 555-0199
    - Website changed: http://momentumclimbing.com -> https://momentumclimbing.com

[3/432] Validating: Old Gym Name (Portland, OR)
  ✗ Status: CLOSED (confidence: 1.00)
    - Gym is permanently closed

================================================================================
VALIDATION SUMMARY
================================================================================
Total gyms validated: 432
  Valid: 387 (89.6%)
  Updated: 38 (8.8%)
  Closed: 5 (1.2%)
  Not found: 2 (0.4%)

API requests: 864
Time elapsed: 86.4s
Average rate: 10.0 req/s
```

### Advanced Options

```bash
# Custom rate limit (be conservative to avoid throttling)
python validate_gyms.py --api-key KEY --rate-limit 5.0

# Dry run (show what would be updated without modifying database)
python validate_gyms.py --api-key KEY --dry-run --auto-update

# Test with subset of gyms
python validate_gyms.py --api-key KEY --limit 50

# Auto-update database with validated info
python validate_gyms.py --api-key KEY --auto-update
```

### Database Schema

#### validation_results table

```sql
CREATE TABLE validation_results (
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
    is_permanently_closed INTEGER,
    changes TEXT,  -- JSON array of changes
    error_message TEXT,
    api_source TEXT,
    FOREIGN KEY (gym_id) REFERENCES gyms(id)
);
```

### Querying Validation Results

```sql
-- Find all closed gyms
SELECT g.name, g.city, g.state, v.validation_date
FROM gyms g
JOIN validation_results v ON g.id = v.gym_id
WHERE v.status = 'closed' AND v.is_permanently_closed = 1
ORDER BY v.validation_date DESC;

-- Find gyms with updated information
SELECT g.name, g.city, v.changes
FROM gyms g
JOIN validation_results v ON g.id = v.gym_id
WHERE v.status = 'updated'
ORDER BY g.name;

-- Check validation coverage
SELECT 
    COUNT(DISTINCT gym_id) as validated_gyms,
    (SELECT COUNT(*) FROM gyms) as total_gyms,
    ROUND(COUNT(DISTINCT gym_id) * 100.0 / (SELECT COUNT(*) FROM gyms), 1) as coverage_pct
FROM validation_results;
```

### Best Practices

1. **Start small** - Test with `--limit 10` first
2. **Use dry-run** - Always test with `--dry-run` before `--auto-update`
3. **Check problems** - Review `gyms_problems.json` manually before bulk updates
4. **Rate limit conservatively** - Start with lower rate limits and increase if stable
5. **Run periodically** - Validate quarterly to keep data fresh
6. **Monitor costs** - Check API usage in your cloud console

### Troubleshooting

**"Rate limited (429)"**
- Decrease `--rate-limit` value
- The script will auto-retry with backoff

**"API key invalid"**
- Verify your API key is correct
- Ensure Places API is enabled in Google Cloud Console
- Check API key restrictions

**"Not found" results**
- Some gyms may have different names in Google
- Small/new gyms may not be indexed
- Try running original scraper to get fresh OSM data

**High false positives**
- Adjust confidence threshold (0.7 default)
- Some gyms legitimately changed names/moved
- Manually verify low-confidence matches

## Updating the Database

To refresh the entire database with new data:

```bash
# Full refresh from OSM + USA Climbing
python usa_climbing_gyms.py --sqlite gyms.sqlite --json gyms.json

# Then validate the new data
python validate_gyms.py --api-key YOUR_KEY --dry-run
```

## License

Gym data includes information from:
- © OpenStreetMap contributors (ODbL license)
- USA Climbing partner directory
- Google Places API (if used for validation)

Please attribute appropriately in your application.

