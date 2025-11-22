//
//  SessionGymSelectorView.swift
//  crakt
//
//  Pre-session gym selector with search and location integration
//

import SwiftUI
import CoreLocation
import MapKit

struct SessionGymSelectorView: View {
    @Binding var selectedGymName: String
    @StateObject private var locationManager = LocationManager.shared

    @State private var searchText = ""
    @State private var isLoading = false
    @State private var gyms: [Gym] = []
    @State private var selectedGym: Gym?
    @State private var awaitingLocation = false
    @State private var showDetailedSelector = false
    @State private var recentGyms: [String] = []
    @State private var showAddGymSheet = false

    @State private var error: GymFinderError?
    @State private var showError = false

    @FocusState private var isSearchFieldFocused: Bool
    
    private let dataSource: any GymDataSource = SQLiteGymDataSource.shared
    private let searchDebouncer = Debouncer(delay: 0.35)
    private let maxRecentGyms = 4
    private let recentGymsKey = "session_recent_gyms"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            quickPickRow

            if showDetailedSelector {
                detailedSelector
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4)
        .task {
            await loadInitialGyms()
        }
        .onAppear {
            loadRecentGyms()
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
            guard searchText.isEmpty else { return }
            awaitingLocation = false
            Task {
                await loadSuggestedGyms(location: newLocation)
            }
        }
        .onChange(of: showDetailedSelector) { _, isExpanded in
            if !isExpanded {
                isSearchFieldFocused = false
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isSearchFieldFocused = true
                }
            }
        }
        .alert("Gym Search Error", isPresented: $showError, presenting: error) { _ in
            Button("OK", role: .cancel) { }
        } message: { error in
            Text(error.localizedDescription)
        }
        .sheet(isPresented: $showAddGymSheet) {
            AddGymSheet(
                userLocation: locationManager.currentLocation,
                dataSource: dataSource,
                onComplete: { gym in
                    handleCustomGymCreated(gym)
                }
            )
        }
    }

    // MARK: - Subviews

    private var quickPickGyms: [String] {
        var gyms = recentGyms
        let currentName = selectedGym?.name ?? (selectedGymName.isEmpty ? nil : selectedGymName)
        if let currentName,
           !gyms.contains(where: { $0.caseInsensitiveCompare(currentName) == .orderedSame }) {
            gyms.insert(currentName, at: 0)
        }
        return Array(gyms.prefix(maxRecentGyms))
    }
    
    private var selectedGymDistanceText: String? {
        if let gym = selectedGym ?? (gyms.first { $0.name.caseInsensitiveCompare(selectedGymName) == .orderedSame }) {
            return gym.formattedDistance(from: locationManager.currentLocation)
        }
        return nil
    }

    private var quickPickRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !quickPickGyms.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("Recent gyms")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    if quickPickGyms.isEmpty {
                        Text("Tap find gyms to pick your spot")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(Capsule())
                    } else {
                        ForEach(quickPickGyms, id: \.self) { name in
                            Button {
                                selectQuickGym(named: name)
                            } label: {
                                HStack(spacing: 6) {
                                    if isCurrentSelection(named: name) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                    Text(name)
                                        .font(.callout)
                                        .fontWeight(.medium)
                                        .lineLimit(1)
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 14)
                                .background(
                                    Capsule()
                                        .fill(isCurrentSelection(named: name) ? Color.blue.opacity(0.15) : Color(.systemBackground))
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(isCurrentSelection(named: name) ? Color.blue.opacity(0.4) : Color.gray.opacity(0.2), lineWidth: 1)
                                )
                                .foregroundColor(isCurrentSelection(named: name) ? .blue : .primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            if let distance = selectedGymDistanceText {
                HStack(spacing: 4) {
                    Image(systemName: "location")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(distance)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .transition(.opacity)
            }
        }
    }

    private var detailedSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Find a gym")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                        showDetailedSelector = false
                        isSearchFieldFocused = false
                    }
                } label: {
                    Label("Collapse", systemImage: "chevron.up")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }

            searchControls

            resultsList
        }
        .padding(.top, 4)
    }

    private var searchControls: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("Search gyms, city, or state", text: $searchText)
                    .focused($isSearchFieldFocused)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
                    .submitLabel(.search)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)

            Button {
                handleLocateMeTap()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                        .frame(width: 36, height: 36)
                    if awaitingLocation {
                        ProgressView()
                    } else {
                        Image(systemName: locationManager.isAuthorized ? "location.fill" : "location.slash")
                            .foregroundColor(locationManager.isAuthorized ? .blue : .secondary)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
        }
    }

    private var header: some View {
        HStack {
            Text("Gym")
                .font(.headline)
                .foregroundColor(.primary)

            Spacer()

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                    showDetailedSelector.toggle()
                }
            } label: {
                Label(showDetailedSelector ? "Hide" : "Find gyms", systemImage: showDetailedSelector ? "chevron.up" : "magnifyingglass")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 14)
                    .background(
                        Capsule()
                            .stroke(Color.blue, lineWidth: 1)
                    )
            }
            .tint(.blue)
        }
    }


    private var resultsList: some View {
        VStack(spacing: 12) {
            if isLoading {
                ProgressView("Loading gyms...")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
            } else if gyms.isEmpty {
                EmptyGymStateView(type: .noResults) {
                    searchText = ""
                    Task {
                        await loadInitialGyms()
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(gyms) { gym in
                            gymResultRow(gym)
                            if gym.id != gyms.last?.id {
                                Divider()
                                    .padding(.leading, 44)
                            }
                        }
                    }
                }
                .frame(maxHeight: 220)
            }
            
            addGymRow
        }
    }

    private func gymResultRow(_ gym: Gym) -> some View {
        Button {
            selectGym(gym)
        } label: {
            let isSelected = isCurrentSelection(named: gym.name)
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 32, height: 32)
                    Image(systemName: "figure.climbing")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.blue)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(gym.name)
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        if let cityState = gym.address.cityState {
                            Text(cityState)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }

                        if let distance = gym.formattedDistance(from: locationManager.currentLocation) {
                            Text(distance)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "chevron.right")
                    .foregroundColor(isSelected ? .green : .secondary)
                    .font(.footnote)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue.opacity(0.08) : Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }
    
    private var addGymRow: some View {
        Button {
            showAddGymSheet = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Add a gym")
                        .font(.footnote)
                        .fontWeight(.semibold)
                    Text("Can't find it? Create a new gym with your info.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }


    // MARK: - Actions

    private func handleLocateMeTap() {
        if !locationManager.isAuthorized {
            locationManager.requestPermission()
            return
        }
        awaitingLocation = true
        if let location = locationManager.currentLocation {
            Task {
                await loadSuggestedGyms(location: location)
                awaitingLocation = false
            }
        } else {
            locationManager.requestOneTimeLocation()
        }
    }

    private func performSearch(query: String) {
        searchDebouncer.debounce {
            Task {
                await executeSearch(query: query)
            }
        }
    }

    private func selectGym(_ gym: Gym) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
            selectedGym = gym
            selectedGymName = gym.name
            showDetailedSelector = false
        }
        recordRecentGym(gym.name)
    }

    private func selectQuickGym(named name: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
            selectedGym = nil
            selectedGymName = name
        }
        recordRecentGym(name)
    }

    private func isCurrentSelection(named name: String) -> Bool {
        if let selectedGym, selectedGym.name.caseInsensitiveCompare(name) == .orderedSame {
            return true
        }
        return selectedGymName.caseInsensitiveCompare(name) == .orderedSame
    }

    // MARK: - Data Loading

    private func loadInitialGyms() async {
        awaitingLocation = false
        await loadSuggestedGyms(location: locationManager.currentLocation)
    }

    private func loadSuggestedGyms(location: CLLocation?) async {
        await loadGyms {
            if let location {
                return try await dataSource.fetchNearbyGyms(location: location, radius: 80000, limit: 25)
            }
            return Array(try await dataSource.fetchAllGyms().prefix(25))
        }
    }

    private func executeSearch(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            await loadSuggestedGyms(location: locationManager.currentLocation)
            return
        }

        if trimmed.count < 2 {
            return
        }

        await loadGyms {
            try await dataSource.searchGyms(
                query: trimmed,
                location: locationManager.currentLocation,
                limit: 50
            )
        }
    }

    private func loadGyms(_ source: @escaping () async throws -> [Gym]) async {
        await MainActor.run {
            isLoading = true
        }

        do {
            let gyms = try await source()
            await MainActor.run {
                self.gyms = gyms
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.error = .searchFailed(error)
                self.showError = true
            }
        }
    }

    private func recordRecentGym(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var updated = recentGyms.filter { $0.caseInsensitiveCompare(trimmed) != .orderedSame }
        updated.insert(trimmed, at: 0)
        if updated.count > maxRecentGyms {
            updated = Array(updated.prefix(maxRecentGyms))
        }
        recentGyms = updated
        UserDefaults.standard.set(updated, forKey: recentGymsKey)
    }

    private func loadRecentGyms() {
        if let stored = UserDefaults.standard.array(forKey: recentGymsKey) as? [String] {
            recentGyms = stored
        }
    }
    
    private func handleCustomGymCreated(_ gym: Gym) {
        selectedGym = gym
        selectedGymName = gym.name
        showDetailedSelector = false
        isSearchFieldFocused = false
        if !gyms.contains(where: { $0.id == gym.id }) {
            gyms.insert(gym, at: 0)
        }
        recordRecentGym(gym.name)
    }

}

