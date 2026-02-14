//
//  Color.swift
//  crakt
//
//  Created by Kyle Thompson on 9/23/23.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension Color {
    // MARK: - Hex Color Support
    
    /// Initialize Color from hex string (e.g., "#FF5733", "FF5733", "#FFF")
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit) - e.g., "FFF"
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit) - e.g., "FF5733"
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit) - e.g., "FFFF5733"
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 128, 128, 128) // Gray fallback
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    /// Convert Color to hex string (e.g., "#FF5733")
    func toHex() -> String {
        #if canImport(UIKit)
        guard let components = UIColor(self).cgColor.components, components.count >= 3 else {
            return "#808080"
        }
        #elseif canImport(AppKit)
        guard let cgColor = NSColor(self).cgColor,
              let components = cgColor.components,
              components.count >= 3 else {
            return "#808080"
        }
        #endif
        
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        
        return String(format: "#%02X%02X%02X", r, g, b)
    }
    
    // MARK: - Color Name Detection
    
    /// Known color mappings for common circuit colors
    private static let knownColors: [(hex: String, name: String, tolerance: Int)] = [
        // System colors
        ("#007AFF", "Blue", 30),
        ("#34C759", "Green", 30),
        ("#FFCC00", "Yellow", 30),
        ("#FF9500", "Orange", 30),
        ("#FF3B30", "Red", 30),
        ("#AF52DE", "Purple", 30),
        ("#000000", "Black", 20),
        ("#FFFFFF", "White", 20),
        ("#8E8E93", "Gray", 30),
        ("#FF2D55", "Pink", 30),
        ("#5856D6", "Indigo", 30),
        ("#00C7BE", "Teal", 30),
        ("#32ADE6", "Cyan", 30),
        ("#A2845E", "Brown", 30),
        
        // Common climbing circuit colors
        ("#0000FF", "Blue", 30),
        ("#00FF00", "Green", 30),
        ("#FFFF00", "Yellow", 30),
        ("#FFA500", "Orange", 30),
        ("#FF0000", "Red", 30),
        ("#800080", "Purple", 30),
        ("#FFC0CB", "Pink", 30),
    ]
    
    /// Get human-readable color name, auto-derived from hex
    var colorName: String {
        let hex = self.toHex().uppercased()
        
        // Try exact match first
        if let exact = Self.knownColors.first(where: { $0.hex.uppercased() == hex }) {
            return exact.name
        }
        
        // Try closest match with tolerance
        if let closest = closestKnownColor() {
            return closest
        }
        
        // Fall back to descriptive name based on RGB
        return descriptiveColorName()
    }
    
    /// Find closest known color within tolerance
    private func closestKnownColor() -> String? {
        let hex = self.toHex()
        guard let (r1, g1, b1) = hexToRGB(hex) else { return nil }
        
        var bestMatch: (name: String, distance: Int)?
        
        for known in Self.knownColors {
            guard let (r2, g2, b2) = hexToRGB(known.hex) else { continue }
            
            // Calculate color distance (simple Euclidean)
            let distance = abs(r1 - r2) + abs(g1 - g2) + abs(b1 - b2)
            
            if distance <= known.tolerance {
                if bestMatch == nil || distance < bestMatch!.distance {
                    bestMatch = (known.name, distance)
                }
            }
        }
        
        return bestMatch?.name
    }
    
    /// Generate descriptive name based on RGB values
    private func descriptiveColorName() -> String {
        let hex = self.toHex()
        guard let (r, g, b) = hexToRGB(hex) else { return hex }
        
        // Determine dominant channel
        let max = max(r, g, b)
        let min = min(r, g, b)
        
        // Check for grayscale
        if max - min < 30 {
            if max < 50 { return "Black" }
            if max > 200 { return "White" }
            return "Gray"
        }
        
        // Determine primary hue
        if r >= g && r >= b {
            if g > b + 50 { return "Orange" }
            if b > 100 { return "Pink" }
            return "Red"
        } else if g >= r && g >= b {
            if b > 100 { return "Teal" }
            if r > 100 { return "Yellow" }
            return "Green"
        } else {
            if r > 100 { return "Purple" }
            if g > 100 { return "Cyan" }
            return "Blue"
        }
    }
    
    /// Parse hex to RGB components
    private func hexToRGB(_ hex: String) -> (r: Int, g: Int, b: Int)? {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard cleaned.count == 6 else { return nil }
        
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        
        return (
            r: Int((int >> 16) & 0xFF),
            g: Int((int >> 8) & 0xFF),
            b: Int(int & 0xFF)
        )
    }
}
