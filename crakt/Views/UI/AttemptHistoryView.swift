//
//  AttemptHistoryView.swift
//  crakt
//
//  Created by Kyle Thompson on 1/25/25.
//

import SwiftUI
import SwiftData

struct AttemptHistoryView: View {
    let route: Route?
    let onDeleteAttempt: (RouteAttempt) -> Void
    let onDismiss: () -> Void

    @State private var attempts: [RouteAttempt] = []

    private var sortedAttempts: [RouteAttempt] {
        attempts.sorted { $0.date > $1.date } // Most recent first
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text(route?.gradeDescription ?? "Route Attempts")
                        .font(.title2)
                        .fontWeight(.bold)

                    HStack(spacing: 16) {
                        statItem(title: "Total", value: "\(attempts.count)")
                        statItem(title: "Sends", value: "\(attempts.filter { $0.status == .send }.count)")
                        statItem(title: "Falls", value: "\(attempts.filter { $0.status == .fall }.count)")
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))

                // Attempts list
                List {
                    ForEach(sortedAttempts) { attempt in
                        AttemptRowView(attempt: attempt)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    onDeleteAttempt(attempt)
                                    attempts.removeAll { $0.id == attempt.id }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.plain)
                .background(Color.white)
            }
            .navigationBarItems(trailing: Button("Done") {
                onDismiss()
            })
            .navigationTitle("Attempt History")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            if let route = route {
                attempts = route.attempts
            }
        }
    }

    private func statItem(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct AttemptRowView: View {
    let attempt: RouteAttempt

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }

    var body: some View {
        HStack(spacing: 16) {
            // Status icon
            VStack {
                Image(systemName: attempt.status.iconName)
                    .font(.title2)
                    .foregroundColor(attempt.status.color)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(attempt.status.color.opacity(0.1))
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(attempt.status.description)
                    .font(.headline)
                    .foregroundColor(attempt.status.color)

                HStack(spacing: 12) {
                    Text(timeFormatter.string(from: attempt.date))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(dateFormatter.string(from: attempt.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Route time indicator (placeholder for now)
            VStack(alignment: .trailing, spacing: 2) {
                Text("0:45")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(.primary)
                Text("route time")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

#Preview {
    AttemptHistoryPreview()
}

struct AttemptHistoryPreview: View {
    var body: some View {
        let tempContext = try! ModelContainer(for: Route.self, RouteAttempt.self).mainContext
        let route = Route(gradeSystem: .yds, grade: "5.10a")

        // Add some sample attempts
        route.attempts = [
            RouteAttempt(date: Date().addingTimeInterval(-300), status: .fall),
            RouteAttempt(date: Date().addingTimeInterval(-180), status: .send),
            RouteAttempt(date: Date().addingTimeInterval(-60), status: .fall)
        ]

        return AttemptHistoryView(
            route: route,
            onDeleteAttempt: { attempt in
                print("Deleted attempt: \(attempt.status)")
            },
            onDismiss: {
                print("Dismissed")
            }
        )
    }
}
