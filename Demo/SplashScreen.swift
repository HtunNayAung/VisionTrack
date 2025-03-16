//
//  SplashScreen.swift
//  Demo
//
//  Created by Htun Nay Aung on 8/3/2025.
//

import SwiftUI
import CoreData

struct SplashScreen: View {
    @State private var isActive = false
    @State private var shouldGoToSetup = true
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        if isActive {
            if shouldGoToSetup {
                SetupDetailsScreen()
            } else {
                DestinationInputView()
//                MapView()
//                                .edgesIgnoringSafeArea(.all)
            }
        } else {
            GeometryReader { geometry in
                VStack {
                    Spacer()

                    Image("AppLogo") // Replace with actual asset name
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width * 0.3) // Adjusts based on screen width
                    
                    Spacer()

                    Text("Vision Track")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                        .padding(.bottom, geometry.size.height * 0.08) // Moves text dynamically based on screen height
                    
                }
                .frame(width: geometry.size.width, height: geometry.size.height) // Ensures full-screen layout
            }
            .onAppear {
                checkUserSetup()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    withAnimation {
                        isActive = true
                    }
                }
            }
        }
    }
    
    private func checkUserSetup() {
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        do {
            let users = try viewContext.fetch(fetchRequest)
            if let _ = users.first { // If a user exists, skip setup
                shouldGoToSetup = false
            }
        } catch {
            print("Error fetching user data: \(error.localizedDescription)")
        }
    }
}
