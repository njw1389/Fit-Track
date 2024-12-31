//
//  iCloudSignInView.swift
//  FitTrack
//
//  Created by Nolan Wira on 11/4/24.
//

import SwiftUI

struct iCloudSignInView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "icloud.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Welcome to FitTrack")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(spacing: 10) {
                Text("Please sign in to iCloud")
                    .font(.headline)
                
                Text("This app requires an iCloud account to store your fitness data securely and sync across your devices.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 20) {
                Text("To sign in to iCloud:")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 10) {
                    InstructionRow(number: "1", text: "Open Settings on your device")
                    InstructionRow(number: "2", text: "Tap your name at the top")
                    InstructionRow(number: "3", text: "Tap 'iCloud'")
                    InstructionRow(number: "4", text: "Sign in with your Apple ID")
                }
                .padding(.horizontal)
            }
            .padding(.top)
            
            Button(action: {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }) {
                Text("Open Settings")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.top)
            
            Button(action: {
                Task {
                    await authManager.checkAuthStatus()
                }
            }) {
                Text("Check iCloud Status")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
}

struct InstructionRow: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Text(number + ".")
                .fontWeight(.bold)
            Text(text)
        }
    }
}

#Preview {
    iCloudSignInView()
}
