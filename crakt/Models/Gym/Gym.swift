//
//  Gym.swift
//  crakt
//
//  Climbing gym data model
//

import Foundation
import CoreLocation

struct Gym: Identifiable, Equatable, Codable {
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
    
    struct Address: Equatable, Codable {
        let houseNumber: String?
        let street: String?
        let city: String?
        let state: String?
        let postcode: String?
        let country: String
        
        var formattedAddress: String {
            var components: [String] = []
            
            if let houseNumber = houseNumber, let street = street {
                components.append("\(houseNumber) \(street)")
            } else if let street = street {
                components.append(street)
            }
            
            if let city = city {
                components.append(city)
            }
            
            if let state = state {
                components.append(state)
            }
            
            if let postcode = postcode {
                components.append(postcode)
            }
            
            return components.isEmpty ? "" : components.joined(separator: ", ")
        }
        
        var cityState: String? {
            guard let city = city else { return nil }
            if let state = state {
                return "\(city), \(state)"
            }
            return city
        }
    }
    
    // MARK: - Distance Calculations
    
    /// Calculate distance from a given location
    func distance(from location: CLLocation) -> CLLocationDistance {
        let gymLocation = CLLocation(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        return location.distance(from: gymLocation)
    }
    
    /// Get formatted distance string from a given location
    func formattedDistance(from location: CLLocation?) -> String? {
        guard let location = location else { return nil }
        let meters = distance(from: location)
        
        if meters < 1000 {
            return String(format: "%.0f m", meters)
        } else {
            return String(format: "%.1f km", meters / 1000)
        }
    }
    
    // MARK: - Codable Conformance for CLLocationCoordinate2D
    
    enum CodingKeys: String, CodingKey {
        case id, name, address, phone, website, hours, source, createdAt, updatedAt
        case latitude, longitude
    }
    
    init(id: Int, name: String, address: Address, phone: String? = nil, 
         website: String? = nil, hours: String? = nil, 
         coordinate: CLLocationCoordinate2D, source: String, 
         createdAt: Date, updatedAt: Date) {
        self.id = id
        self.name = name
        self.address = address
        self.phone = phone
        self.website = website
        self.hours = hours
        self.coordinate = coordinate
        self.source = source
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        address = try container.decode(Address.self, forKey: .address)
        phone = try container.decodeIfPresent(String.self, forKey: .phone)
        website = try container.decodeIfPresent(String.self, forKey: .website)
        hours = try container.decodeIfPresent(String.self, forKey: .hours)
        source = try container.decode(String.self, forKey: .source)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(address, forKey: .address)
        try container.encodeIfPresent(phone, forKey: .phone)
        try container.encodeIfPresent(website, forKey: .website)
        try container.encodeIfPresent(hours, forKey: .hours)
        try container.encode(source, forKey: .source)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
    }
    
    // MARK: - Equatable
    
    static func == (lhs: Gym, rhs: Gym) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Preview Data

extension Gym {
    static let preview = Gym(
        id: 1,
        name: "Pacific Edge",
        address: Address(
            houseNumber: "104",
            street: "Bronson St",
            city: "Santa Cruz",
            state: "CA",
            postcode: "95062",
            country: "US"
        ),
        phone: "+1 831-454-9254",
        website: "https://pacificedgeclimbinggym.com",
        hours: "Monday: 6:00 AM – 11:00 PM; Tuesday: 6:00 AM – 11:00 PM; Wednesday: 6:00 AM – 11:00 PM; Thursday: 6:00 AM – 11:00 PM; Friday: 6:00 AM – 10:00 PM; Saturday: 8:00 AM – 8:00 PM; Sunday: 8:00 AM – 8:00 PM",
        coordinate: CLLocationCoordinate2D(latitude: 36.9741, longitude: -122.0308),
        source: "OSM_OVERPASS",
        createdAt: Date(),
        updatedAt: Date()
    )
    
    static let previewList: [Gym] = [
        preview,
        Gym(
            id: 2,
            name: "Movement Climbing + Fitness",
            address: Address(
                houseNumber: nil,
                street: nil,
                city: "Boulder",
                state: "CO",
                postcode: "80304",
                country: "US"
            ),
            phone: nil,
            website: "https://movementgyms.com",
            hours: nil,
            coordinate: CLLocationCoordinate2D(latitude: 40.0150, longitude: -105.2705),
            source: "OSM_OVERPASS",
            createdAt: Date(),
            updatedAt: Date()
        )
    ]
}

