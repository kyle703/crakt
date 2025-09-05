//
//  WorkoutSummaryCard.swift
//  crakt
//
//  Created by Kyle Thompson on 12/18/24.
//

import SwiftUI

struct WorkoutSummaryCard: View {
    let workout: Workout

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(workout.type.shortDescription)
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                Text(workout.metrics.sendRate.formatted(.percent.precision(.fractionLength(0))))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                        .cornerRadius(3)

                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * workout.completionPercentage, height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)

            // Metrics
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Completed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(workout.completedReps)/\(workout.totalReps)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Duration")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(workout.metrics.totalDuration.map { Duration.seconds($0).formatted(.units(allowed: [.minutes, .seconds], width: .abbreviated)) } ?? "N/A")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Hardest")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(workout.metrics.hardestGradeAttempted ?? "N/A")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }

            // Average rest time (if available)
            if let avgRestTime = workout.metrics.averageRestTime {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Avg rest: \(Duration.seconds(avgRestTime).formatted(.units(allowed: [.minutes, .seconds], width: .abbreviated)))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    WorkoutSummaryCard_Preview()
        .padding()
        .background(Color.gray.opacity(0.1))
}

private struct WorkoutSummaryCard_Preview: View {
    var body: some View {
        let workout = Workout(session: Session(user: User()), type: .intervals)
        workout.status = WorkoutStatus.completed
        workout.endedAt = Date().addingTimeInterval(1800) // 30 minutes

        return WorkoutSummaryCard(workout: workout)
    }
}
