# Gym Finder Map View - Design Plan

## Overview
Add a gym finder feature that displays climbing gyms from the SQLite database on an interactive map with location-based search and filtering.

---

## File Structure

### Models (crakt/Models/)
```
Gym/
├── Gym.swift                      # Core gym data model
├── GymDatabase.swift              # SQLite database manager
└── LocationManager.swift          # Location services wrapper
```

### Views (crakt/Views/)
```
Gym/
├── GymFinderView.swift           # Main container view (map + search)
├── GymMapView.swift              # MapKit wrapper with annotations
├── GymSearchBar.swift            # Unified search bar component
├── GymListView.swift             # List view (alternative to map)
├── GymDetailSheet.swift          # Bottom sheet for selected gym
└── GymAnnotationView.swift       # Custom map pin/annotation
```

### Supporting Files
```
Extensions/
└── CLLocation+Distance.swift     # Distance calculation helpers
```

---

## Component Architecture

### 1. **Gym Model** (`Gym.swift`)
```swift
import Foundation
import CoreLocation

struct Gym: Identifiable, Equatable {
    let id: Int
    let name: String
    let address: Address
    let phone: String?
    let website: String?
    let hours: String?
    let coordinate: CLLocationCoordinate2D
    let source: String
    let createdAt: Date
    let updatedAt: Date
    
    struct Address {
        let street: String?
        let city: String?
        let state: String?
        let postcode: String?
        let country: String
        
        var formattedAddress: String {
            // Returns formatted address string
        }
    }
    
    // Computed properties
    var distanceFromUser: CLLocationDistance? { }
    var formattedDistance: String { }
}
```

**Rationale:**
- Follows existing pattern of simple structs for data models
- Identifiable for SwiftUI ForEach
- Equatable for comparison/caching
- Nested Address type for clarity
- CoreLocation types for map integration

---

### 2. **GymDatabase Manager** (`GymDatabase.swift`)
```swift
import Foundation
import SQLite3
import CoreLocation

@Observable
class GymDatabase {
    static let shared = GymDatabase()
    
    private var db: OpaquePointer?
    private let dbPath: String
    
    // MARK: - Initialization
    init() { }
    
    // MARK: - Query Methods
    func searchGyms(
        query: String,
        userLocation: CLLocation?,
        maxDistance: Double? = nil
    ) async -> [Gym]
    
    func fetchAllGyms() async -> [Gym]
    
    func fetchNearbyGyms(
        location: CLLocation,
        radius: Double // in meters
    ) async -> [Gym]
    
    // MARK: - Private Helpers
    private func openDatabase() -> Bool
    private func closeDatabase()
    private func parseGym(from statement: OpaquePointer) -> Gym?
}
```

**Rationale:**
- Singleton for app-wide database access
- @Observable for reactive SwiftUI updates
- Async methods for non-blocking database operations
- Follows Apple's modern concurrency patterns
- Matches existing pattern (similar to DataController)

---

### 3. **LocationManager** (`LocationManager.swift`)
```swift
import Foundation
import CoreLocation
import Combine

@Observable
class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    
    private let manager = CLLocationManager()
    
    var currentLocation: CLLocation?
    var authorizationStatus: CLAuthorizationStatus
    var isAuthorized: Bool { }
    
    override init() { }
    
    func requestPermission()
    func startUpdatingLocation()
    func stopUpdatingLocation()
    
    // Delegate methods
    func locationManager(_ manager: CLLocationManager, 
                        didUpdateLocations locations: [CLLocation])
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager)
}
```

**Rationale:**
- Singleton for centralized location management
- @Observable for reactive UI updates
- Follows Apple's CLLocationManager patterns
- Can be reused elsewhere in app

---

### 4. **GymFinderView** (Main Container)
```swift
import SwiftUI
import MapKit

struct GymFinderView: View {
    @State private var searchText = ""
    @State private var gyms: [Gym] = []
    @State private var selectedGym: Gym?
    @State private var showingList = false
    @State private var mapRegion = MKCoordinateRegion(...)
    @State private var isSearching = false
    
    private let gymDatabase = GymDatabase.shared
    private let locationManager = LocationManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Map or List View
                if showingList {
                    GymListView(gyms: filteredGyms, 
                               selectedGym: $selectedGym)
                } else {
                    GymMapView(gyms: filteredGyms,
                              region: $mapRegion,
                              selectedGym: $selectedGym)
                }
                
                // Search Bar Overlay
                VStack {
                    GymSearchBar(text: $searchText,
                                isSearching: $isSearching)
                        .padding()
                    Spacer()
                }
            }
            .sheet(item: $selectedGym) { gym in
                GymDetailSheet(gym: gym)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingList.toggle()
                    } label: {
                        Image(systemName: showingList ? "map" : "list.bullet")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        centerOnUserLocation()
                    } label: {
                        Image(systemName: "location.fill")
                    }
                }
            }
            .navigationTitle("Find Gyms")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            await loadGyms()
        }
        .onChange(of: searchText) {
            performSearch()
        }
    }
    
    private var filteredGyms: [Gym] {
        // Filter and sort logic
    }
    
    private func performSearch() { }
    private func loadGyms() async { }
    private func centerOnUserLocation() { }
}
```

