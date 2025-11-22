//
//  GymListView.swift
//  crakt
//
//  List view for displaying gyms with pagination
//

import SwiftUI
import CoreLocation

struct GymListView: View {
    let gyms: [Gym]
    @Binding var selectedGym: Gym?
    let userLocation: CLLocation?
    
    @State private var displayedGyms: [Gym] = []
    private let pageSize = 50
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if displayedGyms.isEmpty && !gyms.isEmpty {
                    // Loading first page
                    ProgressView()
                        .padding()
                } else if gyms.isEmpty {
                    // No gyms found
                    EmptyGymStateView(type: .noResults)
                        .padding(40)
                } else {
                    ForEach(displayedGyms) { gym in
                        GymRowView(gym: gym, userLocation: userLocation)
                            .onTapGesture {
                                selectedGym = gym
                            }
                        
                        if gym.id != displayedGyms.last?.id {
                            Divider()
                                .padding(.leading, 20)
                                .opacity(0.3)
                        }
                    }
                    
                    // Load more button
                    if displayedGyms.count < gyms.count {
                        Button {
                            loadMore()
                        } label: {
                            HStack {
                                Text("Load More (\(gyms.count - displayedGyms.count) remaining)")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                Image(systemName: "arrow.down.circle")
                                    .foregroundColor(.blue)
                            }
                            .padding()
                        }
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
            )
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            loadInitialPage()
        }
        .onChange(of: gyms) { _, _ in
            loadInitialPage()
        }
    }
    
    private func loadInitialPage() {
        displayedGyms = Array(gyms.prefix(pageSize))
    }
    
    private func loadMore() {
        let currentCount = displayedGyms.count
        let nextBatch = gyms.dropFirst(currentCount).prefix(pageSize)
        displayedGyms.append(contentsOf: nextBatch)
    }
}

// MARK: - Gym Row View

struct GymRowView: View {
    let gym: Gym
    let userLocation: CLLocation?
    
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
                    .lineLimit(2)
                
                if let distance = gym.formattedDistance(from: userLocation) {
                    Label(distance, systemImage: "location.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let cityState = gym.address.cityState {
                    Text(cityState)
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

// MARK: - Empty State View

struct EmptyGymStateView: View {
    enum StateType {
        case noResults
        case noPermission
        case loading
    }
    
    let type: StateType
    var onAction: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: iconName)
                .font(.system(size: 56))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            
            if let action = onAction {
                Button(actionTitle) {
                    action()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(40)
    }
    
    private var iconName: String {
        switch type {
        case .noResults: return "magnifyingglass"
        case .noPermission: return "location.slash"
        case .loading: return "hourglass"
        }
    }
    
    private var title: String {
        switch type {
        case .noResults: return "No Gyms Found"
        case .noPermission: return "Location Access Needed"
        case .loading: return "Loading Gyms..."
        }
    }
    
    private var message: String {
        switch type {
        case .noResults: return "Try a different search or browse the map to find climbing gyms"
        case .noPermission: return "Enable location services to find gyms near you"
        case .loading: return "Fetching climbing gyms from database..."
        }
    }
    
    private var actionTitle: String {
        switch type {
        case .noResults: return "Clear Search"
        case .noPermission: return "Open Settings"
        case .loading: return ""
        }
    }
}

// MARK: - Preview

#Preview {
    GymListView(
        gyms: Gym.previewList,
        selectedGym: .constant(nil),
        userLocation: nil
    )
}

