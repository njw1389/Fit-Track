//
//  WelcomeView.swift
//  FitTrack
//
//  Created by Nolan Wira on 12/7/24.
//

import SwiftUI

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 30) {
            // App Icon and Title
            VStack(spacing: 20) {
                Image(systemName: "figure.run.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Welcome to FitTrack")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Your Journey, Tracked")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            // Feature highlights
            VStack(alignment: .leading, spacing: 25) {
                FeatureRow(
                    icon: "chart.bar.fill",
                    title: "Track Your Progress",
                    description: "Log your meals, exercises, and monitor your daily nutrition"
                )
                
                FeatureRow(
                    icon: "heart.fill",
                    title: "Health Integration",
                    description: "Sync with HealthKit to track your steps and active energy"
                )
                
                FeatureRow(
                    icon: "bell.fill",
                    title: "Smart Reminders",
                    description: "Get notifications to stay on track with your fitness goals"
                )
                
                FeatureRow(
                    icon: "lock.fill",
                    title: "Secure & Private",
                    description: "Your data is encrypted and stored securely"
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading) // Ensure consistent alignment
            .padding(.horizontal)
        }
        .padding()
    }
}

// Feature Row Component
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30, alignment: .center)
                .padding(.top, 2) // Adjust icon vertical position to align with title
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading) // Ensure text content uses remaining space
        }
    }
}

#Preview {
    WelcomeView()
}
