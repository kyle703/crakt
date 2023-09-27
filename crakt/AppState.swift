//
//  AppState.swift
//  crakt
//
//  Created by Kyle Thompson on 9/17/23.
//

import Foundation
import SwiftUI
import CoreData
import Combine



class AppState: ObservableObject {
    @Published var currentUser: User?
    
    
    let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
        self.currentUser = fetchOrCreatePreviewUser()
        
        setupCoreDataChangeListening()
    }
    
    private var cancellables: Set<AnyCancellable> = []

    
    private func setupCoreDataChangeListening() {
           NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: context)
               .sink { [weak self] notification in
                   if let userInfo = notification.userInfo {
                       // Check if our currentUser object was updated
                       if let updatedObjects = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>,
                          updatedObjects.contains(self?.currentUser ?? NSManagedObject()) {
                           self?.currentUser = self?.context.object(with: (self?.currentUser!.objectID)!) as? User
                       }
                   }
               }
               .store(in: &cancellables)
       }
}

enum ClimbType: Int16, CustomStringConvertible {
    case boulder = 0
    case toprope = 1
    case lead = 2
    
    var description: String {
        switch self {
        case .boulder:
            return "Boulder"
        case .toprope:
            return "Toprope"
        case .lead:
            return "Lead"
        }
    }
    
    static let allCases: [ClimbType] = [.boulder, .toprope, .lead]
}

enum GradeSystem: Int16, CustomStringConvertible {
    case circuit = 0
    case vscale = 1
    case font = 2
    case french = 3
    case yds = 4
    
    var description: String {
        switch self {
        case .circuit:
            return "Circuit"
        case .vscale:
            return "V-Scale"
        case .font:
            return "Font grade"
        case .french:
            return "French grade"
        case .yds:
            return "Yosemite Decimal System"
        }
    }
    
    var climbType : ClimbType {
        switch self {
        case .circuit, .vscale, .font:
            return .boulder
        case .french, .yds:
            return .lead
        }
    }
    
    static let allCases: [GradeSystem] = [.circuit, .vscale, .font, .french, .yds]
}

enum RouteAttemptStatus: Int16 {
    case fail = 0
    case top = 1
}

extension AppState {
    
    func fetchOrCreatePreviewUser() -> User? {
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", "PreviewUser")
        
        do {
            let matchingUsers = try context.fetch(request)
            
            if let existingUser = matchingUsers.first {
                // Found an existing preview user, use it
                return existingUser
            } else {
                // No preview user found, create one
                let newUser = User(context: context)
                newUser.name = "PreviewUser"
                newUser.id = UUID()
                
                do {
                    try context.save()
                    return newUser
                } catch {
                    // Handle the Core Data error
                    print("Failed to save new user: \(error)")
                    return nil
                }
            }
        } catch {
            // Handle the Core Data fetch error
            print("Failed to fetch user: \(error)")
            return nil
        }
    }
    
    func fetchActiveSessions(for user: User) -> [ActiveSession]? {
        let fetchRequest: NSFetchRequest<Session> = Session.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "user == %@", user)
        
        do {
            let fetchedSessions = try context.fetch(fetchRequest)
            return fetchedSessions.map { $0.toActiveSession() }
        } catch {
            print("Failed to fetch sessions for user \(user.name ?? "Unknown"): \(error)")
            return nil
        }
    }
    
    func saveSession(session: ActiveSession) {
        do {
            let newSession = session.toSession(for: currentUser!, context: context)
            currentUser!.addToSessions(newSession)
            

            try context.save()
            context.refresh(currentUser!, mergeChanges: true)

        } catch {
            print("Failed to save and append session to user \(currentUser?.name ?? "Unknown"): \(error)")
        }
    }
    
}
