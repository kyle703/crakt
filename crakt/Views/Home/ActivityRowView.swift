//
//  ActivityRowView.swift
//  crakt
//  crakt
//
//  Created by Kyle Thompson on 1/16/25.
//

import SwiftUI
import SwiftData

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

#Preview {
    VStack(spacing: 0) {
        // Note: This preview won't work without actual Session data
        // In a real app, you'd create a mock Session for previews
        Text("ActivityRowView Preview")
            .padding()
    }
    .background(Color.gray.opacity(0.1))
    .cornerRadius(12)
    .padding()
} 
