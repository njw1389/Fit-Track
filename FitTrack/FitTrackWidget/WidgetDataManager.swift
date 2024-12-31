//
//  WidgetDataManager.swift
//  FitTrack
//
//  Created by Nolan Wira on 11/28/24.
//

import Foundation
import FirebaseDatabase
import FirebaseAuth

class WidgetDataManager {
    static let shared = WidgetDataManager()
    private let ref = Database.database().reference()
    private let auth = Auth.auth()
    private let userDefaults = UserDefaults(suiteName: "group.wira.nolan.FitTrack")
    
    // Fetch both macro goals and current macros
    func fetchWidgetData() async throws -> MacroEntry {
        let userId = try await getCurrentUserId()
        
        async let macros = fetchTodaysMacros(userId: userId)
        async let goals = fetchMacroGoals(userId: userId)
        
        let (currentMacros, macroGoals) = try await (macros, goals)
        
        // Check if this is an empty day (no foods logged)
        let isEmptyDay = currentMacros.calories == 0 &&
                        currentMacros.netCarbs == 0 &&
                        currentMacros.fat == 0 &&
                        currentMacros.protein == 0
        
        return MacroEntry(
            date: Date(),
            netCarbs: currentMacros.netCarbs,
            fat: currentMacros.fat,
            protein: currentMacros.protein,
            carbsGoal: Double(macroGoals.carbs),
            fatGoal: Double(macroGoals.fat),
            proteinGoal: Double(macroGoals.protein),
            calories: currentMacros.calories,
            calorieGoal: Double(macroGoals.calories),
            hasError: false,
            isEmptyDay: isEmptyDay
        )
    }
    
    private func getCurrentUserId() async throws -> String {
        // First try to get the ID from shared UserDefaults
        if let sharedUserId = userDefaults?.string(forKey: "userId") {
            print("Widget: Retrieved shared user ID: \(sharedUserId)")
            return sharedUserId
        }
        
        print("Widget: No shared user ID found, this shouldn't happen!")
        throw NSError(domain: "", code: -1,
                     userInfo: [NSLocalizedDescriptionKey: "No shared user ID found"])
    }

    private func fetchTodaysMacros(userId: String) async throws -> (netCarbs: Double, fat: Double, protein: Double, calories: Double) {
        print("WidgetDataManager: Fetching today's macros for user: \(userId)")
        return try await withCheckedThrowingContinuation { continuation in
            let dateString = formatDate(Date())
            
            ref.child("users").child(userId).child("foodLogs")
                .queryOrdered(byChild: "date")
                .queryEqual(toValue: dateString)
                .observeSingleEvent(of: .value) { snapshot in
                    print("WidgetDataManager: Full snapshot: \(snapshot.value ?? "nil")")
                    print("WidgetDataManager: Children count: \(snapshot.childrenCount)")
                    
                    var totalNetCarbs = 0.0
                    var totalFat = 0.0
                    var totalProtein = 0.0
                    var totalCalories = 0.0
                    
                    for child in snapshot.children {
                        guard let snapshot = child as? DataSnapshot,
                              let dict = snapshot.value as? [String: Any] else {
                            print("WidgetDataManager: Failed to parse snapshot child")
                            continue
                        }
                        
                        print("WidgetDataManager: Processing food log entry: \(dict)")
                        
                        if let carbs = dict["carbs"] as? Double,
                           let fat = dict["fat"] as? Double,
                           let protein = dict["protein"] as? Double,
                           let calories = dict["calories"] as? Double {
                            totalNetCarbs += carbs
                            totalFat += fat
                            totalProtein += protein
                            totalCalories += calories
                        }
                    }
                    
                    print("WidgetDataManager: Final totals - Carbs: \(totalNetCarbs), Fat: \(totalFat), Protein: \(totalProtein), Calories: \(totalCalories)")
                    continuation.resume(returning: (totalNetCarbs, totalFat, totalProtein, totalCalories))
                } withCancel: { error in
                    print("WidgetDataManager: Error fetching macros: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
        }
    }

    private func fetchMacroGoals(userId: String) async throws -> MacroGoals {
        print("WidgetDataManager: Fetching macro goals for user: \(userId)")
        return try await withCheckedThrowingContinuation { continuation in
            ref.child("users").child(userId).child("profile").child("macroGoals")
                .observeSingleEvent(of: .value) { snapshot in
                    print("WidgetDataManager: Received macro goals snapshot: \(snapshot.value ?? "nil")")
                    
                    guard let dict = snapshot.value as? [String: Any] else {
                        print("WidgetDataManager: No profile exists, using default values")
                        continuation.resume(returning: MacroGoals())
                        return
                    }
                    
                    let macroGoals = MacroGoals(
                        calories: dict["calories"] as? Int ?? 2000,
                        protein: dict["protein"] as? Int ?? 150,
                        carbs: dict["carbs"] as? Int ?? 250,
                        fat: dict["fat"] as? Int ?? 65,
                        weightGoal: dict["weightGoal"] as? Int ?? 150
                    )
                    
                    print("WidgetDataManager: Successfully parsed macro goals: \(macroGoals)")
                    continuation.resume(returning: macroGoals)
                } withCancel: { error in
                    print("WidgetDataManager: Error fetching macro goals: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
