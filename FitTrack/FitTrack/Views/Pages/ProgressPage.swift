//
//  ProgressPage.swift
//  FitTrack
//
//  Created by Nolan Wira on 12/3/24.
//

import SwiftUI
import HealthKit
import Charts

struct ProgressPage: View {
    @StateObject private var healthKitManager = HealthKitManager.shared
    @StateObject private var weightLogManager = WeightLogManager.shared
    @State private var selectedTimeFrame = TimeFrame.week
    @State private var weightLogs: [WeightLogItem] = []
    @State private var exerciseLogs: [ExerciseLogItem] = []
    
    enum TimeFrame: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case threeMonths = "3 Months"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Time frame selector
                    Picker("Time Frame", selection: $selectedTimeFrame) {
                        ForEach(TimeFrame.allCases, id: \.self) { timeFrame in
                            Text(timeFrame.rawValue).tag(timeFrame)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Weight Progress
                    WeightProgressView(weightLogs: weightLogs)
                    
                    // Activity Summary
                    ActivitySummaryView(
                        steps: healthKitManager.steps,
                        activeEnergy: healthKitManager.activeEnergy,
                        exerciseLogs: exerciseLogs
                    )
                }
                .padding()
            }
            .navigationTitle("Progress")
            .onAppear {
                Task {
                    await loadData()
                }
            }
            .onChange(of: selectedTimeFrame) { oldValue, newValue in
                Task {
                    await loadData()
                }
            }
        }
    }
    
    private func loadData() async {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate: Date
        
        switch selectedTimeFrame {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: endDate) ?? endDate
        case .threeMonths:
            startDate = calendar.date(byAdding: .month, value: -3, to: endDate) ?? endDate
        }
        
        // Load weight logs for each day in the range
        var currentDate = startDate
        var logs: [WeightLogItem] = []
        var exercises: [ExerciseLogItem] = []
        
        while currentDate <= endDate {
            do {
                if let dayLogs = try await weightLogManager.fetchWeightLogs(for: currentDate).first {
                    logs.append(dayLogs)
                }
                let dayExercises = try await ExerciseLogManager.shared.fetchExerciseLogs(for: currentDate)
                exercises.append(contentsOf: dayExercises)
            } catch {
                print("Error loading logs: \(error)")
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? endDate
        }
        
        weightLogs = logs.sorted(by: { $0.date < $1.date })
        exerciseLogs = exercises.sorted(by: { $0.date < $1.date })
    }
}

struct WeightProgressView: View {
    let weightLogs: [WeightLogItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weight Progress")
                .font(.headline)
            
            if weightLogs.isEmpty {
                Text("No weight logs for selected period")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                // Weight Chart
                Chart {
                    ForEach(weightLogs) { log in
                        LineMark(
                            x: .value("Date", log.date),
                            y: .value("Weight", log.weight)
                        )
                        .foregroundStyle(.blue)
                        
                        PointMark(
                            x: .value("Date", log.date),
                            y: .value("Weight", log.weight)
                        )
                        .foregroundStyle(.blue)
                    }
                }
                .frame(height: 200)
                
                // Stats
                HStack {
                    if let firstWeight = weightLogs.first?.weight,
                       let lastWeight = weightLogs.last?.weight {
                        let change = lastWeight - firstWeight
                        StatCard(
                            title: "Total Change",
                            value: String(format: "%.1f lbs", abs(change)),
                            trend: change >= 0 ? "↑" : "↓",
                            trendColor: change >= 0 ? .red : .green
                        )
                    }
                    
                    if let averageWeight = weightLogs.map({ $0.weight }).average {
                        StatCard(
                            title: "Average",
                            value: String(format: "%.1f lbs", averageWeight)
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct ActivitySummaryView: View {
    let steps: Int
    let activeEnergy: Double
    let exerciseLogs: [ExerciseLogItem]
    
    var totalExerciseMinutes: Int {
        exerciseLogs.reduce(0) { $0 + $1.duration }
    }
    
    var totalCaloriesBurned: Int {
        exerciseLogs.reduce(0) { $0 + $1.caloriesBurned }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Activity Summary")
                .font(.headline)
            
            HStack(spacing: 20) {
                StatCard(
                    title: "Steps",
                    value: "\(steps)",
                    icon: "figure.walk"
                )
                
                StatCard(
                    title: "Exercise",
                    value: "\(totalExerciseMinutes) min",
                    icon: "figure.run"
                )
                
                StatCard(
                    title: "Calories",
                    value: "\(Int(activeEnergy + Double(totalCaloriesBurned)))",
                    icon: "flame.fill"
                )
            }
            
            if !exerciseLogs.isEmpty {
                Text("Recent Exercises")
                    .font(.subheadline)
                    .padding(.top)
                
                ForEach(exerciseLogs.prefix(5)) { log in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(log.exerciseType)
                                .font(.subheadline)
                            Text("\(log.duration) min • \(log.caloriesBurned) cal • \(log.intensity)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(log.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    var icon: String? = nil
    var trend: String? = nil
    var trendColor: Color = .blue
    
    var body: some View {
        VStack(spacing: 8) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            if let trend = trend {
                Text(trend)
                    .font(.caption)
                    .foregroundColor(trendColor)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}

extension Array where Element == Double {
    var average: Double? {
        guard !isEmpty else { return nil }
        return reduce(0, +) / Double(count)
    }
}

#Preview {
    ProgressPage()
}
