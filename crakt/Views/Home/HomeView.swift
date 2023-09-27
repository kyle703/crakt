//
//  HomeView.swift
//  crakt
//
//  Created by Kyle Thompson on 9/25/23.
//

import SwiftUI


struct UserProfile {
    var name: String
    var id: UUID
    // Add any other necessary user attributes you'd like here...

    init(from user: User?) {
        self.name = user?.name ?? "Unknown"
        self.id = user?.id ?? UUID()
    }
}

let tileSize = (UIScreen.main.bounds.width - (3 * 15)) / 2

struct HomeView: View {
    var user: UserProfile
    var sessions: [ActiveSession]
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            VStack {
                ProfileHeaderView(user: user)

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 10) {
                        NavigationLink {
                            SessionView()
                                .navigationBarHidden(true)
                                .interactiveDismissDisabled(true)
                        } label : {
                            StartSessionTile()
                        }

                        
                        ForEach(sessions, id: \.self) { session in
                            SessionTile(session: session)

                        }
                    }
                    .padding()
                }
            }
        }
    }
}


struct ProfileHeaderView: View {
    var user: UserProfile

    var body: some View {
        HStack {
            Text("Hello, \(user.name)!")
                .font(.title)
                .bold()
            
            Spacer()

            Image(systemName: "person.circle.fill")
                .font(.largeTitle)
                .onTapGesture {
                    // Handle profile tap action, perhaps navigate to a user settings or profile view
                }
        }
        .padding()
    }
}

struct BaseTileView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack {
            content
        }
        .frame(width: tileSize, height: tileSize)
        .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(.white.shadow(.drop(radius: 2))))
    }
}

struct SessionTile: View {
    var session: ActiveSession

    var body: some View {
        BaseTileView {
            VStack(alignment: .leading) {
                Text("\(session.routes.count) Climbs")
                    .font(.headline)
                Text(session.start.toString())
                    .font(.subheadline)
            }
        }
    }
}

struct StartSessionTile: View {
    var body: some View {
        BaseTileView {
            VStack {
                Image(systemName: "plus")
                    .font(.largeTitle)
                Text("Start a new Session")
                    .fontWeight(.medium)
            }
        }
    }
}


struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let userProfile = UserProfile(from: nil)

        // Create instances of ActiveSession as objects.
        let sampleSession1 = ActiveSession()
        sampleSession1.start = Date()
        sampleSession1.routes = []

        let sampleSession2 = ActiveSession()
        sampleSession2.start = Date().addingTimeInterval(-86400)
        sampleSession2.routes = []

        let sampleSession3 = ActiveSession()
        sampleSession3.start = Date().addingTimeInterval(-2 * 86400)
        sampleSession3.routes = []

        // If HomeView expects an array of sessions:
        let sampleSessions: [ActiveSession] = [sampleSession1, sampleSession2, sampleSession3]
        return HomeView(user: userProfile, sessions: sampleSessions)

        // OR if HomeView expects an ObservableObject sessions (maybe a SessionsStore or similar):
        // let sessionsStore = SessionsStore()  // If you have a store like this.
        // sessionsStore.sessions = sampleSessions
        // return HomeView(user: userProfile, sessions: sessionsStore)
    }
}
