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
        ExpandableSection(isExpanded: $isExpanded, label: {
            RouteSummaryView(route: route)
        }, content: {
            AttemptsList(attempts: route.attempts)
        })
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
