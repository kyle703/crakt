//
//  GymGradeConfigurationView.swift
//  crakt
//
//  Configure grade systems for a specific gym
//

import SwiftUI
import SwiftData

struct GymGradeConfigurationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let gymId: UUID
    let gymName: String
    let countryCode: String?
    
    @Query private var circuits: [CustomCircuitGrade]
    
    @State private var boulderSystem: GradeSystem = .vscale
    @State private var ropeSystem: GradeSystem = .yds
    @State private var selectedCircuit: CustomCircuitGrade?
    @State private var showCircuitBuilder = false
    @State private var isLoading = true
    
    init(gymId: UUID, gymName: String, countryCode: String?) {
        self.gymId = gymId
        self.gymName = gymName
        self.countryCode = countryCode
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Boulder Grade System
                Section {
                    Picker("Grade System", selection: $boulderSystem) {
                        ForEach([GradeSystem.circuit, .vscale, .font], id: \.self) { system in
                            Text(system.description).tag(system)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    // Show circuit selector if circuit is selected
                    if boulderSystem == .circuit {
                        circuitSelector
                    }
                } header: {
                    Label("Boulder Grades", systemImage: "mountain.2.fill")
                } footer: {
                    Text(boulderSystemFooter)
                }
                
                // Rope Grade System
                Section {
                    Picker("Grade System", selection: $ropeSystem) {
                        ForEach([GradeSystem.yds, .french], id: \.self) { system in
                            Text(system.description).tag(system)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Label("Rope Grades", systemImage: "figure.climbing")
                } footer: {
                    Text(ropeSystemFooter)
                }
                
                // Regional Info
                Section {
                    HStack {
                        Text("Region")
                        Spacer()
                        Text(GymRegion.from(countryCode: countryCode).rawValue)
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Reset to Regional Defaults") {
                        resetToRegionalDefaults()
                    }
                    .foregroundColor(.orange)
                } header: {
                    Label("Regional Settings", systemImage: "globe")
                }
            }
            .navigationTitle("Grade Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveConfiguration()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                loadConfiguration()
            }
            .sheet(isPresented: $showCircuitBuilder) {
                CircuitGradeBuilderView(existingCircuit: nil)
            }
        }
    }
    
    // MARK: - Circuit Selector
    
    @ViewBuilder
    private var circuitSelector: some View {
        if circuits.isEmpty {
            Button {
                showCircuitBuilder = true
            } label: {
                Label("Create Circuit", systemImage: "plus.circle.fill")
            }
        } else {
            // Circuit picker
            Picker("Circuit", selection: $selectedCircuit) {
                Text("Select a circuit").tag(nil as CustomCircuitGrade?)
                ForEach(circuits) { circuit in
                    HStack {
                        // Color preview
                        HStack(spacing: 2) {
                            ForEach(circuit.orderedMappings.prefix(5)) { mapping in
                                Circle()
                                    .fill(mapping.swiftUIColor)
                                    .frame(width: 12, height: 12)
                            }
                        }
                        Text(circuit.name)
                    }
                    .tag(circuit as CustomCircuitGrade?)
                }
            }
            
            // Show selected circuit preview
            if let circuit = selectedCircuit {
                CircuitPreviewRow(circuit: circuit)
            }
            
            // Create new circuit button
            Button {
                showCircuitBuilder = true
            } label: {
                Label("Create New Circuit", systemImage: "plus.circle")
                    .font(.subheadline)
            }
        }
    }
    
    // MARK: - Footer Text
    
    private var boulderSystemFooter: String {
        switch boulderSystem {
        case .circuit:
            return "Circuit grades use gym-specific color mappings. Each color represents a difficulty range."
        case .vscale:
            return "V-Scale (V0-V17) is the standard US bouldering system."
        case .font:
            return "Fontainebleau (1-8c+) is the European bouldering standard."
        default:
            return ""
        }
    }
    
    private var ropeSystemFooter: String {
        switch ropeSystem {
        case .yds:
            return "Yosemite Decimal System (5.0-5.15d) is standard in North America."
        case .french:
            return "French grades (1-9c) are standard in Europe and many other regions."
        default:
            return ""
        }
    }
    
    // MARK: - Data Management
    
    private func loadConfiguration() {
        // Try to fetch existing configuration
        let descriptor = FetchDescriptor<GymGradeConfiguration>(
            predicate: #Predicate { $0.gymId == gymId }
        )
        
        if let config = try? modelContext.fetch(descriptor).first {
            boulderSystem = config.boulderGradeSystem
            ropeSystem = config.ropeGradeSystem
            selectedCircuit = config.boulderCircuit
        } else {
            // Use regional defaults
            let region = GymRegion.from(countryCode: countryCode)
            boulderSystem = region.defaultBoulderSystem
            ropeSystem = region.defaultRopeSystem
            
            // Select default circuit if available
            if boulderSystem == .circuit {
                selectedCircuit = circuits.first(where: { $0.isDefault })
            }
        }
        
        isLoading = false
    }
    
    private func saveConfiguration() {
        // Find or create configuration
        let descriptor = FetchDescriptor<GymGradeConfiguration>(
            predicate: #Predicate { $0.gymId == gymId }
        )
        
        let config: GymGradeConfiguration
        if let existing = try? modelContext.fetch(descriptor).first {
            config = existing
        } else {
            config = GymGradeConfiguration(gymId: gymId)
            modelContext.insert(config)
        }
        
        // Update configuration
        config.setBoulderSystem(boulderSystem, circuit: selectedCircuit)
        config.setRopeSystem(ropeSystem)
        
        // Save
        do {
            try modelContext.save()
        } catch {
            print("❌ Failed to save gym grade configuration: \(error)")
        }
    }
    
    private func resetToRegionalDefaults() {
        let region = GymRegion.from(countryCode: countryCode)
        boulderSystem = region.defaultBoulderSystem
        ropeSystem = region.defaultRopeSystem
        
        if boulderSystem == .circuit {
            selectedCircuit = circuits.first(where: { $0.isDefault })
        } else {
            selectedCircuit = nil
        }
    }
}

// MARK: - Circuit Preview Row

struct CircuitPreviewRow: View {
    let circuit: CustomCircuitGrade
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Color bar preview
            HStack(spacing: 4) {
                ForEach(circuit.orderedMappings) { mapping in
                    VStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(mapping.swiftUIColor)
                            .frame(height: 24)
                        
                        Text(mapping.gradeRangeDescription)
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    GymGradeConfigurationView(
        gymId: UUID(),
        gymName: "Pacific Edge",
        countryCode: "US"
    )
    .modelContainer(for: [CustomCircuitGrade.self, CircuitColorMapping.self, GymGradeConfiguration.self])
}

