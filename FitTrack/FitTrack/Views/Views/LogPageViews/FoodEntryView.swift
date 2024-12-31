//
//  FoodEntryView.swift
//  FitTrack
//
//  Created by Nolan Wira on 11/27/24.
//

import SwiftUI

struct FoodEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMeal = "Breakfast"
    @State private var foodName = ""
    @State private var servingSize = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var sugar = ""
    @State private var fiber = ""
    @State private var sodium = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showEmptyScanAlert = false
    
    let mealOptions = ["Breakfast", "Lunch", "Dinner", "Snacks"]
    let date: Date
    let scanResult: FoodScanResult?
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
                    TextField("Food Name", text: $foodName)
                }
                
                Section(header: Text("Nutrition Facts")) {
                    HStack {
                        Text("Calories")
                        Spacer()
                        TextField("0", text: $calories)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        Text("kcal")
                    }
                    
                    HStack {
                        Text("Protein")
                        Spacer()
                        TextField("0", text: $protein)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("g")
                    }
                    
                    HStack {
                        Text("Carbohydrates")
                        Spacer()
                        TextField("0", text: $carbs)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("g")
                    }
                    
                    HStack {
                        Text("Fat")
                        Spacer()
                        TextField("0", text: $fat)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("g")
                    }
                    
                    HStack {
                        Text("Sugar")
                        Spacer()
                        TextField("0", text: $sugar)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("g")
                    }
                    
                    HStack {
                        Text("Fiber")
                        Spacer()
                        TextField("0", text: $fiber)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("g")
                    }
                    
                    HStack {
                        Text("Sodium")
                        Spacer()
                        TextField("0", text: $sodium)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("mg")
                    }
                }
            }
            .navigationTitle("Log Your Intake")
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
            .alert("No Product Found", isPresented: $showEmptyScanAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("The scanned product was not found in the database. Please enter the details manually.")
            }
            .onAppear {
                if let result = scanResult, result.isEmptyResult {
                    showEmptyScanAlert = true
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
        guard !foodName.isEmpty else {
            showError("Please enter a food name")
            return
        }
        
        guard let caloriesInt = Double(calories),
              let proteinDouble = Double(protein),
              let carbsDouble = Double(carbs),
              let fatDouble = Double(fat),
              let sugarDouble = Double(sugar),
              let fiberDouble = Double(fiber),
              let sodiumDouble = Double(sodium) else {
            showError("Please enter valid numbers for nutrition values")
            return
        }
        
        do {
            try await FoodLogManager.shared.saveFoodItem(
                date: date,
                mealType: selectedMeal,
                foodName: foodName,
                calories: caloriesInt,
                protein: proteinDouble,
                carbs: carbsDouble,
                fat: fatDouble,
                sugar: sugarDouble,
                fiber: fiberDouble,
                sodium: sodiumDouble
            )
            onSave()
            dismiss()
        } catch {
            showError("Failed to save food log: \(error.localizedDescription)")
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

#Preview {
    FoodEntryView(date: Date(), scanResult: nil, onSave: {})
}
