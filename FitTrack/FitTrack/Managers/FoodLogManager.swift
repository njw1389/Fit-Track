//
//  FoodLogManager.swift
//  FitTrack
//
//  Created by Nolan Wira on 11/27/24.
//

import Firebase
import FirebaseDatabase
import FirebaseAuth
import WidgetKit

struct FoodLogItem: Identifiable {
    let id: String
    let date: Date
    let mealType: String
    let foodName: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let sugar: Double
    let fiber: Double
    let sodium: Double
}

class FoodLogManager: ObservableObject {
    static let shared = FoodLogManager()
    private let groupID = "group.wira.nolan.FitTrack"
    private let ref = Database.database().reference()
    private let auth = Auth.auth()
    private let userDefaults = UserDefaults(suiteName: "group.wira.nolan.FitTrack")
    
    @Published var foodItems: [FoodLogItem] = []
    @Published var currentUserId: String?
    
    private init() {
        if auth.currentUser == nil {
            auth.signInAnonymously { result, error in
                if let error = error {
                    print("Error signing in: \(error)")
                    return
                }
                if let user = result?.user {
                    self.currentUserId = user.uid
                    // Save to shared UserDefaults
                    self.userDefaults?.set(user.uid, forKey: "userId")
                    print("Main App: Saved user ID to shared defaults: \(user.uid)")
                }
            }
        } else {
            currentUserId = auth.currentUser?.uid
            // Save to shared UserDefaults
            userDefaults?.set(auth.currentUser?.uid, forKey: "userId")
            if let uid = auth.currentUser?.uid {
                print("Main App: Saved existing user ID to shared defaults: \(uid)")
            }
        }
    }
    
    func saveFoodItem(date: Date, mealType: String, foodName: String, calories: Double, protein: Double, carbs: Double, fat: Double, sugar: Double, fiber: Double, sodium: Double) async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user ID found"])
        }
        
        let dateString = formatDate(date)
        let foodItem: [String: Any] = [
            "date": dateString,
            "mealType": mealType,
            "foodName": foodName,
            "calories": calories,
            "protein": protein,
            "carbs": carbs,
            "fat": fat,
            "sugar": sugar,
            "fiber": fiber,
            "sodium": sodium,
            "userId": userId
        ]
        
        // Create a unique key for the food item under the user's branch
        let itemRef = ref.child("users").child(userId).child("foodLogs").childByAutoId()
        try await itemRef.setValue(foodItem)
        
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func fetchFoodLogs(for date: Date) async throws -> [FoodLogItem] {
        guard let userId = currentUserId else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user ID found"])
        }
        
        let dateString = formatDate(date)
        
        return try await withCheckedThrowingContinuation { continuation in
            ref.child("users").child(userId).child("foodLogs")
                .queryOrdered(byChild: "date")
                .queryEqual(toValue: dateString)
                .observeSingleEvent(of: .value) { snapshot in
                    var items: [FoodLogItem] = []
                    
                    for child in snapshot.children {
                        guard let snapshot = child as? DataSnapshot,
                              let dict = snapshot.value as? [String: Any],
                              let mealType = dict["mealType"] as? String,
                              let foodName = dict["foodName"] as? String,
                              let calories = dict["calories"] as? Double,
                              let protein = dict["protein"] as? Double,
                              let carbs = dict["carbs"] as? Double,
                              let fat = dict["fat"] as? Double,
                              let sugar = dict["sugar"] as? Double,
                              let fiber = dict["fiber"] as? Double,
                              let sodium = dict["sodium"] as? Double else {
                            continue
                        }
                        
                        let item = FoodLogItem(
                            id: snapshot.key,
                            date: date,
                            mealType: mealType,
                            foodName: foodName,
                            calories: calories,
                            protein: protein,
                            carbs: carbs,
                            fat: fat,
                            sugar: sugar,
                            fiber: fiber,
                            sodium: sodium
                        )
                        items.append(item)
                    }
                    
                    continuation.resume(returning: items)
                } withCancel: { error in
                    continuation.resume(throwing: error)
                }
        }
    }
    
    func deleteFoodLog(_ itemId: String) async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user ID found"])
        }
        
        try await ref.child("users").child(userId).child("foodLogs").child(itemId).removeValue()
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
