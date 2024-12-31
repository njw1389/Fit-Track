//
//  DashboardPage.swift
//  FitTrack
//
//  Created by Nolan Wira on 11/5/24.
//

import SwiftUI
import HealthKit

struct DashboardPage: View {
    @StateObject private var healthKitManager = HealthKitManager.shared
    @StateObject private var profileManager = UserProfileManager.shared
    @StateObject private var foodLogManager = FoodLogManager.shared
    @StateObject private var exerciseLogManager = ExerciseLogManager.shared
    @State private var todaysFoodLogs: [FoodLogItem] = []
    @State private var todaysExerciseLogs: [ExerciseLogItem] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Daily Progress Summary
                    DailySummaryView(
                        calories: calculateTotalCalories(),
                        calorieGoal: profileManager.profile.macroGoals.calories,
                        activeEnergy: healthKitManager.activeEnergy,
                        steps: healthKitManager.steps
                    )
                    
                    // Macros Progress
                    MacrosProgressView(
                        consumedMacros: calculateMacros(),
                        targetMacros: profileManager.profile.macroGoals
                    )
                    
                    // Today's Activities
                    TodaysActivityView(
                        exerciseLogs: todaysExerciseLogs,
                        foodLogs: todaysFoodLogs
                    )
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .onAppear {
                Task {
                    await loadTodaysData()
                }
            }
        }
    }
    
    private func loadTodaysData() async {
        do {
            todaysFoodLogs = try await foodLogManager.fetchFoodLogs(for: Date())
            todaysExerciseLogs = try await exerciseLogManager.fetchExerciseLogs(for: Date())
        } catch {
            print("Error loading today's data: \(error)")
        }
    }
    
    private func calculateTotalCalories() -> Double {
        todaysFoodLogs.reduce(0) { $0 + $1.calories }
    }
    
    private func calculateMacros() -> (protein: Double, carbs: Double, fat: Double) {
        let protein = todaysFoodLogs.reduce(0) { $0 + $1.protein }
        let carbs = todaysFoodLogs.reduce(0) { $0 + $1.carbs }
        let fat = todaysFoodLogs.reduce(0) { $0 + $1.fat }
        return (protein, carbs, fat)
    }
}

struct DailySummaryView: View {
    let calories: Double
    let calorieGoal: Int
    let activeEnergy: Double
    let steps: Int
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Daily Summary")
                .font(.headline)
            
            HStack(spacing: 20) {
                // Calories Consumed
                MetricCard(
                    title: "Calories",
                    value: "\(Int(calories))",
                    subtitle: "of \(calorieGoal)",
                    icon: "flame.fill",
                    color: .orange
                )
                
                // Active Energy
                MetricCard(
                    title: "Active",
                    value: "\(Int(activeEnergy))",
                    subtitle: "kcal burned",
                    icon: "figure.run",
                    color: .green
                )
                
                // Steps
                MetricCard(
                    title: "Steps",
                    value: "\(steps)",
                    subtitle: "steps today",
                    icon: "figure.walk",
                    color: .blue
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct MacrosProgressView: View {
    let consumedMacros: (protein: Double, carbs: Double, fat: Double)
    let targetMacros: MacroGoals
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Macros Progress")
                .font(.headline)
            
            MacroProgressBar(
                title: "Protein",
                consumed: consumedMacros.protein,
                goal: Double(targetMacros.protein),
                color: .blue
            )
            
            MacroProgressBar(
                title: "Carbs",
                consumed: consumedMacros.carbs,
                goal: Double(targetMacros.carbs),
                color: .green
            )
            
            MacroProgressBar(
                title: "Fat",
                consumed: consumedMacros.fat,
                goal: Double(targetMacros.fat),
                color: .orange
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct MacroProgressBar: View {
    let title: String
    let consumed: Double
    let goal: Double
    let color: Color
    
    var progress: Double {
        min(consumed / goal, 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                Spacer()
                Text("\(Int(consumed))g / \(Int(goal))g")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
        }
    }
}

struct TodaysActivityView: View {
    let exerciseLogs: [ExerciseLogItem]
    let foodLogs: [FoodLogItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Activity")
                .font(.headline)
            
            if !exerciseLogs.isEmpty {
                ForEach(exerciseLogs) { log in
                    ActivityRow(
                        title: log.exerciseType,
                        subtitle: "\(log.duration) min • \(log.caloriesBurned) cal",
                        icon: "figure.run",
                        color: .green
                    )
                }
            }
            
            if !foodLogs.isEmpty {
                ForEach(foodLogs) { log in
                    ActivityRow(
                        title: log.foodName,
                        subtitle: "\(log.mealType) • \(Int(log.calories)) cal",
                        icon: "fork.knife",
                        color: .blue
                    )
                }
            }
            
            if exerciseLogs.isEmpty && foodLogs.isEmpty {
                Text("No activities logged today")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

struct ActivityRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    DashboardPage()
}
