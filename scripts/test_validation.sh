#!/bin/bash
# Quick test script to validate a few gyms using the free Nominatim API
# This lets you test the validation system without needing an API key

echo "=========================================="
echo "Testing Gym Validation (First 5 gyms)"
echo "=========================================="
echo ""
echo "Using OpenStreetMap Nominatim API (free, rate-limited to 1 req/s)"
echo "This will take about 10-15 seconds..."
echo ""

python3 validate_gyms.py \
    --api-type nominatim \
    --rate-limit 1.0 \
    --limit 5 \
    --dry-run

echo ""
echo "=========================================="
echo "Test complete!"
echo "=========================================="
echo ""
echo "To validate all gyms with better accuracy, use Google Places API:"
echo "  python3 validate_gyms.py --api-key YOUR_KEY --dry-run"
echo ""

