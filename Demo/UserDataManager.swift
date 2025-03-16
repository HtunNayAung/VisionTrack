//
//  UserDataManager.swift
//  Demo
//
//  Created by Htun Nay Aung on 8/3/2025.
//

import CoreData
import SwiftUI

class UserDataManager: ObservableObject {
    let context = PersistenceController.shared.context

    @Published var user: User?

    init() {
        fetchUser()
    }

    // Fetch user from Core Data
    func fetchUser() {
        let request: NSFetchRequest<User> = User.fetchRequest()
        
        do {
            let users = try context.fetch(request)
            user = users.first // Assuming single user storage
        } catch {
            print("Error fetching user: \(error.localizedDescription)")
        }
    }

    // Save or update user data
    func saveUser(name: String, phoneNumber: String, emergencyEmail: String, cameraPermission: Bool, microphonePermission: Bool) {
        if user == nil {
            user = User(context: context) // Create new user if none exists
        }
        
        user?.name = name
        user?.phoneNumber = phoneNumber
        user?.emergencyEmail = emergencyEmail
        user?.cameraPermission = cameraPermission
        user?.microphonePermission = microphonePermission

        do {
            try context.save()
            fetchUser() // Refresh data after saving
        } catch {
            print("Error saving user data: \(error.localizedDescription)")
        }
    }
}

