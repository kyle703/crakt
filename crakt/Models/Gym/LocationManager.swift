//
//  LocationManager.swift
//  crakt
//
//  Manages location services for gym finding
//

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()
    
    private let manager = CLLocationManager()
    
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var isUpdatingLocation = false
    
    var isAuthorized: Bool {
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return true
        default:
            return false
        }
    }
    
    var canRequestLocation: Bool {
        authorizationStatus == .notDetermined
    }
    
    override private init() {
        self.authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 100 // Update every 100 meters
    }
    
    func requestPermission() {
        guard canRequestLocation else { return }
        manager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        guard isAuthorized else {
            requestPermission()
            return
        }
        
        guard !isUpdatingLocation else { return }
        
        isUpdatingLocation = true
        manager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        isUpdatingLocation = false
        manager.stopUpdatingLocation()
    }
    
    func requestOneTimeLocation() {
        guard isAuthorized else {
            requestPermission()
            return
        }
        manager.requestLocation()
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        // If authorized and was trying to update, start updating
        if isAuthorized && isUpdatingLocation {
            manager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error.localizedDescription)")
        
        // Stop updating on error
        if isUpdatingLocation {
            isUpdatingLocation = false
        }
    }
}

