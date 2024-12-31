//
//  OnboardingView.swift
//  FitTrack
//
//  Created by Nolan Wira on 12/7/24.
//

import SwiftUI
import HealthKit

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var profileManager = UserProfileManager.shared
    @StateObject private var healthKitManager = HealthKitManager.shared
    @StateObject private var biometricManager = BiometricManager()
    @State private var currentStep = 0
    @State private var acceptedTerms = false
    @State private var showBiometricAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress bar
                ProgressView(value: Double(currentStep), total: 5)
                    .padding()
                
                // Tab content
                TabView(selection: $currentStep) {
                    // Step 1: Welcome
                    WelcomeView()
                        .tag(0)
                    
                    // Step 2: Terms and Privacy
                    TermsView(acceptedTerms: $acceptedTerms, onTermsAccepted: { accepted in
                        // Immediately update the state when terms are accepted
                        withAnimation {
                            acceptedTerms = accepted
                        }
                    })
                    .tag(1)
                    
                    // Step 3: Profile Setup
                    ProfileSetupView(profile: $profileManager.profile)
                        .tag(2)
                    
                    // Step 4: Goals Setup
                    GoalsSetupView(macroGoals: $profileManager.profile.macroGoals)
                        .tag(3)
                    
                    // Step 5: Permissions Setup
                    PermissionsSetupView(biometricManager: biometricManager)
                        .tag(4)
                }
                .indexViewStyle(.page(backgroundDisplayMode: .never))
                .interactiveDismissDisabled()
                
                // Navigation buttons with solid background
                VStack {
                    Divider()
                    HStack {
                        if currentStep > 0 {
                            Button("Back") {
                                withAnimation {
                                    currentStep -= 1
                                }
                            }
                        }
                        
                        Spacer()
                        
                        Button(currentStep == 4 ? "Get Started" : "Next") {
                            handleNextButton()
                        }
                        .disabled(!canProceed)
                    }
                    .padding()
                }
                .background(Color(.systemBackground))
            }
            .dismissKeyboardOnTap()
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .alert("Biometric Authentication Required", isPresented: $showBiometricAlert) {
                Button("Enable", role: .none) {
                    biometricManager.authenticate()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Please enable biometric authentication to continue using FitTrack.")
            }
        }
    }
    
    private func handleNextButton() {
        if currentStep == 4 {
            if biometricManager.isUnlocked {
                completeOnboarding()
            } else {
                showBiometricAlert = true
            }
        } else {
            withAnimation {
                currentStep += 1
            }
        }
    }
    
    private var navigationTitle: String {
        switch currentStep {
        case 0: return "Welcome"
        case 1: return "Terms & Privacy"
        case 2: return "Your Profile"
        case 3: return "Set Your Goals"
        case 4: return "Enable Features"
        default: return ""
        }
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 0: return true // Welcome page can always proceed
        case 1: return acceptedTerms
        case 2: return isProfileValid
        case 3: return areGoalsValid
        case 4: return true
        default: return false
        }
    }
    
    private var isProfileValid: Bool {
        profileManager.profile.heightFeet > 0 &&
        profileManager.profile.age > 0
    }
    
    private var areGoalsValid: Bool {
        profileManager.profile.macroGoals.calories > 0 &&
        profileManager.profile.macroGoals.protein > 0 &&
        profileManager.profile.macroGoals.carbs > 0 &&
        profileManager.profile.macroGoals.fat > 0
    }
    
    private func completeOnboarding() {
        Task {
            try? await profileManager.saveProfile()
            withAnimation {
                hasCompletedOnboarding = true
            }
        }
    }
}
