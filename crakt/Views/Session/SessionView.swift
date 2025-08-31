//
//  SessionView.swift
//  crakt
//
//  Created by Kyle Thompson on 9/17/23.
//

import SwiftUI
import SwiftData
import Foundation

// MARK: RouteAttempScrollView
struct RouteAttemptScrollView: View {
    var routes: [Route]
    
    var body: some View {
        ScrollViewReader { scrollView in
            if routes.isEmpty {
                // Enhanced empty state with CTA button
                VStack(spacing: 24) {
                    Image(systemName: "mountain.2.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.blue.opacity(0.7))
                    
                    VStack(spacing: 12) {
                        Text("No routes logged yet!")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Start your climbing session by logging your first route")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                    }
                    
                    
                }
                .padding(.vertical, 40)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity)
            } else {
                ForEach(routes, id: \.id) { route in
                    RouteLogRowItem(route: route)
                }
                .onChange(of: routes.count) { _ in
                    // Scroll to last item whenever a new route is added
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


// MARK: ViewModifiers for consistent styling
struct CardStyle: ViewModifier {
    var backgroundColor: Color

    func body(content: Content) -> some View {
        content
            .padding(12)
            .background(backgroundColor)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct PillStyle: ViewModifier {
    var borderColor: Color

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(borderColor, lineWidth: 2)
            )
            .background(Color.white)
            .cornerRadius(20)
    }
}

extension View {
    func cardStyle(backgroundColor: Color) -> some View {
        self.modifier(CardStyle(backgroundColor: backgroundColor))
    }

    func pillStyle(borderColor: Color) -> some View {
        self.modifier(PillStyle(borderColor: borderColor))
    }
}



struct SessionView_Previews: PreviewProvider {
    static var previews: some View {
        SessionView(session: Session())
    }
}


struct SessionView: View {
    @Environment(\.modelContext) private var modelContext

    @StateObject var stopwatch = Stopwatch()
    @State var session: Session

    @State var selectedGradeSystem: GradeSystem = .circuit
    @State var selectedClimbType: ClimbType = .boulder
    @State var selectedGrade: String?

    var body: some View {
        VStack {
            
                        
            SessionHeader(session: session, stopwatch: stopwatch, selectedClimbType: $selectedClimbType, selectedGradeSystem: $selectedGradeSystem)
                .onAppear {
                    stopwatch.start()
                }.onChange(of: selectedClimbType) { _ in
                    session.clearRoute(context: modelContext)
                }
                .onChange(of: selectedGradeSystem) { _ in
                    session.clearRoute(context: modelContext)
                }

            
            
            // ScrollView with a transition-based animation on the active route card
            ScrollView {
                // Animate changes to session.activeRoute
                if let route = session.activeRoute {
                    ActiveRouteCard(session: session, stopwatch: stopwatch)
                        // A scale transition that starts slightly smaller/larger
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                }
                
                RouteAttemptScrollView(routes: session.routesSortedByDate)
            }
            .animation(.spring(), value: session.activeRoute)
            // ^ Ties any changes to session.activeRoute to a spring animation
            
            // If there's no active route, show the "add new route" UI
            if session.activeRoute == nil {
                Spacer()
                if let grade = selectedGrade {
                    HStack {
                        Spacer()
                        OutlineButton {
                            withAnimation {
                                let newRoute = Route(gradeSystem: selectedGradeSystem,
                                                     grade: grade)
                                newRoute.status = .active
                                modelContext.insert(newRoute)
                                session.activeRoute = newRoute
                            }
                        } 
                        Spacer()
                    }
                    .padding(.horizontal)
                }

                ClimbingGradeSelector(gradeSystem: GradeSystems.systems[selectedGradeSystem]!,
                                      selectedGrade: $selectedGrade)
                    .frame(height: 90)
            }
        }
    }
}


