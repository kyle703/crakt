//
//  RouteLogRowItem.swift
//  crakt
//
//  Created by Kyle Thompson on 9/23/23.
//

import SwiftUI

struct RouteLogRowItem: View {
    var route: Route
    @State private var isExpanded: Bool = false
    
    var body: some View {
        // Derive the background color from route’s grade
        let gradeSystem = GradeSystems.systems[route.gradeSystem]!
        let gradeColor = route.grade.flatMap { gradeSystem.colors(for: $0).first } ?? .purple
        
        // Use the ExpandableSection as before, but place
        // the background around it so everything is in one card.
        ExpandableSection(isExpanded: $isExpanded,
                          label: {
            RouteSummaryView(route: route)
        }, content: {
            AttemptsList(route: route)
                .padding([.horizontal, .bottom]) // Padding inside the card
        })
        // The entire ExpandableSection (label + content) is inside a rounded rectangle
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(gradeColor)
        )
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}



//struct RouteLogRowItem_Previews: PreviewProvider {
//
//
//    static let mockAttempts1: [RouteAttempt] = [
//        RouteAttempt(status: .send),
//        RouteAttempt(status: .fall)
//    ]
//
//    static let mockAttempts2: [RouteAttempt] = [
//        RouteAttempt(status: .send),
//        RouteAttempt(status: .fall),
//        RouteAttempt(status: .fall)
//    ]
//
//    static let entry1 = Route(gradeSystem: GradeSystem.vscale, grade: "4", attempts: mockAttempts1) // Cannot convert value of type 'VGrade' to expected argument type 'AnyGradeProtocol'
//    static let entry2 = Route(gradeSystem: GradeSystem.yds, grade: "5.11b", attempts: mockAttempts2)
//    static let mockEntries = [entry1, entry2]
//
//
//    static var previews: some View {
//        Group {
//            List (mockEntries, id: \.id) { entry in
//                RouteLogRowItem(route: entry)
//                    .previewLayout(.sizeThatFits)
//            }
//            VStack {
//                ForEach(mockEntries, id: \.id) { entry in
//                    SelectedRouteSummaryView(route: entry)
//                        .previewLayout(.sizeThatFits)
//
//                }
//            }.padding()
//
//        }
//    }
//}
