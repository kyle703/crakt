//
//  RouteLogRowItem.swift
//  crakt
//
//  Created by Kyle Thompson on 9/23/23.
//

import SwiftUI

struct RouteLogRowItem: View {
    var logEntry: RouteLogEntry
    @State private var isExpanded: Bool = false
    
    var body: some View {
        ExpandableSection(isExpanded: $isExpanded, label: {
            RouteSummaryView(logEntry: logEntry)
        }, content: {
            AttemptsList(attempts: logEntry.attempts)
        })
    }
}

struct AttemptsList: View {
    var attempts: [ClimbAttempt]
    
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
    var logEntry: RouteLogEntry
    var actionButton: AnyView?
    
    
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                
                let height: CGFloat = actionButton != nil ? 50 : 20
                RoundedRectangle(cornerRadius: 8)
                    .fill(logEntry.gradeSystem.colors(for: logEntry.grade).first ?? Color.purple)
                    .frame(width: 50, height: height)
                    .overlay(
                        Text(logEntry.gradeSystem.description(for: logEntry.grade))
                            .font(.headline)
                            .foregroundColor(Color.white)
                    )
                
                if let button = actionButton {
                    button
                }
                
                Spacer()
                
                ForEach(ClimbStatus.allCases, id: \.self) { action in
                    if let count = logEntry.actionCounts[action], count > 0 {
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
    let logEntry: RouteLogEntry
    var actionButton: AnyView?
    
    let cornerRadius: CGFloat = 8
    
    
    
    var body: some View {
        RouteSummaryView(logEntry: logEntry, actionButton: actionButton)
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
    
    
    static let mockAttempts1: [ClimbAttempt] = [
        ClimbAttempt(status: .topped, date: Date()),
        ClimbAttempt(status: .fall, date: Date().addingTimeInterval(-3600))
    ]
    
    static let mockAttempts2: [ClimbAttempt] = [
        ClimbAttempt(status: .topped, date: Date().addingTimeInterval(-7200)),
        ClimbAttempt(status: .fall, date: Date().addingTimeInterval(-10000)),
        ClimbAttempt(status: .fall, date: Date().addingTimeInterval(-15000))
    ]
    
    static let entry1 = RouteLogEntry(gradeSystem: AnyGradeProtocol(VGrade()), grade: "4", attempts: mockAttempts1) // Cannot convert value of type 'VGrade' to expected argument type 'AnyGradeProtocol'
    static let entry2 = RouteLogEntry(gradeSystem: AnyGradeProtocol(YDS()), grade: "5.11b", attempts: mockAttempts2)
    static let mockEntries = [entry1, entry2]
    
    
    static var previews: some View {
        Group {
            List (mockEntries, id: \.id) { entry in
                RouteLogRowItem(logEntry: entry)
                    .previewLayout(.sizeThatFits)
            }
            VStack {
                ForEach(mockEntries, id: \.id) { entry in
                    SelectedRouteSummaryView(logEntry: entry)
                        .previewLayout(.sizeThatFits)
                    
                }
            }.padding()
            
        }
    }
}
