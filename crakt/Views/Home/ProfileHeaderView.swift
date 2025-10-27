//
//  ProfileHeaderView.swift
//  crakt
//
//  Created by Kyle Thompson on 1/16/25.
//

import SwiftUI
import SwiftData

struct ProfileHeaderView: View {
    var user: User
    var sessions: [Session]
    var onTrackEvent: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sup, Climber!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    if sessions.isEmpty {
                        Text("Ready to start a new session?")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    } else {
                        let recentStat = getRecentStat()
                        Text(recentStat)
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Button(action: {
                    // Navigate to profile or settings
                    onTrackEvent("profile_header_profile_button_tapped")
                }) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.blue)
                        .background(
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 60, height: 60)
                        )
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
    
    private func getRecentStat() -> String {
        guard let lastSession = sessions.first else {
            return "Ready for your next climb?"
        }
        
        let totalRoutes = lastSession.totalRoutes
        let totalAttempts = lastSession.totalAttempts
        
        if totalRoutes > 0 {
            if totalAttempts > 0 {
                return "Last session: \(totalRoutes) routes, \(totalAttempts) attempts"
            } else {
                return "Last session: \(totalRoutes) routes"
            }
        } else {
            return "Ready for your next climb?"
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        // Note: This preview won't work without actual User/Session data
        // In a real app, you'd create mock data for previews
        Text("ProfileHeaderView Preview")
            .padding()
    }
    .background(Color.gray.opacity(0.1))
    .cornerRadius(12)
    .padding()
} 
