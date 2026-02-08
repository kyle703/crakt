# Gym Finder Setup Instructions

## Required Manual Steps in Xcode

The Gym Finder feature implementation is complete, but requires a few manual steps in Xcode to finish setup.

---

## 1. Bundle the SQLite Database

### Step 1: Copy Database File
1. Copy the file `/Users/kylethompson/code/crakt/scripts/gyms.sqlite` 
2. Drag it into your Xcode project navigator
3. **Important:** Make sure "Copy items if needed" is checked
4. Add to target: `crakt`

### Step 2: Verify Bundle Resources
1. In Xcode, select the `crakt` target
2. Go to "Build Phases" tab
3. Expand "Copy Bundle Resources"
4. Verify `gyms.sqlite` is listed
5. If not, click `+` and add it

### Expected Result
The database should be ~1.5 MB and will be copied into the app bundle during build.

---

## 2. Add Location Permission to Info.plist

### Step 1: Open Info.plist
1. In Xcode project navigator, find `Info.plist`
2. Right-click and select "Open As" → "Source Code"

### Step 2: Add Permission Key
Add this entry inside the `<dict>` tag:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We use your location to find climbing gyms near you and show your distance from gyms.</string>
```

### Alternative (Property List Editor):
1. Right-click in Info.plist
2. Select "Add Row"
3. Key: `Privacy - Location When In Use Usage Description`
4. Type: `String`
5. Value: `We use your location to find climbing gyms near you and show your distance from gyms.`

### Expected Result
When the app first launches, it will prompt the user for location permission with this message.

---

## 3. Verify File Structure

Ensure all new files are in the correct locations:

```
crakt/
├── Models/
│   └── Gym/
│       ├── Gym.swift                      ✅ Created
│       ├── GymDataSource.swift            ✅ Created
│       ├── SQLiteGymDataSource.swift      ✅ Created
│       └── LocationManager.swift          ✅ Created
│
└── Views/
    └── Gym/
        ├── GymFinderView.swift            ✅ Created
        ├── GymMapView.swift               ✅ Created
        ├── GymSearchBar.swift             ✅ Created
        ├── GymListView.swift              ✅ Created
        └── GymDetailSheet.swift           ✅ Created
