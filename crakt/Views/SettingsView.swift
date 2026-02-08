//
//  SettingsView.swift
//  crakt
//
//  Created by Kyle Thompson on 1/14/26.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @Query private var circuits: [CustomCircuitGrade]
    
    var body: some View {
        NavigationView {
            List {
                if let user = users.first {
                    // 1) Default Climb Preferences
                    DefaultPreferencesSection(user: user, circuits: circuits)
                    
                    // 2) Circuit Grade Builder
                    CircuitGradeManagerSection(circuits: circuits)
                    
                    // 3) Developer Settings
                    DeveloperSettingsSection()
                } else {
                    Text("No user found.")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Default Preferences Section

struct DefaultPreferencesSection: View {
    @Bindable var user: User
    let circuits: [CustomCircuitGrade]
    
    var body: some View {
        Section {
            // Climb Type
            HStack {
                Label("Climb Type", systemImage: "figure.climbing")
                Spacer()
                Picker("", selection: $user.climbType) {
                    ForEach(ClimbType.allCases, id: \.self) { type in
                        Text(type.description).tag(type)
                    }
                }
                .pickerStyle(.menu)
                .tint(.primary)
            }
            
            // Grade System
            HStack {
                Label("Grade System", systemImage: "number.circle")
                Spacer()
                Picker("", selection: $user.gradeSystem) {
                    ForEach(validGradeSystems, id: \.self) { system in
                        Text(system.description).tag(system)
                    }
                }
                .pickerStyle(.menu)
                .tint(.primary)
            }
            
            // If circuit is selected, show circuit picker
            if user.gradeSystem == .circuit {
                HStack {
                    Label("Default Circuit", systemImage: "circle.grid.3x3")
                    Spacer()
                    if let defaultCircuit = circuits.first(where: { $0.isDefault }) {
                        Text(defaultCircuit.name)
                            .foregroundColor(.secondary)
                    } else {
                        Text("None")
                            .foregroundColor(.secondary)
                    }
                }
            }
        } header: {
            Text("Default Preferences")
        } footer: {
            Text("These settings are used when starting new sessions.")
        }
    }
    
    private var validGradeSystems: [GradeSystem] {
        switch user.climbType {
        case .boulder:
            return [.circuit, .vscale, .font]
        case .toprope, .lead:
            return [.yds, .french]
        }
    }
}

// MARK: - Circuit Grade Manager Section

struct CircuitGradeManagerSection: View {
    let circuits: [CustomCircuitGrade]
    @State private var showingBuilder = false
    @State private var editingCircuit: CustomCircuitGrade?
    
    var body: some View {
        Section {
            // List existing circuits
            ForEach(circuits) { circuit in
                CircuitRowView(circuit: circuit)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editingCircuit = circuit
                        showingBuilder = true
                    }
            }
            
            // Add new circuit button
            Button {
                editingCircuit = nil
                showingBuilder = true
            } label: {
                Label("Create New Circuit", systemImage: "plus.circle.fill")
            }
        } header: {
            Text("Circuit Grades")
        } footer: {
            Text("Custom circuits map colors to grade ranges from standard systems like V-Scale or Font.")
        }
        .sheet(isPresented: $showingBuilder) {
            CircuitGradeBuilderView(existingCircuit: editingCircuit)
        }
    }
}

struct CircuitRowView: View {
    let circuit: CustomCircuitGrade
    
    var body: some View {
        HStack(spacing: 12) {
            // Color preview
            HStack(spacing: 2) {
                ForEach(circuit.orderedMappings.prefix(7)) { mapping in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(mapping.swiftUIColor)
                        .frame(width: 16, height: 24)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(circuit.name)
                        .fontWeight(.medium)
                    
                    if circuit.isDefault {
                        Text("Default")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }
                
                Text("\(circuit.colorCount) colors • \(circuit.orderedMappings.first?.baseGradeSystem.description ?? "V-Scale")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Circuit Grade Builder View

struct CircuitGradeBuilderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let existingCircuit: CustomCircuitGrade?
    
    @State private var name: String = ""
    @State private var baseSystem: GradeSystem = .vscale
    @State private var colorMappings: [EditableColorMapping] = []
    @State private var isDefault: Bool = false
    @State private var showingColorPicker = false
    @State private var editingMappingIndex: Int?
    
    private let availableColors: [(name: String, hex: String, color: Color)] = [
        ("Blue", "#007AFF", .blue),
        ("Green", "#34C759", .green),
        ("Yellow", "#FFCC00", .yellow),
        ("Orange", "#FF9500", .orange),
        ("Red", "#FF3B30", .red),
        ("Purple", "#AF52DE", .purple),
        ("Pink", "#FF2D55", .pink),
        ("Teal", "#00C7BE", .teal),
        ("Indigo", "#5856D6", .indigo),
        ("Brown", "#A2845E", .brown),
        ("Black", "#1C1C1E", Color(.systemGray)),
        ("White", "#F2F2F7", Color(.systemGray5)),
    ]
    
    init(existingCircuit: CustomCircuitGrade?) {
        self.existingCircuit = existingCircuit
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Basic Info
                Section("Circuit Info") {
                    TextField("Circuit Name", text: $name)
                    
                    Toggle("Set as Default", isOn: $isDefault)
                    
                    Picker("Base Grade System", selection: $baseSystem) {
                        Text("V-Scale").tag(GradeSystem.vscale)
                        Text("Font").tag(GradeSystem.font)
                    }
                }
                
                // Color Mappings
                Section {
                    ForEach(colorMappings.indices, id: \.self) { index in
                        ColorMappingRow(
                            mapping: $colorMappings[index],
                            baseSystem: baseSystem,
                            onDelete: { colorMappings.remove(at: index) }
                        )
                    }
                    .onMove { from, to in
                        colorMappings.move(fromOffsets: from, toOffset: to)
                    }
                    
                    Button {
                        addNewColor()
                    } label: {
                        Label("Add Color", systemImage: "plus.circle.fill")
                    }
                } header: {
                    Text("Color Mappings")
                } footer: {
                    Text("Colors are ordered from easiest (top) to hardest (bottom).")
                }
                
                // Delete button for existing circuits
                if existingCircuit != nil {
                    Section {
                        Button(role: .destructive) {
                            deleteCircuit()
                        } label: {
                            Label("Delete Circuit", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(existingCircuit == nil ? "New Circuit" : "Edit Circuit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveCircuit() }
                        .disabled(name.isEmpty || colorMappings.isEmpty)
                }
            }
            .onAppear {
                loadExistingCircuit()
            }
        }
    }
    
    private func loadExistingCircuit() {
        if let circuit = existingCircuit {
            name = circuit.name
            isDefault = circuit.isDefault
            baseSystem = circuit.orderedMappings.first?.baseGradeSystem ?? .vscale
            colorMappings = circuit.orderedMappings.map { mapping in
                EditableColorMapping(
                    id: mapping.id,
                    colorHex: mapping.color,
                    minGrade: mapping.minGrade,
                    maxGrade: mapping.maxGrade
                )
            }
        } else {
            // Default setup for new circuit
            name = "My Circuit"
            colorMappings = createDefaultMappings()
        }
    }
    
    private func createDefaultMappings() -> [EditableColorMapping] {
        let defaults: [(hex: String, min: String, max: String)] = [
            ("#007AFF", "B", "0"),
            ("#34C759", "1", "2"),
            ("#FFCC00", "3", "4"),
            ("#FF9500", "5", "6"),
            ("#FF3B30", "7", "8"),
            ("#AF52DE", "9", "10"),
            ("#1C1C1E", "11", "17"),
        ]
        
        return defaults.map { EditableColorMapping(colorHex: $0.hex, minGrade: $0.min, maxGrade: $0.max) }
    }
    
    private func addNewColor() {
        // Find a color not yet used
        let usedColors = Set(colorMappings.map { $0.colorHex.uppercased() })
        let availableColor = availableColors.first { !usedColors.contains($0.hex.uppercased()) }
        
        let proto = GradeSystemFactory.safeProtocol(for: baseSystem)
        let grades = proto.grades
        let lastMax = colorMappings.last?.maxGrade ?? grades.first ?? "0"
        let nextIndex = (grades.firstIndex(of: lastMax) ?? 0) + 1
        let nextGrade = nextIndex < grades.count ? grades[nextIndex] : lastMax
        
        colorMappings.append(EditableColorMapping(
            colorHex: availableColor?.hex ?? "#808080",
            minGrade: nextGrade,
            maxGrade: nextGrade
        ))
    }
    
    private func saveCircuit() {
        if let circuit = existingCircuit {
            // Update existing
            circuit.name = name
            
            // Remove old mappings
            for mapping in circuit.colorMappings {
                modelContext.delete(mapping)
            }
            circuit.colorMappings.removeAll()
            
            // Add new mappings
            for (index, editable) in colorMappings.enumerated() {
                let mapping = CircuitColorMapping(
                    color: editable.colorHex,
                    sortOrder: index,
                    baseGradeSystem: baseSystem,
                    minGrade: editable.minGrade,
                    maxGrade: editable.maxGrade
                )
                circuit.addMapping(mapping)
            }
            
            if isDefault {
                try? circuit.setAsDefault(in: modelContext)
            }
        } else {
            // Create new
            let circuit = CustomCircuitGrade(name: name, isDefault: isDefault)
            
            for (index, editable) in colorMappings.enumerated() {
                let mapping = CircuitColorMapping(
                    color: editable.colorHex,
                    sortOrder: index,
                    baseGradeSystem: baseSystem,
                    minGrade: editable.minGrade,
                    maxGrade: editable.maxGrade
                )
                circuit.addMapping(mapping)
            }
            
            modelContext.insert(circuit)
            
            if isDefault {
                try? circuit.setAsDefault(in: modelContext)
            }
        }
        
        try? modelContext.save()
        dismiss()
    }
    
    private func deleteCircuit() {
        if let circuit = existingCircuit {
            modelContext.delete(circuit)
            try? modelContext.save()
        }
        dismiss()
    }
}

// MARK: - Editable Color Mapping

struct EditableColorMapping: Identifiable {
    let id: UUID
    var colorHex: String
    var minGrade: String
    var maxGrade: String
    
    init(id: UUID = UUID(), colorHex: String, minGrade: String, maxGrade: String) {
        self.id = id
        self.colorHex = colorHex
        self.minGrade = minGrade
        self.maxGrade = maxGrade
    }
}

struct ColorMappingRow: View {
    @Binding var mapping: EditableColorMapping
    let baseSystem: GradeSystem
    let onDelete: () -> Void
    
    @State private var showingColorPicker = false
    
    private let availableColors: [(name: String, hex: String)] = [
        ("Blue", "#007AFF"),
        ("Green", "#34C759"),
        ("Yellow", "#FFCC00"),
        ("Orange", "#FF9500"),
        ("Red", "#FF3B30"),
        ("Purple", "#AF52DE"),
        ("Pink", "#FF2D55"),
        ("Teal", "#00C7BE"),
        ("Indigo", "#5856D6"),
        ("Brown", "#A2845E"),
        ("Black", "#1C1C1E"),
        ("Gray", "#8E8E93"),
    ]
    
    var body: some View {
        HStack(spacing: 12) {
            // Color swatch
            Button {
                showingColorPicker = true
            } label: {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(hex: mapping.colorHex))
                    .frame(width: 36, height: 36)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(Color.primary.opacity(0.2), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            
            // Grade range pickers
            VStack(alignment: .leading, spacing: 4) {
                Text(Color(hex: mapping.colorHex).colorName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 8) {
                    let proto = GradeSystemFactory.safeProtocol(for: baseSystem)
                    Picker("Min", selection: $mapping.minGrade) {
                        ForEach(proto.grades, id: \.self) { grade in
                            Text(proto.description(for: grade) ?? grade).tag(grade)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    
                    Text("to")
                        .foregroundColor(.secondary)
                    
                    Picker("Max", selection: $mapping.maxGrade) {
                        ForEach(proto.grades, id: \.self) { grade in
                            Text(proto.description(for: grade) ?? grade).tag(grade)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
            }
            
            Spacer()
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingColorPicker) {
            ColorPickerSheet(selectedHex: $mapping.colorHex, colors: availableColors)
        }
    }
}

struct ColorPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedHex: String
    let colors: [(name: String, hex: String)]
    
    let columns = [GridItem(.adaptive(minimum: 60))]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(colors, id: \.hex) { color in
                        Button {
                            selectedHex = color.hex
                            dismiss()
                        } label: {
                            VStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(hex: color.hex))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .strokeBorder(
                                                selectedHex.uppercased() == color.hex.uppercased() 
                                                    ? Color.blue : Color.clear,
                                                lineWidth: 3
                                            )
                                    )
                                
                                Text(color.name)
                                    .font(.caption2)
                                    .foregroundColor(.primary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Developer Settings Section

struct DeveloperSettingsSection: View {
    @Environment(\.modelContext) private var context
    
    var body: some View {
        Section("Developer") {
            Button(role: .destructive) {
                clearDatabase()
            } label: {
                Label("Clear All Data", systemImage: "trash")
            }
        }
    }
    
    private func clearDatabase() {
        Task {
            do {
                // Delete all data
                let users = try context.fetch(FetchDescriptor<User>())
                users.forEach { context.delete($0) }
                
                let sessions = try context.fetch(FetchDescriptor<Session>())
                sessions.forEach { context.delete($0) }
                
                let routes = try context.fetch(FetchDescriptor<Route>())
                routes.forEach { context.delete($0) }
                
                let attempts = try context.fetch(FetchDescriptor<RouteAttempt>())
                attempts.forEach { context.delete($0) }
                
                let circuits = try context.fetch(FetchDescriptor<CustomCircuitGrade>())
                circuits.forEach { context.delete($0) }
                
                let mappings = try context.fetch(FetchDescriptor<CircuitColorMapping>())
                mappings.forEach { context.delete($0) }
                
                try context.save()
                
                // Re-insert fresh user and default circuit
                let newUser = User()
                context.insert(newUser)
                
                _ = GradeSystemFactory.defaultCircuit(context)
                
                try context.save()
                print("Database cleared successfully.")
            } catch {
                print("Error clearing database: \(error)")
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [User.self, CustomCircuitGrade.self, CircuitColorMapping.self])
}
