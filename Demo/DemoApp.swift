//
//  DemoApp.swift
//  Demo
//
//  Created by Htun Nay Aung on 8/3/2025.
//

import SwiftUI

@main
struct DemoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            SplashScreen()
                .environment(\.managedObjectContext, persistenceController.context) // Inject Core Data
        }
    }
}
