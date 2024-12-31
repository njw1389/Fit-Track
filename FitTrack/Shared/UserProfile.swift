//
//  UserProfile.swift
//  FitTrack
//
//  Created by Nolan Wira on 12/3/24.
//

import Foundation
import FirebaseDatabase
import FirebaseAuth
import WidgetKit

struct UserProfile: Codable {
    var heightFeet: Int
    var heightInches: Int
    var age: Int
    var gender: String
    var macroGoals: MacroGoals
    
    init(heightFeet: Int = 5, heightInches: Int = 8, age: Int = 25, gender: String = "Not Specified",
         macroGoals: MacroGoals = MacroGoals()) {
        self.heightFeet = heightFeet
        self.heightInches = heightInches
        self.age = age
        self.gender = gender
        self.macroGoals = macroGoals
    }
}

struct MacroGoals: Codable {
    var calories: Int
    var protein: Int
    var carbs: Int
    var fat: Int
    var weightGoal: Int
    
    init(calories: Int = 2000, protein: Int = 150, carbs: Int = 250, fat: Int = 65, weightGoal: Int = 150) {
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.weightGoal = weightGoal
    }
}

class UserProfileManager: ObservableObject {
    static let shared = UserProfileManager()
    private let ref = Database.database().reference()
    private let auth = Auth.auth()
    
    @Published var profile = UserProfile()
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
                    self.fetchProfile()
                }
            }
        } else {
            currentUserId = auth.currentUser?.uid
            fetchProfile()
        }
    }
    
    func saveProfile() async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user ID found"])
        }
        
        let profileData: [String: Any] = [
            "heightFeet": profile.heightFeet,
            "heightInches": profile.heightInches,
            "age": profile.age,
            "gender": profile.gender,
            "macroGoals": [
                "calories": profile.macroGoals.calories,
                "protein": profile.macroGoals.protein,
                "carbs": profile.macroGoals.carbs,
                "fat": profile.macroGoals.fat,
                "weightGoal": profile.macroGoals.weightGoal
            ]
        ]
        
        try await ref.child("users").child(userId).child("profile").setValue(profileData)
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func fetchProfile() {
        guard let userId = currentUserId else { return }
        
        ref.child("users").child(userId).child("profile").observe(.value) { [weak self] snapshot in
            guard let dict = snapshot.value as? [String: Any] else { return }
            
            let heightFeet = dict["heightFeet"] as? Int ?? 5
            let heightInches = dict["heightInches"] as? Int ?? 8
            let age = dict["age"] as? Int ?? 25
            let gender = dict["gender"] as? String ?? "Not Specified"
            
            let macroDict = dict["macroGoals"] as? [String: Any]
            let macroGoals = MacroGoals(
                calories: macroDict?["calories"] as? Int ?? 2000,
                protein: macroDict?["protein"] as? Int ?? 150,
                carbs: macroDict?["carbs"] as? Int ?? 250,
                fat: macroDict?["fat"] as? Int ?? 65,
                weightGoal: macroDict?["weightGoal"] as? Int ?? 150
            )
            
            DispatchQueue.main.async {
                self?.profile = UserProfile(
                    heightFeet: heightFeet,
                    heightInches: heightInches,
                    age: age,
                    gender: gender,
                    macroGoals: macroGoals
                )
            }
        }
    }
}
