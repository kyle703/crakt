//
//  ContentView.swift
//  crakt
//
//  Created by Kyle Thompson on 9/16/23.
//

import SwiftUI
import SwiftData

struct MainTabView: View {

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            ActivityHistoryView()
                .tabItem {
                    Label("Activity", systemImage: "clock")
                }

            Text("adf")
                .tabItem {
                    Label("Stats", systemImage: "chart.bar")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}


struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack {
//            OutlineButton(action: clear_swift_data, label: "Delete db")
            MainTabView()
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
