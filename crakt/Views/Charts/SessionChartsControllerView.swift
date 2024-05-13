//
//  SessionChartsControllerView.swift
//  crakt
//
//  Created by Kyle Thompson on 4/27/24.
//

import SwiftUI

struct ChartInfo: Identifiable {
    let id = UUID()
    let makeChartView: (_ preview: Bool) -> AnyView
    let description: String
}


struct SessionChartsControllerView: View {
    var session: Session

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var chartInfos: [ChartInfo] {
        [
            ChartInfo(makeChartView: { preview in AnyView(AttemptsByGradePieChartView(session: session, preview: preview)) }, description: "Grades"),
            ChartInfo(makeChartView: { preview in AnyView(AttemptStatusByGradeStackedBarChartView(session: session, preview: preview)) }, description: "Attempts"),
            ChartInfo(makeChartView: { preview in AnyView(AttemptsHistogramView(session: session, preview: preview)) }, description: "Routes")
        ]
    }
    
    var body: some View {
        VStack {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(chartInfos) { info in
                    NavigationLink(destination: info.makeChartView(false)) {
                        ChartTile(chart: { info.makeChartView(true) } , description: info.description)
                    }
                }
            }
        }
    }
}




struct ChartTile: View {
    let chart: () -> AnyView
    let description: String
    
    var body: some View {
        BaseTileView {
            VStack {
                chart()  // Render the chart preview
                    .frame(height: 150) // Setting a fixed height for uniformity
                Text(description)
                    
            }.padding()
        }
    }
}



