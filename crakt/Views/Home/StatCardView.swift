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
