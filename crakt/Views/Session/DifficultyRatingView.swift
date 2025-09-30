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
    let onRatingSelected: (DifficultyRating?) -> Void
    let onDismiss: () -> Void

    @State private var selectedRating: DifficultyRating?
    @State private var selectedExperiences: [ClimbExperience] = []

    var body: some View {
        ZStack {
            // Semi-transparent background with more opacity
            Color.black.opacity(0.8)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    // Dismiss without rating
                    onRatingSelected(nil)
                }

            // Rating card with more opacity
            VStack(spacing: 20) {
                // Title
                Text("Route Experience")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                // Rating buttons
                HStack(spacing: 20) {
                    ForEach(DifficultyRating.allCases, id: \.self) { rating in
                        Button(action: {
                            // Select rating but do not auto-dismiss
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
                                    .shadow(color: Color.black.opacity(0.1), radius: 4)
                            )
                        }
                    }
                }

                // Experience tags selection
                VStack(spacing: 8) {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 6) {
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
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedExperiences.contains(experience) ? experience.color.opacity(0.1) : Color(.systemBackground))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(selectedExperiences.contains(experience) ? experience.color : Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                        }
                    }
                }
                // Bottom primary action button (Skip/Done)
                let hasFeedback = (selectedRating != nil) || (!selectedExperiences.isEmpty)
                Button(action: {
                    if hasFeedback {
                        // Save experiences before completing
                        if !selectedExperiences.isEmpty {
                            route.experiences = selectedExperiences
                            do {
                                try route.modelContext?.save()
                            } catch {
                                print("Failed to save experiences: \(error)")
                            }
                        }
                        onRatingSelected(selectedRating)
                    } else {
                        // Easy skip
                        onRatingSelected(nil)
                    }
                }) {
                    Text(hasFeedback ? "Done" : "Skip")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(hasFeedback ? Color.blue : Color.gray.opacity(0.15))
                        .foregroundColor(hasFeedback ? .white : .blue)
                        .cornerRadius(12)
                }
                .accessibilityLabel(hasFeedback ? "Complete survey" : "Skip survey")
            }
            .padding(20)
            .background(Color(.systemBackground).opacity(0.95))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.3), radius: 16, x: 0, y: 8)
            .frame(maxWidth: 300)
            .padding(.horizontal, 20)
        }
    }

}

#Preview {
    DifficultyRatingView(
        route: Route(gradeSystem: .vscale, grade: "V4"),
        attempt: RouteAttempt(status: .send),
        onRatingSelected: { _ in },
        onDismiss: { }
    )
}
