//
//  CompactGradeSelector.swift
//  crakt
//
//  Created by Kyle Thompson on 1/25/25.
//

import SwiftUI

struct CompactGradeSelector: View {
    var gradeSystem: any GradeProtocol
    @Binding var selectedGrade: String?

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 16) {
            if !isExpanded {
                // Compact view
                Button(action: {
                    withAnimation(.spring()) {
                        isExpanded = true
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
                    }
                }
                .gesture(
                    LongPressGesture(minimumDuration: 0.5)
                        .onEnded { _ in
                            withAnimation(.spring()) {
                                isExpanded = true
                            }
                        }
                )
            } else {
                // Expanded view - takes full width of row
                VStack(spacing: 12) {
                    // Header with close button
                    HStack {
                        Text("Select Grade")
                            .font(.headline)
                        Spacer()
                        Button(action: {
                            withAnimation(.spring()) {
                                isExpanded = false
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }

                    // Full grade selector
                    VStack {
                        switch gradeSystem {
                        case let vGrade as VGrade:
                            ClimbingGradeSelector(
                                gradeSystem: vGrade,
                                selectedGrade: $selectedGrade
                            )
                            .frame(height: 80)
                        case let yds as YDS:
                            ClimbingGradeSelector(
                                gradeSystem: yds,
                                selectedGrade: $selectedGrade
                            )
                            .frame(height: 80)
                        case let fontGrade as FontGrade:
                            ClimbingGradeSelector(
                                gradeSystem: fontGrade,
                                selectedGrade: $selectedGrade
                            )
                            .frame(height: 80)
                        case let frenchGrade as FrenchGrade:
                            ClimbingGradeSelector(
                                gradeSystem: frenchGrade,
                                selectedGrade: $selectedGrade
                            )
                            .frame(height: 80)
                        default:
                            Text("Grade system not supported")
                                .foregroundColor(.secondary)
                                .frame(height: 80)
                        }
                    }
                }
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
            }
        }
    }
}

// Preview
#Preview {
    CompactGradeSelector(
        gradeSystem: VGrade() as any GradeProtocol,
        selectedGrade: .constant("V3")
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}
