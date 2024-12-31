//
//  TermsView.swift
//  FitTrack
//
//  Created by Nolan Wira on 12/7/24.
//

import SwiftUI
import HealthKit

struct TermsView: View {
    @Binding var acceptedTerms: Bool
    var onTermsAccepted: ((Bool) -> Void)?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Terms of Service & Privacy Policy")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 12) {
                    TermsSection(title: "Data Collection and Storage", content: """
                        FitTrack collects and stores:
                        • Personal information (height, weight, age, gender)
                        • Fitness goals and preferences
                        • Food and exercise logs
                        • HealthKit data (with permission)
                        
                        All data is stored securely using Firebase and iCloud.
                        """)
                    
                    TermsSection(title: "Data Usage", content: """
                        Your data is used to:
                        • Provide personalized recommendations
                        • Track your progress
                        • Generate health insights
                        
                        We never share your data with third parties.
                        """)
                    
                    TermsSection(title: "Your Rights", content: """
                        You have the right to:
                        • Access your personal data
                        • Request data deletion
                        • Opt out of data collection
                        • Export your data
                        """)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                
                Toggle("I accept the Terms of Service and Privacy Policy", isOn: Binding(
                    get: { acceptedTerms },
                    set: { newValue in
                        acceptedTerms = newValue
                        onTermsAccepted?(newValue)
                    }
                ))
                .padding(.top)
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }
}

struct TermsSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(content)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}