**Rationale:**
- Follows existing HomeView pattern with NavigationStack
- State management matches app conventions
- ZStack for overlay UI pattern (common in app)
- Sheet for detail view (matches existing patterns)
- Toolbar buttons for common actions

---

### 5. **GymMapView** (MapKit Integration)
```swift
import SwiftUI
import MapKit

struct GymMapView: View {
    let gyms: [Gym]
    @Binding var region: MKCoordinateRegion
    @Binding var selectedGym: Gym?
    
    var body: some View {
        Map(coordinateRegion: $region,
            interactionModes: .all,
            showsUserLocation: true,
            annotationItems: gyms) { gym in
            MapAnnotation(coordinate: gym.coordinate) {
                GymAnnotationView(gym: gym,
                                 isSelected: selectedGym?.id == gym.id)
                    .onTapGesture {
                        selectedGym = gym
                    }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}
```

**Rationale:**
- Uses SwiftUI's Map for iOS 14+ compatibility
- Custom annotations for branding
- Binding for two-way communication
- Matches existing view patterns

---

### 6. **GymSearchBar** (Unified Search)
```swift
import SwiftUI

struct GymSearchBar: View {
    @Binding var text: String
    @Binding var isSearching: Bool
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search gyms, city, or state", text: $text)
                    .focused($isFocused)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                if !text.isEmpty {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
            
            if isSearching {
                Button("Cancel") {
                    text = ""
                    isFocused = false
                    isSearching = false
                }
                .foregroundColor(.blue)
            }
        }
        .onChange(of: isFocused) { _, newValue in
            isSearching = newValue
        }
    }
}
```

**Rationale:**
- Follows iOS standard search bar patterns
- Uses @FocusState (modern SwiftUI)
- Matches app's design language (rounded corners, shadows)
- Similar to existing pickers/selectors in app

---

### 7. **GymListView** (List Alternative)
```swift
import SwiftUI

struct GymListView: View {
    let gyms: [Gym]
    @Binding var selectedGym: Gym?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(gyms) { gym in
                    GymRowView(gym: gym)
                        .onTapGesture {
                            selectedGym = gym
                        }
                    
                    if gym.id != gyms.last?.id {
                        Divider()
                            .padding(.leading, 20)
                    }
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct GymRowView: View {
    let gym: Gym
    
    var body: some View {
        HStack(spacing: 16) {
            // Gym icon
            Image(systemName: "figure.climbing")
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 44, height: 44)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(gym.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let distance = gym.formattedDistance {
                    Text(distance)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let city = gym.address.city, 
                   let state = gym.address.state {
                    Text("\(city), \(state)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.system(size: 14))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
    }
}
```

**Rationale:**
- Matches ActivityRowView pattern exactly
- Same styling as recent activities list
- Consistent with app's design system
- LazyVStack for performance

---

### 8. **GymDetailSheet** (Bottom Sheet)
```swift
import SwiftUI
import MapKit

struct GymDetailSheet: View {
    let gym: Gym
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(gym.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        if let distance = gym.formattedDistance {
                            HStack {
                                Image(systemName: "location.fill")
                                    .font(.caption)
                                Text(distance)
                                    .font(.subheadline)
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                    
                    // Address Section
                    DetailRow(icon: "mappin.circle.fill",
                             title: "Address",
                             value: gym.address.formattedAddress)
                    
                    // Phone Section
                    if let phone = gym.phone {
                        DetailRow(icon: "phone.fill",
                                 title: "Phone",
                                 value: phone,
                                 action: { callGym() })
                    }
                    
                    // Website Section
                    if let website = gym.website {
                        DetailRow(icon: "globe",
                                 title: "Website",
                                 value: website,
                                 action: { openWebsite() })
                    }
                    
                    // Hours Section
                    if let hours = gym.hours {
                        DetailRow(icon: "clock.fill",
                                 title: "Hours",
                                 value: hours)
                    }
                    
                    // Action Buttons
                    HStack(spacing: 12) {
                        Button {
                            openInMaps()
                        } label: {
                            Label("Directions", systemImage: "arrow.triangle.turn.up.right.circle.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    private func openInMaps() { }
    private func callGym() { }
    private func openWebsite() { }
}

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button {
            action?()
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(value)
                        .font(.body)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .disabled(action == nil)
        .buttonStyle(PlainButtonStyle())
    }
}
```

**Rationale:**
- Sheet presentation matches app patterns
- DetailRow reusable component
- Action buttons for common tasks
- Presentation detents for modern iOS feel

---

