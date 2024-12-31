//
//  HealthDataManager.swift
//  FitTrack
//
//  Created by Nolan Wira on 12/3/24.
//

import Firebase
import FirebaseDatabase
import FirebaseAuth
import HealthKit

struct HealthDataItem: Identifiable {
    let id: String
    let date: Date
    let steps: Int
    let activeEnergy: Double
    let restingEnergy: Double
    let totalCaloriesBurned: Double
}

class HealthDataManager: ObservableObject {
    static let shared = HealthDataManager()
    private let ref = Database.database().reference()
    private let auth = Auth.auth()
    private let healthKitManager = HealthKitManager.shared
    
    @Published var healthData: [HealthDataItem] = []
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
                }
            }
        } else {
            currentUserId = auth.currentUser?.uid
        }
    }
    
    func saveHealthData(date: Date) async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user ID found"])
        }
        
        let dateString = formatDate(date)
        let healthData: [String: Any] = [
            "date": dateString,
            "steps": healthKitManager.steps,
            "activeEnergy": healthKitManager.activeEnergy,
            "restingEnergy": healthKitManager.restingEnergy,
            "totalCaloriesBurned": healthKitManager.totalCaloriesBurned,
            "userId": userId
        ]
        
        // Create a unique key for the health data under the user's branch
        let itemRef = ref.child("users").child(userId).child("healthData").child(dateString)
        try await itemRef.setValue(healthData)
    }
    
    func fetchHealthData(for date: Date) async throws -> HealthDataItem? {
        guard let userId = currentUserId else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user ID found"])
        }
        
        let dateString = formatDate(date)
        
        return try await withCheckedThrowingContinuation { continuation in
            ref.child("users").child(userId).child("healthData").child(dateString)
                .observeSingleEvent(of: .value) { snapshot in
                    guard let dict = snapshot.value as? [String: Any],
                          let steps = dict["steps"] as? Int,
                          let activeEnergy = dict["activeEnergy"] as? Double,
                          let restingEnergy = dict["restingEnergy"] as? Double,
                          let totalCaloriesBurned = dict["totalCaloriesBurned"] as? Double else {
                        continuation.resume(returning: nil)
                        return
                    }
                    
                    let item = HealthDataItem(
                        id: snapshot.key,
                        date: date,
                        steps: steps,
                        activeEnergy: activeEnergy,
                        restingEnergy: restingEnergy,
                        totalCaloriesBurned: totalCaloriesBurned
                    )
                    
                    continuation.resume(returning: item)
                }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
