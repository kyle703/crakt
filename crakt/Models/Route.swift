//
//  Route.swift
//  crakt
//
//  Created by Kyle Thompson on 3/21/24.
//
//

import Foundation
import SwiftData
import Charts
import SwiftUI


enum RouteStatus: Int, Codable {
    case active = 0
    case inactive = 1
}

// MARK: - Wall Angle (physical characteristic of the climbing surface)
enum WallAngle: String, Codable, CaseIterable {
    case slab = "Slab"
    case vertical = "Vertical"
    case overhang = "Overhang"
    case steep = "Steep"
    case roof = "Roof"
    
    var description: String { rawValue }
    
    var iconName: String {
        switch self {
        case .slab: return "arrow.up.left"
        case .vertical: return "arrow.up"
        case .overhang: return "arrow.up.right"
        case .steep: return "arrow.right"
        case .roof: return "arrow.down.right"
        }
    }
    
    var color: Color {
        switch self {
        case .slab: return .cyan
        case .vertical: return .green
        case .overhang: return .yellow
        case .steep: return .orange
        case .roof: return .red
        }
    }
}

// MARK: - Hold Types (what grips dominate the route)
enum HoldType: String, Codable, CaseIterable {
    case jugs = "Jugs"
    case crimps = "Crimps"
    case slopers = "Slopers"
    case pinches = "Pinches"
    case pockets = "Pockets"
    case volumes = "Volumes"
    
    var description: String { rawValue }
    
    var iconName: String {
        switch self {
        case .jugs: return "hand.raised.fill"
        case .crimps: return "hand.point.up.fill"
        case .slopers: return "hand.point.down.fill"
        case .pinches: return "hand.point.left.fill"
        case .pockets: return "circle.fill"
        case .volumes: return "cube.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .jugs: return .green
        case .crimps: return .orange
        case .slopers: return .pink
        case .pinches: return .purple
        case .pockets: return .blue
        case .volumes: return .mint
        }
    }
}

// MARK: - Movement Style (how the route climbs)
enum MovementStyle: String, Codable, CaseIterable {
    case dynamic = "Dynamic"
    case staticStyle = "Static"
    case technical = "Technical"
    case powerful = "Powerful"
    case coordination = "Coordination"
    case compression = "Compression"
    
    var description: String {
        switch self {
        case .staticStyle: return "Static"
        default: return rawValue
        }
    }
    
    var iconName: String {
        switch self {
        case .dynamic: return "bolt.fill"
        case .staticStyle: return "pause.fill"
        case .technical: return "brain"
        case .powerful: return "figure.strengthtraining.traditional"
        case .coordination: return "figure.gymnastics"
        case .compression: return "arrow.left.arrow.right"
        }
    }
    
    var color: Color {
        switch self {
        case .dynamic: return .yellow
        case .staticStyle: return .blue
        case .technical: return .purple
        case .powerful: return .red
        case .coordination: return .orange
        case .compression: return .indigo
        }
    }
}

enum DifficultyRating: String, Codable, CaseIterable {
    case easy = "Easy"
    case justRight = "Just Right"
    case hard = "Hard"

    var description: String {
        return self.rawValue
    }

    var iconName: String {
        switch self {
        case .easy: return "hand.thumbsup"
        case .justRight: return "checkmark.circle"
        case .hard: return "hand.thumbsdown"
        }
    }

    var color: Color {
        switch self {
        case .easy: return .green
        case .justRight: return .blue
        case .hard: return .orange
        }
    }
}

// MARK: - Grade Feel (how accurate the grade felt)
enum GradeFeel: String, Codable, CaseIterable {
    case soft = "Soft"
    case onGrade = "On Grade"
    case stiff = "Stiff"
    
    var description: String { rawValue }
    
    var iconName: String {
        switch self {
        case .soft: return "arrow.down.circle.fill"
        case .onGrade: return "checkmark.circle.fill"
        case .stiff: return "arrow.up.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .soft: return .green
        case .onGrade: return .blue
        case .stiff: return .red
        }
    }
}

