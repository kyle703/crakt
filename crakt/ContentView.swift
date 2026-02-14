//
//  ContentView.swift
//  crakt
//
//  Created by Kyle Thompson on 9/16/23.
//

import SwiftUI

struct MainTabView: View {

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            GymFinderView()
                .tabItem {
                    Label("Gyms", systemImage: "figure.climbing")
                }

            ActivityHistoryView()
                .tabItem {
                    Label("Activity", systemImage: "clock")
                }

            GlobalSessionsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}


struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}
