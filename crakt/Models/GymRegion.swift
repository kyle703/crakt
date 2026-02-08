//
//  GymRegion.swift
//  crakt
//
//  Created by Kyle Thompson on 1/14/26.
//

import Foundation

/// Geographic region for determining default grade systems
enum GymRegion: String, Codable, CaseIterable {
    case northAmerica = "North America"
    case europe = "Europe"
    case uk = "United Kingdom"
    case asia = "Asia"
    case oceania = "Oceania"
    case other = "Other"
    
    /// Detect region from ISO country code
    static func from(countryCode: String?) -> GymRegion {
        guard let code = countryCode?.uppercased() else { return .other }
        
        switch code {
        // North America
        case "US", "CA", "MX":
            return .northAmerica
            
        // United Kingdom (separate due to different conventions)
        case "GB":
            return .uk
            
        // Europe
        case "FR", "DE", "ES", "IT", "CH", "AT", "BE", "NL", "PT", "PL", 
             "CZ", "SK", "HU", "RO", "BG", "GR", "SE", "NO", "FI", "DK",
             "IE", "LU", "SI", "HR", "RS", "BA", "ME", "MK", "AL", "XK":
            return .europe
            
        // Oceania
        case "AU", "NZ":
            return .oceania
            
        // Asia
        case "JP", "KR", "CN", "TW", "TH", "SG", "MY", "ID", "PH", "VN",
             "IN", "HK", "MO":
            return .asia
            
        default:
            return .other
        }
    }
    
    /// Default grade systems for this region
    var defaultBoulderSystem: GradeSystem {
        switch self {
        case .northAmerica, .asia, .oceania, .other:
            return .vscale
        case .europe, .uk:
            return .font
        }
    }
    
    var defaultRopeSystem: GradeSystem {
        switch self {
        case .northAmerica, .asia, .oceania, .other:
            return .yds
        case .europe, .uk:
            return .french
        }
    }
}

