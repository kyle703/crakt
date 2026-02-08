# Custom Circuit Grade Systems — Feature Specification

## Overview

The Custom Circuit Grade Systems feature allows users to create and manage personalized circuit grading schemes where each color (or visual identifier) corresponds to a grade range from a concrete grade system (V-Scale, Font, YDS, French). This replaces the current simplistic circuit implementation that merely maps colors to color names with a robust, gym-aware system that integrates with the existing Difficulty Index (DI) normalization system.

**Status**: Specification Complete — Ready for Implementation Planning

---

## Problem Statement

### Current Limitations

1. **Semantic Mismatch**: Current circuit grades use `Color.description` as the grade identifier, which is fragile and not user-configurable
2. **No Grade Mapping**: Circuit grades are excluded from DI conversions, making cross-session analytics impossible
3. **Not Customizable**: Users cannot configure circuit colors to match their gym's actual grading system
4. **No Gym Association**: Circuit grades are global, but gyms have different circuit systems
5. **No Persistence**: Circuit configuration is hardcoded, not stored per-user or per-gym

### Target User Needs

- **Gym Climbers**: Map their gym's circuit colors to concrete grade ranges for accurate tracking
- **Multi-Gym Users**: Save different circuit configs for different gyms
- **Analytics Users**: Compare circuit-based sessions with grade-based sessions using DI
- **Progress Trackers**: Understand what grade range they're actually climbing when using circuits

---

## Core Architecture

### Data Models

#### 1. GymGradeConfiguration (SwiftData Model)

Associates grade systems with a gym, including regional defaults.

```swift
@Model
class GymGradeConfiguration: Identifiable {
    var id: UUID
    
    // Gym association
    var gymId: UUID  // Required - links to Gym model
    
    // Grade systems for this gym
    var boulderGradeSystem: GradeSystem  // .circuit, .vscale, .font
    var ropeGradeSystem: GradeSystem     // .yds, .french
    
    // If boulder system is circuit, reference the circuit config
    @Relationship(deleteRule: .nullify)
    var boulderCircuit: CustomCircuitGrade?
    
    init(gymId: UUID,
         boulderGradeSystem: GradeSystem = .vscale,
         ropeGradeSystem: GradeSystem = .yds)
    
    // Apply regional defaults
    static func defaultsForRegion(_ region: GymRegion) -> (boulder: GradeSystem, rope: GradeSystem) {
        switch region {
        case .northAmerica:
            return (.vscale, .yds)      // US/Canada standard
        case .europe:
            return (.font, .french)     // European standard
        case .uk:
            return (.font, .french)     // UK uses European grades
        case .asia, .oceania, .other:
            return (.vscale, .yds)      // Default to US system
        }
    }
}

enum GymRegion: String, Codable, CaseIterable {
    case northAmerica = "North America"
    case europe = "Europe"
    case uk = "United Kingdom"
    case asia = "Asia"
    case oceania = "Oceania"
    case other = "Other"
    
    // Detect region from country code
    static func from(countryCode: String?) -> GymRegion {
        guard let code = countryCode?.uppercased() else { return .other }
        switch code {
        case "US", "CA", "MX":
            return .northAmerica
        case "GB":
            return .uk
        case "FR", "DE", "ES", "IT", "CH", "AT", "BE", "NL", "PT", "PL", "CZ":
            return .europe
        case "AU", "NZ":
            return .oceania
        case "JP", "KR", "CN", "TW", "TH", "SG", "MY":
            return .asia
        default:
            return .other
        }
    }
}
```

**Key Decision**: Gyms have explicit grade system preferences. Regional defaults apply automatically based on gym location.

#### 2. CircuitColorMapping (SwiftData Model)

Represents a single color in a circuit grade system.

```swift
@Model
class CircuitColorMapping: Identifiable {
    var id: UUID  // This IS the grade identifier - stable UUID
    
    // Visual properties
    var color: String  // Hex color code: "#FF5733"
    
    // Position in difficulty progression
    var sortOrder: Int
    
    // Grade range from concrete system
    var baseGradeSystem: GradeSystem  // .vscale, .font, .yds, .french
    var minGrade: String  // e.g., "V2"
    var maxGrade: String  // e.g., "V4"
    
    // Relationship
    @Relationship(deleteRule: .nullify, inverse: \CustomCircuitGrade.colorMappings)
    var circuit: CustomCircuitGrade?
    
    init(id: UUID = UUID(),
         color: String, 
         sortOrder: Int, 
         baseGradeSystem: GradeSystem, 
         minGrade: String, 
         maxGrade: String)
    
    // Validation
    func validate() throws
    
    // Computed properties - display name derived from color
    var displayName: String {
        Color(hex: color).colorName  // "Green", "Blue", etc.
    }
    
    var gradeRangeDescription: String {
        let baseProtocol = baseGradeSystem._protocol
        let minDesc = baseProtocol.description(for: minGrade) ?? minGrade
        let maxDesc = baseProtocol.description(for: maxGrade) ?? maxGrade
        return "\(minDesc) - \(maxDesc)"
    }
    
    var midpointDI: Int? {
        DifficultyIndex.normalizeToDI(circuitMapping: self)
    }
}
```

**Key Decision**: Use `id` (UUID) as the stable grade identifier. Display name is auto-derived from the color - users never type it manually. The whole point of circuit grades is they're just colors that map to ranges.

#### 3. CustomCircuitGrade (SwiftData Model)

Represents a complete circuit grade system configuration.

```swift
@Model
class CustomCircuitGrade: Identifiable {
    var id: UUID
    var name: String  // e.g., "Brooklyn Boulders Manhattan" (auto-populated from gym name)
    var createdDate: Date
    var lastModifiedDate: Date
    var isDefault: Bool
    
    @Relationship(deleteRule: .cascade, inverse: \CircuitColorMapping.circuit)
    var colorMappings: [CircuitColorMapping]
    
    // Gym association
    @Relationship(deleteRule: .nullify)
    var gym: GymGradeConfiguration?
    
    init(id: UUID = UUID(), name: String, isDefault: Bool = false)
    
    // Computed properties
    var orderedMappings: [CircuitColorMapping] {
        colorMappings.sorted { $0.sortOrder < $1.sortOrder }
    }
    
    // Management methods
    func setAsDefault(in context: ModelContext) throws
    func reorderMapping(from sourceIndex: Int, to destinationIndex: Int)
    func validate() throws
}
```

**Key Decision**: Enforce single default through explicit `setAsDefault()` method that clears other defaults. Circuit name defaults to gym name when associated.

#### 4. CircuitGrade (GradeProtocol Implementation)

Runtime protocol implementation for circuit grades.

```swift
struct CircuitGrade: GradeProtocol {
    let system: GradeSystem = .circuit
    let customCircuit: CustomCircuitGrade
    
    init(customCircuit: CustomCircuitGrade)
    
    // GradeProtocol conformance
    var grades: [String] {
        // Returns stable UUID strings as grade identifiers
        customCircuit.orderedMappings.map { $0.id.uuidString }
    }
    
    var colorMap: [String: Color] {
        // Maps UUID string to current display color
        customCircuit.orderedMappings.reduce(into: [:]) { result, mapping in
            result[mapping.id.uuidString] = Color(hex: mapping.color)
        }
    }
    
    func colors(for grade: String) -> [Color] {
        // grade is UUID string, lookup current color
        if let uuid = UUID(uuidString: grade),
           let mapping = customCircuit.orderedMappings.first(where: { $0.id == uuid }) {
            return [Color(hex: mapping.color)]
        }
        return [.gray]
    }
    
    func description(for grade: String) -> String? {
        // Return color name and grade range (e.g., "Green (V2-V4)")
        if let uuid = UUID(uuidString: grade),
           let mapping = customCircuit.orderedMappings.first(where: { $0.id == uuid }) {
            return "\(mapping.displayName) (\(mapping.gradeRangeDescription))"
        }
        return nil
    }
    
    // Lookup mapping by UUID
    func mapping(for grade: String) -> CircuitColorMapping? {
        guard let uuid = UUID(uuidString: grade) else { return nil }
        return customCircuit.orderedMappings.first { $0.id == uuid }
    }
    
    static func == (lhs: CircuitGrade, rhs: CircuitGrade) -> Bool {
        lhs.customCircuit.id == rhs.customCircuit.id
    }
}
```

#### 5. Route Model Updates

Update Route to store which circuit was used.

