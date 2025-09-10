//
//  WorkoutSummaryCard.swift
//  crakt
//
//  Created by Kyle Thompson on 12/18/24.
//  Enhanced for climbing coach analytics and performance insights

import SwiftUI
import SwiftData

struct WorkoutSummaryCard: View {
    let workout: Workout

    // MARK: - Computed Properties
    private var workoutIntensityColor: Color {
        switch workout.type.intensity {
        case .easy: return .green
        case .moderate: return .blue
        case .hard: return .orange
        case .limit: return .red
        case .progressive: return .purple
        }
    }

    private var completionColor: Color {
        let percentage = workout.completionPercentage
        if percentage >= 1.0 { return .green }
        else if percentage >= 0.8 { return .blue }
        else if percentage >= 0.5 { return .orange }
        else { return .red }
    }

    private var sendRateColor: Color {
        let rate = workout.metrics.sendRate
        if rate >= 0.8 { return .green }
        else if rate >= 0.6 { return .blue }
        else if rate >= 0.4 { return .orange }
        else { return .red }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Enhanced Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Image(systemName: workout.type.icon)
                            .foregroundColor(workoutIntensityColor)
                            .font(.title3)

                        Text(workout.type.shortDescription)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }

                    Text(workout.type.intensity.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(workoutIntensityColor.opacity(0.1))
                        .cornerRadius(4)
                }

                Spacer()

                // Status indicator
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(workout.isCompleted ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                        Text(workout.isCompleted ? "Completed" : "In Progress")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text(workout.metrics.sendRate.formatted(.percent.precision(.fractionLength(0))))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(sendRateColor)
                }
            }

            // Enhanced Progress Section
            VStack(spacing: 8) {
                // Progress bar with better styling
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                            .cornerRadius(4)

                        Rectangle()
                            .fill(completionColor)
                            .frame(width: geometry.size.width * workout.completionPercentage, height: 8)
                            .cornerRadius(4)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text("Progress")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(workout.completedReps)/\(workout.totalReps) reps")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }

            // Performance Metrics Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                MetricItem(
                    title: "Duration",
                    value: workout.metrics.totalDuration.map {
                        Duration.seconds($0).formatted(.units(allowed: [.minutes, .seconds], width: .abbreviated))
                    } ?? "N/A",
                    icon: "clock.fill",
                    color: .blue
                )

                MetricItem(
                    title: "Hardest",
                    value: workout.metrics.hardestGradeAttempted ?? "N/A",
                    icon: "arrow.up.circle.fill",
                    color: .orange
                )

                if let avgRestTime = workout.metrics.averageRestTime {
                    MetricItem(
                        title: "Avg Rest",
                        value: Duration.seconds(avgRestTime).formatted(.units(allowed: [.minutes, .seconds], width: .abbreviated)),
                        icon: "pause.circle.fill",
                        color: .purple
                    )
                }
            }

            // Workout Effectiveness Insights
            VStack(alignment: .leading, spacing: 8) {
                Text("Performance Insights")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                VStack(alignment: .leading, spacing: 6) {
                    // Send rate analysis
                    let sendRate = workout.metrics.sendRate
                    if sendRate >= 0.8 {
                        InsightRow(
                            icon: "star.fill",
                            color: .green,
                            text: "Excellent efficiency (\(Int(sendRate * 100))% success rate)"
                        )
                    } else if sendRate >= 0.6 {
                        InsightRow(
                            icon: "checkmark.circle.fill",
                            color: .blue,
                            text: "Good performance (\(Int(sendRate * 100))% success rate)"
                        )
                    } else if sendRate >= 0.4 {
                        InsightRow(
                            icon: "arrow.up.circle.fill",
                            color: .orange,
                            text: "Room for improvement (\(Int(sendRate * 100))% success rate)"
                        )
                    } else {
                        InsightRow(
                            icon: "exclamationmark.triangle.fill",
                            color: .red,
                            text: "Focus on technique (\(Int(sendRate * 100))% success rate)"
                        )
                    }

                    // Rest time analysis
                    if let avgRestTime = workout.metrics.averageRestTime {
                        let recommendedRest = workout.type.restDuration.typical
                        if avgRestTime > recommendedRest * 1.5 {
                            InsightRow(
                                icon: "tortoise.fill",
                                color: .orange,
                                text: "Longer rests - consider more consistent pacing"
                            )
                        } else if avgRestTime < recommendedRest * 0.7 {
                            InsightRow(
                                icon: "hare.fill",
                                color: .red,
                                text: "Short rests - ensure adequate recovery"
                            )
                        }
                    }

                    // Completion analysis
                    let completionRate = workout.completionPercentage
                    if completionRate >= 1.0 {
                        InsightRow(
                            icon: "checkmark.seal.fill",
                            color: .green,
                            text: "Full workout completed successfully"
                        )
                    } else if completionRate >= 0.8 {
                        InsightRow(
                            icon: "checkmark.circle.fill",
                            color: .blue,
                            text: "Mostly completed - good effort"
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

struct MetricItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)

            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(1)

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }
}

struct InsightRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 16, height: 16)

            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
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
