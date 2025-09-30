//
//  CompactGradeSelector.swift
//  crakt
//
//  Created by Kyle Thompson on 1/25/25.
//

import SwiftUI
import SwiftData

struct CompactGradeSelector: View {
    var gradeSystem: any GradeProtocol
    @Binding var selectedGrade: String?
    var isLocked: Bool = false

    @State private var isExpanded = false
    @State private var showLockedAlert = false
    @State private var wiggleTrigger = false

    var body: some View {
        // Fixed height container to prevent layout shifts
        ZStack {
            if !isExpanded {
                // Compact view - centered in fixed height container
                ZStack {
                    Button(action: {
                        if isLocked {
                            // Trigger wiggle animation
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.3)) {
                                wiggleTrigger.toggle()
                            }
                        } else {
                            withAnimation(.spring()) {
                                isExpanded = true
                            }
                        }
                    }) {
                        ZStack {
                            if let selectedGrade = selectedGrade {
                                let colors = gradeSystem.colors(for: selectedGrade)
                                if colors.count == 1 {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(colors.first!)
                                        .frame(width: 60, height: 60)
                                } else if colors.count == 2 {
                                    LinearGradient(gradient: Gradient(colors: colors), startPoint: .leading, endPoint: .trailing)
                                        .frame(width: 60, height: 60)
                                        .cornerRadius(10)
                                } else {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.gray)
                                        .frame(width: 60, height: 60)
                                }
                            } else {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 60, height: 60)
                            }

                            Text(gradeSystem.description(for: selectedGrade ?? "") ?? "Select")
                                .foregroundColor(.white)
                                .font(.system(size: 14, weight: .bold))

                            // Opacity overlay when locked
                            if isLocked {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.black.opacity(0.4))
                                    .frame(width: 60, height: 60)
                            }
                        }
                    }
                    .gesture(
                        LongPressGesture(minimumDuration: 0.5)
                            .onEnded { _ in
                                if !isLocked {
                                    withAnimation(.spring()) {
                                        isExpanded = true
                                    }
                                }
                            }
                    )
                    .gesture(
                        TapGesture(count: 2)
                            .onEnded { _ in
                                if isLocked {
                                    showLockedAlert = true
                                }
                            }
                    )
                    .modifier(WiggleModifier(trigger: wiggleTrigger))
                }
            } else {
                // Expanded view - fills the fixed height container
                ZStack {
                    // Background tap to dismiss
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring()) {
                                isExpanded = false
                            }
                        }

                    // Full grade selector
                    ClimbingGradeSelector(
                        gradeSystem: AnyGradeProtocol(gradeSystem),
                        selectedGrade: $selectedGrade
                    )
                }
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
            }
        }
        .frame(height: 80) // Fixed height to match ClimbingGradeSelector
        .alert("Grade is Locked", isPresented: $showLockedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("This grade is locked because the route has attempts. Move to a new route to change the grade.")
        }
    }
}

// Wiggle animation modifier
struct WiggleModifier: ViewModifier {
    let trigger: Bool

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(trigger ? 2 : 0))
            .animation(.spring(response: 0.3, dampingFraction: 0.3), value: trigger)
    }
}

// Helper Views for Preview
struct ClimbTypeSelectorView: View {
    @Binding var selectedClimbType: ClimbType
    @Binding var selectedGradeSystem: GradeSystem
    @Binding var selectedGrade: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Climb Type")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                    ForEach(ClimbType.allCases, id: \.self) { climbType in
                        Button(action: {
                            // Convert current grade if we have one using DI system
                            if let currentGrade = selectedGrade {
                                // Switch to appropriate grade system for new climb type
                                let newGradeSystem: GradeSystem

                                switch climbType {
                                case .boulder:
                                    newGradeSystem = .vscale
                                case .toprope, .lead:
                                    newGradeSystem = .yds
                                }

                                let convertedGrade = DifficultyIndex.convertGrade(
                                    fromGrade: currentGrade,
                                    fromSystem: selectedGradeSystem,
                                    fromType: selectedClimbType,
                                    toSystem: newGradeSystem,
                                    toType: climbType
                                )

                                selectedClimbType = climbType
                                selectedGradeSystem = newGradeSystem
                                if let convertedGrade = convertedGrade {
                                    selectedGrade = convertedGrade
                                    print("🔄 Preview DI Converted \(currentGrade) to \(convertedGrade) when switching to \(climbType.description)")
                                } else {
                                    // If conversion fails, keep the original grade
                                    print("⚠️ Could not convert \(currentGrade) when switching to \(climbType.description), keeping original")
                                }
                            } else {
                                selectedClimbType = climbType
                                // Auto-select appropriate grade system for climb type
                                switch climbType {
                                case .boulder:
                                    selectedGradeSystem = .vscale
                                    selectedGrade = "V3"
                                case .toprope, .lead:
                                    selectedGradeSystem = .yds
                                    selectedGrade = "5.8"
                                }
                            }
                        }) {
                        Text(climbType.description)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                selectedClimbType == climbType ?
                                Color.blue : Color.gray.opacity(0.2)
                            )
                            .foregroundColor(
                                selectedClimbType == climbType ?
                                .white : .primary
                            )
                            .cornerRadius(8)
                    }
                }
            }
        }
    }
}

