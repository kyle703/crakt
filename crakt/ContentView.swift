//
//  ContentView.swift
//  crakt
//
//  Created by Kyle Thompson on 9/16/23.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
        
    
    func clear_swift_data() {
        do {
            try modelContext.delete(model: User.self)
            try modelContext.delete(model: Session.self)
            try modelContext.delete(model: Route.self)
            try modelContext.delete(model: RouteAttempt.self)
        } catch {
            print("Failed to clear")
        }
        
    }

    var body: some View {
        VStack {
            OutlineButton(action: clear_swift_data, label: "Delete db")
            HomeView()
        }
    }
}

//struct NewSessionView: View {
//    // State to control showing exit alert
//    
//    
//    var body: some View {
//        SessionView()
//            .navigationBarHidden(true)
//            .interactiveDismissDisabled(true)
//    }
//}


//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
