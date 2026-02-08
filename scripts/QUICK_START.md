# Quick Start - Gym Validation

## Your Database
- **432 gyms** from OpenStreetMap
- 50% missing contact info (phone/website)
- Need validation to update outdated entries

## Commands

### View Database Stats
```bash
cd /Users/kylethompson/code/crakt/scripts
python3 show_gym_stats.py
```

### Test Validation (Free, No API Key)
```bash
./test_validation.sh
```
Tests 5 gyms using free OSM API (~10 seconds)

### Validate with Google Places API (New)

**Get API Key:** https://console.cloud.google.com/ → Enable "Places API (New)"

Uses the latest [Places API v1](https://developers.google.com/maps/documentation/places/web-service/op-overview) with enhanced accuracy.

```bash
# Test 10 gyms
python3 validate_gyms.py --api-key YOUR_KEY --limit 10

# Validate all (dry-run, no changes)
python3 validate_gyms.py --api-key YOUR_KEY --dry-run

# Apply updates
python3 validate_gyms.py --api-key YOUR_KEY --auto-update
```

## What It Does

✓ Checks if gyms are still open  
✓ Updates phone numbers & websites  
✓ Verifies addresses & coordinates  
✓ Flags closed gyms  
✓ Smart rate limiting (no throttling)  

## Time & Cost

- **Time**: ~45-90 seconds for 432 gyms
- **Cost**: ~$15, but **FREE** with Google's $200/month credit
- **Rate**: 10 requests/second (configurable)

## Results You'll See

```
[1/432] Validating: Pacific Edge (Santa Cruz, CA)
  ✓ Status: VALID (confidence: 0.95)

[2/432] Validating: Old Climbing Gym (Portland, OR)
  ✗ Status: CLOSED (confidence: 1.00)

[3/432] Validating: Mountain Project Gym (Boulder, CO)
  ⟳ Status: UPDATED (confidence: 0.87)
    - Phone changed: (303) 555-0100 -> (303) 555-0199
    - Website updated

================================================================================
VALIDATION SUMMARY
================================================================================
Total gyms validated: 432
  Valid: 387 (89.6%)
  Updated: 38 (8.8%)
  Closed: 5 (1.2%)
  Not found: 2 (0.4%)
```

## Output Files

- `validation_results` table in `gyms.sqlite`
- `gyms_problems.json` - gyms needing attention

## Need Help?

See `VALIDATION_GUIDE.md` for detailed documentation.

