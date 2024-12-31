//
//  ScannedFoodEntryView.swift
//  FitTrack
//
//  Created by Nolan Wira on 11/28/24.
//

import SwiftUI

struct ScannedFoodEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMeal = "Breakfast"
    @State private var showingError = false
    @State private var errorMessage = ""
    
    let mealOptions = ["Breakfast", "Lunch", "Dinner", "Snacks"]
    let date: Date
    let foodInfo: FoodScanResult
    var onSave: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Meal Details")) {
                    Picker("Meal", selection: $selectedMeal) {
                        ForEach(mealOptions, id: \.self) { meal in
                            Text(meal).tag(meal)
                        }
                    }
                    
                    HStack {
                        Text("Food Name")
                        Spacer()
                        Text(foodInfo.name)
                            .foregroundColor(.secondary)
                        
                    }
                }
                
                Section(header: Text("Nutrition Facts")) {
                    HStack {
                        Text("Calories")
                        Spacer()
                        Text("\(Int(foodInfo.calories))")
                            .foregroundColor(.secondary)
                        Text("kcal")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Protein")
                        Spacer()
                        Text(String(format: "%.1f", foodInfo.protein))
                            .foregroundColor(.secondary)
                        Text("g")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Carbohydrates")
                        Spacer()
                        Text(String(format: "%.1f", foodInfo.carbs))
                            .foregroundColor(.secondary)
                        Text("g")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Fat")
                        Spacer()
                        Text(String(format: "%.1f", foodInfo.fat))
                            .foregroundColor(.secondary)
                        Text("g")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Sugar")
                        Spacer()
                        Text(String(format: "%.1f", foodInfo.sugar))
                            .foregroundColor(.secondary)
                        Text("g")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Fiber")
                        Spacer()
                        Text(String(format: "%.1f", foodInfo.fiber))
                            .foregroundColor(.secondary)
                        Text("g")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Sodium")
                        Spacer()
                        Text(String(format: "%.1f", foodInfo.sodium))
                            .foregroundColor(.secondary)
                        Text("mg")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Scanned Food Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await saveFoodLog()
                        }
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .dismissKeyboardOnTap()
        }
    }
    
    private func saveFoodLog() async {
        do {
            try await FoodLogManager.shared.saveFoodItem(
                date: date,
                mealType: selectedMeal,
                foodName: foodInfo.name,
                calories: foodInfo.calories,
                protein: foodInfo.protein,
                carbs: foodInfo.carbs,
                fat: foodInfo.fat,
                sugar: foodInfo.sugar,
                fiber: foodInfo.fiber,
                sodium: foodInfo.sodium
            )
            onSave()
            dismiss()
        } catch {
            errorMessage = "Failed to save food log: \(error.localizedDescription)"
            showingError = true
        }
    }
}
