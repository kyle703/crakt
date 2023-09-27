//
//  ContentView.swift
//  crakt
//
//  Created by Kyle Thompson on 9/16/23.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
   

    var body: some View {
        let activeSessions: [ActiveSession] = (appState.currentUser?.sessions?.allObjects as? [Session] ?? []).map { $0.toActiveSession() }

        HomeView(user: UserProfile(from: appState.currentUser), sessions: activeSessions)
    }
}

struct NewSessionView: View {
    // State to control showing exit alert
    
    
    var body: some View {
        SessionView()
            .navigationBarHidden(true)
            .interactiveDismissDisabled(true)
    }
}


//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
