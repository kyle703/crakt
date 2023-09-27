//
//  craktApp.swift
//  crakt
//
//  Created by Kyle Thompson on 9/16/23.
//

import SwiftUI

@main
struct MainApp: App {
    let persistenceController = PersistenceController.shared
    let appState = AppState(context: PersistenceController.shared.container.viewContext)


    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(appState)
                
        }
    }
}