```swift
@Model class Route: Identifiable {
    // ... existing fields
    
    // Circuit grade tracking - grade field stores UUID string of CircuitColorMapping
    var customCircuitId: UUID?
    @Relationship(deleteRule: .nullify)
    var customCircuit: CustomCircuitGrade?
    
    // Helper to get appropriate grade protocol
    func gradeProtocol(modelContext: ModelContext) -> any GradeProtocol {
        switch gradeSystem {
        case .circuit:
            if let circuit = customCircuit {
                return CircuitGrade(customCircuit: circuit)
            } else if let circuitId = customCircuitId {
                // Fetch by ID (circuit relationship may be broken)
                let descriptor = FetchDescriptor<CustomCircuitGrade>(
                    predicate: #Predicate { $0.id == circuitId }
                )
                if let circuit = try? modelContext.fetch(descriptor).first {
                    return CircuitGrade(customCircuit: circuit)
                }
            }
            // Fallback to default
            return CircuitGrade(customCircuit: GradeSystemFactory.defaultCircuit(modelContext))
        default:
            return gradeSystem._protocol
        }
    }
}
```

**Key Decision**: Route's `grade` field stores the UUID string of the `CircuitColorMapping`. Store circuit ID and relationship for resilience.

---

### Grade System Factory Pattern

Replace the problematic `GradeSystem._protocol` with a factory pattern.

```swift
struct GradeSystemFactory {
    /// Get grade protocol for a system
    static func gradeProtocol(for system: GradeSystem, 
                             circuit: CustomCircuitGrade? = nil,
                             modelContext: ModelContext) -> any GradeProtocol {
        switch system {
        case .circuit:
            let circuitToUse = circuit ?? defaultCircuit(modelContext)
            return CircuitGrade(customCircuit: circuitToUse)
        case .vscale:
            return VGrade()
        case .font:
            return FontGrade()
        case .yds:
            return YDS()
        case .french:
            return FrenchGrade()
        }
    }
    
    /// Get grade systems for a gym (with regional defaults)
    static func gradeSystemsForGym(_ gymId: UUID, 
                                   countryCode: String?,
                                   modelContext: ModelContext) -> GymGradeConfiguration {
        // Try to fetch existing config
        let descriptor = FetchDescriptor<GymGradeConfiguration>(
            predicate: #Predicate { $0.gymId == gymId }
        )
        
        if let config = try? modelContext.fetch(descriptor).first {
            return config
        }
        
        // Create new config with regional defaults
        let region = GymRegion.from(countryCode: countryCode)
        let defaults = GymGradeConfiguration.defaultsForRegion(region)
        
        let config = GymGradeConfiguration(
            gymId: gymId,
            boulderGradeSystem: defaults.boulder,
            ropeGradeSystem: defaults.rope
        )
        
        modelContext.insert(config)
        try? modelContext.save()
        
        return config
    }
    
    /// Get or create default circuit
    static func defaultCircuit(_ modelContext: ModelContext) -> CustomCircuitGrade {
        // Try to fetch default
        let descriptor = FetchDescriptor<CustomCircuitGrade>(
            predicate: #Predicate { $0.isDefault == true }
        )
        
        if let circuit = try? modelContext.fetch(descriptor).first {
            return circuit
        }
        
        // Create default if none exists
        return createAndSaveDefaultCircuit(modelContext)
    }
    
    /// Create standard default circuit (V-scale based for US default)
    private static func createAndSaveDefaultCircuit(_ modelContext: ModelContext) -> CustomCircuitGrade {
        let circuit = CustomCircuitGrade(name: "Default Circuit", isDefault: true)
        
        // Standard V-scale mapping: 
        // Blue(VB-V0), Green(V1-V2), Yellow(V3-V4), 
        // Orange(V5-V6), Red(V7-V8), Purple(V9-V10), Black(V11+)
        let defaultMappings: [(color: String, min: String, max: String)] = [
            ("#007AFF", "B", "0"),     // Blue
            ("#34C759", "1", "2"),     // Green
            ("#FFCC00", "3", "4"),     // Yellow
            ("#FF9500", "5", "6"),     // Orange
            ("#FF3B30", "7", "8"),     // Red
            ("#AF52DE", "9", "10"),    // Purple
            ("#000000", "11", "17")    // Black
        ]
        
        for (index, mapping) in defaultMappings.enumerated() {
            let colorMapping = CircuitColorMapping(
                color: mapping.color,
                sortOrder: index,
                baseGradeSystem: .vscale,
                minGrade: mapping.min,
                maxGrade: mapping.max
            )
            circuit.colorMappings.append(colorMapping)
        }
        
        modelContext.insert(circuit)
        try? modelContext.save()
        
        return circuit
    }
    
    /// Create Font-based default circuit (European style)
    static func createFontBasedDefaultCircuit(_ modelContext: ModelContext) -> CustomCircuitGrade {
        let circuit = CustomCircuitGrade(name: "European Circuit", isDefault: false)
        
        let defaultMappings: [(color: String, min: String, max: String)] = [
            ("#007AFF", "1", "3"),     // Blue
            ("#34C759", "4", "5"),     // Green
            ("#FFCC00", "6a", "6b"),   // Yellow
            ("#FF9500", "6c", "6d"),   // Orange
            ("#FF3B30", "7a", "7b"),   // Red
            ("#AF52DE", "7c", "7d"),   // Purple
            ("#000000", "8a", "8d")    // Black
        ]
        
        for (index, mapping) in defaultMappings.enumerated() {
            let colorMapping = CircuitColorMapping(
                color: mapping.color,
                sortOrder: index,
                baseGradeSystem: .font,
                minGrade: mapping.min,
                maxGrade: mapping.max
            )
            circuit.colorMappings.append(colorMapping)
        }
        
        modelContext.insert(circuit)
        try? modelContext.save()
        
        return circuit
    }
}
```

**Key Decision**: Factory pattern avoids SwiftUI environment issues and makes testing easier. Regional defaults apply automatically based on gym location.

---

### Difficulty Index Integration

Extend DI system to support circuit grades using midpoint calculation.

```swift
extension DifficultyIndex {
    /// Normalize circuit color mapping directly to DI
    static func normalizeToDI(circuitMapping mapping: CircuitColorMapping) -> Int? {
        // Get DI for min and max grades
        guard let minDI = normalizeToDI(grade: mapping.minGrade, 
                                       system: mapping.baseGradeSystem, 
                                       climbType: mapping.baseGradeSystem.climbType),
              let maxDI = normalizeToDI(grade: mapping.maxGrade, 
                                       system: mapping.baseGradeSystem, 
                                       climbType: mapping.baseGradeSystem.climbType) else {
            return nil
        }
        
        // Return midpoint (simple average for V1)
        return (minDI + maxDI) / 2
    }
    
    /// Normalize circuit grade (UUID string) to DI using midpoint of grade range
    static func normalizeToDI(circuitGrade: String, 
                             circuit: CustomCircuitGrade) -> Int? {
        guard let uuid = UUID(uuidString: circuitGrade),
              let mapping = circuit.orderedMappings.first(where: { $0.id == uuid }) else {
            return nil
        }
        
        return normalizeToDI(circuitMapping: mapping)
    }
    
    /// Get human-readable grade range for circuit color
    static func gradeRangeDescription(circuitGrade: String, 
                                     circuit: CustomCircuitGrade) -> String? {
        guard let uuid = UUID(uuidString: circuitGrade),
              let mapping = circuit.orderedMappings.first(where: { $0.id == uuid }) else {
            return nil
        }
        
        return mapping.gradeRangeDescription
    }
    
    /// Convert from circuit grade to another system via DI
    static func convertFromCircuit(circuitGrade: String,
                                  circuit: CustomCircuitGrade,
                                  toSystem: GradeSystem,
                                  toType: ClimbType) -> String? {
        guard let di = normalizeToDI(circuitGrade: circuitGrade, circuit: circuit) else {
            return nil
        }
        
        return gradeForDI(di, system: toSystem, climbType: toType)
    }
}
```

**Key Decision**: Use simple midpoint for V1. Future versions can add weighted average or user-configurable bias.

---

### Validation System

Comprehensive validation for circuit configurations.

