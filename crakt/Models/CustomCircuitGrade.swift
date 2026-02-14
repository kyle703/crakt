//
//  CustomCircuitGrade.swift
//  crakt
//
//  Created by Kyle Thompson on 1/14/26.
//

import Foundation
import SwiftData
import SwiftUI

/// Represents a complete custom circuit grade system configuration.
/// Contains ordered color mappings that define the difficulty progression.
@Model
class CustomCircuitGrade: Identifiable {
    /// Unique identifier
    var id: UUID
    
    /// Display name (e.g., "Brooklyn Boulders Manhattan", "Default Circuit")
    var name: String
    
    /// When this circuit was created
    var createdDate: Date
    
    /// Last modification timestamp
    var lastModifiedDate: Date
    
    /// Whether this is the user's default circuit
    var isDefault: Bool
    
    /// Color mappings that define this circuit
    @Relationship(deleteRule: .cascade)
    var colorMappings: [CircuitColorMapping] = []
    
    /// Optional gym ID association
    var gymId: UUID?
    
    init(id: UUID = UUID(),
         name: String,
         isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.createdDate = Date()
        self.lastModifiedDate = Date()
        self.isDefault = isDefault
    }
    
    // MARK: - Computed Properties
    
    /// Mappings sorted by sortOrder (easiest first)
    var orderedMappings: [CircuitColorMapping] {
        colorMappings.sorted { $0.sortOrder < $1.sortOrder }
    }
    
    /// Number of colors in this circuit
    var colorCount: Int {
        colorMappings.count
    }
    
    // MARK: - Management Methods
    
    /// Set this circuit as the default, clearing others
    func setAsDefault(in context: ModelContext) throws {
        // Clear all other defaults
        let descriptor = FetchDescriptor<CustomCircuitGrade>()
        let allCircuits = try context.fetch(descriptor)
        
        for circuit in allCircuits where circuit.id != self.id {
            circuit.isDefault = false
        }
        
        self.isDefault = true
        try context.save()
    }
    
    /// Add a new color mapping at the end
    func addMapping(_ mapping: CircuitColorMapping) {
        mapping.sortOrder = colorMappings.count
        mapping.circuit = self
        colorMappings.append(mapping)
        lastModifiedDate = Date()
    }
    
    // MARK: - Lookup Methods
    
    /// Find a mapping by its UUID
    func mapping(forId id: UUID) -> CircuitColorMapping? {
        colorMappings.first { $0.id == id }
    }
    
    /// Find a mapping by UUID string (grade identifier)
    func mapping(forGrade grade: String) -> CircuitColorMapping? {
        guard let uuid = UUID(uuidString: grade) else { return nil }
        return mapping(forId: uuid)
    }
}
