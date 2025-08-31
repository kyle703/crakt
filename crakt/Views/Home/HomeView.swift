//
//  HomeView.swift
//  crakt
//
//  Created by Kyle Thompson on 9/25/23.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Query private var user: [User]
    
    @Query(sort: \Session.startDate, order: .reverse)
    var sessions: [Session] = []
    
    // Analytics tracking
    @State private var hasTrackedEmptyStateImpression = false
        
    var body: some View {
        NavigationStack {
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
                            Text("Start a New Session")
                                .font(.title)
                                .padding()
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
                Text("Start a New Session")
                    .font(.title)
                    .padding()
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
        let routes = sessions.flatMap { $0.routes }
        let grades = routes.compactMap { $0.normalizedGrade }
        
        guard !grades.isEmpty else { return "N/A" }
        
        let average = grades.reduce(0, +) / Double(grades.count)
        return formatGrade(average)
    }
    
    private var totalHours: Int {
        let totalSeconds = sessions.reduce(0) { $0 + $1.elapsedTime }
        return Int(totalSeconds / 3600)
    }
    
    private func formatGrade(_ grade: Double) -> String {
        // Simple grade formatting - you can enhance this based on your grade system
        if grade < 1 { return "V0" }
        if grade < 2 { return "V1" }
        if grade < 3 { return "V2" }
        if grade < 4 { return "V3" }
        if grade < 5 { return "V4" }
        if grade < 6 { return "V5" }
        if grade < 7 { return "V6" }
        if grade < 8 { return "V7" }
        if grade < 9 { return "V8" }
        return "V9+"
    }
}

// Components
struct ActivityRowView: View {
    var session: Session

    var body: some View {
        HStack(spacing: 16) {
            // Session icon/indicator
            VStack(spacing: 4) {
                Circle()
                    .fill(session.totalRoutes > 0 ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
                
                if session.totalRoutes > 0 {
                    Circle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 4, height: 4)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(session.sessionDescription)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(formatDate(session.startDate))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if session.totalRoutes > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "mountain.2")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            if session.totalAttempts > 0 {
                                Text("\(session.totalRoutes) routes, \(session.totalAttempts) attempts")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("\(session.totalRoutes) routes")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.caption2)
                                .foregroundColor(.orange)
                            Text("No routes logged")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.trailing, 8)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE" // Full weekday name
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d" // Jan 15
            return formatter.string(from: date)
        }
    }
}

struct StatCardView: View {
    var icon: String
    var title: String
    var subtitle: String
    var color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .padding(12)
                .background(
                    Circle()
                        .fill(color.opacity(0.1))
                )
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

struct StartSessionTile: View {
    @Query private var user: [User]
    
    var body: some View {
        NavigationLink {
            SessionView(session: Session(), selectedGradeSystem: user.first!.gradeSystem, selectedClimbType: user.first!.climbType)
                .navigationBarHidden(true)
                .interactiveDismissDisabled(true)
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

struct ProfileHeaderView: View {
    var user: User
    var sessions: [Session]
    var onTrackEvent: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Hi, \(user.name)!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    if sessions.isEmpty {
                        Text("Ready for your next climb?")
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



