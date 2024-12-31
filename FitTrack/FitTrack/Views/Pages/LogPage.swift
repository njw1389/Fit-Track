//
//  LogPage.swift
//  FitTrack
//
//  Created by Nolan Wira on 11/5/24.
//

import SwiftUI
import HealthKit

struct LogPage: View {
    @State private var selectedDate = Date()
    @State private var selectedMonth = Calendar.current.component(.month, from: Date())
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    @State private var showingFoodEntry = false
    @State private var showingWeightEntry = false
    @State private var showingExerciseEntry = false
    @StateObject private var foodLogManager = FoodLogManager.shared
    @StateObject private var weightLogManager = WeightLogManager.shared
    @StateObject private var exerciseLogManager = ExerciseLogManager.shared
    @StateObject private var healthKitManager = HealthKitManager.shared
    @StateObject private var healthDataManager = HealthDataManager.shared
    @State private var foodLogs: [FoodLogItem] = []
    @State private var weightLogs: [WeightLogItem] = []
    @State private var exerciseLogs: [ExerciseLogItem] = []
    @State private var healthData: HealthDataItem?
    @State private var showingBarcodeScanner = false
    @State private var scannedFoodInfo: FoodScanResult?
    
    let months = Array(1...12)
    let years = Array((Calendar.current.component(.year, from: Date()) - 10)...Calendar.current.component(.year, from: Date()))
    
    // Helper function to calculate middle date of a month
    private func middleDateOfMonth(year: Int, month: Int) -> Date {
        let calendar = Calendar.current
        let components = DateComponents(year: year, month: month)
        guard let startOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: startOfMonth) else {
            return Date()
        }
        