// MARK: - Climb Experience (physical demands and subjective feel)
enum ClimbExperience: String, Codable, CaseIterable {
    // Physical demands
    case pumpy = "Pumpy"
    case fingery = "Fingery"
    case core = "Core"
    case shouldery = "Shoulders"
    case endurance = "Endurance"
    case balance = "Balance"
    // Subjective feel
    case fun = "Fun"
    case frustrating = "Frustrating"
    case satisfying = "Satisfying"

    var description: String { rawValue }

    var iconName: String {
        switch self {
        case .pumpy: return "flame.fill"
        case .fingery: return "hand.point.up.fill"
        case .core: return "figure.core.training"
        case .shouldery: return "figure.arms.open"
        case .endurance: return "clock.fill"
        case .balance: return "figure.stand"
        case .fun: return "face.smiling.fill"
        case .frustrating: return "face.dashed"
        case .satisfying: return "star.fill"
        }
    }

    var color: Color {
        switch self {
        case .pumpy: return .orange
        case .fingery: return .red
        case .core: return .purple
        case .shouldery: return .blue
        case .endurance: return .cyan
        case .balance: return .green
        case .fun: return .yellow
        case .frustrating: return .gray
        case .satisfying: return .mint
        }
    }
}



@Model class Route: Identifiable {
    
    var id: UUID
    
    var climbType: ClimbType = ClimbType.boulder
    
    /// Grade identifier - for circuit grades this is a UUID string, for others it's the grade value
    var grade: String?
    var gradeSystem: GradeSystem = GradeSystem.circuit
    
    // MARK: - Circuit Grade Support
    
    /// For circuit grades: stores the circuit ID for resilience if relationship is broken
    var customCircuitId: UUID?
    
    /// For circuit grades: reference to the circuit configuration used
    @Relationship(deleteRule: .nullify)
    var customCircuit: CustomCircuitGrade?
    
    // MARK: - Grade Display Properties
    
    var gradeDescription: String? {
        guard let grade = grade else { return nil }
        
        // For circuit grades, use the circuit's description
        if gradeSystem == .circuit {
            // Try customCircuit first (most common case)
            if let circuit = customCircuit {
                return CircuitGrade(customCircuit: circuit).description(for: grade)
            }
            // Fallback: If customCircuit is nil but we have the mapping via circuitMapping
            // (which also checks customCircuit, so this is a safety check)
            if let mapping = circuitMapping {
                return mapping.displayName
            }
            // Last resort: Return a generic circuit label instead of UUID
            // This prevents UUIDs from being displayed in charts
            // The UUID is still stored in route.grade for data integrity
            return "Circuit"
        }
        
        return GradeSystemFactory.safeProtocol(for: gradeSystem).description(for: grade)
    }
    
    var gradeColor: Color {
        guard let grade = grade else { return .gray }
        
        // For circuit grades, use the circuit's color
        if gradeSystem == .circuit, let circuit = customCircuit {
            return CircuitGrade(customCircuit: circuit).colors(for: grade).first ?? .gray
        }
        
        return GradeSystemFactory.safeProtocol(for: gradeSystem).colorMap[grade] ?? .gray
    }
    
    var gradeIndex: Int {
        guard let grade = grade else { return 0 }
        
        // For circuit grades, use the circuit's grades array
        if gradeSystem == .circuit, let circuit = customCircuit {
            return CircuitGrade(customCircuit: circuit).gradeIndex(for: grade)
        }
        
        return GradeSystemFactory.safeProtocol(for: gradeSystem).gradeIndex(for: grade)
    }
    
    /// Get the circuit color mapping for this route (circuit grades only)
    var circuitMapping: CircuitColorMapping? {
        guard gradeSystem == .circuit,
              let circuit = customCircuit,
              let grade = grade else { return nil }
        return circuit.mapping(forGrade: grade)
    }
    
    /// Get the equivalent grade range description for circuit grades
    var circuitGradeRange: String? {
        circuitMapping?.gradeRangeDescription
    }
    