```

---

## 4. Add Files to Xcode Project

If any files are not showing in Xcode:

1. Right-click on the appropriate folder in Xcode
2. Select "Add Files to 'crakt'..."
3. Navigate to the file
4. **Uncheck** "Copy items if needed" (files are already in place)
5. Select the file(s)
6. Click "Add"

---

## 5. Build and Run

### Expected Behavior on First Launch:

1. **Location Permission Prompt**
   - App requests "When In Use" permission
   - Message: "We use your location to find climbing gyms near you..."

2. **Database Initialization**
   - Console should show: `✅ Copied gym database to documents directory`
   - Console should show: `✅ Created gym database indexes`

3. **Gym Tab Available**
   - New tab with climbing icon appears
   - Tapping shows map view with gym markers

4. **Features Working**
   - Search bar filters gyms
   - Map shows user location (if permitted)
   - Tapping gym markers shows details
   - Toggle button switches between map and list view
   - Location button centers on user

### Troubleshooting First Launch

**If database doesn't load:**
- Check console for error messages
- Verify `gyms.sqlite` is in Bundle Resources
- Clean build folder: Product → Clean Build Folder
- Rebuild

**If location doesn't work:**
- Check Info.plist has location permission key
- Go to Settings → Privacy → Location Services → crakt
- Ensure "While Using" is selected

**If gyms don't appear:**
- Check console output for SQL errors
- Database file might be corrupted
- Try re-copying from scripts folder

---

## 6. Testing Checklist

### Basic Functionality
- [ ] App builds without errors
- [ ] Gym tab appears in tab bar
- [ ] Map loads with markers
- [ ] Search filters results
- [ ] Location permission prompt appears
- [ ] User location shows on map (after permission granted)

### Search Testing
- [ ] Search by gym name (e.g., "Pacific Edge")
- [ ] Search by city (e.g., "Boulder")
- [ ] Search by state (e.g., "CA")
- [ ] Search updates as you type (debounced)
- [ ] Clear search shows all gyms
- [ ] Empty search results show appropriate message

### Map View Testing
- [ ] Gym markers appear
- [ ] Tapping marker selects it (shows blue highlight)
- [ ] Selected marker opens detail sheet
- [ ] Location button centers on user
- [ ] Map is interactive (pinch, drag, etc.)

### List View Testing
- [ ] Toggle button switches to list view
- [ ] Gyms sorted by distance (with location)
- [ ] Pagination works (Load More button)
- [ ] Tapping gym row opens detail sheet
- [ ] Distance shows for each gym (with location)

### Detail Sheet Testing
- [ ] Gym name and info display correctly
- [ ] Address is formatted properly
- [ ] Phone number is tappable (opens phone app)
- [ ] Website is tappable (opens Safari)
- [ ] Directions button opens Maps app
- [ ] Hours format correctly (line breaks)
- [ ] Sheet is dismissible

### Location Testing
- [ ] Without permission: location icon is grayed out
- [ ] Tapping location button requests permission
- [ ] With permission: user location shows on map
- [ ] Distance calculations are accurate
- [ ] Gyms sorted by distance work

### Error Handling
- [ ] No gyms found shows empty state
- [ ] Location denied shows appropriate message
- [ ] Search errors don't crash app
- [ ] Database errors are caught and logged

---

## 7. Performance Verification

### Check Console Output

Expected console messages on successful launch:
```
✅ Copied gym database to documents directory
✅ Created gym database indexes
```

### Performance Expectations
- Initial database load: < 1 second
- Search results: < 300ms after typing stops
- Map marker rendering: Smooth (no lag)
- List scrolling: Smooth with 50-item pages
- Sheet presentation: Immediate

### Memory Usage
- Expected: 50-100 MB for 432 gyms
- Map view uses more memory than list view
- Should not increase significantly over time

---

## 8. Known Limitations

1. **Map Clustering**: Not implemented in v1
   - All 432 gyms shown at once
   - May be crowded on zoomed-out view
   - Future enhancement opportunity

2. **Offline Support**: Database is local
   - Works offline after initial setup
   - Cannot update gym data without app update
   - Consider periodic validation workflow

3. **Advanced Filters**: Not implemented
   - No filter by amenities
   - No filter by rating
   - No favorites/bookmarks
   - Future enhancement opportunity

---

## 9. Data Updates

To update the gym database in the future:

1. Run validation script to refresh data:
```bash
cd scripts
python3 validate_gyms.py --api-key YOUR_KEY --auto-update
```

2. Copy updated `gyms.sqlite` to project
3. Clean build folder
4. Rebuild app

Note: Users will need to update the app to get new data.

---

## 10. Architecture Overview

```
User Interaction
      ↓
GymFinderView (Main Container)
      ↓
├── GymSearchBar → Debouncer → Search Query
├── GymMapView   → Displays gyms on map
├── GymListView  → Displays gyms in list
└── GymDetailSheet → Shows gym details
      ↓
SQLiteGymDataSource (Actor)
      ↓
gyms.sqlite (Bundle → Documents)
```

### Thread Safety
- Database operations use Swift `actor` for thread safety
- UI updates on main thread via `@MainActor`
- Location updates via `@Published` properties

### State Management
- `@StateObject` for LocationManager (singleton)
- `@State` for local view state
- `@Binding` for parent-child communication
- Actor isolation for database access

---

## Need Help?

### Common Issues

**"Cannot find 'GymFinderView' in scope"**
- Verify all files are added to Xcode target
- Clean and rebuild

**"Database not found"**
- Check gyms.sqlite is in Bundle Resources
- Verify file is copied to app bundle

**"Location permission not working"**
- Check Info.plist entry
- Reset privacy permissions: Settings → General → Transfer or Reset iPhone → Reset Location & Privacy

**"App crashes on launch"**
- Check console for specific error
- Verify all files compile without errors
- Check for missing imports

---

## Success Criteria

✅ App builds and runs without errors  
✅ Gym tab appears and is functional  
✅ Location permission prompt appears  
✅ 432 gyms load and display  
✅ Search works and is performant  
✅ Map and list views both functional  
✅ Detail sheets open correctly  
✅ All actions (call, website, directions) work  

When all criteria are met, the Gym Finder feature is complete! 🎉

