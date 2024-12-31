//
//  WeightEntryView.swift
//  FitTrack
//
//  Created by Nolan Wira on 12/6/24.
//

import SwiftUI

struct WeightEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var weight = ""
    @State private var note = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    let date: Date
    var onSave: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Weight")) {
                    HStack {
                        TextField("Enter weight", text: $weight)
                            .keyboardType(.decimalPad)
                        Text("lbs")
                    }
                }
                
                Section(header: Text("Note (Optional)")) {
                    TextField("Add a note", text: $note)
                }
            }
            .navigationTitle("Record Weight")
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
                            await saveWeight()
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
    
    private func saveWeight() async {
        guard let weightValue = Double(weight) else {
            errorMessage = "Please enter a valid weight"
            showingError = true
            return
        }
        
        do {
            try await WeightLogManager.shared.saveWeightLog(
                date: date,
                weight: weightValue,
                note: note.isEmpty ? nil : note
            )
            onSave()
            dismiss()
        } catch {
            errorMessage = "Failed to save weight: \(error.localizedDescription)"
            showingError = true
        }
    }
}

#Preview {
    WeightEntryView(date: Date(), onSave: {})
}