struct GradeSystemSelectorView: View {
    let selectedClimbType: ClimbType
    @Binding var selectedGradeSystem: GradeSystem
    @Binding var selectedGrade: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Grade System")
                .font(.subheadline)
                .foregroundColor(.secondary)

            let availableSystems = selectedClimbType == .boulder ?
                [GradeSystem.vscale, .font, .circuit] :
                [GradeSystem.yds, .french]

                HStack(spacing: 12) {
                    ForEach(availableSystems, id: \.self) { gradeSystem in
                        Button(action: {
                            // Convert current grade to new system using DI if we have one
                            if let currentGrade = selectedGrade {
                                let convertedGrade = DifficultyIndex.convertGrade(
                                    fromGrade: currentGrade,
                                    fromSystem: selectedGradeSystem,
                                    fromType: selectedClimbType,
                                    toSystem: gradeSystem,
                                    toType: selectedClimbType
                                )

                                selectedGradeSystem = gradeSystem
                                if let convertedGrade = convertedGrade {
                                    selectedGrade = convertedGrade
                                    print("🔄 Preview DI Converted \(currentGrade) from \(selectedGradeSystem.description) to \(convertedGrade) in \(gradeSystem.description)")
                                } else {
                                    // If conversion fails, keep the original grade
                                    print("⚠️ Could not convert \(currentGrade) from \(selectedGradeSystem.description) to \(gradeSystem.description), keeping original")
                                }
                            } else {
                                selectedGradeSystem = gradeSystem
                            }
                        }) {
                        Text(gradeSystem.description)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                selectedGradeSystem == gradeSystem ?
                                Color.orange : Color.gray.opacity(0.2)
                            )
                            .foregroundColor(
                                selectedGradeSystem == gradeSystem ?
                                .white : .primary
                            )
                            .cornerRadius(8)
                    }
                }
            }
        }
    }
}

struct CurrentSelectionView: View {
    let selectedClimbType: ClimbType
    let selectedGradeSystem: GradeSystem
    let selectedGrade: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Current Selection")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack {
                Text("\(selectedClimbType.description) • \(selectedGradeSystem.description)")
                    .font(.caption)
                    .foregroundColor(.primary)

                if let grade = selectedGrade {
                    Text("• Grade: \(grade)")
                        .font(.caption)
                        .foregroundColor(.blue)

                    if let di = DifficultyIndex.normalizeToDI(grade: grade, system: selectedGradeSystem, climbType: selectedClimbType) {
                        Text("• DI: \(di)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Debug: Show cross-system conversions
            if let grade = selectedGrade {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Conversions:")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    let systems = selectedClimbType == .boulder ?
                        [GradeSystem.vscale, .font] :
                        [GradeSystem.yds, .french]

                    ForEach(systems.filter { $0 != selectedGradeSystem }, id: \.self) { system in
                        if let converted = DifficultyIndex.convertGrade(
                            fromGrade: grade,
                            fromSystem: selectedGradeSystem,
                            fromType: selectedClimbType,
                            toSystem: system,
                            toType: selectedClimbType
                        ) {
                            Text("→ \(system.description): \(converted)")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
    }
}

// Preview Helper
struct CompactGradeSelectorPreview: View {
    @State private var selectedClimbType: ClimbType = .boulder
    @State private var selectedGradeSystem: GradeSystem = .vscale
    @State private var selectedGrade: String? = "V3"

    var gradeSystem: any GradeProtocol {
        GradeSystems.systems[selectedGradeSystem]!
    }

    var body: some View {
        VStack(spacing: 20) {
            // Controls
            VStack(spacing: 16) {
                ClimbTypeSelectorView(
                    selectedClimbType: $selectedClimbType,
                    selectedGradeSystem: $selectedGradeSystem,
                    selectedGrade: $selectedGrade
                )

                GradeSystemSelectorView(
                    selectedClimbType: selectedClimbType,
                    selectedGradeSystem: $selectedGradeSystem,
                    selectedGrade: $selectedGrade
                )

                CurrentSelectionView(
                    selectedClimbType: selectedClimbType,
                    selectedGradeSystem: selectedGradeSystem,
                    selectedGrade: selectedGrade
                )
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)

            // Compact Grade Selector
            CompactGradeSelector(
                gradeSystem: gradeSystem,
                selectedGrade: $selectedGrade
            )
            .padding(.horizontal)

            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}

// Preview
#Preview {
    CompactGradeSelectorPreview()
}
