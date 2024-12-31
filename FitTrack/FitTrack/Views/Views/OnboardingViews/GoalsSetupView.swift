//
//  GoalsSetupView.swift
//  FitTrack
//
//  Created by Nolan Wira on 12/7/24.
//

import SwiftUI
import HealthKit

struct GoalsSetupView: View {
    @Binding var macroGoals: MacroGoals
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Section
                VStack(spacing: 8) {
                    Image(systemName: "target")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Set Your Goals")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Customize your daily nutritional targets")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 8)
                
                // Goals Form
                VStack(spacing: 24) {
                    GoalField(
                        title: "Daily Calories",
                        value: $macroGoals.calories,
                        unit: "kcal",
                        icon: "flame.fill",
                        color: .orange
                    )
                    
                    GoalField(
                        title: "Target Weight",
                        value: $macroGoals.weightGoal,
                        unit: "lbs",
                        icon: "scalemass.fill",
                        color: .purple
                    )
                    
                    GoalField(
                        title: "Protein",
                        value: $macroGoals.protein,
                        unit: "g",
                        icon: "leaf.fill",
                        color: .green
                    )
                    
                    GoalField(
                        title: "Carbs",
                        value: $macroGoals.carbs,
                        unit: "g",
                        icon: "chart.pie.fill",
                        color: .blue
                    )
                    
                    GoalField(
                        title: "Fat",
                        value: $macroGoals.fat,
                        unit: "g",
                        icon: "drop.fill",
                        color: .yellow
                    )
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

struct GoalField: View {
    let title: String
    @Binding var value: Int
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
            }
            
            HStack(spacing: 12) {
                TextField("Value", value: $value, format: .number)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: .infinity)
                
                Text(unit)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(width: 40)
            }
        }
    }
}