### 9. **GymAnnotationView** (Custom Pin)
```swift
import SwiftUI

struct GymAnnotationView: View {
    let gym: Gym
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "figure.climbing")
                .font(.system(size: isSelected ? 20 : 16))
                .foregroundColor(.white)
                .padding(isSelected ? 12 : 8)
                .background(
                    Circle()
                        .fill(Color.blue)
                        .shadow(color: .black.opacity(0.3), 
                               radius: isSelected ? 8 : 4)
                )
            
            // Pin point
            Triangle()
                .fill(Color.blue)
                .frame(width: 12, height: 8)
                .offset(y: -1)
        }
        .scaleEffect(isSelected ? 1.2 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
```

**Rationale:**
- Custom annotation for brand identity
- Animated selection state
- Climbing icon matches app theme
- Shadow for depth

---

## Search Logic

### Unified Search Algorithm
```swift
func searchGyms(query: String, userLocation: CLLocation?) -> [Gym] {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    
    if trimmed.isEmpty {
        return sortByDistance(allGyms, from: userLocation)
    }
    
    let filtered = allGyms.filter { gym in
        // Match gym name
        gym.name.localizedCaseInsensitiveContains(trimmed) ||
        // Match city
        gym.address.city?.localizedCaseInsensitiveContains(trimmed) == true ||
        // Match state
        gym.address.state?.localizedCaseInsensitiveContains(trimmed) == true ||
        // Match full address
        gym.address.formattedAddress.localizedCaseInsensitiveContains(trimmed)
    }
    
    return sortByRelevance(filtered, query: trimmed, userLocation: userLocation)
}

func sortByRelevance(_ gyms: [Gym], query: String, userLocation: CLLocation?) -> [Gym] {
    return gyms.sorted { gym1, gym2 in
        let score1 = relevanceScore(gym: gym1, query: query, userLocation: userLocation)
        let score2 = relevanceScore(gym: gym2, query: query, userLocation: userLocation)
        return score1 > score2
    }
}

func relevanceScore(gym: Gym, query: String, userLocation: CLLocation?) -> Double {
    var score = 0.0
    
    // Name match = highest priority
    if gym.name.localizedCaseInsensitiveContains(query) {
        score += 100.0
        // Bonus for starting with query
        if gym.name.lowercased().hasPrefix(query.lowercased()) {
            score += 50.0
        }
    }
    
    // City/state match = medium priority
    if gym.address.city?.localizedCaseInsensitiveContains(query) == true ||
       gym.address.state?.localizedCaseInsensitiveContains(query) == true {
        score += 50.0
    }
    
    // Distance bonus (closer = higher score)
    if let userLocation = userLocation,
       let distance = gym.distanceFromUser {
        let maxDistance = 100_000.0 // 100km
        let distanceScore = max(0, (maxDistance - distance) / maxDistance * 25.0)
        score += distanceScore
    }
    
    return score
}
```

---

## Integration Points

### 1. Add to Tab Bar (ContentView.swift)
```swift
struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            GymFinderView()  // NEW
                .tabItem {
                    Label("Gyms", systemImage: "map.fill")
                }

            ActivityHistoryView()
                .tabItem {
                    Label("Activity", systemImage: "clock")
                }

            GlobalSessionsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}
```

### 2. Bundle SQLite Database
- Add `gyms.sqlite` to Xcode project
- Mark as "Copy Bundle Resources" in Build Phases
- Copy to app bundle during build

### 3. Info.plist Updates
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We use your location to find climbing gyms near you</string>
```

---

## Testing Strategy

### Unit Tests
1. `GymDatabaseTests` - SQLite operations
2. `SearchAlgorithmTests` - Search relevance
3. `DistanceCalculationTests` - Location calculations

### Integration Tests
1. Map annotation selection
2. Search and filter flow
3. Location permission handling

### Manual Testing Checklist
- [ ] Search by gym name
- [ ] Search by city
- [ ] Search by state
- [ ] Location permission flow
- [ ] Map annotations tap
- [ ] Detail sheet actions
- [ ] Toggle map/list view
- [ ] Center on user location
- [ ] No gyms found state
- [ ] No location permission state

---

## Performance Considerations

1. **Database**
   - Load gyms on background thread
   - Cache results in memory
   - Use indexes on name, city, state columns

2. **Map**
   - Limit visible annotations (cluster if needed)
   - Lazy load gym details
   - Debounce search input (300ms)

3. **Location**
   - Stop updates when not needed
   - Use significant location change API
   - Cache last known location

---

## Accessibility

1. **VoiceOver Support**
   - Map annotations are labeled
   - Search bar has proper hints
   - Action buttons have labels

2. **Dynamic Type**
   - All text scales properly
   - Minimum touch targets 44x44pt

3. **Color Contrast**
   - Meets WCAG AA standards
   - Works in light/dark mode

---

## Future Enhancements (Out of Scope)

1. Gym favorites/bookmarks
2. Filter by amenities (parking, accessibility)
3. Gym ratings integration
4. Check-in feature
5. Share gym with friends
6. Route photos from gyms
7. Gym-specific statistics

---

## Estimated Implementation Time

- Models & Database: 2-3 hours
- Map View: 3-4 hours
- Search & Filter: 2-3 hours
- Detail View: 1-2 hours
- Testing & Polish: 2-3 hours

**Total: 10-15 hours**