        let middleDay = (range.count + 1) / 2
        let middleDayComponents = DateComponents(year: year, month: month, day: middleDay)
        return calendar.date(from: middleDayComponents) ?? Date()
    }
    
    // Helper function to check if a month/year is current
    private func isCurrentMonthAndYear(month: Int, year: Int) -> Bool {
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: Date())
        let currentYear = calendar.component(.year, from: Date())
        return month == currentMonth && year == currentYear
    }
    
    var calendarDays: [CalendarDay] {
        let calendar = Calendar.current
        let components = DateComponents(year: selectedYear, month: selectedMonth)
        guard let startOfMonth = calendar.date(from: components) else { return [] }
        
        var days: [CalendarDay] = []
        
        // Always show 5 days from previous month
        if let previousMonth = calendar.date(byAdding: .month, value: -1, to: startOfMonth),
           let daysInPreviousMonth = calendar.range(of: .day, in: .month, for: previousMonth)?.count {
            let startDay = daysInPreviousMonth - 4  // Show last 5 days
            for day in startDay...daysInPreviousMonth {
                let components = DateComponents(year: calendar.component(.year, from: previousMonth),
                                             month: calendar.component(.month, from: previousMonth),
                                             day: day)
                if let date = calendar.date(from: components) {
                    days.append(CalendarDay(date: date, isCurrentMonth: false))
                }
            }
        }
        
        // Current month days
        if let range = calendar.range(of: .day, in: .month, for: startOfMonth) {
            for day in range {
                let components = DateComponents(year: selectedYear, month: selectedMonth, day: day)
                if let date = calendar.date(from: components) {
                    days.append(CalendarDay(date: date, isCurrentMonth: true))
                }
            }
        }
        
        // Always show 5 days from next month
        if let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) {
            for day in 1...5 { // Show first 5 days
                let components = DateComponents(year: calendar.component(.year, from: nextMonth),
                                             month: calendar.component(.month, from: nextMonth),
                                             day: day)
                if let date = calendar.date(from: components) {
                    days.append(CalendarDay(date: date, isCurrentMonth: false))
                }
            }
        }
        
        return days
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Month and Year Selectors
            HStack(spacing: 16) {
                // Month Picker
                Menu {
                    Picker("Month", selection: $selectedMonth) {
                        ForEach(months, id: \.self) { month in
                            Text(Calendar.current.monthSymbols[month - 1])
                                .tag(month)
                        }
                    }
                } label: {
                    HStack {
                        Text(Calendar.current.monthSymbols[selectedMonth - 1])
                            .font(.system(size: 17, weight: .semibold))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
                }
                
                // Year Picker
                Menu {
                    Picker("Year", selection: $selectedYear) {
                        ForEach(years, id: \.self) { year in
                            Text(String(year))
                                .tag(year)
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedYear.formatted(.number.grouping(.never)))
                            .font(.system(size: 17, weight: .semibold))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
                }
            }
            .padding(.horizontal)
            
            // Calendar
            ScrollView(.horizontal, showsIndicators: false) {
                ScrollViewReader { proxy in
                    HStack(spacing: 8) {
                        ForEach(calendarDays, id: \.date) { calendarDay in
                            if calendarDay.isCurrentMonth {
                                DateButton(date: calendarDay.date,
                                           isSelected: Calendar.current.isDate(calendarDay.date, inSameDayAs: selectedDate)) {
                                    selectedDate = calendarDay.date
                                }
                                           .id(calendarDay.date)
                            } else {
                                // Greyed out, non-interactive days
                                VStack(spacing: 0) {
                                    Text(calendarDay.date.formatted(.dateTime.month(.abbreviated)))
                                        .font(.caption2)
                                    Text(calendarDay.date.formatted(.dateTime.weekday(.short)))
                                        .font(.caption)
                                    Text("\(Calendar.current.component(.day, from: calendarDay.date))")
                                        .font(.title2.bold())
                                }
                                .frame(width: 60)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray6))
                                .foregroundColor(Color(.systemGray3))
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .onAppear {
                        if let currentDate = calendarDays.first(where: { $0.isCurrentMonth && Calendar.current.isDate($0.date, inSameDayAs: Date()) }) {
                            withAnimation(.smooth) {
                                proxy.scrollTo(currentDate.date, anchor: .center)
                            }
                        }
                    }
                    .onChange(of: selectedDate) { oldValue, newValue in
                        withAnimation(.smooth) {
                            proxy.scrollTo(newValue, anchor: .center)
                        }
                    }
                    .onChange(of: selectedMonth) { oldValue, newValue in
                        withAnimation(.smooth) {
                            if isCurrentMonthAndYear(month: newValue, year: selectedYear) {
                                selectedDate = Date()
                                if let currentDate = calendarDays.first(where: {
                                    $0.isCurrentMonth && Calendar.current.isDate($0.date, inSameDayAs: Date())
                                }) {
                                    proxy.scrollTo(currentDate.date, anchor: .center)
                                }
                            } else {
                                selectedDate = middleDateOfMonth(year: selectedYear, month: newValue)
                            }
                        }
                    }
                    .onChange(of: selectedYear) { oldValue, newValue in
                        withAnimation(.smooth) {
                            if isCurrentMonthAndYear(month: selectedMonth, year: newValue) {
                                selectedDate = Date()
                                if let currentDate = calendarDays.first(where: {
                                    $0.isCurrentMonth && Calendar.current.isDate($0.date, inSameDayAs: Date())
                                }) {
                                    proxy.scrollTo(currentDate.date, anchor: .center)
                                }
                            } else {
                                selectedDate = middleDateOfMonth(year: newValue, month: selectedMonth)
                            }
                        }
                    }
                }
            }
            
            ScrollView {
                VStack(spacing: 16) {
                    if healthKitManager.isAuthorized {
                        HealthSectionView(healthData: healthData)
                    }
                    
                    // Weight Logs Section
                    if !weightLogs.isEmpty {
                        WeightLogSectionView(
                            logs: weightLogs,
                            selectedDate: selectedDate,
                            onDelete: {
                                Task {
                                    await loadData()
                                }
                            }
                        )
                    }
                    
                    // Exercise Logs Section
                    if !exerciseLogs.isEmpty {
                        ExerciseLogSectionView(
                            logs: exerciseLogs,
                            selectedDate: selectedDate,
                            onDelete: {
                                Task {
                                    await loadData()
                                }
                            }
                        )
                    }
                    
                    ForEach(getFoodLog(for: selectedDate)) { section in
                        MealSectionView(
                            section: section,
                            onDelete: {
                                Task {
                                    await loadData()
                                }
                            }
                        )
                    }
                }
                .padding()
            }
            
            // Food logging buttons
            HStack(spacing: 12) {
                Button(action: {
                    showingFoodEntry = true
                    scannedFoodInfo = nil
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Manual Entry")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(EdgeInsets(top: 16, leading: 0, bottom: 16, trailing: 0))
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                Button(action: {
                    scannedFoodInfo = nil
                    showingBarcodeScanner = true
                }) {
                    HStack {
                        Image(systemName: "barcode.viewfinder")
                        Text("Scan Food")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(EdgeInsets(top: 16, leading: 0, bottom: 16, trailing: 0))
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal)
            
            // Weight and Exercise buttons
            HStack(spacing: 12) {
                Button(action: {
                    showingWeightEntry = true
                }) {
                    HStack {
                        Image(systemName: "scalemass.fill")
                        Text("Record Weight")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(EdgeInsets(top: 16, leading: 0, bottom: 16, trailing: 0))
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                Button(action: {
                    showingExerciseEntry = true
                }) {
                    HStack {
                        Image(systemName: "figure.run")
                        Text("Record Exercise")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(EdgeInsets(top: 16, leading: 0, bottom: 16, trailing: 0))
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 10)
        .onChange(of: selectedDate) { oldValue, newValue in
            Task {
                await loadData()
            }
        }
        .onAppear {
            Task {
                await loadData()
            }
        }
        .sheet(isPresented: $showingBarcodeScanner) {
            BarcodeScannerView { foodResult in
                scannedFoodInfo = foodResult
                showingBarcodeScanner = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showingFoodEntry = true
                }
            }
        }
        .sheet(isPresented: $showingFoodEntry, onDismiss: {
            scannedFoodInfo = nil
        }) {
            if let scannedFood = scannedFoodInfo {
                if scannedFood.isEmptyResult {
                    FoodEntryView(date: selectedDate, scanResult: scannedFood) {Task { await loadData() }}
                } else {
                    ScannedFoodEntryView(date: selectedDate, foodInfo: scannedFood) {Task { await loadData() }}
                }
            } else {
                FoodEntryView(date: selectedDate, scanResult: nil) {Task { await loadData() }}
            }
        }
        .sheet(isPresented: $showingWeightEntry) {
            WeightEntryView(date: selectedDate) {Task { await loadData() }}
        }
        .sheet(isPresented: $showingExerciseEntry) {
            ExerciseEntryView(date: selectedDate) {Task { await loadData() }}
        }
    }
    
    private func loadData() async {
        // Load food logs
        do {
            foodLogs = try await FoodLogManager.shared.fetchFoodLogs(for: selectedDate)
        } catch {
            print("Error fetching food logs: \(error)")
            foodLogs = []
        }
        
        // Load weight logs
        do {
            weightLogs = try await weightLogManager.fetchWeightLogs(for: selectedDate)
        } catch {
            print("Error fetching weight logs: \(error)")
            weightLogs = []
        }
        
        // Load exercise logs
        do {
            exerciseLogs = try await exerciseLogManager.fetchExerciseLogs(for: selectedDate)
        } catch {
            print("Error fetching exercise logs: \(error)")
            exerciseLogs = []
        }
        
        // Load health data
        if healthKitManager.isAuthorized {
            if Calendar.current.isDateInToday(selectedDate) {
                do {
                    try await healthDataManager.saveHealthData(date: selectedDate)
                } catch {
                    print("Error saving health data: \(error)")
                }
            }
            
            do {
                healthData = try await healthDataManager.fetchHealthData(for: selectedDate)
            } catch {
                print("Error fetching health data: \(error)")
                healthData = nil
            }
        }
    }
    
    func getFoodLog(for date: Date) -> [MealSection] {
        let mealTypes = ["Breakfast", "Lunch", "Dinner", "Snacks"]
        
        return mealTypes.map { mealType in
            let items = foodLogs
                .filter { $0.mealType == mealType }
                .map { log in
                    FoodItem(
                        id: log.id,
                        name: log.foodName,
                        calories: Int(log.calories),
                        mealType: log.mealType,
                        protein: log.protein,
                        carbs: log.carbs,
                        fat: log.fat,
                        sugar: log.sugar,
                        fiber: log.fiber,
                        sodium: log.sodium
                    )
                }
            
            if items.isEmpty {
                return MealSection(
                    name: mealType,
                    items: [FoodItem(id: UUID().uuidString, name: "Not logged yet", calories: 0, mealType: mealType, protein: 0, carbs: 0, fat: 0, sugar: 0, fiber: 0, sodium: 0)]
                )
            }
            
            return MealSection(name: mealType, items: items)
        }
    }
}

struct DateButton: View {
    let date: Date
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                Text(date.formatted(.dateTime.month(.abbreviated)))
                    .font(.caption2)
                Text(date.formatted(.dateTime.weekday(.short)))
                    .font(.caption)
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.title2.bold())
                
                // Add the red circle indicator for the current day
                if Calendar.current.isDateInToday(date) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .offset(y: 0.5)
                }
            }
            .frame(width: 60)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(10)
        }
    }
}

// Models
struct MealSection: Identifiable {
    let id = UUID()
    let name: String
    let items: [FoodItem]
}

struct CalendarDay {
    let date: Date
    let isCurrentMonth: Bool
}

struct FoodItem: Identifiable {
    let id: String
    let name: String
    let calories: Int
    let mealType: String
    let protein: Double
    let carbs: Double
    let fat: Double
    let sugar: Double
    let fiber: Double
    let sodium: Double
}

#Preview {
    LogPage()
}