// MARK: - Preview

#Preview {
    SessionGymSelectorView(selectedGymName: .constant(""))
        .padding()
        .background(Color(.systemGroupedBackground))
}

// MARK: - Add Gym Sheet

private struct AddGymFormData {
    var name: String = ""
    var houseNumber: String = ""
    var street: String = ""
    var city: String = ""
    var state: String = ""
    var postcode: String = ""
    var country: String = "US"
    var phone: String = ""
    var website: String = ""
    var hours: String = ""
    var coordinate: CLLocationCoordinate2D?
    
    var coordinateSummary: String {
        guard let coordinate else { return "Tap map to drop a pin" }
        return String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
    }
    
    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && coordinate != nil
    }
    
    func toDetails() -> NewGymDetails? {
        guard let coordinate else { return nil }
        
        return NewGymDetails(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            houseNumber: houseNumber.isEmpty ? nil : houseNumber,
            street: street.isEmpty ? nil : street,
            city: city.isEmpty ? nil : city,
            state: state.isEmpty ? nil : state,
            postcode: postcode.isEmpty ? nil : postcode,
            country: country.isEmpty ? "US" : country,
            phone: phone.isEmpty ? nil : phone,
            website: website.isEmpty ? nil : website,
            hours: hours.isEmpty ? nil : hours,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
    }
}

