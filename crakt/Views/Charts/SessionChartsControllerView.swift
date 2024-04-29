//
//  SessionChartsControllerView.swift
//  crakt
//
//  Created by Kyle Thompson on 4/27/24.
//

import SwiftUI

enum ChartType: String, CaseIterable, Identifiable {
    case pie = "Pie Chart"
    case stackedBar = "Stacked Bar Chart"
    case sessionDetail = "Session Histogram"

    var id: String { self.rawValue }
}


struct SessionChartsControllerView: View {
    var session: Session
    @State private var selectedChartType: ChartType = .pie
    @State var gradeSystem: GradeSystem
    
    var body: some View {
        VStack {
            // Grade system picker
            GradeSystemPicker(selectedGradeSystem: $gradeSystem, climbType: session.routes.first!.climbType)
            
            // Segmented control to switch between chart views
            Picker("Select Chart Type", selection: $selectedChartType) {
                ForEach(ChartType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            // Dynamically display the selected chart view
            switch selectedChartType {
            case .pie:
                AttemptsByGradePieChartView(session: session)
            case .stackedBar:
                AttemptStatusByGradeStackedBarChartView(session: session)
            case .sessionDetail:
                AttemptsHistogramView(session: session, preview: false)
            }
        }
    }
}
