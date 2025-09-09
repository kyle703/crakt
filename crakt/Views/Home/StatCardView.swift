//
//  StatCardView.swift
//  crakt
//
//  Created by Kyle Thompson on 1/16/25.
//

import SwiftUI

struct StatCardView: View {
    var icon: String
    var title: String
    var subtitle: String
    var color: Color
    var trend: String? = nil

    private func trendColor(for trend: String) -> Color {
        switch trend {
        case "↑": return .green
        case "↓": return .red
        default: return .gray
        }
    }

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
                HStack(spacing: 4) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    if let trend = trend {
                        Text(trend)
                            .font(.title3)
                            .foregroundColor(trendColor(for: trend))
                            .fontWeight(.bold)
                    }
                }

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

#Preview {
    HStack(spacing: 16) {
        StatCardView(
            icon: "chart.bar.fill",
            title: "141",
            subtitle: "Total Climbs",
            color: .blue
        )
        
        StatCardView(
            icon: "flame.fill",
            title: "V4",
            subtitle: "Avg Grade",
            color: .orange
        )
        
        StatCardView(
            icon: "clock.fill",
            title: "126h",
            subtitle: "Climbing Time",
            color: .green
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
} 
