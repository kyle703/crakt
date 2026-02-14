//
//  GymFinderView.swift
//  crakt
//
//  Main gym finder view with map and search
//

import SwiftUI
import MapKit

struct GymFinderView: View {
    @StateObject private var locationManager = LocationManager.shared
    @State private var searchText = ""
    @State private var gyms: [Gym] = []
    @State private var filteredGyms: [Gym] = []
    @State private var selectedGym: Gym?
    @State private var showingList = false
    @State private var isSearching = false
    @State private var isLoading = false
    @State private var error: GymFinderError?
    @State private var showError = false
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795), // Center of US
        span: MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 40)
    )
    
    private let dataSource: GymDataSource = SQLiteGymDataSource.shared
    private let searchDebouncer = Debouncer(delay: 0.3)
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Map or List View
                if showingList {
                    GymListView(
                        gyms: filteredGyms,
                        selectedGym: $selectedGym,
                        userLocation: locationManager.currentLocation
                    )
                } else {
                    GymMapView(
                        gyms: filteredGyms,
                        region: $mapRegion,
                        selectedGym: $selectedGym
                    )
                }
                
                // Loading overlay
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                        .background(Color(.systemBackground).opacity(0.8))
                        .cornerRadius(12)
                }
                
                // Search Bar Overlay
                VStack {
                    GymSearchBar(
                        text: $searchText,
                        isSearching: $isSearching
                    )
                    .padding()
                    
                    Spacer()
                }
            }
            .sheet(item: $selectedGym) { gym in
                GymDetailSheet(gym: gym, userLocation: locationManager.currentLocation)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingList.toggle()
                    } label: {
                        Image(systemName: showingList ? "map.fill" : "list.bullet")
                            .foregroundColor(.blue)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        centerOnUserLocation()
                    } label: {
                        Image(systemName: locationManager.isAuthorized ? "location.fill" : "location.slash")
                            .foregroundColor(locationManager.isAuthorized ? .blue : .secondary)
                    }
                }
            }
            .navigationTitle("Find Gyms")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: $showError, presenting: error) { _ in
                Button("OK") { }
            } message: { error in
                Text(error.localizedDescription)
            }
        }
        .task {
            await loadGyms()
        }
        .onAppear {
            if locationManager.canRequestLocation {
                locationManager.requestPermission()
            }
            locationManager.startUpdatingLocation()
        }
        .onDisappear {
            locationManager.stopUpdatingLocation()
        }
        .onChange(of: searchText) { _, newValue in
            performSearch(query: newValue)
        }
        .onChange(of: locationManager.currentLocation) { _, newLocation in
            if let location = newLocation, searchText.isEmpty {
                centerMapOnLocation(location)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func loadGyms() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            gyms = try await dataSource.fetchAllGyms()
            filteredGyms = gyms
        } catch {
            self.error = .databaseLoadFailed(error)
            showError = true
        }
    }
    
    private func performSearch(query: String) {
        searchDebouncer.debounce {
            Task {
                await executeSearch(query: query)
            }
        }
    }
    
    private func executeSearch(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            // Show all gyms
            filteredGyms = gyms
            return
        }
        
        if trimmed.count < 2 {
            // Wait for at least 2 characters
            return
        }
        
        do {
            filteredGyms = try await dataSource.searchGyms(
                query: trimmed,
                location: locationManager.currentLocation,
                limit: 100
            )
        } catch {
            self.error = .searchFailed(error)
            showError = true
        }
    }
    
    private func centerOnUserLocation() {
        if !locationManager.isAuthorized {
            locationManager.requestPermission()
            return
        }
        
        if let location = locationManager.currentLocation {
            centerMapOnLocation(location)
        } else {
            locationManager.requestOneTimeLocation()
        }
    }
    
    private func centerMapOnLocation(_ location: CLLocation) {
        withAnimation {
            mapRegion = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
            )
        }
    }
}

// MARK: - Error Types

enum GymFinderError: LocalizedError {
    case databaseLoadFailed(Error)
    case searchFailed(Error)
    case locationPermissionDenied
    
    var errorDescription: String? {
        switch self {
        case .databaseLoadFailed(let error):
            return "Failed to load gyms: \(error.localizedDescription)"
        case .searchFailed(let error):
            return "Search failed: \(error.localizedDescription)"
        case .locationPermissionDenied:
            return "Location access denied. Enable it in Settings to find nearby gyms."
        }
    }
}

// MARK: - Debouncer

class Debouncer {
    private let delay: TimeInterval
    private var workItem: DispatchWorkItem?
    
    init(delay: TimeInterval) {
        self.delay = delay
    }
    
    func debounce(action: @escaping () -> Void) {
        workItem?.cancel()
        workItem = DispatchWorkItem(block: action)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem!)
    }
}

// MARK: - Preview

#Preview {
    GymFinderView()
}
