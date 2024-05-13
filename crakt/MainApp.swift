//
//  craktApp.swift
//  crakt
//
//  Created by Kyle Thompson on 9/16/23.
//

import SwiftUI
import SwiftData

@main
struct MainApp: App {
    
    let modelContainer: ModelContainer
        
    init() {
        do {
            modelContainer = try ModelContainer(for: User.self, Session.self, Route.self, RouteAttempt.self)
        } catch {
            fatalError("Could not initialize ModelContainer")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                //.modelContainer(DataController.previewContainer)
        }

    }
}


@MainActor
class DataController {
    static let previewContainer: ModelContainer = {
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: Session.self, Route.self, RouteAttempt.self, configurations: config)
            let session = Session()
            container.mainContext.insert(session)
            
            // Define the start and end date for the session
            let startDate = Date()
            var currentTime = startDate
            let endTime = startDate.addingTimeInterval(90 * 60)  // 90 minutes later

            let maxGrade = 12
            var grade = 0
            var exampleRoutes: [Route] = []

            while currentTime < endTime {
                let easierRouteFrequency = Double.random(in: 0...1)
                if easierRouteFrequency > 0.5 {  // 50% chance to keep the grade stable or decrease it
                    grade = max(0, grade - 1)
                } else {  // 50% chance to increase the grade gradually
                    if grade < maxGrade {
                        grade += 1
                    }
                }
                
                var route = Route(
                    gradeSystem: .vscale,
                    grade: "\(grade)",
                    session: session
                )

                // Rest period influenced by difficulty and includes random jitter
                let restPeriod = TimeInterval(60)
                currentTime.addTimeInterval(restPeriod)
                
                let successProbability = max(0.1, 1 - Double(grade) * 0.08)
                let attemptsCount = (grade <= 2) ? Int.random(in: 1...2) : max(3, min(grade, 5))

                var attempts: [RouteAttempt] = []
                var topped = false
                for attemptIndex in 1...attemptsCount {
                    print(route.normalizedGrade)
                    let status: ClimbStatus = ClimbStatus.allCases[Int.random(in: 0...ClimbStatus.allCases.count - 1)]
                    let attemptTime = TimeInterval(attemptIndex * 10 + Int.random(in: -10...10))
                    currentTime.addTimeInterval(attemptTime)
                    route.attempts.append(RouteAttempt(date: currentTime.addingTimeInterval(attemptTime), status: status))
                    if status == .send {
                        break  // End attempts if topped
                    }
                }

                
                
//                attempts.forEach { container.mainContext.insert($0) }
                container.mainContext.insert(route)
                exampleRoutes.append(route)

                currentTime.addTimeInterval(TimeInterval(attemptsCount * 60))  // Adding time spent on attempts
                grade += Int.random(in: 0...1)  // Random walk but trending upward

                // Check if time exceeds the session duration
                if currentTime.addingTimeInterval(120) >= endTime {
                    break
                }
            }

            session.routes = exampleRoutes
            session.startDate = startDate
            session.endDate = currentTime  // End when last route is done
            
            return container
        } catch {
            fatalError("Failed to create model container for previewing: \(error.localizedDescription)")
        }
    }()
}


