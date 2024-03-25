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

struct AttemptsList: View {
    var attempts: [RouteAttempt]
    
    var body: some View {
        VStack {
            ForEach(attempts, id: \.id) { attempt in
                HStack {
                    Image(systemName: attempt.status.iconName)
                        .foregroundColor(attempt.status.color)
                    
                    Text(attempt.status.description)
                        .font(.caption)
                        .padding(.leading)
                    
                    Spacer()
                    
                    Text(attempt.date.toString())
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
            }
        }
    }
}

struct ExpandableSection<Label: View, Content: View>: View {
    @Binding var isExpanded: Bool
    let label: () -> Label
    let content: () -> Content
    
    var body: some View {
        VStack() {
            HStack {
                label()
                Spacer()
                Image(systemName: "chevron.up")
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 10)
                    .rotationEffect(Angle(degrees: isExpanded ? 0 : 180))
            }
            .frame(maxWidth: .infinity) // Ensures the HStack occupies the full width
            .contentShape(Rectangle()) // ensures the entire area is tappable
            .onTapGesture {
                withAnimation(nil) {
                    isExpanded.toggle()
                }
            }
            
            if isExpanded {
                content()
            }
        }
    }
}

struct RouteSummaryView: View {
    var route: Route
    var actionButton: AnyView?
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                
                let height: CGFloat = actionButton != nil ? 50 : 20
                let _system = GradeSystems.systems[route.gradeSystem]!
                RoundedRectangle(cornerRadius: 8)
                    .fill(_system.colors(for: route.grade!).first ?? Color.purple)
                    .frame(width: 50, height: height)
                    .overlay(
                        Text(_system.description(for: route.grade!))
                            .font(.headline)
                            .foregroundColor(Color.white)
                    )
                
                if let button = actionButton {
                    button
                }
                
                Spacer()
                
                ForEach(ClimbStatus.allCases, id: \.self) { action in
                    if let count = route.actionCounts[action], count > 0 {
                        HStack {
                            Image(systemName: action.iconName)
                                .foregroundColor(action.color)
                            
                            Text("\(count)")
                                .font(.caption)
                                .foregroundColor(.black)
                        }
                    }
                }
            }
            
        }
    }
}
struct SelectedRouteSummaryView: View {
    let route: Route
    var actionButton: AnyView?
    
    let cornerRadius: CGFloat = 8
    
    
    
    var body: some View {
        RouteSummaryView(route: route, actionButton: actionButton)
            .padding()
            .overlay(
                Rectangle()
                    .fill(Color.green)
                    .frame(width: 6)
                    .padding([.top, .bottom], -1),
                alignment: .leading
            )
            .background(
                Color.white
                    .cornerRadius(cornerRadius)
                
            )
            .cornerRadius(cornerRadius)
            .shadow(color: .gray, radius: 4, x: 0, y: 2)
    }
}
struct RouteLogRowItem_Previews: PreviewProvider {
    
    
    static let mockAttempts1: [RouteAttempt] = [
        RouteAttempt(status: .topped),
        RouteAttempt(status: .fall)
    ]
    
    static let mockAttempts2: [RouteAttempt] = [
        RouteAttempt(status: .topped),
        RouteAttempt(status: .fall),
        RouteAttempt(status: .fall)
    ]
    
    static let entry1 = Route(gradeSystem: GradeSystem.vscale, grade: "4", attempts: mockAttempts1) // Cannot convert value of type 'VGrade' to expected argument type 'AnyGradeProtocol'
    static let entry2 = Route(gradeSystem: GradeSystem.yds, grade: "5.11b", attempts: mockAttempts2)
    static let mockEntries = [entry1, entry2]
    
    
    static var previews: some View {
        Group {
            List (mockEntries, id: \.id) { entry in
                RouteLogRowItem(route: entry)
                    .previewLayout(.sizeThatFits)
            }
            VStack {
                ForEach(mockEntries, id: \.id) { entry in
                    SelectedRouteSummaryView(route: entry)
                        .previewLayout(.sizeThatFits)
                    
                }
            }.padding()
            
        }
    }
}
