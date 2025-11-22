//
//  GymMapView.swift
//  crakt
//
//  Map view for displaying gyms
//

import SwiftUI
import MapKit

struct GymMapView: View {
    let gyms: [Gym]
    @Binding var region: MKCoordinateRegion
    @Binding var selectedGym: Gym?
    let userLocation: CLLocation?
    
    var body: some View {
        Map(coordinateRegion: $region,
            interactionModes: .all,
            showsUserLocation: true,
            annotationItems: gyms) { gym in
            MapAnnotation(coordinate: gym.coordinate) {
                GymAnnotationView(
                    gym: gym,
                    isSelected: selectedGym?.id == gym.id
                )
                .onTapGesture {
                    withAnimation {
                        selectedGym = gym
                    }
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

// MARK: - Gym Annotation View

struct GymAnnotationView: View {
    let gym: Gym
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Icon circle
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

// MARK: - Triangle Shape

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

// MARK: - Preview

#Preview {
    GymMapView(
        gyms: Gym.previewList,
        region: .constant(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 36.9741, longitude: -122.0308),
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )),
        selectedGym: .constant(nil),
        userLocation: nil
    )
}

