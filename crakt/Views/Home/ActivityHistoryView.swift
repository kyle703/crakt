//
//  ActivityHistoryView.swift
//  crakt
//
//  Created by Kyle Thompson on 1/12/25.
//

import SwiftUI
import SwiftData
import Charts

struct ActivityHistoryView: View {
    @Query(sort: \Session.startDate, order: .reverse)
    var sessions: [Session]

    @State private var showActiveSession = false
    @State private var activeSession: Session?

    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                if sessions.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 15) {
                        LazyVStack(spacing: 10) {
                            ForEach(sessions, id: \.id) { session in
                                if session.status == .active {
                                    Button(action: {
                                        activeSession = session
                                        showActiveSession = true
                                    }) {
                                        SessionRowCardView(session: session)
                                            .padding(.horizontal)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                } else {
                                    NavigationLink {
                                        SessionDetailView(session: session)
                                    } label: {
                                        SessionRowCardView(session: session)
                                            .padding(.horizontal)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Activity History")
        }
        .fullScreenCover(item: $activeSession) { session in
            SessionView(session: session) { _ in
                // On completion from History, just dismiss; analysis viewed via Home
                activeSession = nil
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.climbing")
                .font(.system(size: 48))
                .foregroundColor(.blue)

            Text("No history yet")
                .font(.title2)
                .fontWeight(.bold)

            Text("Start a session or find a gym to log your first climb.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            HStack(spacing: 12) {
                NavigationLink(destination: SessionConfigView()) {
                    Text("Start Session")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                NavigationLink(destination: GymFinderView()) {
                    Text("Find a Gym")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(10)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 60)
    }
}

struct StatView: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading) {
            
            HStack(spacing: 4) {
                
                Text(value)
                    .font(.headline)
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
            }
            
                
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        
        }
    }
}

// MARK: - Session Row Card
struct SessionRowCardView: View {
    let session: Session

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header Section
            SessionHeaderView(session: session)

            Divider()

            // Stats Section
            HStack(spacing: 20) {
                
                StatView(
                    icon: "clock.fill",
                    label: "Duration",
                    value: formattedDuration(session.elapsedTime),
                    color: .orange
                )
                Spacer()
                
                StatView(
                    icon: "flag.fill",
                    label: "Tops",
                    value: "\(session.tops)",
                    color: .green
                )
                StatView(
                    icon: "arrow.up.square.fill",
                    label: "Tries",
                    value: "\(session.tries)",
                    color: .blue
                )
                
            }
        }
        .padding()
        .modifier(ContainerStyleModifier())
        .frame(maxWidth: .infinity)
    }

    func formattedDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}


// MARK: - Session Header
struct SessionHeaderView: View {
    let session: Session

    var body: some View {
        HStack(alignment: .center, spacing: 15) {
            // Climb Type Icon
            Circle()
                .fill(Color.blue)
                .frame(width: 40, height: 40)
                .overlay(
                    Text("C") // Placeholder for climb type icon
                        .font(.headline)
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(session.sessionDescription)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                

                HStack(spacing: 10) {
                    Label(session.startDate.toString(), systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()

                    Label("Peak RVA", systemImage: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            Spacer()
        }
    }
}

// MARK: - Custom Container Modifier
struct ContainerStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color(.systemBackground).shadow(.drop(radius: 2)))
            )
    }
}
