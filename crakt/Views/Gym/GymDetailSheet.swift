//
//  GymDetailSheet.swift
//  crakt
//
//  Detail sheet for selected gym
//

import SwiftUI
import MapKit
import CoreLocation

struct GymDetailSheet: View {
    let gym: Gym
    let userLocation: CLLocation?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    
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

// MARK: - Preview

#Preview {
    GymDetailSheet(
        gym: .preview,
        userLocation: CLLocation(latitude: 37.0, longitude: -122.0)
    )
}

