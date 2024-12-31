//
//  MacroWidget.swift
//  FitTrack
//
//  Created by Nolan Wira on 11/28/24.
//

import WidgetKit
import SwiftUI
import FirebaseCore
import FirebaseAuth

struct ErrorOverlayView: View {
    let message: String
    let systemImage: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
            
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                
                Text(message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
        }
    }
}

struct MacroEntry: TimelineEntry {
    let date: Date
    let netCarbs: Double
    let fat: Double
    let protein: Double
    let carbsGoal: Double
    let fatGoal: Double
    let proteinGoal: Double
    let calories: Double
    let calorieGoal: Double
    let hasError: Bool
    let isEmptyDay: Bool
    
    static func placeholder() -> MacroEntry {
        MacroEntry(
            date: Date(),
            netCarbs: 0, fat: 0, protein: 0,
            carbsGoal: 201, fatGoal: 64, proteinGoal: 230,
            calories: 0, calorieGoal: 2000,
            hasError: false,
            isEmptyDay: false
        )
    }
    
    static func error() -> MacroEntry {
        MacroEntry(
            date: Date(),
            netCarbs: 0, fat: 0, protein: 0,
            carbsGoal: 201, fatGoal: 64, proteinGoal: 230,
            calories: 0, calorieGoal: 2000,
            hasError: true,
            isEmptyDay: false
        )
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> MacroEntry {
        MacroEntry.placeholder()
    }

    func getSnapshot(in context: Context, completion: @escaping (MacroEntry) -> ()) {
        let entry = MacroEntry(
            date: Date(),
            netCarbs: 45, fat: 20, protein: 65,
            carbsGoal: 201, fatGoal: 64, proteinGoal: 230,
            calories: 850, calorieGoal: 2000,
            hasError: false,
            isEmptyDay: false
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MacroEntry>) -> ()) {
        Task {
            do {
                let currentDate = Date()
                let widgetData = try await WidgetDataManager.shared.fetchWidgetData()
                
                // Check if this is an empty day (no foods logged)
                let isEmptyDay = widgetData.calories == 0 &&
                                widgetData.netCarbs == 0 &&
                                widgetData.fat == 0 &&
                                widgetData.protein == 0
                
                let entry = MacroEntry(
                    date: widgetData.date,
                    netCarbs: widgetData.netCarbs,
                    fat: widgetData.fat,
                    protein: widgetData.protein,
                    carbsGoal: widgetData.carbsGoal,
                    fatGoal: widgetData.fatGoal,
                    proteinGoal: widgetData.proteinGoal,
                    calories: widgetData.calories,
                    calorieGoal: widgetData.calorieGoal,
                    hasError: false,
                    isEmptyDay: isEmptyDay
                )
                
                let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate)!
                let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
                completion(timeline)
                
            } catch {
                print("Widget: Error fetching data: \(error)")
                let entry = MacroEntry.error()
                let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(300)))
                completion(timeline)
            }
        }
    }
}

struct MacroProgressCircle: View {
    let value: Double
    let total: Double
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: CGFloat(min(value / total, 1.0)))
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(Int(value))")
                        .font(.system(size: 16, weight: .bold))
                    Text("/\(Int(total))g")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
            }
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(color)
            
            Text("\(Int(total - value))g left")
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
    }
}

struct CalorieProgressBar: View {
    let calories: Double
    let goal: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Calories")
                    .font(.system(size: 12, weight: .medium))
                Spacer()
                Text("\(Int(calories))/\(Int(goal))")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * CGFloat(min(calories / goal, 1.0)), height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)
        }
    }
}

struct MacroWidgetEntryView: View {
    var entry: MacroEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            // Base widget content
            VStack(spacing: 12) {
                HStack(spacing: 20) {
                    MacroProgressCircle(value: entry.netCarbs, total: entry.carbsGoal,
                                      title: "Net Carbs", color: .cyan)
                    MacroProgressCircle(value: entry.fat, total: entry.fatGoal,
                                      title: "Fat", color: .purple)
                    MacroProgressCircle(value: entry.protein, total: entry.proteinGoal,
                                      title: "Protein", color: .yellow)
                }
                .padding(.horizontal, 8)
                
                CalorieProgressBar(calories: entry.calories, goal: entry.calorieGoal)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }
            .padding(.top, 12)
            
            // Error overlay
            if entry.hasError {
                ErrorOverlayView(
                    message: "There was a problem reading your data",
                    systemImage: "exclamationmark.triangle.fill"
                )
            }
            // Empty day overlay
            else if entry.isEmptyDay {
                ErrorOverlayView(
                    message: "No foods logged today",
                    systemImage: "fork.knife"
                )
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct MacroWidget: Widget {
    let kind: String = "MacroWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            MacroWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Macro Tracker")
        .description("Track your daily macros and calories.")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}

#Preview(as: .systemMedium) {
    MacroWidget()
} timeline: {
    MacroEntry(
        date: Date(),
        netCarbs: 45, fat: 20, protein: 65,
        carbsGoal: 201, fatGoal: 64, proteinGoal: 230,
        calories: 850, calorieGoal: 2000,
        hasError: false,
        isEmptyDay: false
    )
    MacroEntry(
        date: Date(),
        netCarbs: 0, fat: 0, protein: 0,
        carbsGoal: 201, fatGoal: 64, proteinGoal: 230,
        calories: 0, calorieGoal: 2000,
        hasError: false,
        isEmptyDay: true
    )
    MacroEntry(
        date: Date(),
        netCarbs: 0, fat: 0, protein: 0,
        carbsGoal: 201, fatGoal: 64, proteinGoal: 230,
        calories: 0, calorieGoal: 2000,
        hasError: true,
        isEmptyDay: false
    )
}
