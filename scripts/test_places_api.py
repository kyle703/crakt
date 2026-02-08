#!/usr/bin/env python3
"""
Quick test script to verify Google Places API (New) is working correctly.
"""

import json
import sys
import urllib.request

def test_places_api(api_key: str):
    """Test the Places API (New) with a simple search"""
    
    print("Testing Google Places API (New)...")
    print("=" * 60)
    
    # Test 1: Text Search
    print("\n1. Testing Text Search...")
    url = "https://places.googleapis.com/v1/places:searchText"
    
    request_body = {
        "textQuery": "Pacific Edge climbing gym Santa Cruz CA"
    }
    
    headers = {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": api_key,
        "X-Goog-FieldMask": "places.name,places.displayName,places.formattedAddress"
    }
    
    try:
        req = urllib.request.Request(
            url=url,
            data=json.dumps(request_body).encode('utf-8'),
            headers=headers,
            method="POST"
        )
        
        with urllib.request.urlopen(req, timeout=30) as response:
            data = json.loads(response.read().decode('utf-8'))
            
        print("✓ Text Search successful!")
        print(f"Response keys: {list(data.keys())}")
        
        if data.get("places"):
            place = data["places"][0]
            print(f"\nFirst result:")
            print(f"  Resource name: {place.get('name', 'N/A')}")
            print(f"  Display name: {place.get('displayName', {}).get('text', 'N/A')}")
            print(f"  Address: {place.get('formattedAddress', 'N/A')}")
            
            # Test 2: Place Details
            resource_name = place.get("name")
            if resource_name:
                print(f"\n2. Testing Place Details for: {resource_name}...")
                
                details_url = f"https://places.googleapis.com/v1/{resource_name}"
                details_headers = {
                    "Content-Type": "application/json",
                    "X-Goog-Api-Key": api_key,
                    "X-Goog-FieldMask": "displayName,formattedAddress,internationalPhoneNumber,websiteUri,location,businessStatus"
                }
                
                req2 = urllib.request.Request(
                    url=details_url,
                    headers=details_headers,
                    method="GET"
                )
                
                with urllib.request.urlopen(req2, timeout=30) as response2:
                    details = json.loads(response2.read().decode('utf-8'))
                
                print("✓ Place Details successful!")
                print(f"\nPlace details:")
                print(f"  Name: {details.get('displayName', {}).get('text', 'N/A')}")
                print(f"  Address: {details.get('formattedAddress', 'N/A')}")
                print(f"  Phone: {details.get('internationalPhoneNumber', 'N/A')}")
                print(f"  Website: {details.get('websiteUri', 'N/A')}")
                print(f"  Status: {details.get('businessStatus', 'N/A')}")
                
                location = details.get('location', {})
                if location:
                    print(f"  Location: {location.get('latitude', 'N/A')}, {location.get('longitude', 'N/A')}")
                
                print("\n" + "=" * 60)
                print("✓ All tests passed! API is working correctly.")
                print("=" * 60)
                return True
        else:
            print("✗ No places found in search results")
            return False
            
    except urllib.error.HTTPError as e:
        print(f"✗ HTTP Error: {e.code} {e.reason}")
        print(f"URL: {e.url}")
        try:
            error_body = e.read().decode('utf-8')
            print(f"Error details: {error_body}")
        except:
            pass
        return False
    except Exception as e:
        print(f"✗ Error: {type(e).__name__}: {e}")
        return False

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python test_places_api.py YOUR_API_KEY")
        sys.exit(1)
    
    api_key = sys.argv[1]
    success = test_places_api(api_key)
    sys.exit(0 if success else 1)

