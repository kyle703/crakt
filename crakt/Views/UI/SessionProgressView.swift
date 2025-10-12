//
//  SessionProgressView.swift
//  crakt
//
//  Created by Kyle Thompson on 1/27/25.
//

import SwiftUI
import SwiftData

struct SessionProgressView: View {
    let session: Session

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Hero Stats - Key session metrics
                heroStatsSection
                
                // Performance - Best achievements
                performanceSection
                
                // Volume Breakdown - Where you focused
                volumeDistributionSection
                
                // Efficiency - How effective
                efficiencySection
            }
            .padding(.vertical, 16)
        }
    }

    // MARK: - Hero Stats Section
    private var heroStatsSection: some View {
        VStack(spacing: 20) {
            SectionHeader(title: "Session Summary", icon: "chart.bar.fill")
            
            // Primary metrics in larger format
            VStack(spacing: 16) {
                // Attempts and Sends
                HStack(spacing: 20) {
                    HeroStatCard(
                        value: "\(session.totalAttempts)",
                        label: "Attempts",
                        icon: "arrow.up.circle.fill",
                        color: .blue
                    )
                    
                    HeroStatCard(
                        value: "\(session.totalSends)",
                        label: "Sends",
                        icon: "checkmark.circle.fill",
                        color: .green
                    )
                }
                
                // Success rate - prominent display
                VStack(spacing: 8) {
                    Text(session.formattedSuccessPercentage)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                    
                    Text("Success Rate")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(1)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Performance Section
    private var performanceSection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Performance", icon: "flame.fill")
            
            HStack(spacing: 16) {
                // Hardest sent
                VStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .font(.title)
                        .foregroundColor(.yellow)
                    
                    Text(session.hardestGradeSent ?? "—")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Hardest Sent")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 4)
                
                // Median grade
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title)
                        .foregroundColor(.purple)
                    
                    Text(session.medianGradeSent ?? "—")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Median Grade")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 4)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Efficiency Section
    private var efficiencySection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Efficiency", icon: "target")
            
            VStack(spacing: 12) {
                // Main efficiency metric
                HStack(spacing: 12) {
                    Image(systemName: "repeat.circle.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.formattedAttemptsPerSend)
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Attempts per Send")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Quality indicator
                    EfficiencyBadge(attemptsPerSend: session.attemptsPerSend)
                }
                .padding(20)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 4)
                
                // Context text
                Text("Lower is better - fewer attempts needed to send each route")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Volume Distribution Section
    private var volumeDistributionSection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Grade Distribution", icon: "chart.bar.fill")
            
            if session.formattedGradeDistribution.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar")
                        .font(.largeTitle)
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Text("No attempts yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Start climbing to see your grade distribution")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color(.systemBackground))
                .cornerRadius(12)
            } else {
                VStack(spacing: 8) {
                    ForEach(session.formattedGradeDistribution, id: \.band) { distribution in
                        VStack(spacing: 8) {
                            HStack {
                                // Grade band
                                Text(distribution.band)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .frame(width: 70, alignment: .leading)
                                
                                // Progress bar
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.gray.opacity(0.15))
                                            .frame(height: 24)
                                        
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.blue.opacity(0.8))
                                            .frame(width: geometry.size.width * distribution.percentage / 100.0, height: 24)
                                        
                                        // Count label inside bar
                                        if distribution.percentage > 15 {
                                            Text("\(distribution.attempts)")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(.white)
                                                .padding(.leading, 8)
                                        }
                                    }
                                }
                                .frame(height: 24)
                                
                                // Percentage
                                Text(String(format: "%.0f%%", distribution.percentage))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                    .frame(width: 45, alignment: .trailing)
                            }
                            .frame(height: 24)
                        }
                    }
                }
                .padding(16)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 4)
            }
        }
        .padding(.horizontal)
    }

}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.primary)
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            Spacer()
        }
    }
}

struct HeroStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4)
    }
}

struct EfficiencyBadge: View {
    let attemptsPerSend: Double
    
    private var quality: (label: String, color: Color) {
        switch attemptsPerSend {
        case 0..<2.0:
            return ("Excellent", .green)
        case 2.0..<3.5:
            return ("Good", .blue)
        case 3.5..<5.0:
            return ("Average", .orange)
        default:
            return ("Working", .gray)
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title2)
                .foregroundColor(quality.color)
            
            Text(quality.label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(quality.color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(quality.color.opacity(0.15))
        .cornerRadius(8)
    }
}

#Preview {
    let tempContext = try! ModelContainer(for: Route.self, RouteAttempt.self).mainContext
    let session = Session.active_preview

    return SessionProgressView(session: session)
        .padding(.vertical)
        .background(Color.gray.opacity(0.1))
}