private struct AddGymSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let userLocation: CLLocation?
    let dataSource: any GymDataSource
    let onComplete: (Gym) -> Void
    
    @State private var form = AddGymFormData()
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
        span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5)
    )
    @State private var pinCoordinate: CLLocationCoordinate2D?
    
    private var pinItems: [MapPin] {
        guard let coordinate = pinCoordinate else { return [] }
        return [MapPin(coordinate: coordinate)]
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Gym name", text: $form.name)
                    
                    TextField("Street address", text: $form.street)
                    TextField("Building / Number (optional)", text: $form.houseNumber)
                    TextField("City", text: $form.city)
                    HStack {
                        TextField("State", text: $form.state)
                        TextField("Postal Code", text: $form.postcode)
                    }
                    TextField("Country", text: $form.country)
                }
                
                Section("Contact & Info") {
                    TextField("Website", text: $form.website)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                    TextField("Phone", text: $form.phone)
                        .keyboardType(.phonePad)
                    TextField("Hours (optional)", text: $form.hours)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        MapReader { proxy in
                            Map(
                                coordinateRegion: $mapRegion,
                                interactionModes: .all,
                                showsUserLocation: userLocation != nil,
                                annotationItems: pinItems
                            ) { pin in
                                MapAnnotation(coordinate: pin.coordinate) {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.red)
                                        .shadow(radius: 4)
                                }
                            }
                            .frame(height: 240)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            .gesture(
                                SpatialTapGesture()
                                    .onEnded { value in
                                        if let coordinate = proxy.convert(value.location, from: .local) {
                                            updateSelectedCoordinate(coordinate, recenter: false)
                                        }
                                    }
                            )
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Label(form.coordinateSummary, systemImage: "mappin.and.ellipse")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Button {
                                    let center = mapRegion.center
                                    updateSelectedCoordinate(center, recenter: false)
                                } label: {
                                    Label("Drop at center", systemImage: "scope")
                                }
                                .buttonStyle(.bordered)
                                
                                Spacer()
                                
                                Button {
                                    if let location = userLocation {
                                        updateSelectedCoordinate(location.coordinate, recenter: true)
                                    }
                                } label: {
                                    Label("Use my location", systemImage: "location.fill")
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.blue)
                                .disabled(userLocation == nil)
                            }
                            .font(.caption)
                        }
                    }
                } header: {
                    Text("Location")
                } footer: {
                    Text("Pan/zoom the map, then tap to drop a pin where the gym is located. Accurate locations improve distance calculations and directions.")
                }
            }
            .navigationTitle("Add a Gym")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveGym()
                    }
                    .disabled(!form.canSave || isSaving)
                }
            }
            .alert("Unable to Save", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .onAppear {
                initializeMap()
            }
        }
    }
    
    private func saveGym() {
        guard form.canSave else { return }
        guard let details = form.toDetails() else {
            errorMessage = "Please provide valid coordinates."
            return
        }
        
        isSaving = true
        Task {
            do {
                let newGym = try await dataSource.addCustomGym(details)
                await MainActor.run {
                    isSaving = false
                    onComplete(newGym)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func initializeMap() {
        if let coordinate = form.coordinate {
            pinCoordinate = coordinate
            mapRegion = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
        } else if let location = userLocation {
            let coordinate = location.coordinate
            updateSelectedCoordinate(coordinate, recenter: true)
            mapRegion.span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        } else {
            pinCoordinate = nil
            mapRegion = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
                span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5)
            )
        }
    }
    
    private func updateSelectedCoordinate(_ coordinate: CLLocationCoordinate2D, recenter: Bool) {
        pinCoordinate = coordinate
        form.coordinate = coordinate
        if recenter {
            mapRegion.center = coordinate
        }
    }
    
    private struct MapPin: Identifiable {
        let id = UUID()
        let coordinate: CLLocationCoordinate2D
    }
}
