//
//  ContentView.swift
//  FitTrack
//
//  Created by Nolan Wira on 11/3/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var biometricManager = BiometricManager()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView()
            } else if !biometricManager.isUnlocked {
                BiometricUnlockView()
                    .environmentObject(biometricManager)
                    .transition(.opacity)
            } else if authManager.isAuthenticated {
                HomeView()
            } else {
                iCloudSignInView()
            }
        }
        .environmentObject(authManager)
    }
}

#Preview {
    ContentView()
}
