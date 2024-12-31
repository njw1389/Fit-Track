//
//  ProfilePage.swift
//  FitTrack
//
//  Created by Nolan Wira on 11/3/24.
//

import SwiftUI
import HealthKit

struct ProfilePage: View {
    @StateObject private var healthKitManager = HealthKitManager.shared
    @StateObject private var profileManager = UserProfileManager.shared
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("HealthKit Connection")) {
                    Button(action: {
                        if healthKitManager.isAuthorized {
                            healthKitManager.disconnect()
                        } else {
                            healthKitManager.requestAuthorization()
                        }
                    }) {
                        HStack {
                            Image(systemName: healthKitManager.isAuthorized ? "heart.fill" : "heart")
                                .foregroundColor(healthKitManager.isAuthorized ? .green : .gray)
                            Text(healthKitManager.isAuthorized ? "Disconnect HealthKit" : "Connect HealthKit")
                            Spacer()
                        }
                    }
                }
                
                Section(header: Text("Personal Information")) {
                    NavigationLink(destination: PersonalInfoEditor(profile: $profileManager.profile)
                        .onDisappear {
                            Task {
                                try? await profileManager.saveProfile()
                            }
                        }
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Personal Details")
                            Group {
                                Text("Height: \(profileManager.profile.heightFeet)'\(profileManager.profile.heightInches)\"")
                                Text("Age: \(profileManager.profile.age)")
                                Text("Gender: \(profileManager.profile.gender)")
                            }
                            .font(.caption)
                            .foregroundColor(.gray)
                        }
                    }
                }
                
                Section(header: Text("Goals")) {
                    NavigationLink(destination: MacroGoalsEditor(macroGoals: $profileManager.profile.macroGoals)
                        .onDisappear {
                            Task {
                                try? await profileManager.saveProfile()
                            }
                        }
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Targets")
                            Group {
                                Text("Weight Goal: \(profileManager.profile.macroGoals.weightGoal) lbs")
                                Text("Calories: \(profileManager.profile.macroGoals.calories) kcal")
                                Text("Protein: \(profileManager.profile.macroGoals.protein)g")
                                Text("Carbs: \(profileManager.profile.macroGoals.carbs)g")
                                Text("Fat: \(profileManager.profile.macroGoals.fat)g")
                            }
                            .font(.caption)
                            .foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}

struct PersonalInfoEditor: View {
    @Binding var profile: UserProfile
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Form {
            Section(header: Text("Height")) {
                HStack {
                    Text("Feet")
                    Spacer()
                    TextField("Feet", value: $profile.heightFeet, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
                
                HStack {
                    Text("Inches")
                    Spacer()
                    TextField("Inches", value: $profile.heightInches, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
            }
            
            Section {
                HStack {
                    Text("Age")
                    Spacer()
                    TextField("Age", value: $profile.age, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
                
                Picker("Gender", selection: $profile.gender) {
                    Text("Not Specified").tag("Not Specified")
                    Text("Male").tag("Male")
                    Text("Female").tag("Female")
                    Text("Other").tag("Other")
                }
            }
        }
        .navigationTitle("Edit Personal Info")
        .navigationBarTitleDisplayMode(.inline)
        .dismissKeyboardOnTap()
    }
}

struct MacroGoalsEditor: View {
    @Binding var macroGoals: MacroGoals
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Form {
            Section(header: Text("Weight Goal")) {
                HStack {
                    Text("Target Weight (lbs)")
                    Spacer()
                    TextField("Weight", value: $macroGoals.weightGoal, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
            }
            
            Section(header: Text("Daily Macro Goals")) {
                HStack {
                    Text("Calories")
                    Spacer()
                    TextField("Calories", value: $macroGoals.calories, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
                
                HStack {
                    Text("Protein (g)")
                    Spacer()
                    TextField("Protein", value: $macroGoals.protein, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
                
                HStack {
                    Text("Carbs (g)")
                    Spacer()
                    TextField("Carbs", value: $macroGoals.carbs, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
                
                HStack {
                    Text("Fat (g)")
                    Spacer()
                    TextField("Fat", value: $macroGoals.fat, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .navigationTitle("Edit Goals")
        .navigationBarTitleDisplayMode(.inline)
        .dismissKeyboardOnTap()
    }
}

#Preview {
    ProfilePage()
}
