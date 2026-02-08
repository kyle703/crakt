//
//  DifficultyRatingView.swift
//  crakt
//
//  Created by Kyle Thompson on 1/27/25.
//

import SwiftUI
import SwiftData

struct DifficultyRatingView: View {
    let route: Route
    let attempt: RouteAttempt
    let onSave: (DifficultyRating?, [ClimbExperience]) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var selectedRating: DifficultyRating?
    @State private var selectedExperiences: [ClimbExperience] = []
    
    // Track original values to restore on cancel
    @State private var originalRating: DifficultyRating?
    @State private var originalExperiences: [ClimbExperience] = []
    @State private var wasCancelled = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Title
                    Text("Route Experience")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .padding(.top)
                    
                    Text("How did this route feel?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    // Rating buttons
                    HStack(spacing: 20) {
                        ForEach(DifficultyRating.allCases, id: \.self) { rating in
                            Button(action: {
                                selectedRating = rating
                            }) {
                                VStack(spacing: 8) {
                                    Image(systemName: rating.iconName)
                                        .font(.title)
                                        .foregroundColor(selectedRating == rating ? rating.color : .gray)

                                    Text(rating.rawValue)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(selectedRating == rating ? rating.color : .secondary)
                                }
                                .frame(width: 80, height: 80)
                                .background(
                                    Circle()
                                        .fill(selectedRating == rating ? rating.color.opacity(0.1) : Color(.systemBackground))
                                        .overlay(
                                            Circle()
                                                .stroke(selectedRating == rating ? rating.color : Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                        }
                    }
                    .padding(.vertical, 8)

                    // Experience tags section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Experience Tags")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            ForEach(ClimbExperience.allCases, id: \.self) { experience in
                                Button(action: {
                                    if selectedExperiences.contains(experience) {
                                        selectedExperiences.removeAll { $0 == experience }
                                    } else {
                                        selectedExperiences.append(experience)
                                    }
                                }) {
                                    VStack(spacing: 4) {
                                        Image(systemName: experience.iconName)
                                            .font(.title3)
                                            .foregroundColor(selectedExperiences.contains(experience) ? experience.color : .gray)

                                        Text(experience.description)
                                            .font(.caption2)
                                            .foregroundColor(selectedExperiences.contains(experience) ? experience.color : .secondary)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 60)
                                    .padding(8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedExperiences.contains(experience) ? experience.color.opacity(0.1) : Color(.systemBackground))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(selectedExperiences.contains(experience) ? experience.color : Color.gray.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        // Mark as cancelled and restore original values
                        wasCancelled = true
                        selectedRating = originalRating
                        selectedExperiences = originalExperiences
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Store original values when sheet opens
                originalRating = attempt.difficultyRating
                originalExperiences = route.experiences
                // Initialize with current values
                selectedRating = attempt.difficultyRating
                selectedExperiences = route.experiences
            }
            .onDisappear {
                // Save changes when dismissed by swipe-down (not cancel)
                if !wasCancelled {
                    onSave(selectedRating, selectedExperiences)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    DifficultyRatingView(
        route: Route(gradeSystem: .vscale, grade: "V4"),
        attempt: RouteAttempt(status: .send),
        onSave: { _, _ in }
    )
}
