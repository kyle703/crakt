//
//  GymDetailSheet.swift
//  crakt
//
//  Detail sheet for selected gym
//

import SwiftUI
import SwiftData
import MapKit
import CoreLocation

struct GymDetailSheet: View {
    let gym: Gym
    let userLocation: CLLocation?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.modelContext) private var modelContext
    
    @State private var showGradeConfiguration = false
    @State private var gradeConfiguration: GymGradeConfiguration?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(gym.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        if let distance = gym.formattedDistance(from: userLocation) {
                            HStack {
                                Image(systemName: "location.fill")
                                    .font(.caption)
                                Text(distance + " away")
                                    .font(.subheadline)
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                    
                    // Address Section
                    if !gym.address.formattedAddress.isEmpty {
                        DetailRow(
                            icon: "mappin.circle.fill",
                            title: "Address",
                            value: gym.address.formattedAddress
                        )
                    }
                    
                    // Phone Section
                    if let phone = gym.phone {
                        DetailRow(
                            icon: "phone.fill",
                            title: "Phone",
                            value: phone
                        ) {
                            callGym(phone: phone)
                        }
                    }
                    
                    // Website Section
                    if let website = gym.website {
                        DetailRow(
                            icon: "globe",
                            title: "Website",
                            value: formatWebsite(website)
                        ) {
                            openWebsite(website)
                        }
                    }
                    
                    // Hours Section
                    if let hours = gym.hours {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 12) {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                
                                Text("Hours")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(formatHours(hours))
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                    
                    // Grade Configuration Section
                    GradeConfigurationSection(
                        configuration: gradeConfiguration,
                        onEdit: { showGradeConfiguration = true }
                    )
                    
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
                    
                    // Source info
                    Text("Data source: \(gym.source)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
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
        .onAppear {
            loadGradeConfiguration()
        }
        .sheet(isPresented: $showGradeConfiguration) {
            GymGradeConfigurationView(
                gymId: UUID(uuidString: String(gym.id)) ?? UUID(),
                countryCode: gym.address.country
            )
        }
    }
    
    // MARK: - Load Configuration
    
    private func loadGradeConfiguration() {
        // Use gym.id as string for UUID since Gym.id is Int
        let gymUUID = UUID(uuidString: String(gym.id)) ?? UUID()
        
        let descriptor = FetchDescriptor<GymGradeConfiguration>(
            predicate: #Predicate { $0.gymId == gymUUID }
        )
        
        gradeConfiguration = try? modelContext.fetch(descriptor).first
    }
    
    // MARK: - Private Methods
    
    private func openInMaps() {
        let placemark = MKPlacemark(coordinate: gym.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = gym.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
    
    private func callGym(phone: String) {
        let cleaned = phone.filter { $0.isNumber }
        guard let phoneURL = URL(string: "tel://\(cleaned)") else { return }
        openURL(phoneURL)
    }
    
    private func openWebsite(_ website: String) {
        var urlString = website
        if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
            urlString = "https://\(urlString)"
        }
        
        guard let url = URL(string: urlString) else { return }
        openURL(url)
    }
    
    private func formatWebsite(_ website: String) -> String {
        // Remove http:// or https:// for display
        return website
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "www.", with: "")
    }
    
    private func formatHours(_ hours: String) -> String {
        // Hours come in format "Monday: 6:00 AM – 11:00 PM; Tuesday: ..."
        return hours.replacingOccurrences(of: "; ", with: "\n")
    }
}

// MARK: - Detail Row

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
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .disabled(action == nil)
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Grade Configuration Section

struct GradeConfigurationSection: View {
    let configuration: GymGradeConfiguration?
    let onEdit: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "number.circle.fill")
                    .foregroundColor(.orange)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Grade Systems")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let config = configuration {
                        HStack(spacing: 16) {
                            // Boulder system
                            HStack(spacing: 4) {
                                Image(systemName: "mountain.2.fill")
                                    .font(.caption)
                                Text(config.boulderGradeSystem.description)
                                    .font(.subheadline)
                            }
                            
                            // Rope system
                            HStack(spacing: 4) {
                                Image(systemName: "figure.climbing")
                                    .font(.caption)
                                Text(config.ropeGradeSystem.description)
                                    .font(.subheadline)
                            }
                        }
                    } else {
                        Text("Not configured")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button {
                    onEdit()
                } label: {
                    Text(configuration == nil ? "Set Up" : "Edit")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
            }
            
            // Show circuit preview if using circuit grades
            if let config = configuration,
               config.boulderGradeSystem == .circuit,
               let circuit = config.boulderCircuit {
                HStack(spacing: 4) {
                    ForEach(circuit.orderedMappings.prefix(7)) { mapping in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(mapping.swiftUIColor)
                            .frame(height: 16)
                    }
                }
                .padding(.leading, 36)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    GymDetailSheet(
        gym: .preview,
        userLocation: CLLocation(latitude: 37.0, longitude: -122.0)
    )
    .modelContainer(for: [GymGradeConfiguration.self, CustomCircuitGrade.self, CircuitColorMapping.self])
}
