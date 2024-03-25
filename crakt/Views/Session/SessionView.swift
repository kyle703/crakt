//
//  SessionView.swift
//  crakt
//
//  Created by Kyle Thompson on 9/17/23.
//

import SwiftUI

struct SessionView: View {
    @Environment(\.modelContext) private var modelContext

    @StateObject var stopwatch = Stopwatch()
    @State var session: Session
    
    @State var selectedGradeSystem: GradeSystem = .circuit
    @State var selectedClimbType: ClimbType = .boulder
    @State var selectedGrade: String?

    
    var routeLogActionButton: OutlineButton {
        if session.activeRoute?.attempts.count == 0 {
            return OutlineButton(action: {session.clearRoute(context: modelContext)}, systemImage: "trash.circle.fill", label: "Remove", color: .gray)
        } else {
            return OutlineButton(action: {session.logRoute(context: modelContext)}, systemImage: "checkmark.circle.fill", label: "Log it", color: .green)
        }
    }
    
    var body: some View {
        VStack {
            Text("\(session.id.uuidString)")
            SessionHeader(session: session, stopwatch: stopwatch)
                .frame(height: 150).onAppear {
                    stopwatch.start()
                }
            
            GradeSystemSelectionView(selectedClimbType: $selectedClimbType, selectedGradeSystem: $selectedGradeSystem)
                .padding(.horizontal)
                .padding(.bottom)
                .onChange(of: selectedClimbType, perform: {_ in session.clearRoute(context: modelContext)})
                .onChange(of: selectedGradeSystem, perform: {_ in session.clearRoute(context: modelContext)})

            
            Spacer()
            if session.routes.isEmpty {
                Text("No route logs yet!")
                    .foregroundColor(.gray)
            } else {
                ScrollViewReader { scrollView in
                    List {
                        ForEach(session.routes, id: \.id) { route in
                            RouteLogRowItem(route: route)
                        }
                    }
                    .listStyle(PlainListStyle())
                    .onChange(of: session.routes.count) { newValue in
                        if let lastItem = session.routes.last {
                            withAnimation {
                                scrollView.scrollTo(lastItem.id, anchor: .bottom)
                            }
                        }
                    }
                }

            }
            Spacer()
            
            // MARK: Session Footer
            VStack {
                
                if session.activeRoute != nil {
                    SelectedRouteSummaryView(route: session.activeRoute!, actionButton: AnyView(routeLogActionButton)).padding()
                    
                    SessionActionBar(session: session)
                } else {
                    if let grade = selectedGrade {
                        HStack {
                            Spacer()
                            OutlineButton {
                                let _route = Route(gradeSystem: selectedGradeSystem, grade: grade)
                                modelContext.insert(_route)
                                session.activeRoute = _route
                                session.routes.append(_route)
                            }
                            Spacer()
                        }.padding(.horizontal)
                    }
                
                    ClimbingGradeSelector(gradeSystem: GradeSystems.systems[selectedGradeSystem]!, selectedGrade: $selectedGrade).frame(height: 90)
                }
                
            }
            
        }
    }
}




struct RoutesList: View {
    var body: some View {
        List {
            // Example List items (Replace with actual data)
            Text("Route 1")
            Text("Route 2")
            Text("Route 3")
        }
    }
}





struct SessionView_Previews: PreviewProvider {
    static var previews: some View {
        SessionView(session: Session())
    }
}
