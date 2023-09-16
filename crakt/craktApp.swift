//
//  craktApp.swift
//  crakt
//
//  Created by Kyle Thompson on 9/16/23.
//

import SwiftUI

@main
struct craktApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
