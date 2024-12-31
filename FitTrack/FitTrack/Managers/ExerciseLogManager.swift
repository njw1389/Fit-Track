//
//  ExerciseLogManager.swift
//  FitTrack
//
//  Created by Nolan Wira on 12/6/24.
//

import Firebase
import FirebaseDatabase
import FirebaseAuth
import WidgetKit

struct ExerciseLogItem: Identifiable {
    let id: String
    let date: Date
    let exerciseType: String
    let duration: Int // in minutes
    let caloriesBurned: Int
    let intensity: String // "Low", "Medium", "High"
    let note: String?
}

class ExerciseLogManager: ObservableObject {
    static let shared = ExerciseLogManager()
    private let ref = Database.database().reference()
    private let auth = Auth.auth()
    
    @Published var exerciseItems: [ExerciseLogItem] = []
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
    
    func saveExerciseLog(date: Date, exerciseType: String, duration: Int, caloriesBurned: Int, intensity: String, note: String? = nil) async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user ID found"])
        }
        
        let dateString = formatDate(date)
        var exerciseItem: [String: Any] = [
            "date": dateString,
            "exerciseType": exerciseType,
            "duration": duration,
            "caloriesBurned": caloriesBurned,
            "intensity": intensity,
            "userId": userId
        ]
        
        if let note = note {
            exerciseItem["note"] = note
        }
        
        let itemRef = ref.child("users").child(userId).child("exerciseLogs").childByAutoId()
        try await itemRef.setValue(exerciseItem)
    }
    
    func fetchExerciseLogs(for date: Date) async throws -> [ExerciseLogItem] {
        guard let userId = currentUserId else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user ID found"])
        }
        
        let dateString = formatDate(date)
        
        return try await withCheckedThrowingContinuation { continuation in
            ref.child("users").child(userId).child("exerciseLogs")
                .queryOrdered(byChild: "date")
                .queryEqual(toValue: dateString)
                .observeSingleEvent(of: .value) { snapshot in
                    var items: [ExerciseLogItem] = []
                    
                    for child in snapshot.children {
                        guard let snapshot = child as? DataSnapshot,
                              let dict = snapshot.value as? [String: Any],
                              let exerciseType = dict["exerciseType"] as? String,
                              let duration = dict["duration"] as? Int,
                              let caloriesBurned = dict["caloriesBurned"] as? Int,
                              let intensity = dict["intensity"] as? String else {
                            continue
                        }
                        
                        let note = dict["note"] as? String
                        
                        let item = ExerciseLogItem(
                            id: snapshot.key,
                            date: date,
                            exerciseType: exerciseType,
                            duration: duration,
                            caloriesBurned: caloriesBurned,
                            intensity: intensity,
                            note: note
                        )
                        items.append(item)
                    }
                    
                    continuation.resume(returning: items)
                } withCancel: { error in
                    continuation.resume(throwing: error)
                }
        }
    }
    
    func deleteExerciseLog(_ itemId: String) async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user ID found"])
        }
        
        try await ref.child("users").child(userId).child("exerciseLogs").child(itemId).removeValue()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
