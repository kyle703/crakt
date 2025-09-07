//
//  GradeScrubberView.swift
//  crakt
//
//  Created by Kyle Thompson on 1/25/25.
//

import SwiftUI

struct GradeScrubberView: View {
    let gradeSystem: GradeSystem
    @Binding var selectedGrade: String?
    let onGradeSelected: (String) -> Void

    @State private var dragOffset: CGFloat = 0
    @State private var lastHapticGradeIndex: Int = -1

    private var availableGrades: [String] {
        gradeSystem._protocol.grades
    }

    private var currentGradeIndex: Int {
        guard let selectedGrade = selectedGrade,
              let index = availableGrades.firstIndex(of: selectedGrade) else {
            return 0
        }
        return index
    }

    private var scrubberWidth: CGFloat {
        let gradeCount = availableGrades.count
        return CGFloat(gradeCount) * 60 + 200 // Extra space for centering
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header
            Text("Select Grade")
                .font(.headline)
                .foregroundColor(.primary)

            // Grade display
            if let selectedGrade = selectedGrade {
                Text(gradeSystem._protocol.description(for: selectedGrade) ?? selectedGrade)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(gradeSystem._protocol.colors(for: selectedGrade).first ?? .gray)
                    .padding(.vertical, 8)
            }

            // Horizontal scrubber
            ZStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        // Left padding
                        Color.clear.frame(width: 100)

                        ForEach(availableGrades.indices, id: \.self) { index in
                            let grade = availableGrades[index]
                            let isSelected = selectedGrade == grade

                            VStack(spacing: 8) {
                                // Grade chip
                                Text(gradeSystem._protocol.description(for: grade) ?? grade)
                                    .font(.system(size: isSelected ? 24 : 18, weight: isSelected ? .bold : .medium))
                                    .foregroundColor(isSelected ? .white : .primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(isSelected ? (gradeSystem._protocol.colors(for: grade).first ?? .gray) : Color.gray.opacity(0.2))
                                    )
                                    .frame(width: 60)

                                // Selection indicator
                                if isSelected {
                                    Circle()
                                        .fill(gradeSystem._protocol.colors(for: grade).first ?? .gray)
                                        .frame(width: 8, height: 8)
                                } else {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 6, height: 6)
                                }
                            }
                        }

                        // Right padding
                        Color.clear.frame(width: 100)
                    }
                    .frame(width: scrubberWidth)
                }
                .frame(height: 80)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation.width
                            updateSelectedGradeFromDrag()
                        }
                        .onEnded { _ in
                            // Snap to nearest grade
                            snapToNearestGrade()
                            dragOffset = 0
                        }
                )
            }
            .frame(height: 80)

            // Instructions
            Text("Drag horizontally to change grade")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 10)
        .onAppear {
            lastHapticGradeIndex = currentGradeIndex
        }
    }

    private func updateSelectedGradeFromDrag() {
        let totalWidth = scrubberWidth - 200 // Account for padding
        let gradeWidth = totalWidth / CGFloat(availableGrades.count)
        let draggedIndex = Int((dragOffset / gradeWidth).rounded())

        let newIndex = max(0, min(availableGrades.count - 1, currentGradeIndex + draggedIndex))

        if newIndex != lastHapticGradeIndex {
            // Play haptic feedback for grade change
            HapticManager.shared.playAttempt()
            lastHapticGradeIndex = newIndex
        }

        let newGrade = availableGrades[newIndex]
        selectedGrade = newGrade
    }

    private func snapToNearestGrade() {
        // The grade is already updated during drag, just trigger the callback
        if let selectedGrade = selectedGrade {
            onGradeSelected(selectedGrade)
            // Success haptic for final selection
            HapticManager.shared.playSuccess()
        }
    }
}

#Preview {
    GradeScrubberPreview()
}

struct GradeScrubberPreview: View {
    @State var selectedGrade: String? = "5.10a"

    var body: some View {
        GradeScrubberView(
            gradeSystem: .yds,
            selectedGrade: $selectedGrade
        ) { grade in
            print("Selected grade: \(grade)")
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}
