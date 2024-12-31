//
//  WeightLogManager.swift
//  FitTrack
//
//  Created by Nolan Wira on 12/6/24.
//

import Firebase
import FirebaseDatabase
import FirebaseAuth
import WidgetKit

struct WeightLogItem: Identifiable {
    let id: String
    let date: Date
    let timestamp: Date
    let weight: Double
    let note: String?
}

class WeightLogManager: ObservableObject {
    static let shared = WeightLogManager()
    private let ref = Database.database().reference()
    private let auth = Auth.auth()
    
    @Published var weightItems: [WeightLogItem] = []
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
    
    func saveWeightLog(date: Date, weight: Double, note: String? = nil) async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user ID found"])
        }
        
        let dateString = formatDate(date)
        let timestamp = Date()  // Current timestamp
        var weightItem: [String: Any] = [
            "date": dateString,
            "timestamp": timestamp.timeIntervalSince1970,  // Store as Unix timestamp
            "weight": weight,
            "userId": userId
        ]
        
        if let note = note {
            weightItem["note"] = note
        }
        
        let itemRef = ref.child("users").child(userId).child("weightLogs").childByAutoId()
        try await itemRef.setValue(weightItem)
    }
    
    func fetchWeightLogs(for date: Date) async throws -> [WeightLogItem] {
        guard let userId = currentUserId else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user ID found"])
        }
        
        let dateString = formatDate(date)
        
        return try await withCheckedThrowingContinuation { continuation in
            ref.child("users").child(userId).child("weightLogs")
                .queryOrdered(byChild: "date")
                .queryEqual(toValue: dateString)
                .observeSingleEvent(of: .value) { snapshot in
                    var items: [WeightLogItem] = []
                    
                    for child in snapshot.children {
                        guard let snapshot = child as? DataSnapshot,
                              let dict = snapshot.value as? [String: Any],
                              let weight = dict["weight"] as? Double,
                              let timestampDouble = dict["timestamp"] as? Double else {
                            continue
                        }
                        
                        let timestamp = Date(timeIntervalSince1970: timestampDouble)
                        let note = dict["note"] as? String
                        
                        let item = WeightLogItem(
                            id: snapshot.key,
                            date: date,
                            timestamp: timestamp,
                            weight: weight,
                            note: note
                        )
                        items.append(item)
                    }
                    
                    // Sort by timestamp
                    items.sort { $0.timestamp > $1.timestamp }
                    continuation.resume(returning: items)
                }
        }
    }
    
    func deleteWeightLog(_ itemId: String) async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user ID found"])
        }
        
        try await ref.child("users").child(userId).child("weightLogs").child(itemId).removeValue()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
