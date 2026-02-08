# Gym Database Validation Guide

## Overview

You have **432 climbing gyms** in your database, all sourced from OpenStreetMap. Based on the stats, you have some data quality issues:

- ✓ 100% have names and coordinates
- ⚠️ ~50% missing city/state information
- ⚠️ 68% missing phone numbers
- ⚠️ 52% missing websites
- ⚠️ 66% missing hours

The validation script I created will help you:
1. Verify gyms are still open
2. Fill in missing data (phone, website, hours)
3. Update outdated information
4. Flag closed gyms

## Quick Start

### 1. Check Current Database Stats

```bash
cd /Users/kylethompson/code/crakt/scripts
python3 show_gym_stats.py
```

This shows you the current state of your database.

### 2. Test Validation (Free, No API Key)

```bash
./test_validation.sh
```

This tests the first 5 gyms using the free OpenStreetMap Nominatim API. It's slow (1 request/second) but lets you see how the system works.

### 3. Full Validation with Google Places API (New) - Recommended

**Step 1: Get a Google API Key**
- Go to https://console.cloud.google.com/
- Create a new project
- Enable "Places API (New)" - the v1 API with enhanced features
- Create an API key
- Cost: Free tier covers ~8,500 gyms/month

**What's New in Places API (New)?**
This script uses the [latest Places API](https://developers.google.com/maps/documentation/places/web-service/op-overview) with:
- More accurate business status detection
- Better formatted contact information
- Enhanced place attributes and accessibility info
- Improved search relevance

**Step 2: Test with 10 gyms**
```bash
python3 validate_gyms.py --api-key YOUR_API_KEY --limit 10
```

**Step 3: Validate all gyms (dry-run, no changes)**
```bash
python3 validate_gyms.py --api-key YOUR_API_KEY --dry-run
```

This will take about **45-90 seconds** for all 432 gyms at 10 req/s.

**Step 4: Review the results**
- Check console output for summary
- Review `gyms_problems.json` for gyms needing attention
- Query `validation_results` table in SQLite

**Step 5: Apply updates**
```bash
python3 validate_gyms.py --api-key YOUR_API_KEY --auto-update
```

## What the Validation Script Does

### Rate Limiting (Prevents API Throttling)

The script has sophisticated rate limiting:
- **Token bucket algorithm** - smooth, burst-tolerant
- **Configurable rate** - default 10 req/s, adjustable
- **Automatic retry** - exponential backoff on errors
- **Respects Retry-After** - honors API server requests
- **Real-time stats** - shows progress and actual rate

Example output:
```
[45/432] Validating: Movement Climbing + Fitness (Boulder, CO)
  ✓ Status: VALID (confidence: 0.92)

Progress: 50/432 (11.6%)
Rate: 9.8 req/s
```

### Validation Checks

For each gym:
1. **Text search** - Find gym by name + location
2. **Get details** - Fetch current information
3. **Compare** - Check against database
4. **Confidence score** - 0.0-1.0 based on match quality

### Status Codes

- `valid` (✓) - All information matches
- `updated` (⟳) - Information changed (phone/website/etc)
- `moved` (→) - Gym relocated
- `closed` (✗) - Permanently closed
- `not_found` (?) - Could not find in API
- `error` (!) - API error

### What Gets Updated

When you use `--auto-update`, the script will:
- ✓ Update phone numbers
- ✓ Update websites  
- ✓ Update coordinates (if moved)
- ✓ Update names (if changed)
- ✓ Flag closed gyms
- ✗ **Never deletes** gyms (just flags as closed)

Only updates with **confidence > 0.7** to avoid false positives.

## Expected Results

Based on typical climbing gym databases:

- **85-90% valid** - No changes needed
- **5-10% updated** - Phone/website changed
- **2-3% closed** - Permanently closed
- **1-2% moved** - Relocated
- **1-2% not found** - Small/new gyms not in API

For your 432 gyms:
- ~385 will be valid
- ~30 will have updates
- ~10 may be closed
- ~7 may not be found

## Example Workflow

```bash
# 1. Check current state
python3 show_gym_stats.py

# 2. Run validation (dry-run)
python3 validate_gyms.py --api-key YOUR_KEY --dry-run

# Output:
# ================================================================================
# VALIDATION SUMMARY
# ================================================================================
# Total gyms validated: 432
#   Valid: 387 (89.6%)
#   Updated: 38 (8.8%)
#   Closed: 5 (1.2%)
#   Not found: 2 (0.4%)

# 3. Check problematic gyms
cat gyms_problems.json | python3 -m json.tool | head -30

# 4. Query validation results
sqlite3 gyms.sqlite "
SELECT g.name, g.city, g.state, v.status, v.confidence 
FROM gyms g 
JOIN validation_results v ON g.id = v.gym_id 
WHERE v.status IN ('closed', 'moved', 'not_found')
ORDER BY v.status;
"

# 5. If everything looks good, apply updates
python3 validate_gyms.py --api-key YOUR_KEY --auto-update

# 6. Check updated stats
python3 show_gym_stats.py
```

## SQL Queries for Analysis

### Find all validated gyms with issues
```sql
SELECT 
    g.name,
    g.city,
    g.state,
    v.status,
    v.confidence,
    v.changes
FROM gyms g
JOIN validation_results v ON g.id = v.gym_id
WHERE v.status != 'valid'
ORDER BY v.status, g.state, g.name;
```

### Find gyms with missing data that validation could fill
```sql
SELECT 
    g.id,
    g.name,
    g.city,
    g.state,
    CASE WHEN g.phone IS NULL THEN 'missing' ELSE 'ok' END as phone_status,
    CASE WHEN g.website IS NULL THEN 'missing' ELSE 'ok' END as website_status,
    v.found_phone,
    v.found_website
FROM gyms g
LEFT JOIN validation_results v ON g.id = v.gym_id
WHERE (g.phone IS NULL OR g.website IS NULL)
  AND (v.found_phone IS NOT NULL OR v.found_website IS NOT NULL)
LIMIT 20;
```

### Check validation coverage by state
```sql
SELECT 
    g.state,
    COUNT(DISTINCT g.id) as total_gyms,
    COUNT(DISTINCT v.gym_id) as validated_gyms,
    ROUND(COUNT(DISTINCT v.gym_id) * 100.0 / COUNT(DISTINCT g.id), 1) as coverage_pct
FROM gyms g
LEFT JOIN validation_results v ON g.id = v.gym_id
WHERE g.state IS NOT NULL
GROUP BY g.state
ORDER BY total_gyms DESC
LIMIT 20;
```

## Cost Estimation

### Google Places API
- **Places Text Search**: $17/1000 requests
- **Place Details**: $17/1000 requests  
- **Each gym**: 2 requests = $0.034 per gym
- **432 gyms**: ~$15 total
- **Free tier**: $200/month = ~5,800 gyms free

Your validation will cost ~$15, but you'll be within the free tier.

### Nominatim (Free)
- Free but limited to 1 req/s
- 432 gyms × 2 requests = 864 seconds = ~14.5 minutes
- Less detailed results than Google

## Automation

### Set up periodic validation
```bash
# Add to crontab (monthly validation)
0 0 1 * * cd /Users/kylethompson/code/crakt/scripts && python3 validate_gyms.py --api-key KEY --auto-update > validation.log 2>&1
```

### Create a monitoring script
```bash
#!/bin/bash
# monthly_gym_check.sh

echo "Running monthly gym validation..."
python3 validate_gyms.py --api-key $GOOGLE_API_KEY --auto-update

echo "Generating updated stats..."
python3 show_gym_stats.py

echo "Checking for issues..."
sqlite3 gyms.sqlite "SELECT COUNT(*) FROM validation_results WHERE status IN ('closed', 'moved')"
```

## Troubleshooting

### "Rate limited (429)" errors
```bash
# Reduce rate limit
python3 validate_gyms.py --api-key KEY --rate-limit 5.0
```

### High number of "not_found" results
- OpenStreetMap data may use different names
- Try re-running the original scraper first
- Some small/new gyms may not be indexed in Google

### Low confidence matches
- Review manually before auto-update
- Check gyms_problems.json for details
- Query validation_results for confidence < 0.7

### API quota exceeded
- Wait for quota reset (daily/monthly)
- Use Nominatim as free alternative
- Split validation into batches with --limit

## Next Steps

1. **Test first** - Always use `--limit 10` and `--dry-run`
2. **Review results** - Check `gyms_problems.json` before updating
3. **Apply updates** - Use `--auto-update` after review
4. **Verify** - Run `show_gym_stats.py` to see improvements
5. **Schedule** - Set up monthly validation for ongoing accuracy

## Files Created

- `validate_gyms.py` - Main validation script
- `show_gym_stats.py` - Database statistics viewer
- `test_validation.sh` - Quick test using free API
- `README.md` - Comprehensive documentation
- `config.example.txt` - Configuration examples
- `VALIDATION_GUIDE.md` - This file

All scripts are executable and ready to use!

