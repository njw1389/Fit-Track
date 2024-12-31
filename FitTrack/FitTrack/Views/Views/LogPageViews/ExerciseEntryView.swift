//
//  ExerciseEntryView.swift
//  FitTrack
//
//  Created by Nolan Wira on 12/6/24.
//

import SwiftUI

struct ExerciseEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var exerciseType = ""
    @State private var duration = ""
    @State private var caloriesBurned = ""
    @State private var selectedIntensity = "Medium"
    @State private var note = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    let date: Date
    let intensityOptions = ["Low", "Medium", "High"]
    var onSave: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Exercise Details")) {
                    TextField("Exercise Type", text: $exerciseType)
                    
                    HStack {
                        TextField("Duration", text: $duration)
                            .keyboardType(.numberPad)
                        Text("minutes")
                    }
                    
                    HStack {
                        TextField("Calories Burned", text: $caloriesBurned)
                            .keyboardType(.numberPad)
                        Text("calories")
                    }
                    
                    Picker("Intensity", selection: $selectedIntensity) {
                        ForEach(intensityOptions, id: \.self) { intensity in
                            Text(intensity).tag(intensity)
                        }
                    }
                }
                
                Section(header: Text("Note (Optional)")) {
                    TextField("Add a note", text: $note)
                }
            }
            .navigationTitle("Record Exercise")
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
                            await saveExercise()
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
    
    private func saveExercise() async {
        guard !exerciseType.isEmpty else {
            errorMessage = "Please enter an exercise type"
            showingError = true
            return
        }
        
        guard let durationValue = Int(duration) else {
            errorMessage = "Please enter a valid duration"
            showingError = true
            return
        }
        
        guard let caloriesValue = Int(caloriesBurned) else {
            errorMessage = "Please enter valid calories burned"
            showingError = true
            return
        }
        
        do {
            try await ExerciseLogManager.shared.saveExerciseLog(
                date: date,
                exerciseType: exerciseType,
                duration: durationValue,
                caloriesBurned: caloriesValue,
                intensity: selectedIntensity,
                note: note.isEmpty ? nil : note
            )
            onSave()
            dismiss()
        } catch {
            errorMessage = "Failed to save exercise: \(error.localizedDescription)"
            showingError = true
        }
    }
}

#Preview {
    ExerciseEntryView(date: Date(), onSave: {})
}
