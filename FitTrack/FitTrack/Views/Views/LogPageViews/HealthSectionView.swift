//
//  HealthSectionView.swift
//  FitTrack
//
//  Created by Nolan Wira on 12/9/24.
//

import SwiftUI

struct HealthSectionView: View {
    let healthData: HealthDataItem?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Health Data")
                .font(.headline)
            
            if let data = healthData {
                // Steps
                HStack {
                    Image(systemName: "figure.walk")
                        .foregroundColor(.blue)
                    Text("Steps")
                    Spacer()
                    Text("\(data.steps)")
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
                
                // Total Calories
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("Total Calories Burned")
                    Spacer()
                    Text("\(Int(data.totalCaloriesBurned)) kcal")
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
                
                // Active Energy
                HStack {
                    Image(systemName: "figure.run")
                        .foregroundColor(.green)
                    Text("Active Energy")
                    Spacer()
                    Text("\(Int(data.activeEnergy)) kcal")
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
                
                // Resting Energy
                HStack {
                    Image(systemName: "bed.double.fill")
                        .foregroundColor(.blue)
                    Text("Resting Energy")
                    Spacer()
                    Text("\(Int(data.restingEnergy)) kcal")
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            } else {
                Text("No health data available")
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}
