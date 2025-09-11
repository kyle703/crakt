//
//  HomeView.swift
//  crakt
//
//  Created by Kyle Thompson on 9/25/23.
//

import SwiftUI
import SwiftData
import Foundation

struct HomeView: View {
    @Query private var user: [User]

    @Query(sort: \Session.startDate, order: .reverse)
    var sessions: [Session] = []

    // Navigation
    @State private var navigationPath = NavigationPath()

    // Analytics tracking
    @State private var hasTrackedEmptyStateImpression = false
        
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    ProfileHeaderView(user: user.first ?? User(), sessions: sessions, onTrackEvent: trackEvent)

                    VStack(alignment: .leading, spacing: 20) {
                        // Lifetime Stats Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Lifetime Stats")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)

                            lifetimeStatsGrid
                        }
                        
                        // Start a New Session Section
                        NavigationLink {
                            SessionConfigView(
                                onSessionComplete: { completedSession in
                                    // Navigate to session detail view when session completes
                                    navigationPath.append(completedSession)
                                },
                                onSessionStart: {
                                    // Reset navigation when session starts
                                    navigationPath = NavigationPath()
                                }
                            )
                        } label: {
                            StartSessionTile()
                        }
                        .onTapGesture {
                            // Analytics: Track Start Session CTA tap
                            trackEvent("start_session_cta_tapped")
                        }

                        // Recent Activities Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Recent Activities")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)

                            if sessions.isEmpty {
                                // Empty state
                                emptyStateView
                                    .onAppear {
                                        if !hasTrackedEmptyStateImpression {
                                            trackEvent("empty_state_impression")
                                            hasTrackedEmptyStateImpression = true
                                        }
                                    }
                            } else {
                                // Recent activities list
                                recentActivitiesList
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationDestination(for: Session.self) { session in
                SessionDetailView(session: session)
            }
        }
        .onAppear {
            // Analytics: Track Home View impression
            trackEvent("home_view_impression")
        }
    }
    
    // Analytics tracking function
    private func trackEvent(_ eventName: String) {
        // TODO: Implement actual analytics tracking
        print("Analytics: \(eventName)")
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            // Enhanced illustration with multiple climbing elements
            VStack(spacing: 16) {
                Image(systemName: "mountain.2.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.blue)
                
                HStack(spacing: 12) {
                    Image(systemName: "figure.climbing")
                        .font(.system(size: 24))
                        .foregroundColor(.blue.opacity(0.7))
                    Image(systemName: "figure.climbing")
                        .font(.system(size: 20))
                        .foregroundColor(.blue.opacity(0.5))
                        .offset(x: -8, y: 4)
                }
            }
            .padding(.top, 8)
            
            VStack(spacing: 8) {
                Text("Begin Your Climbing Journey")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Track your progress, celebrate achievements, and discover your climbing potential")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            
            NavigationLink {
                SessionConfigView()
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                    Text("Start Your First Session")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.blue, .blue.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(PlainButtonStyle())
            .onTapGesture {
                trackEvent("empty_state_start_session_tapped")
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
    
    private var recentActivitiesList: some View {
        VStack(spacing: 0) {
            ForEach(sessions.prefix(10), id: \.id) { session in
                NavigationLink {
                    SessionDetailView(session: session)
                } label: {
                    ActivityRowView(session: session)
                }
                .buttonStyle(PlainButtonStyle())
                .onTapGesture {
                    // Analytics: Track activity row tap
                    trackEvent("activity_row_tapped")
                }
                
                if session.id != sessions.prefix(10).last?.id {
                    Divider()
                        .padding(.leading, 20)
                        .opacity(0.3)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
    
    private var lifetimeStatsGrid: some View {
        HStack(spacing: 16) {
            StatCardView(
                icon: "chart.bar.fill", 
                title: "\(totalClimbs)", 
                subtitle: "Total Climbs",
                color: .blue
            )
            .onTapGesture {
                trackEvent("stats_total_climbs_tapped")
            }
            
            StatCardView(
                icon: "flame.fill", 
                title: averageGrade, 
                subtitle: "Avg Grade",
                color: .orange
            )
            .onTapGesture {
                trackEvent("stats_avg_grade_tapped")
            }
            
            StatCardView(
                icon: "clock.fill", 
                title: "\(totalHours)h", 
                subtitle: "Climbing Time",
                color: .green
            )
            .onTapGesture {
                trackEvent("stats_climbing_time_tapped")
            }
        }
    }
    
    // Computed properties for stats
    private var totalClimbs: Int {
        sessions.reduce(0) { $0 + $1.totalAttempts }
    }
    
    private var averageGrade: String {
        // Get all successful attempts across all sessions
        let successfulAttempts = sessions.flatMap { session in
            session.allAttempts.filter { $0.status == .send || $0.status == .flash || $0.status == .topped }
        }

        // Get grade indices for successful attempts
        let gradeIndices = successfulAttempts.compactMap { attempt in
            attempt.route?.gradeIndex
        }

        guard !gradeIndices.isEmpty else { return "N/A" }

        // Calculate average grade index
        let averageIndex = gradeIndices.reduce(0, +) / gradeIndices.count

        // Convert back to grade string using V-Scale as reference
        if averageIndex >= 0 && averageIndex < VGrade().grades.count {
            return "V\(VGrade().grades[averageIndex])"
        } else {
            return "V\(averageIndex)"
        }
    }
    
    private var totalHours: Int {
        // Calculate actual climbing time based on attempt durations
        // Estimate 3 minutes (180 seconds) per attempt as average climbing time
        let totalAttempts = sessions.reduce(0) { $0 + $1.totalAttempts }
        let estimatedClimbingSeconds = Double(totalAttempts) * 180.0 // 3 minutes per attempt
        return Int(estimatedClimbingSeconds / 3600.0)
    }
}

// Components




struct StartSessionTile: View {
    @Query private var user: [User]
    
    var body: some View {
        NavigationLink {
            SessionConfigView()
        } label: {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ready to climb?")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Start a new climbing session")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(
                LinearGradient(
                    colors: [.blue, .blue.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(20)
            .shadow(color: .blue.opacity(0.3), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(PlainButtonStyle())
    }
}