```swift
enum CircuitValidationError: LocalizedError {
    case emptyName
    case emptyColor
    case invalidHexColor(String)
    case invalidGradeRange(min: String, max: String)
    case duplicateColor(String)
    case noMappings
    case invalidSortOrder
    case invalidGymConfiguration
    
    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "Circuit name cannot be empty"
        case .emptyColor:
            return "Color cannot be empty"
        case .invalidHexColor(let color):
            return "Invalid hex color format: \(color)"
        case .invalidGradeRange(let min, let max):
            return "Grade range invalid: \(min) must be ≤ \(max)"
        case .duplicateColor(let color):
            return "Duplicate color: \(color)"
        case .noMappings:
            return "Circuit must have at least one color"
        case .invalidSortOrder:
            return "Sort order must be sequential starting from 0"
        case .invalidGymConfiguration:
            return "Gym grade configuration is invalid"
        }
    }
}

extension CircuitColorMapping {
    func validate() throws {
        // Validate color
        guard !color.isEmpty else {
            throw CircuitValidationError.emptyColor
        }
        
        guard isValidHexColor(color) else {
            throw CircuitValidationError.invalidHexColor(color)
        }
        
        // No displayName validation - it's auto-derived from color
        
        // Validate grade range
        let baseProtocol = baseGradeSystem._protocol
        let minIndex = baseProtocol.gradeIndex(for: minGrade)
        let maxIndex = baseProtocol.gradeIndex(for: maxGrade)
        
        guard minIndex <= maxIndex else {
            throw CircuitValidationError.invalidGradeRange(min: minGrade, max: maxGrade)
        }
    }
    
    private func isValidHexColor(_ hex: String) -> Bool {
        let pattern = "^#[0-9A-Fa-f]{6}$"
        return hex.range(of: pattern, options: .regularExpression) != nil
    }
}

extension CustomCircuitGrade {
    func validate() throws {
        // Validate name
        guard !name.isEmpty else {
            throw CircuitValidationError.emptyName
        }
        
        // Validate has mappings
        guard !colorMappings.isEmpty else {
            throw CircuitValidationError.noMappings
        }
        
        // Validate sort order
        let sortOrders = orderedMappings.map { $0.sortOrder }
        let expectedOrders = Array(0..<colorMappings.count)
        guard sortOrders == expectedOrders else {
            throw CircuitValidationError.invalidSortOrder
        }
        
        // Validate no duplicate colors
        let colors = colorMappings.map { $0.color }
        let uniqueColors = Set(colors)
        guard colors.count == uniqueColors.count else {
            let duplicate = colors.first { color in
                colors.filter { $0 == color }.count > 1
            }
            throw CircuitValidationError.duplicateColor(duplicate ?? "unknown")
        }
        
        // No gradeId validation needed - IDs are UUIDs, always unique
        
        // Validate each mapping
        for mapping in colorMappings {
            try mapping.validate()
        }
    }
}

extension GymGradeConfiguration {
    func validate() throws {
        // Validate boulder system is valid for bouldering
        guard [.circuit, .vscale, .font].contains(boulderGradeSystem) else {
            throw CircuitValidationError.invalidGymConfiguration
        }
        
        // Validate rope system is valid for ropes
        guard [.yds, .french].contains(ropeGradeSystem) else {
            throw CircuitValidationError.invalidGymConfiguration
        }
        
        // If boulder system is circuit, must have associated circuit
        if boulderGradeSystem == .circuit && boulderCircuit == nil {
            throw CircuitValidationError.invalidGymConfiguration
        }
    }
}
```

---

### Color Utilities

Cross-platform color conversion utilities.

```swift
extension Color {
    /// Initialize Color from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
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
    
    /// Convert Color to hex string (cross-platform)
    func toHex() -> String {
        #if os(iOS)
        guard let components = UIColor(self).cgColor.components else { 
            return "#808080" 
        }
        #elseif os(macOS)
        guard let components = NSColor(self).cgColor?.components else { 
            return "#808080" 
        }
        #endif
        
        let r = Int((components[0]) * 255)
        let g = Int((components[1]) * 255)
        let b = Int((components[2]) * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
    
    /// Get human-readable color name
    var colorName: String {
        let hex = self.toHex().uppercased()
        
        // Common color mappings
        let commonColors: [String: String] = [
            "#007AFF": "Blue",
            "#34C759": "Green",
            "#FFCC00": "Yellow",
            "#FF9500": "Orange",
            "#FF3B30": "Red",
            "#AF52DE": "Purple",
            "#000000": "Black",
            "#FFFFFF": "White",
            "#808080": "Gray"
        ]
        
        // Try exact match
        if let name = commonColors[hex] {
            return name
        }
        
        // Return hex if no match
        return hex
    }
}
```

---

## User Interface Components

### 1. Circuit Grade Builder View (Settings)

Main entry point for managing circuit configurations.

**Location**: `SettingsView` → "Circuit Grade Builder" section

**Features**:
- List all saved circuits with metadata (name, color count, last modified)
- Create new circuit
- Edit existing circuit
- Delete circuits (with confirmation)
- Set default circuit
- Search/filter circuits

**Layout**:
```
┌─────────────────────────────────────┐
│ Circuit Grade Builder               │
├─────────────────────────────────────┤
│ Active Circuit: [Default ▼]        │
│ [+ Create New Circuit]              │
│                                     │
│ Saved Circuits (3)                  │
│ ┌─────────────────────────────────┐ │
│ │ 🟦🟩🟨🟠🟥🟣⬛ Default Circuit    │ │
│ │ 7 colors • V-Scale based         │ │
│ │ [✓ Default] [Edit] [Delete]     │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ 🟦🟢🟡🟠🔴 Brooklyn Boulders     │ │
│ │ 5 colors • V-Scale based         │ │
│ │ Last used: 2 days ago            │ │
│ │ [Set Default] [Edit] [Delete]   │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

**Implementation**:
```swift
struct CircuitGradeBuilderView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var circuits: [CustomCircuitGrade]
    @State private var showingCreateSheet = false
    @State private var editingCircuit: CustomCircuitGrade?
    @State private var circuitToDelete: CustomCircuitGrade?
    
    var body: some View {
        List {
            Section {
                Button(action: { showingCreateSheet = true }) {
                    Label("Create New Circuit", systemImage: "plus.circle.fill")
                }
            }
            
            Section("Saved Circuits (\(circuits.count))") {
                ForEach(circuits) { circuit in
                    CircuitCardView(circuit: circuit,
                                   onEdit: { editingCircuit = circuit },
                                   onDelete: { circuitToDelete = circuit },
                                   onSetDefault: { setAsDefault(circuit) })
                }
            }
        }
        .navigationTitle("Circuit Grade Builder")
        .sheet(isPresented: $showingCreateSheet) {
            CircuitEditorView(circuit: nil, onSave: { newCircuit in
                modelContext.insert(newCircuit)
                try? modelContext.save()
            })
        }
        .sheet(item: $editingCircuit) { circuit in
            CircuitEditorView(circuit: circuit, onSave: { _ in
                try? modelContext.save()
            })
        }
        .alert("Delete Circuit", 
               isPresented: .constant(circuitToDelete != nil),
               presenting: circuitToDelete) { circuit in
            Button("Cancel", role: .cancel) { circuitToDelete = nil }
            Button("Delete", role: .destructive) { 
                deleteCircuit(circuit) 
            }
        } message: { circuit in
            Text("Delete '\(circuit.name)'? This cannot be undone.")
        }
    }
    
    private func setAsDefault(_ circuit: CustomCircuitGrade) {
        try? circuit.setAsDefault(in: modelContext)
    }
    
    private func deleteCircuit(_ circuit: CustomCircuitGrade) {
        modelContext.delete(circuit)
        try? modelContext.save()
        circuitToDelete = nil
    }
}
```

### 2. Circuit Editor View

Full-featured editor for creating/modifying circuits.

**Features**:
- Name input
- Optional gym association
- Add/remove color mappings
- Reorder colors via drag & drop
- Edit individual color mappings
- Live preview of circuit
- Validation with error messages
- Save/Cancel actions

**Layout**:
```
┌─────────────────────────────────────┐
│ ← Edit Circuit                      │
├─────────────────────────────────────┤
│ Circuit Name                        │
│ [Brooklyn Boulders Manhattan      ] │
│                                     │
│ Associate with Gym (Optional)       │
│ [Select Gym...                    ▼]│
│                                     │
│ Colors (5)                     [+]  │
│ ┌─────────────────────────────────┐ │
│ │ ≡ 🟦 Blue          V0 - V1  [⋯] │ │
│ │ ≡ 🟩 Green         V2 - V3  [⋯] │ │
│ │ ≡ 🟨 Yellow        V4 - V5  [⋯] │ │
│ │ ≡ 🟠 Orange        V6 - V7  [⋯] │ │
│ │ ≡ 🔴 Red           V8 - V9  [⋯] │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Preview                             │
│ [🟦][🟩][🟨][🟠][🔴]               │
│                                     │
│ [Cancel]              [Save Circuit]│
└─────────────────────────────────────┘
```

**Implementation**:
```swift
struct CircuitEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let originalCircuit: CustomCircuitGrade?
    let onSave: (CustomCircuitGrade) -> Void
    
    @State private var name: String
    @State private var selectedGymId: UUID?
    @State private var mappings: [CircuitColorMapping]
    @State private var showingAddMapping = false
    @State private var editingMapping: CircuitColorMapping?
    @State private var validationError: String?
    
    init(circuit: CustomCircuitGrade?, onSave: @escaping (CustomCircuitGrade) -> Void) {
        self.originalCircuit = circuit
        self.onSave = onSave
        _name = State(initialValue: circuit?.name ?? "")
        _selectedGymId = State(initialValue: circuit?.gymId)
        _mappings = State(initialValue: circuit?.orderedMappings ?? [])
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Circuit Details") {
                    TextField("Circuit Name", text: $name)
                    
                    // Future: Gym picker
                    // GymPickerView(selectedGymId: $selectedGymId)
                }
                
                Section {
                    ForEach(mappings) { mapping in
                        ColorMappingRow(mapping: mapping,
                                       onEdit: { editingMapping = mapping },
                                       onDelete: { deleteMapping(mapping) })
                    }
                    .onMove { from, to in
                        mappings.move(fromOffsets: from, toOffset: to)
                        reindexMappings()
                    }
                    
                    Button(action: { showingAddMapping = true }) {
                        Label("Add Color", systemImage: "plus.circle.fill")
                    }
                } header: {
                    HStack {
                        Text("Colors (\(mappings.count))")
                        Spacer()
                        EditButton()
                    }
                }
                
                Section("Preview") {
                    CircuitPreviewView(mappings: mappings)
                }
                
                if let error = validationError {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(originalCircuit == nil ? "New Circuit" : "Edit Circuit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveCircuit() }
                        .disabled(name.isEmpty || mappings.isEmpty)
                }
            }
            .sheet(isPresented: $showingAddMapping) {
                ColorMappingEditorView(mapping: nil, 
                                      sortOrder: mappings.count,
                                      onSave: { newMapping in
                    mappings.append(newMapping)
                })
            }
            .sheet(item: $editingMapping) { mapping in
                ColorMappingEditorView(mapping: mapping, 
                                      sortOrder: mapping.sortOrder,
                                      onSave: { updatedMapping in
                    if let index = mappings.firstIndex(where: { $0.id == mapping.id }) {
                        mappings[index] = updatedMapping
                    }
                })
            }
        }
    }
    
    private func saveCircuit() {
        let circuit = originalCircuit ?? CustomCircuitGrade(name: name)
        circuit.name = name
        circuit.gymId = selectedGymId
        circuit.lastModifiedDate = Date()
        
        // Update mappings
        circuit.colorMappings = mappings
        
        // Validate
        do {
            try circuit.validate()
            onSave(circuit)
            dismiss()
        } catch {
            validationError = error.localizedDescription
        }
    }
    
    private func deleteMapping(_ mapping: CircuitColorMapping) {
        mappings.removeAll { $0.id == mapping.id }
        reindexMappings()
    }
    
    private func reindexMappings() {
        for (index, mapping) in mappings.enumerated() {
            mapping.sortOrder = index
        }
    }
}
```

### 3. Color Mapping Editor View

Modal editor for individual color mappings. **User only picks a color and grade range** - display name is auto-derived.

**Features**:
- Color picker (system ColorPicker) - display name auto-derives from this
- Base grade system selector
- Min/max grade pickers (dynamic based on selected system)
- Real-time validation
- Live preview of color and grade range

**Layout**:
```
┌─────────────────────────────────────┐
│ ← Add Color                         │
├─────────────────────────────────────┤
│ Color                               │
│ [🟠 Orange        ] ← ColorPicker   │
│                                     │
│ Grade System                        │
│ [V-Scale ▼]                         │
│                                     │
│ Grade Range                         │
│ Min: [V5 ▼]    Max: [V6 ▼]         │
│                                     │
│ Preview                             │
│ ┌─────────────────────────────────┐ │
│ │           🟠 Orange             │ │
│ │            V5 - V6              │ │
│ └─────────────────────────────────┘ │
│                                     │
│ [Cancel]                   [Add]    │
└─────────────────────────────────────┘
```

**Implementation**:
```swift
struct ColorMappingEditorView: View {
    @Environment(\.dismiss) private var dismiss
    
