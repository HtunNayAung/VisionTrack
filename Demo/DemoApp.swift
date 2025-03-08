//
//  DemoApp.swift
//  Demo
//
//  Created by Htun Nay Aung on 8/3/2025.
//

import SwiftUI

@main
struct DemoApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
