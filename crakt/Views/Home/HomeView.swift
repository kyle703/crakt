//
//  HomeView.swift
//  crakt
//
//  Created by Kyle Thompson on 9/25/23.
//

import SwiftUI
import SwiftData


let tileSize = (UIScreen.main.bounds.width - (3 * 15)) / 2

//struct SessionDetailView: View {
//
//    var session: Session
//    
//    var body: some View {
//        VStack {
//            RouteAttemptScrollView(routes: session.routes)
//        }
//    }
//}

struct HomeView: View {
//    @Bindable var user: User
    
    @Query(sort: \Session.startDate, order: .reverse)
    var sessions: [Session] = []
        
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            VStack {
                // ProfileHeaderView(user: user)

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 10) {
                        NavigationLink {
                            
                            SessionView(session: Session())
                                .navigationBarHidden(true)
                                .interactiveDismissDisabled(true)
                        } label : {
                            StartSessionTile()
                        }

                        
                        ForEach(sessions, id: \.self) { session in
                            NavigationLink {
                                SessionDetailView(viewModel: SessionDetailViewModel(session: session))
                            } label : {
                                SessionTile(session: session)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
}


struct ProfileHeaderView: View {
    var user: User

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
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(.white.shadow(.drop(radius: 2))))
    }
}

struct SessionTile: View {
    var session: Session
    let isDelete: Bool = false

    var body: some View {
        BaseTileView {
            VStack(alignment: .leading) {
                Text("\(session.routes.count) Climbs")
                    .font(.headline)
                Text(session.startDate.toString())
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


//struct HomeView_Previews: PreviewProvider {
//    static var previews: some View {
//        let user = User()
//
//        // Create instances of ActiveSession as objects.
//        let sampleSession1 = Session()
//        sampleSession1.startDate = Date()
//        sampleSession1.routes = []
//
//        let sampleSession2 = Session()
//        sampleSession2.startDate = Date().addingTimeInterval(-86400)
//        sampleSession2.routes = []
//
//        let sampleSession3 = Session()
//        sampleSession3.startDate = Date().addingTimeInterval(-2 * 86400)
//        sampleSession3.routes = []
//
//        
//        let sessions = [sampleSession1, sampleSession2, sampleSession3]
//        
//        return HomeView(user: sessions)
//    }
//}
