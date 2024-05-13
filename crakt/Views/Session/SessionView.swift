//
//  SessionView.swift
//  crakt
//
//  Created by Kyle Thompson on 9/17/23.
//

import SwiftUI

struct RouteAttemptScrollView: View {
    var routes: [Route]
    var body: some View {

        
        ScrollViewReader { scrollView in
            if routes.isEmpty {
                Text("No route logs yet!")
                    .foregroundColor(.gray)
            } else {
                
                ForEach(routes, id: \.id) { route in
                    RouteLogRowItem(route: route)
                }
                .onChange(of: routes.count) { newValue in
                    if let lastItem = routes.last {
                        withAnimation {
                            scrollView.scrollTo(lastItem.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
    }
}

struct SessionView: View {
    @Environment(\.modelContext) private var modelContext
    
    @StateObject var stopwatch = Stopwatch()
    @State var session: Session
    
    @State var selectedGradeSystem: GradeSystem = .circuit
    @State var selectedClimbType: ClimbType = .boulder
    @State var selectedGrade: String?
    
    
    var routeLogActionButton: ActionButton {
        if session.activeRoute?.attempts.count == 0 {
            return ActionButton(icon: "trash.circle.fill", label: nil, color: .gray) {session.clearRoute(context: modelContext)}
        } else {
            return ActionButton(icon: "checkmark.circle.fill", label: "Log it", color: .green) {session.logRoute()}
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

            RouteAttemptScrollView(routes: session.routes)
                
            Spacer()
            
            // MARK: Session Footer
            VStack {
                
                
                if session.activeRoute != nil {
                    GroupBox {
                        
                        RouteSummaryView(route: session.activeRoute!).padding(1)
                        
                        
                    }
                    SessionActionBar(session: session, actionButton: AnyView(routeLogActionButton))
                } else {
                    if let grade = selectedGrade {
                        HStack {
                            Spacer()
                            OutlineButton {
                                let _route = Route(gradeSystem: selectedGradeSystem, grade: grade)
                                _route.status = .active
                                modelContext.insert(_route)
                                session.activeRoute = _route
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





struct SessionView_Previews: PreviewProvider {
    static var previews: some View {
        SessionView(session: Session())
    }
}
