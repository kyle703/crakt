//
//  RoutePickerView.swift
//  crakt
//
//  Created by Kyle Thompson on 1/25/25.
//

import SwiftUI

struct RoutePickerView: View {
    let gradeSystem: GradeSystem
    @Binding var selectedGrade: String?
    let onRouteSelected: (String) -> Void
    let onDismiss: () -> Void

    @State private var searchText = ""
    @State private var availableGrades: [String] = []

    private var filteredGrades: [String] {
        if searchText.isEmpty {
            return availableGrades
        } else {
            return availableGrades.filter { grade in
                grade.localizedCaseInsensitiveContains(searchText) ||
                (gradeSystem._protocol.description(for: grade)?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Grade rail at top
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(availableGrades, id: \.self) { grade in
                            let isSelected = selectedGrade == grade

                            Text(gradeSystem._protocol.description(for: grade) ?? grade)
                                .font(.system(size: isSelected ? 18 : 16, weight: isSelected ? .bold : .medium))
                                .foregroundColor(isSelected ? .white : gradeSystem._protocol.colors(for: grade).first ?? .primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(isSelected ? (gradeSystem._protocol.colors(for: grade).first ?? .blue) : Color.gray.opacity(0.2))
                                )
                                .onTapGesture {
                                    selectedGrade = grade
                                    HapticManager.shared.playAttempt()
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(Color.gray.opacity(0.1))

                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search grades...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.gray.opacity(0.2)),
                    alignment: .bottom
                )

                // Grades list
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80, maximum: 120))], spacing: 16) {
                        ForEach(filteredGrades, id: \.self) { grade in
                            let isSelected = selectedGrade == grade

                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(gradeSystem._protocol.colors(for: grade).first ?? .gray)
                                        .frame(width: 60, height: 60)
                                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)

                                    Text(gradeSystem._protocol.description(for: grade) ?? grade)
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                }

                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.title2)
                                }
                            }
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedGrade = grade
                                HapticManager.shared.playSuccess()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    onRouteSelected(grade)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Select Route")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Cancel") {
                onDismiss()
            })
            .onAppear {
                availableGrades = gradeSystem._protocol.grades
            }
        }
    }
}

#Preview {
    RoutePickerPreview()
}

struct RoutePickerPreview: View {
    @State var selectedGrade: String? = "5.10a"

    var body: some View {
        RoutePickerView(
            gradeSystem: .yds,
            selectedGrade: $selectedGrade
        ) { grade in
            print("Selected route grade: \(grade)")
        } onDismiss: {
            print("Route picker dismissed")
        }
    }
}
