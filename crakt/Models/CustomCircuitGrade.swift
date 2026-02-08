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
    
    /// Preview of circuit colors
    var colorPreview: [Color] {
        orderedMappings.map { $0.swiftUIColor }
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
    
    /// Reorder a mapping from one position to another
    func reorderMapping(from sourceIndex: Int, to destinationIndex: Int) {
        var ordered = orderedMappings
        guard sourceIndex >= 0, sourceIndex < ordered.count,
              destinationIndex >= 0, destinationIndex < ordered.count else {
            return
        }
        
        let item = ordered.remove(at: sourceIndex)
        ordered.insert(item, at: destinationIndex)
        
        // Reassign sortOrder
        for (index, mapping) in ordered.enumerated() {
            mapping.sortOrder = index
        }
    }
    
    /// Add a new color mapping at the end
    func addMapping(_ mapping: CircuitColorMapping) {
        mapping.sortOrder = colorMappings.count
        mapping.circuit = self
        colorMappings.append(mapping)
        lastModifiedDate = Date()
    }
    
    /// Remove a mapping and reindex
    func removeMapping(_ mapping: CircuitColorMapping) {
        colorMappings.removeAll { $0.id == mapping.id }
        
        // Reindex remaining mappings
        for (index, m) in orderedMappings.enumerated() {
            m.sortOrder = index
        }
        lastModifiedDate = Date()
    }
    
    // MARK: - Validation
    
    func validate() throws {
        // Validate name
        guard !name.isEmpty else {
            throw CircuitValidationError.emptyName
        }
        
        // Validate has mappings
        guard !colorMappings.isEmpty else {
            throw CircuitValidationError.noMappings
        }
        
        // Validate sort order is sequential
        let sortOrders = orderedMappings.map { $0.sortOrder }
        let expectedOrders = Array(0..<colorMappings.count)
        guard sortOrders == expectedOrders else {
            throw CircuitValidationError.invalidSortOrder
        }
        
        // Validate no duplicate colors
        let colors = colorMappings.map { $0.color.uppercased() }
        let uniqueColors = Set(colors)
        guard colors.count == uniqueColors.count else {
            let duplicate = colors.first { color in
                colors.filter { $0 == color }.count > 1
            }
            throw CircuitValidationError.duplicateColor(duplicate ?? "unknown")
        }
        
        // Validate each mapping
        for mapping in colorMappings {
            try mapping.validate()
        }
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

