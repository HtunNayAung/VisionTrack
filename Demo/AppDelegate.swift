//
//  AppDelegate.swift
//  Demo
//
//  Created by Htun Nay Aung on 8/3/2025.
//

import UIKit
import GoogleMaps
import GoogleNavigation

class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        // Load API key from Info.plist
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMSAPIKey") as? String {
            GMSServices.provideAPIKey(apiKey)
        } else {
            fatalError("Google Maps API key is missing in Info.plist")
        }

        return true
    }
}

