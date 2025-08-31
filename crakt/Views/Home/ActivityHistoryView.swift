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

    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 15) {
                    // Weekly Progress Stats Header
                    WeeklyProgressHeaderView(sessions: sessions)
                        .padding(.horizontal)

                    // List View of Sessions
                    LazyVStack(spacing: 10) {
                        ForEach(sessions, id: \.id) { session in
                            NavigationLink {
                                SessionDetailView(session: session)
                            } label: {
                                SessionRowCardView(session: session)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Activity History")
        }
    }
}

// MARK: - Weekly Progress Header
struct WeeklyProgressHeaderView: View {
    let sessions: [Session]

    var weeklyData: [(day: String, volume: Int)] {
        let calendar = Calendar.current
        let weekdays = calendar.weekdaySymbols
        var volumeByDay: [String: Int] = [:]

        for session in sessions {
            let day = weekdays[calendar.component(.weekday, from: session.startDate) - 1]
            volumeByDay[day, default: 0] += session.routes.count
            
        }

        return weekdays.map { ($0, volumeByDay[$0] ?? 0) }
    }

    var gradeData: [String: [String: Int]] {
        var data: [String: [String: Int]] = ["Boulder": [:], "Ropes": [:]]

        for session in sessions {
            for route in session.routes {
                if let grade = route.grade {
                    let climbTypeKey = route.climbType.isRopes ? "Ropes" : "Boulder"
                    data[climbTypeKey, default: [:]][grade, default: 0] += 1
                }
            }
        }

        return data
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Weekly Metrics")
                .font(.headline)

            WeeklyVolumeChart(weeklyData: weeklyData)

            Text("Grade Distribution")
                .font(.headline)

            GradeDistributionPickerChart(gradeData: gradeData)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
        .shadow(radius: 1)
    }
}

// Weekly Climbing Volume Bar Chart
struct WeeklyVolumeChart: View {
    let weeklyData: [(day: String, volume: Int)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("7 Day Volume")
                .font(.headline)

            Chart {
                ForEach(weeklyData, id: \..day) { data in
                    LineMark(
                        x: .value("Day", data.day),
                        y: .value("Volume", data.volume)
                    )
                    .symbol(Circle().strokeBorder(lineWidth: 2))
                    .symbolSize(40)
                    .foregroundStyle(.blue)

                    PointMark(
                        x: .value("Day", data.day),
                        y: .value("Volume", data.volume)
                    )
                    .symbol(Circle().strokeBorder(lineWidth: 2))
                    .symbolSize(10)
                    .foregroundStyle(.blue)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartPlotStyle { plotArea in
                plotArea
                    .frame(height: 120)
                    .background(Color.clear)
            }
            .frame(height: 150)
        }
        .padding(.vertical)
    }
}

// MARK: - Grade Distribution Pie Chart
struct GradeDistributionChart: View {
    let gradeData: [String: [String: Int]] // [climbType: [grade: volume]]
    let selectedClimbType: ClimbType

    var filteredGradeData: [String: Int] {
        let typeKey = selectedClimbType.isRopes ? "Ropes" : "Boulder"
        return gradeData[typeKey, default: [:]]
    }

    var body: some View {
        VStack {
            Chart {
                ForEach(filteredGradeData.keys.sorted(), id: \..self) { grade in
                    SectorMark(
                        angle: .value("Attempts", filteredGradeData[grade] ?? 0),
                        innerRadius: .ratio(0.5),
                        outerRadius: .ratio(1.0)
                    )
                    .foregroundStyle(by: .value("Grade", grade))
                }
            }
            .frame(height: 150)
            .padding(.vertical)
        }
    }
}

struct GradeDistributionPickerChart: View {
    @State private var selectedClimbType: ClimbType = .boulder
    let gradeData: [String: [String: Int]] // [climbType: [grade: volume]]

    var body: some View {
        VStack {
            Picker("Climb Type", selection: $selectedClimbType) {
                Text(ClimbType.boulder.description).tag(ClimbType.boulder)
                Text("Ropes").tag(ClimbType.lead) // Combined ropes types
            }
            .pickerStyle(SegmentedPickerStyle())

            GradeDistributionChart(gradeData: gradeData, selectedClimbType: selectedClimbType)
        }
    }
}

// Chart Previews
struct WeeklyVolumeChart_Previews: PreviewProvider {
    static var previews: some View {
        WeeklyVolumeChart(weeklyData: [
            ("Mon", 5), ("Tue", 8), ("Wed", 2), ("Thu", 10), ("Fri", 4), ("Sat", 7), ("Sun", 3)
        ])
        .previewLayout(.sizeThatFits)
        .padding()
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
                    .fill(Color.white.shadow(.drop(radius: 2)))
            )
    }
}