    let originalMapping: CircuitColorMapping?
    let sortOrder: Int
    let onSave: (CircuitColorMapping) -> Void
    
    @State private var color: Color
    @State private var baseGradeSystem: GradeSystem
    @State private var minGrade: String
    @State private var maxGrade: String
    @State private var validationError: String?
    
    init(mapping: CircuitColorMapping?, 
         sortOrder: Int,
         onSave: @escaping (CircuitColorMapping) -> Void) {
        self.originalMapping = mapping
        self.sortOrder = sortOrder
        self.onSave = onSave
        
        _color = State(initialValue: mapping != nil ? Color(hex: mapping!.color) : .blue)
        _baseGradeSystem = State(initialValue: mapping?.baseGradeSystem ?? .vscale)
        _minGrade = State(initialValue: mapping?.minGrade ?? "0")
        _maxGrade = State(initialValue: mapping?.maxGrade ?? "0")
    }
    
    var availableGrades: [String] {
        baseGradeSystem._protocol.grades
    }
    
    // Display name is auto-derived from color
    var derivedDisplayName: String {
        color.colorName
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Color") {
                    ColorPicker("Select Color", selection: $color, supportsOpacity: false)
                    
                    HStack {
                        Text("Display Name:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(derivedDisplayName)
                            .fontWeight(.medium)
                    }
                }
                
                Section("Grade Mapping") {
                    Picker("Grade System", selection: $baseGradeSystem) {
                        Text("V-Scale").tag(GradeSystem.vscale)
                        Text("Font").tag(GradeSystem.font)
                        Text("YDS").tag(GradeSystem.yds)
                        Text("French").tag(GradeSystem.french)
                    }
                    .onChange(of: baseGradeSystem) { _, _ in
                        // Reset grades when system changes
                        minGrade = availableGrades.first ?? ""
                        maxGrade = availableGrades.first ?? ""
                    }
                    
                    HStack {
                        Text("Min:")
                        Picker("", selection: $minGrade) {
                            ForEach(availableGrades, id: \.self) { grade in
                                Text(baseGradeSystem._protocol.description(for: grade) ?? grade)
                                    .tag(grade)
                            }
                        }
                    }
                    
                    HStack {
                        Text("Max:")
                        Picker("", selection: $maxGrade) {
                            ForEach(availableGrades, id: \.self) { grade in
                                Text(baseGradeSystem._protocol.description(for: grade) ?? grade)
                                    .tag(grade)
                            }
                        }
                    }
                }
                
                Section("Preview") {
                    VStack(spacing: 8) {
                        Circle()
                            .fill(color)
                            .frame(width: 60, height: 60)
                        
                        Text(derivedDisplayName)
                            .font(.headline)
                        
                        if !minGrade.isEmpty && !maxGrade.isEmpty {
                            let minDesc = baseGradeSystem._protocol.description(for: minGrade) ?? minGrade
                            let maxDesc = baseGradeSystem._protocol.description(for: maxGrade) ?? maxGrade
                            Text("\(minDesc) - \(maxDesc)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                
                if let error = validationError {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(originalMapping == nil ? "Add Color" : "Edit Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(originalMapping == nil ? "Add" : "Save") { 
                        saveMapping() 
                    }
                }
            }
        }
    }
    
    private func saveMapping() {
        // ID is UUID - auto-generated for new, preserved for existing
        let mapping = CircuitColorMapping(
            id: originalMapping?.id ?? UUID(),
            color: color.toHex(),
            sortOrder: sortOrder,
            baseGradeSystem: baseGradeSystem,
            minGrade: minGrade,
            maxGrade: maxGrade
        )
        
        do {
            try mapping.validate()
            onSave(mapping)
            dismiss()
        } catch {
            validationError = error.localizedDescription
        }
    }
}
```

### 4. Updated Grade System Selection

Modify existing grade system selection to handle circuit grades properly.

**Changes to `GradeSystemSelectionView`**:
- When circuit is selected, show current default circuit name
- Add "Edit Circuits" button that navigates to Circuit Builder
- Show quick preview of circuit colors

### 5. Updated Route Grade Display

Enhance route display to show grade range for circuit grades.

**Changes**:
- Color circle/square (visual identifier)
- Display name below color
- Grade range in smaller text (e.g., "V2-V4")
- Tooltip with full details

---

## Migration Strategy

### Phase 1: Cleanup Old Implementation

**Tasks**:
1. Delete `UserConfiguredCircuitGrade` class (lines 403-440 in ClimbingGrade.swift)
2. Delete `CircuitGradeProtocol` protocol (lines 398-400)
3. Delete `DEFAULT_CIRCUIT` constant (line 402)
4. Delete `CircuitGradeSelector.swift` (unused/outdated)

### Phase 2: Create New Models

**Tasks**:
1. Create `GymGradeConfiguration` SwiftData model
2. Create `CircuitColorMapping` SwiftData model
3. Create `CustomCircuitGrade` SwiftData model
4. Create `GymRegion` enum
5. Add validation methods
6. Add management methods (reorder, setAsDefault)

### Phase 3: Update Core Systems

**Tasks**:
1. Create `GradeSystemFactory` utility with regional defaults
2. Update `DifficultyIndex` with circuit support
3. Create `Color` extension utilities (hex conversion, colorName)
4. Update `Route` model with circuit tracking
5. Update `User` model with default circuit reference
6. Update Gym-related views to use grade configuration

### Phase 4: Data Migration Script

**Migration Code**:
```swift
struct CircuitGradeMigrationV1toV2 {
    /// Run once on app launch to migrate old circuit data
    static func migrate(context: ModelContext) throws {
        // Check if migration already performed
        let migrationKey = "circuit_grade_migration_v2_completed"
        if UserDefaults.standard.bool(forKey: migrationKey) {
            return
        }
        
        print("🔄 Starting circuit grade migration...")
        
        // 1. Create default circuit if none exists
        let defaultCircuit = GradeSystemFactory.defaultCircuit(context)
        print("✅ Created default circuit: \(defaultCircuit.name)")
        
        // 2. Build mapping from old color names to new UUIDs
        var colorNameToUUID: [String: UUID] = [:]
        for mapping in defaultCircuit.orderedMappings {
            let colorName = mapping.displayName.lowercased()
            colorNameToUUID[colorName] = mapping.id
        }
        
        // 3. Find all routes using circuit grade system
        let circuitRoutes = try context.fetch(
            FetchDescriptor<Route>(
                predicate: #Predicate { $0.gradeSystem == .circuit }
            )
        )
        
        print("📊 Found \(circuitRoutes.count) routes using circuit grades")
        
        // 4. Update each route
        var migrated = 0
        for route in circuitRoutes {
            if let oldGrade = route.grade?.lowercased(),
               let newId = colorNameToUUID[oldGrade] {
                // Update to new UUID string
                route.grade = newId.uuidString
                route.customCircuit = defaultCircuit
                migrated += 1
            } else {
                // Fallback: use first color if unknown
                route.grade = defaultCircuit.orderedMappings.first?.id.uuidString
                route.customCircuit = defaultCircuit
                print("⚠️ Unknown color '\(route.grade ?? "nil")' mapped to first color")
            }
        }
        
        print("✅ Migrated \(migrated) routes successfully")
        
        // 5. Save changes
        try context.save()
        
        // 6. Mark migration as complete
        UserDefaults.standard.set(true, forKey: migrationKey)
        print("✅ Circuit grade migration complete")
    }
}
```

**Trigger Migration**:
Add to `MainApp.swift`:
```swift
@main
struct CraktApp: App {
    let modelContainer: ModelContainer
    
    init() {
        // ... existing setup
        
        // Run migration on first launch
        Task {
            try? CircuitGradeMigrationV1toV2.migrate(context: modelContainer.mainContext)
        }
    }
    
    var body: some Scene {
        // ... existing scene
    }
}
```

### Phase 5: Update Views

**Tasks**:
1. Create `CircuitGradeBuilderView`
2. Create `CircuitEditorView`
3. Create `ColorMappingEditorView`
4. Update `SettingsView` to use new builder
5. Update `GradeSystemSelectionView`
6. Update route display components
7. Update analytics views to show circuit grade ranges

### Phase 6: Testing & Validation

**Tasks**:
1. Unit tests for validation
2. Unit tests for DI conversion
3. Unit tests for color utilities
4. Integration tests for circuit CRUD
5. UI tests for circuit builder flow
6. Migration testing with sample data

---

## Analytics Integration

### Chart Updates

**Affected Views**:
- `AttemptsByGradePieChartView`
- `AttemptsHistogramView`
- `AttemptStatusByGradeStackedBarChartView`
- `DifficultyTimelineChartView`
- `GradePyramidChartView`

**Changes Required**:
1. Display color swatches for circuit grades in legends
2. Show grade range tooltips on hover/tap
3. Add toggle to view "circuit view" vs "equivalent grade view"
4. Use DI for cross-session comparisons

**Example Enhancement**:
```swift
struct GradePyramidChartView: View {
    let routes: [Route]
    @State private var showCircuitEquivalent = false
    
    var body: some View {
        VStack {
            Toggle("Show Grade Equivalents", isOn: $showCircuitEquivalent)
                .padding()
            
            Chart {
                ForEach(chartData) { data in
                    BarMark(
                        x: .value("Count", data.count),
                        y: .value("Grade", data.gradeLabel(showEquivalent: showCircuitEquivalent))
                    )
                    .foregroundStyle(data.color)
                }
            }
        }
    }
}
```

---

## User Workflows

### Workflow 1: Creating a New Circuit

1. User navigates to **Settings → Circuit Grade Builder**
2. Taps **"Create New Circuit"**
3. Enters circuit name (e.g., "My Gym Circuit") or selects a gym (name auto-populates)
4. Taps **"Add Color"** for each level:
   - Picks color from ColorPicker (display name "Green" auto-derives)
   - Selects base system (V-Scale)
   - Selects min grade (VB)
   - Selects max grade (V0)
   - Taps **"Add"**
5. Repeats step 4 for all difficulty levels
6. Reorders colors if needed via drag handles
7. Reviews preview
8. Taps **"Save Circuit"**
9. Optionally sets as default

**Result**: New circuit is saved and available for use. No manual typing of color names needed.

### Workflow 2: Using Circuit in Active Session

1. User starts a session at a gym
2. System auto-detects gym's grade configuration:
   - Uses gym's boulder system (Circuit/V-Scale/Font)
   - Uses gym's rope system (YDS/French)
   - Regional defaults apply if gym has no config (US = V-Scale/YDS, Europe = Font/French)
3. If circuit system:
   - Gym's circuit loads automatically if associated
   - User's default circuit otherwise
   - Generic default if none configured
4. When logging a route, user sees color picker with:
   - Color swatches
   - Color names (auto-derived)
   - Grade ranges (small text, e.g., "V1-V2")
5. User selects color (e.g., "Green V1-V2")
6. Route is logged with:
   - `grade = "<UUID>"` (mapping ID)
   - `customCircuit = <selected circuit>`
   - `gradeSystem = .circuit`

**Result**: Route is logged with proper circuit reference and stable UUID identifier

### Workflow 3: Viewing Circuit Analytics

1. User navigates to session detail or global analytics
2. Charts display circuit routes with:
   - Color-coded bars/segments
   - Display names in legends
   - Grade range tooltips
3. User toggles **"Show Grade Equivalents"**
4. Chart updates to show DI-converted grades
5. User can compare circuit sessions with grade sessions

**Result**: Unified analytics across grade systems

### Workflow 4: Editing Existing Circuit

1. User navigates to **Settings → Circuit Grade Builder**
2. Taps **"Edit"** on desired circuit
3. Makes changes:
   - Rename circuit
   - Change colors (existing routes unaffected due to gradeId)
   - Add/remove colors
   - Adjust grade ranges
4. Taps **"Save"**
5. System validates changes
6. Changes are saved

**Result**: Circuit is updated, existing routes remain intact

---

## Testing Requirements

### Unit Tests

**File**: `CircuitGradeTests.swift`

```swift
class CircuitGradeTests: XCTestCase {
    func testCircuitColorMappingValidation() {
        // Test valid mapping
        let validMapping = CircuitColorMapping(
            color: "#007AFF",
            sortOrder: 0,
            baseGradeSystem: .vscale,
            minGrade: "0",
            maxGrade: "1"
        )
        XCTAssertNoThrow(try validMapping.validate())
        XCTAssertEqual(validMapping.displayName, "Blue")  // Auto-derived
        
        // Test invalid hex color
        let invalidMapping = CircuitColorMapping(
            color: "not-a-hex",
            sortOrder: 0,
            baseGradeSystem: .vscale,
            minGrade: "0",
            maxGrade: "1"
        )
        XCTAssertThrowsError(try invalidMapping.validate())
        
        // Test invalid grade range (max < min)
        let invalidRange = CircuitColorMapping(
            color: "#34C759",
            sortOrder: 0,
            baseGradeSystem: .vscale,
            minGrade: "5",
            maxGrade: "2"
        )
        XCTAssertThrowsError(try invalidRange.validate())
    }
    
    func testDICalculationForCircuit() {
        let context = TestModelContext()
        let circuit = createTestCircuit(context: context)
        let blueMapping = circuit.orderedMappings.first!
        
        // Test midpoint calculation
        let blueDI = DifficultyIndex.normalizeToDI(
            circuitGrade: blueMapping.id.uuidString,
            circuit: circuit
        )
        
        // Blue is VB-V0, which maps to 6a (DI=60) and 6a+ (DI=70)
        // Midpoint should be 65
        XCTAssertEqual(blueDI, 65)
    }
    
    func testColorHexConversion() {
        let blue = Color(hex: "#007AFF")
        let hex = blue.toHex()
        XCTAssertEqual(hex, "#007AFF")
        XCTAssertEqual(blue.colorName, "Blue")
    }
    
    func testMappingIdStability() {
        // Changing color should not affect ID
        let mapping = CircuitColorMapping(
            color: "#007AFF",
            sortOrder: 0,
            baseGradeSystem: .vscale,
            minGrade: "0",
            maxGrade: "1"
        )
        
        let originalId = mapping.id
        mapping.color = "#0000FF"  // Change color
        
        XCTAssertEqual(mapping.id, originalId)  // ID remains stable
        XCTAssertEqual(mapping.displayName, "Blue")  // Name updates to new color
    }
    
    func testRegionalDefaults() {
        XCTAssertEqual(GymRegion.from(countryCode: "US"), .northAmerica)
        XCTAssertEqual(GymRegion.from(countryCode: "FR"), .europe)
        XCTAssertEqual(GymRegion.from(countryCode: "GB"), .uk)
        
        let usDefaults = GymGradeConfiguration.defaultsForRegion(.northAmerica)
        XCTAssertEqual(usDefaults.boulder, .vscale)
        XCTAssertEqual(usDefaults.rope, .yds)
        
        let euDefaults = GymGradeConfiguration.defaultsForRegion(.europe)
        XCTAssertEqual(euDefaults.boulder, .font)
        XCTAssertEqual(euDefaults.rope, .french)
    }
}
```

### Integration Tests

**File**: `CircuitCRUDTests.swift`

```swift
class CircuitCRUDTests: XCTestCase {
    func testCreateAndFetchCircuit() throws {
        let context = TestModelContext()
        
        // Create circuit
        let circuit = CustomCircuitGrade(name: "Test Circuit")
        let mapping = CircuitColorMapping(
            color: "#007AFF",
            sortOrder: 0,
            baseGradeSystem: .vscale,
            minGrade: "0",
            maxGrade: "1"
        )
        circuit.colorMappings.append(mapping)
        
        context.insert(circuit)
        try context.save()
        
        // Fetch circuit
        let descriptor = FetchDescriptor<CustomCircuitGrade>()
        let circuits = try context.fetch(descriptor)
        
        XCTAssertEqual(circuits.count, 1)
        XCTAssertEqual(circuits.first?.name, "Test Circuit")
        XCTAssertEqual(circuits.first?.colorMappings.count, 1)
        XCTAssertEqual(circuits.first?.colorMappings.first?.displayName, "Blue")
    }
    
    func testSetDefaultCircuit() throws {
        let context = TestModelContext()
        
        // Create two circuits
        let circuit1 = CustomCircuitGrade(name: "Circuit 1", isDefault: true)
        let circuit2 = CustomCircuitGrade(name: "Circuit 2", isDefault: false)
        
        context.insert(circuit1)
        context.insert(circuit2)
        try context.save()
        
        // Set circuit2 as default
        try circuit2.setAsDefault(in: context)
        
        // Verify only circuit2 is default
        let descriptor = FetchDescriptor<CustomCircuitGrade>()
        let circuits = try context.fetch(descriptor)
        
        XCTAssertFalse(circuits.first { $0.name == "Circuit 1" }!.isDefault)
        XCTAssertTrue(circuits.first { $0.name == "Circuit 2" }!.isDefault)
    }
    
    func testGymGradeConfiguration() throws {
        let context = TestModelContext()
        let gymId = UUID()
        
        // Get config with US defaults
        let config = GradeSystemFactory.gradeSystemsForGym(gymId, countryCode: "US", modelContext: context)
        
        XCTAssertEqual(config.boulderGradeSystem, .vscale)
        XCTAssertEqual(config.ropeGradeSystem, .yds)
        
        // Same gym should return same config
        let config2 = GradeSystemFactory.gradeSystemsForGym(gymId, countryCode: "US", modelContext: context)
        XCTAssertEqual(config.id, config2.id)
    }
}
```

### UI Tests

**File**: `CircuitBuilderUITests.swift`

```swift
class CircuitBuilderUITests: XCTestCase {
    func testCreateCircuitWorkflow() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Navigate to settings
        app.tabBars.buttons["Settings"].tap()
        
        // Open circuit builder
        app.buttons["Circuit Grade Builder"].tap()
        
        // Create new circuit
        app.buttons["Create New Circuit"].tap()
        
        // Fill in details
        let nameField = app.textFields["Circuit Name"]
        nameField.tap()
        nameField.typeText("Test Gym")
        
        // Add color
        app.buttons["Add Color"].tap()
        
        let displayNameField = app.textFields["Display Name"]
        displayNameField.tap()
        displayNameField.typeText("Beginner")
        
        // Select grade range (simplified - actual picker interaction needed)
        app.buttons["Add"].tap()
        
        // Save circuit
        app.buttons["Save Circuit"].tap()
        
        // Verify circuit appears in list
        XCTAssertTrue(app.staticTexts["Test Gym"].exists)
    }
}
```

---

## Implementation Timeline

### Phase 1: Foundation (Week 1)
- **Days 1-2**: Data models and validation
- **Days 3-4**: GradeSystemFactory and DI integration
- **Day 5**: Color utilities and testing

### Phase 2: Core UI (Week 2)
- **Days 1-2**: Circuit Builder list view
- **Days 3-4**: Circuit Editor view
- **Day 5**: Color Mapping Editor view

### Phase 3: Integration (Week 3)
- **Days 1-2**: Route model updates and migration
- **Days 3-4**: Grade system selection updates
- **Day 5**: Route display updates

### Phase 4: Analytics (Week 4)
- **Days 1-3**: Chart updates for circuit support
- **Days 4-5**: Testing and bug fixes

### Phase 5: Polish (Week 5)
- **Days 1-2**: UI polish and accessibility
- **Days 3-4**: Documentation
- **Day 5**: Final testing and release prep

**Total Estimated Time**: 5 weeks

---

## Success Metrics

### User Adoption
- % of users who create custom circuits: Target 40%
- Average circuits per user: Target 2-3
- % of sessions using circuit grades: Target 30%

### Data Quality
- Circuit grade validation error rate: Target <5%
- Migration success rate: Target 100%
- DI conversion accuracy: Target 100%

### User Satisfaction
- Feature discovery rate: Target 60%
- Circuit editing completion rate: Target 80%
- User feedback sentiment: Target >4.0/5.0

### Technical Metrics
- Circuit loading time: Target <100ms
- Database query performance: Target <50ms
- Crash rate: Target <0.1%

---

## Future Enhancements (Post-V1)

### V2 Features
1. **Circuit Versioning**: Track gym circuit changes over time
2. **Import/Export**: Share circuits via QR code or JSON
3. **Gym Integration**: Auto-load circuit when selecting gym
4. **Crowd-Sourced Data**: Community-contributed gym circuits
5. **Smart Suggestions**: AI-recommended circuit mappings based on climbs

### V3 Features
1. **Circuit Analytics Dashboard**: Detailed circuit-specific insights
2. **Historical Tracking**: See how gym circuits change season-to-season
3. **Weighted DI Calculation**: Configurable bias for grade range midpoint
4. **Pattern/Texture Options**: Accessibility beyond color
5. **Circuit API**: External apps can submit/retrieve circuit data

---

## Open Questions & Decisions Needed

### Resolved
- ✅ Use UUID (`id`) as primary identifier - not string-based gradeId
- ✅ Display name auto-derives from color picker - no manual typing
- ✅ Use factory pattern instead of @Observable with @Environment
- ✅ Store circuit reference on Route for resilience
- ✅ Use simple midpoint for DI calculation in V1
- ✅ Include gym-grade system association in this work
- ✅ Apply regional defaults (US = V-Scale/YDS, Europe = Font/French)

### Pending User Confirmation
- ⏳ Should circuits be shareable between users?
- ⏳ Privacy model for gym-associated circuits?
- ⏳ Maximum number of colors per circuit?

### Technical Unknowns
- ⚠️ SwiftData cascade delete behavior with circuit relationships
- ⚠️ Performance with 100+ circuits (edge case)

---

## Dependencies

### Internal
- Existing `DifficultyIndex` system (must remain intact)
- `GradeSystem` enum (minimal changes)
- `Route` model (relationship addition)
- SwiftData model container configuration

### External
- None (feature is self-contained)

---

## Risk Assessment

### High Risk
- **Migration complexity**: Existing routes must migrate cleanly
  - Mitigation: Extensive testing, rollback capability
- **Performance**: Complex grade protocol lookups
  - Mitigation: Caching, profiling, optimization

### Medium Risk
- **User confusion**: Circuit system is more complex than simple colors
  - Mitigation: Clear onboarding, good defaults, tooltips
- **Validation edge cases**: Unusual grade range configurations
  - Mitigation: Comprehensive validation, user feedback

### Low Risk
- **Color accessibility**: Color-blind users
  - Mitigation: Require display names, future pattern support
- **Storage growth**: Many circuits per user
  - Mitigation: Reasonable limits, cleanup tools

---

## Accessibility Considerations

### Must Have (V1)
- [x] Display names required (not just colors)
- [x] VoiceOver support for all UI components
- [x] Color contrast validation (WCAG AA)
- [x] Keyboard navigation support
- [x] Dynamic type support

### Should Have (V2)
- [ ] Pattern/texture options in addition to color
- [ ] High contrast mode
- [ ] Haptic feedback for circuit selection
- [ ] Voice control support

---

## Documentation Requirements

### User-Facing
- Help article: "Creating Custom Circuit Grades"
- Video tutorial: Circuit builder walkthrough
- FAQ: Common circuit configuration questions

### Developer-Facing
- Architecture diagram: Circuit grade system
- API documentation: GradeSystemFactory
- Migration guide: V1 to V2 circuit grades
- Testing guide: Circuit feature test coverage

---

## Conclusion

The Custom Circuit Grade Systems feature represents a significant enhancement to the crakt climbing app, enabling users to accurately track their climbing progress using gym-specific circuit grading systems. By integrating with the existing Difficulty Index (DI) system, the feature maintains cross-system analytics capabilities while providing the flexibility users need for real-world gym climbing.

The implementation addresses all critical technical issues identified in the tech lead review, including proper state management, data persistence, stable identifiers, and comprehensive validation. The phased rollout approach minimizes risk while delivering value incrementally.

**Status**: Specification complete. Ready for implementation.

---

## Milestones & Task Breakdown

### Milestone 1: Data Models & Core Infrastructure (3 days)

Foundation layer - all subsequent work depends on this.

- [ ] **1.1 Delete Old Circuit Implementation**
  - **Files**: `ClimbingGrade.swift`, `CircuitGradeSelector.swift`
  - **Tasks**:
    - Delete `UserConfiguredCircuitGrade` class (lines 403-440)
    - Delete `CircuitGradeProtocol` protocol (lines 398-400)
    - Delete `DEFAULT_CIRCUIT` constant (line 402)
    - Delete `CircuitGradeSelector.swift`
  - **Dependencies**: None
  - **Estimated**: 30 min

- [ ] **1.2 Create GymRegion Enum**
  - **Files**: `GradeSystem.swift` (new enum)
  - **Tasks**:
    - Implement `GymRegion` enum with all cases
    - Implement `from(countryCode:)` static method
    - Add regional default mapping logic
  - **Dependencies**: None
  - **Estimated**: 1 hour

- [ ] **1.3 Create GymGradeConfiguration Model**
  - **Files**: `GymGradeConfiguration.swift` (new file)
  - **Tasks**:
    - Create SwiftData model with gymId, boulderGradeSystem, ropeGradeSystem
    - Add relationship to CustomCircuitGrade
    - Add `defaultsForRegion()` static method
    - Add validation method
  - **Dependencies**: 1.2
  - **Estimated**: 2 hours

- [ ] **1.4 Create CircuitColorMapping Model**
  - **Files**: `CircuitColorMapping.swift` (new file)
  - **Tasks**:
    - Create SwiftData model with UUID id, color, sortOrder, grades
    - Add computed `displayName` property (auto-derived from color)
    - Add computed `gradeRangeDescription` property
    - Add computed `midpointDI` property
    - Add validation method
  - **Dependencies**: None
  - **Estimated**: 2 hours

- [ ] **1.5 Create CustomCircuitGrade Model**
  - **Files**: `CustomCircuitGrade.swift` (new file)
  - **Tasks**:
    - Create SwiftData model with relationships
    - Add `orderedMappings` computed property
    - Add `setAsDefault(in:)` method
    - Add `reorderMapping(from:to:)` method
    - Add validation method
  - **Dependencies**: 1.4
  - **Estimated**: 2 hours

- [ ] **1.6 Create CircuitGrade Protocol Implementation**
  - **Files**: `CircuitGrade.swift` (new file)
  - **Tasks**:
    - Implement `GradeProtocol` conformance
    - Implement `grades`, `colorMap`, `colors(for:)`, `description(for:)`
    - Add `mapping(for:)` helper method
  - **Dependencies**: 1.5
  - **Estimated**: 1.5 hours

- [ ] **1.7 Create Color Extension Utilities**
  - **Files**: `Color+Hex.swift` (new file in Extensions/)
  - **Tasks**:
    - Implement `init(hex:)` initializer
    - Implement `toHex()` method (cross-platform)
    - Implement `colorName` computed property
  - **Dependencies**: None
  - **Estimated**: 1.5 hours

---

### Milestone 2: Grade System Factory & DI Integration (2 days)

Wire the new models into existing systems.

- [ ] **2.1 Create GradeSystemFactory**
  - **Files**: `GradeSystemFactory.swift` (new file)
  - **Tasks**:
    - Implement `gradeProtocol(for:circuit:modelContext:)`
    - Implement `gradeSystemsForGym(_:countryCode:modelContext:)`
    - Implement `defaultCircuit(_:)` with caching
    - Implement `createAndSaveDefaultCircuit(_:)`
    - Implement `createFontBasedDefaultCircuit(_:)`
  - **Dependencies**: Milestone 1 complete
  - **Estimated**: 3 hours

- [ ] **2.2 Update DifficultyIndex for Circuit Support**
  - **Files**: `ClimbingGrade.swift` (DifficultyIndex extension)
  - **Tasks**:
    - Add `normalizeToDI(circuitMapping:)` method
    - Add `normalizeToDI(circuitGrade:circuit:)` method
    - Add `gradeRangeDescription(circuitGrade:circuit:)` method
    - Add `convertFromCircuit(circuitGrade:circuit:toSystem:toType:)` method
    - Update existing `normalizeToDI` to handle .circuit case
  - **Dependencies**: Milestone 1 complete
  - **Estimated**: 2 hours

- [ ] **2.3 Update Route Model**
  - **Files**: `Route.swift`
  - **Tasks**:
    - Add `customCircuitId: UUID?` field
    - Add `customCircuit: CustomCircuitGrade?` relationship
    - Add `gradeProtocol(modelContext:)` method
    - Update `gradeColor` computed property
    - Update `gradeDescription` computed property
  - **Dependencies**: 2.1
  - **Estimated**: 2 hours

- [ ] **2.4 Update GradeSystem Enum**
  - **Files**: `GradeSystem.swift`
  - **Tasks**:
    - Update `._protocol` to work with factory or deprecate
    - Add circuit-aware grade system helpers
  - **Dependencies**: 2.1
  - **Estimated**: 1 hour

- [ ] **2.5 Register New Models with SwiftData Container**
  - **Files**: `MainApp.swift`
  - **Tasks**:
    - Add new models to schema
    - Test model container initialization
  - **Dependencies**: 2.1, 2.3
  - **Estimated**: 30 min

---

### Milestone 3: Data Migration (1 day)

Migrate existing circuit data to new format.

- [ ] **3.1 Create Migration Script**
  - **Files**: `CircuitGradeMigration.swift` (new file)
  - **Tasks**:
    - Implement `CircuitGradeMigrationV1toV2.migrate(context:)`
    - Build color name → UUID mapping
    - Update existing routes
    - Add error handling and logging
    - Add migration completion flag
  - **Dependencies**: Milestone 2 complete
  - **Estimated**: 2 hours

- [ ] **3.2 Integrate Migration into App Launch**
  - **Files**: `MainApp.swift`
  - **Tasks**:
    - Call migration on app launch
    - Handle migration errors gracefully
  - **Dependencies**: 3.1
  - **Estimated**: 30 min

- [ ] **3.3 Test Migration with Sample Data**
  - **Files**: Test files
  - **Tasks**:
    - Create test routes with old circuit grades
    - Verify migration preserves data
    - Verify UUIDs are correctly assigned
  - **Dependencies**: 3.2
  - **Estimated**: 2 hours

---

### Milestone 4: Circuit Builder UI (3 days)

User-facing circuit management interface.

- [ ] **4.1 Create CircuitCardView Component**
  - **Files**: `CircuitCardView.swift` (new file in Views/Settings/)
  - **Tasks**:
    - Display circuit name, color swatches, metadata
    - Add Edit, Delete, Set Default actions
    - Show "Default" badge for default circuit
  - **Dependencies**: Milestone 1 complete
  - **Estimated**: 2 hours

- [ ] **4.2 Create CircuitPreviewView Component**
  - **Files**: `CircuitPreviewView.swift` (new file)
  - **Tasks**:
    - Display horizontal color swatch preview
    - Show color names on tap/hover
  - **Dependencies**: None
  - **Estimated**: 1 hour

- [ ] **4.3 Create CircuitGradeBuilderView**
  - **Files**: `CircuitGradeBuilderView.swift` (new file)
  - **Tasks**:
    - List all circuits with @Query
    - Create new circuit button
    - Edit/delete circuit actions
    - Set default circuit action
    - Navigation title and styling
  - **Dependencies**: 4.1
  - **Estimated**: 3 hours

- [ ] **4.4 Create ColorMappingRow Component**
  - **Files**: `ColorMappingRow.swift` (new file)
  - **Tasks**:
    - Display color swatch, auto-derived name, grade range
    - Drag handle for reordering
    - Edit/delete buttons
  - **Dependencies**: None
  - **Estimated**: 1.5 hours

- [ ] **4.5 Create ColorMappingEditorView**
  - **Files**: `ColorMappingEditorView.swift` (new file)
  - **Tasks**:
    - ColorPicker for color selection
    - Auto-derived display name display (read-only)
    - Grade system picker
    - Min/max grade pickers
    - Preview section
    - Validation display
  - **Dependencies**: 4.2
  - **Estimated**: 3 hours

- [ ] **4.6 Create CircuitEditorView**
  - **Files**: `CircuitEditorView.swift` (new file)
  - **Tasks**:
    - Circuit name text field
    - Gym picker (optional association)
    - Color mappings list with reorder
    - Add color button → ColorMappingEditorView
    - Preview section
    - Save/Cancel actions with validation
  - **Dependencies**: 4.4, 4.5
  - **Estimated**: 4 hours

- [ ] **4.7 Update SettingsView**
  - **Files**: `SettingsView.swift`
  - **Tasks**:
    - Replace placeholder `CircuitGradeBuilderSectionView`
    - Navigate to `CircuitGradeBuilderView`
  - **Dependencies**: 4.3
  - **Estimated**: 30 min

---

### Milestone 5: Gym Grade Configuration UI (2 days)

Gym-level grade system preferences.

- [ ] **5.1 Create GymGradeConfigurationView**
  - **Files**: `GymGradeConfigurationView.swift` (new file)
  - **Tasks**:
    - Boulder grade system picker (Circuit/V-Scale/Font)
    - Rope grade system picker (YDS/French)
    - If circuit, show circuit selector
    - Save configuration
  - **Dependencies**: Milestone 4 complete
  - **Estimated**: 3 hours

- [ ] **5.2 Update GymDetailSheet**
  - **Files**: `GymDetailSheet.swift`
  - **Tasks**:
    - Add grade system configuration section
    - Show current boulder/rope systems
    - Link to edit configuration
  - **Dependencies**: 5.1
  - **Estimated**: 2 hours

- [ ] **5.3 Update SessionConfigView for Gym Grade Systems**
  - **Files**: `SessionConfigView.swift`
  - **Tasks**:
    - Auto-detect gym's grade configuration
    - Pre-select boulder/rope systems based on gym
    - Apply regional defaults when no gym config
  - **Dependencies**: 5.1
  - **Estimated**: 2 hours

- [ ] **5.4 Update GradeSystemSelectionView**
  - **Files**: `GradeSystemSelectionView.swift`
  - **Tasks**:
    - Show current circuit name when circuit selected
    - Add "Edit Circuits" navigation
    - Show circuit color preview
  - **Dependencies**: 5.3
  - **Estimated**: 2 hours

---

### Milestone 6: Route & Session Integration (2 days)

Connect circuits to route logging flow.

- [ ] **6.1 Create CircuitGradePicker Component**
  - **Files**: `CircuitGradePicker.swift` (new file)
  - **Tasks**:
    - Display circuit colors as selectable swatches
    - Show color name and grade range
    - Return UUID string on selection
  - **Dependencies**: Milestone 4 complete
  - **Estimated**: 2 hours

- [ ] **6.2 Update CompactGradeSelector**
  - **Files**: `CompactGradeSelector.swift`
  - **Tasks**:
    - Handle circuit grade system with CircuitGradePicker
    - Pass circuit reference for display
  - **Dependencies**: 6.1
  - **Estimated**: 1.5 hours

- [ ] **6.3 Update Route Display Components**
  - **Files**: Various route display views
  - **Tasks**:
    - Show color swatch for circuit grades
    - Display color name and grade range
    - Handle missing circuit gracefully
  - **Dependencies**: 6.2
  - **Estimated**: 2 hours

- [ ] **6.4 Update RouteReviewView**
  - **Files**: `RouteReviewView.swift`
  - **Tasks**:
    - Display circuit grade with color and range
    - Allow editing circuit selection
  - **Dependencies**: 6.2
  - **Estimated**: 1.5 hours

- [ ] **6.5 Update Session Route Logging**
  - **Files**: `SessionTabView.swift`, `SessionActionBar.swift`
  - **Tasks**:
    - Use gym's grade configuration
    - Store circuit reference on new routes
    - Handle circuit grade selection
  - **Dependencies**: 6.2
  - **Estimated**: 2 hours

---

### Milestone 7: Analytics Integration (2 days)

Update charts to support circuit grades.

- [ ] **7.1 Update AttemptsByGradePieChartView**
  - **Files**: `AttemptsByGradePieChartView.swift`
  - **Tasks**:
    - Show circuit colors in chart
    - Display color name in legend
    - Show grade range tooltip
  - **Dependencies**: Milestone 6 complete
  - **Estimated**: 2 hours

- [ ] **7.2 Update AttemptsHistogramView**
  - **Files**: `AttemptsHistogramView.swift`
  - **Tasks**:
    - Handle circuit grades in histogram
    - Use DI for positioning
  - **Dependencies**: Milestone 6 complete
  - **Estimated**: 2 hours

- [ ] **7.3 Update GradePyramidChartView**
  - **Files**: `GradePyramidChartView.swift`
  - **Tasks**:
    - Display circuit colors
    - Add toggle for "Show Grade Equivalents"
  - **Dependencies**: Milestone 6 complete
  - **Estimated**: 2 hours

- [ ] **7.4 Update DifficultyTimelineChartView**
  - **Files**: `DifficultyTimelineChartView.swift`
  - **Tasks**:
    - Use DI for circuit grades
    - Show color indicators
  - **Dependencies**: Milestone 6 complete
  - **Estimated**: 2 hours

- [ ] **7.5 Update Global Analytics Views**
  - **Files**: `GlobalSessionsView.swift`, session stats views
  - **Tasks**:
    - Handle circuit grades in aggregations
    - Use DI for cross-system comparison
  - **Dependencies**: 7.1-7.4
  - **Estimated**: 2 hours

---

### Milestone 8: Testing & Polish (2 days)

Comprehensive testing and refinement.

- [ ] **8.1 Unit Tests for Models**
  - **Files**: `CircuitGradeTests.swift` (new file)
  - **Tasks**:
    - Test CircuitColorMapping validation
    - Test CustomCircuitGrade validation
    - Test GymGradeConfiguration validation
    - Test DI calculations
    - Test color utilities
    - Test regional defaults
  - **Dependencies**: All milestones
  - **Estimated**: 3 hours

- [ ] **8.2 Integration Tests for CRUD**
  - **Files**: `CircuitCRUDTests.swift` (new file)
  - **Tasks**:
    - Test circuit creation and fetch
    - Test setAsDefault behavior
    - Test gym grade configuration
    - Test route with circuit grade
  - **Dependencies**: All milestones
  - **Estimated**: 2 hours

- [ ] **8.3 UI Tests for Circuit Builder**
  - **Files**: `CircuitBuilderUITests.swift` (new file)
  - **Tasks**:
    - Test create circuit workflow
    - Test edit circuit workflow
    - Test delete circuit workflow
    - Test color picker integration
  - **Dependencies**: All milestones
  - **Estimated**: 2 hours

- [ ] **8.4 Migration Testing**
  - **Tasks**:
    - Test migration with production data sample
    - Verify all routes migrate correctly
    - Test migration idempotency
  - **Dependencies**: All milestones
  - **Estimated**: 2 hours

- [ ] **8.5 UI Polish & Accessibility**
  - **Tasks**:
    - VoiceOver testing for all new views
    - Dynamic type support verification
    - Color contrast validation
    - Keyboard navigation testing
  - **Dependencies**: All milestones
  - **Estimated**: 2 hours

- [ ] **8.6 Final QA Pass**
  - **Tasks**:
    - End-to-end testing of all workflows
    - Performance testing with many circuits
    - Edge case testing
    - Bug fixes
  - **Dependencies**: 8.1-8.5
  - **Estimated**: 3 hours

---

## Summary

**Total Estimated Time**: ~17 working days (3.5 weeks)

**Critical Path**: 
1. Milestone 1 (Data Models) → 
2. Milestone 2 (Factory & DI) → 
3. Milestone 3 (Migration) → 
4. Milestone 4 (Builder UI) → 
5. Milestone 6 (Route Integration) → 
6. Milestone 8 (Testing)

**Parallel Work Possible**:
- Milestone 4 (Builder UI) can start while Milestone 3 (Migration) is in progress
- Milestone 5 (Gym Config UI) can parallel with Milestone 6 (Route Integration)
- Milestone 7 (Analytics) can parallel with Milestone 8 (Testing)

