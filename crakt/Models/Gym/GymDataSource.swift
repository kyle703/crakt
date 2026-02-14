//
//  GymDataSource.swift
//  crakt
//
//  Protocol abstraction for gym data access
//

import Foundation
import CoreLocation

/// Error types for gym data operations
enum GymDataSourceError: LocalizedError {
    case databaseNotFound
    case databaseInitializationFailed(Error)
    case queryFailed(Error)
    case invalidData
    case insertionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .databaseNotFound:
            return "Gym database not found"
        case .databaseInitializationFailed(let error):
            return "Failed to initialize database: \(error.localizedDescription)"
        case .queryFailed(let error):
            return "Database query failed: \(error.localizedDescription)"
        case .invalidData:
            return "Invalid data in database"
        case .insertionFailed(let message):
            return "Failed to save gym: \(message)"
        }
    }
}

/// Protocol for gym data source - allows for different implementations (SQLite, Core Data, API, etc.)
struct NewGymDetails {
    var name: String
    var houseNumber: String?
    var street: String?
    var city: String?
    var state: String?
    var postcode: String?
    var country: String
    var phone: String?
    var website: String?
    var hours: String?
    var latitude: Double
    var longitude: Double
}

protocol GymDataSource {
    /// Fetch all gyms from the data source
    func fetchAllGyms() async throws -> [Gym]
    
    /// Search gyms by query string (name, city, state)
    /// - Parameters:
    ///   - query: Search query string
    ///   - location: Optional user location for distance sorting
    ///   - limit: Maximum number of results (default: 100)
    /// - Returns: Array of matching gyms
    func searchGyms(
        query: String,
        location: CLLocation?,
        limit: Int
    ) async throws -> [Gym]
    
    /// Fetch nearby gyms within a radius
    /// - Parameters:
    ///   - location: Center point
    ///   - radius: Radius in meters
    ///   - limit: Maximum number of results
    /// - Returns: Array of gyms sorted by distance
    func fetchNearbyGyms(
        location: CLLocation,
        radius: Double,
        limit: Int
    ) async throws -> [Gym]
    
    /// Insert a user-provided gym and return the stored record
    func addCustomGym(_ details: NewGymDetails) async throws -> Gym
}

/// Default parameter values
extension GymDataSource {
    func searchGyms(
        query: String,
        location: CLLocation? = nil,
        limit: Int = 100
    ) async throws -> [Gym] {
        try await searchGyms(query: query, location: location, limit: limit)
    }
    
    func fetchNearbyGyms(
        location: CLLocation,
        radius: Double = 50000, // 50km default
        limit: Int = 100
    ) async throws -> [Gym] {
        try await fetchNearbyGyms(location: location, radius: radius, limit: limit)
    }
}