    /// Get the color name for circuit grades
    var circuitColorName: String? {
        circuitMapping?.displayName
    }
    
    // MARK: - Date Properties
    
    var firstAttemptDate: Date? {
        attempts.min(by: { $0.date < $1.date })?.date
    }
    
    var lastAttemptDate: Date? {
        attempts.max(by: { $0.date < $1.date })?.date
    }
    
    var attemptDateRange: ClosedRange<Date> {
        guard let first = firstAttemptDate, let last = lastAttemptDate else {
            let now = Date()
            return now...now
        }
        return first...last
    }
    
    // MARK: - Status & Relationships
    
    var status: RouteStatus = RouteStatus.inactive

    @Relationship(deleteRule: .cascade, inverse: \RouteAttempt.route)
    var attempts: [RouteAttempt] = []
    
    var session: Session?

    // Route timer state (for persistence across navigation)
    var routeStartElapsed: TimeInterval?
    var lastAttemptElapsed: TimeInterval?
    var totalRestTime: TimeInterval = 0

    // Route characteristics (for categorization and filtering)
    var wallAngles: [WallAngle] = []
    var holdTypes: [HoldType] = []
    var movementStyles: [MovementStyle] = []
    var experiences: [ClimbExperience] = []

    // MARK: - Initializers
    
    public init(gradeSystem: GradeSystem) {
        self.id = UUID()
        self.gradeSystem = gradeSystem
    }
    
    public init(gradeSystem: GradeSystem, attempts: [RouteAttempt] = []) {
        self.id = UUID()
        self.gradeSystem = gradeSystem
        self.attempts = attempts
    }
    
    public init(gradeSystem: GradeSystem, grade: String, attempts: [RouteAttempt] = []) {
        self.id = UUID()
        self.gradeSystem = gradeSystem
        self.attempts = attempts
        self.grade = grade
    }
    
    public init(gradeSystem: GradeSystem, grade: String, attempts: [RouteAttempt] = [], session: Session) {
        self.id = UUID()
        self.gradeSystem = gradeSystem
        self.attempts = attempts
        self.grade = grade
        self.session = session
    }
    
    public init(gradeSystem: GradeSystem, grade: String) {
        self.id = UUID()
        self.gradeSystem = gradeSystem
        self.grade = grade
    }
    
    /// Create a circuit route with proper circuit reference
    public init(circuit: CustomCircuitGrade, grade: String, session: Session? = nil) {
        self.id = UUID()
        self.gradeSystem = .circuit
        self.grade = grade
        self.customCircuit = circuit
        self.customCircuitId = circuit.id
        self.session = session
    }
    
    // MARK: - Grade Protocol Helper
    
    /// Get appropriate grade protocol, using circuit if available
    func gradeProtocol(modelContext: ModelContext) -> any GradeProtocol {
        switch gradeSystem {
        case .circuit:
            // Try to use stored circuit
            if let circuit = customCircuit {
                return CircuitGrade(customCircuit: circuit)
            }
            // Try to fetch by ID
            if let circuitId = customCircuitId,
               let circuit = GradeSystemFactory.circuit(forId: circuitId, modelContext: modelContext) {
                return CircuitGrade(customCircuit: circuit)
            }
            // Fallback to default circuit
            return CircuitGrade(customCircuit: GradeSystemFactory.defaultCircuit(modelContext))
        default:
            return GradeSystemFactory.safeProtocol(for: gradeSystem)
        }
    }
    
    /// Set circuit for this route (use when grade system is circuit)
    func setCircuit(_ circuit: CustomCircuitGrade) {
        self.customCircuit = circuit
        self.customCircuitId = circuit.id
    }
}

extension Route {
    var actionCounts: [ClimbStatus: Int] {
        var counts: [ClimbStatus: Int] = [:]
        
        for attempt in attempts {
            counts[attempt.status, default: 0] += 1
        }
        
        return counts
    }
    
    func addAttempt(status: ClimbStatus) {
        attempts.append(RouteAttempt(status: status))
    }
}
