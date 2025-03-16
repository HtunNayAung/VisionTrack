//
//  SetupDetailsScreen.swift
//  Demo
//
//  Created by Htun Nay Aung on 8/3/2025.
//

import SwiftUI

struct SetupDetailsScreen: View {
    @StateObject private var userManager = UserDataManager()
    @State private var name = ""
    @State private var phoneNumber = ""
    @State private var emergencyEmail = ""
    @State private var cameraPermission = false
    @State private var microphonePermission = false
    @State private var navigateToMap = false
    @State private var destination = ""
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        NavigationView {
            VStack (spacing: 20) {
                Text("Set up your Details")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center) // Ensures centering
                    .padding(.top, 10)

                Text("Please complete all information and allow the permissions to continue.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                VStack(spacing: 20) {
                    TextField("Your Name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    TextField("Emergency Contact Number", text: $phoneNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    TextField("Emergency Contact Email", text: $emergencyEmail)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer().frame(height: 20)

                VStack(spacing: 15) {
                    Toggle(isOn: $cameraPermission) {
                        VStack(alignment: .leading) {
                            Text("Camera")
                            Text("Enable camera for navigation support.")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal)
                    
                    Toggle(isOn: $microphonePermission) {
                        VStack(alignment: .leading) {
                            Text("Microphone")
                            Text("Enable microphone for voice navigation.")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal)
                }

//                NavigationLink(destination: MapView(destination: $destination), isActive: $navigateToMap) {
//                    EmptyView()
//                }
                NavigationLink(destination: DestinationInputView(), isActive: $navigateToMap) {
                    EmptyView()
                }


                Button(action: {
                    saveUser()
                    navigateToMap = true
                }) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                }
                .padding(.top, 20)
            }
            .navigationBarHidden(true)
            .onAppear {
                if let user = userManager.user {
                    name = user.name ?? ""
                    phoneNumber = user.phoneNumber ?? ""
                    emergencyEmail = user.emergencyEmail ?? ""
                    cameraPermission = user.cameraPermission
                    microphonePermission = user.microphonePermission
                }
            }
        }
    }
    
    private func saveUser() {
        let newUser = User(context: viewContext)
        newUser.name = name
        newUser.phoneNumber = phoneNumber
        newUser.emergencyEmail = emergencyEmail
        newUser.cameraPermission = cameraPermission
        newUser.microphonePermission = microphonePermission

        do {
            try viewContext.save()
        } catch {
            print("Error saving user data: \(error.localizedDescription)")
        }
    }
}

