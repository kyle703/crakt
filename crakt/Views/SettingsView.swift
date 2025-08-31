import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var users: [User]
    
    var body: some View {
        NavigationView {
            List {
                if let user = users.first {
                    // 1) User Preferences
                    UserPreferencesSectionView(user: user)
                    
                    // 2) Circuit Grade Builder
                    CircuitGradeBuilderSectionView()
                    
                    // 3) Developer Settings
                    DeveloperSettingsSectionView()
                } else {
                    Text("No user found.")
                }
            }
            .navigationTitle("Settings")
        }
    }
}


struct UserPreferencesSectionView: View {
    @Bindable var user: User  // For direct $user.name usage
    
    var body: some View {
//        Text("sdf")
        Section("Default Climb Preferences") {
            
            GradeSystemSelectionView(selectedClimbType: $user.climbType, selectedGradeSystem: $user.gradeSystem)
            
        }
    }
}

struct CircuitGradeBuilderSectionView: View {
    var body: some View {
        Section(header: Text("Circuit Grade Builder")) {
            Text("Feature coming soon!")
        }
    }
}

struct DeveloperSettingsSectionView: View {
    @Environment(\.modelContext) private var context
    
    var body: some View {
        Section(header: Text("Developer Settings")) {
            Button("Clear Database") {
                clearDatabase()
            }
        }
    }
    
    private func clearDatabase() {
        Task {
            do {
                // 1) Delete all Users
                let allUsers = try context.fetch(FetchDescriptor<User>())
                allUsers.forEach { context.delete($0) }
                
                // 2) Delete all other models as needed
                let allSessions = try context.fetch(FetchDescriptor<Session>())
                allSessions.forEach { context.delete($0) }
                
                let allRoutes = try context.fetch(FetchDescriptor<Route>())
                allRoutes.forEach { context.delete($0) }
                
                let allAttempts = try context.fetch(FetchDescriptor<RouteAttempt>())
                allAttempts.forEach { context.delete($0) }
                
                // 3) Save the deletions
                try context.save()
                
                // 4) Re-insert a fresh single user (optional)
                let newUser = User()
                context.insert(newUser)
                try context.save()
                
                print("Database cleared. Inserted a fresh user named: \(newUser.name)")
            } catch {
                print("Error clearing database: \(error)")
            }
        }
    }
}
