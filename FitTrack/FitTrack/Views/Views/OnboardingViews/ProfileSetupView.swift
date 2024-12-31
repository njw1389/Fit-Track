//
//  ProfileSetupView.swift
//  FitTrack
//
//  Created by Nolan Wira on 12/7/24.
//

import SwiftUI

struct ProfileSetupView: View {
    @Binding var profile: UserProfile
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Section
                VStack(spacing: 8) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Tell us about yourself")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("This helps us personalize your experience")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 8)
                
                // Profile Form
                VStack(spacing: 24) {
                    // Height Section
                    ProfileFormSection(title: "Height") {
                        HStack(spacing: 16) {
                            // Feet Input
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Feet")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                TextField("", value: $profile.heightFeet, format: .number)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(maxWidth: .infinity)
                            }
                            
                            // Inches Input
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Inches")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                TextField("", value: $profile.heightInches, format: .number)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    
                    // Age Section
                    ProfileFormSection(title: "Age") {
                        TextField("", value: $profile.age, format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    // Gender Section
                    ProfileFormSection(title: "Gender") {
                        Picker("", selection: $profile.gender) {
                            Text("Male").tag("Male")
                            Text("Female").tag("Female")
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .padding(20)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
            }
            .padding()
        }
        .dismissKeyboardOnTap()
    }
}

// Helper view for form sections
struct ProfileFormSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            content
        }
    }
}
