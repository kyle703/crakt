//
//  RouteHUDView.swift
//  crakt
//
//  Created by Kyle Thompson on 1/25/25.
//

import SwiftUI
import SwiftData

struct RouteHUDView: View {
    let route: Route?
    let onTap: () -> Void

    private var sendCount: Int {
        route?.attempts.filter { $0.status == .send }.count ?? 0
    }

    private var fallCount: Int {
        route?.attempts.filter { $0.status == .fall }.count ?? 0
    }

    private var totalAttempts: Int {
        sendCount + fallCount
    }

    var body: some View {
        HStack(spacing: 16) {
            // Grade chip - large and prominent
            if let gradeDesc = route?.gradeDescription {
                Text(gradeDesc)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(route?.gradeColor ?? .gray)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
            }

            // Attempt counter
            VStack(alignment: .leading, spacing: 2) {
                Text("A:\(totalAttempts)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                HStack(spacing: 8) {
                    if sendCount > 0 {
                        Text("S:\(sendCount)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.green)
                    }
                    if fallCount > 0 {
                        Text("F:\(fallCount)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.red)
                    }
                }
            }

            Spacer()

            // Set/Rep indicator (placeholder for now)
            if let route = route {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Set 1")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    Text("Rep 1")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                }
            }

            // Progress ring (compact)
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                    .frame(width: 32, height: 32)

                Circle()
                    .trim(from: 0, to: 0.75) // Example progress
                    .stroke(Color.blue, lineWidth: 3)
                    .frame(width: 32, height: 32)
                    .rotationEffect(.degrees(-90))

                Text("75%")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.95))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Route \(route?.gradeDescription ?? "Unknown grade"), \(totalAttempts) attempts, \(sendCount) sends, \(fallCount) falls")
        .accessibilityHint("Tap to view route details")
    }
}

#Preview {
    RouteHUDPreview()
}

struct RouteHUDPreview: View {
    var body: some View {
        let tempContext = try! ModelContainer(for: Route.self, RouteAttempt.self).mainContext
        let session = Session.active_preview

        return RouteHUDView(route: session.activeRoute) {
            print("Route details tapped")
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}
