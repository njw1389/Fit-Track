//
//  ExerciseLogSectionView.swift
//  FitTrack
//
//  Created by Nolan Wira on 12/9/24.
//

import SwiftUI

struct ExerciseLogSectionView: View {
    let logs: [ExerciseLogItem]
    let selectedDate: Date
    @State private var showingDeleteAlert = false
    @State private var selectedItem: ExerciseLogItem?
    
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Exercise Log")
                .font(.headline)
            
            ForEach(logs) { log in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        VStack(alignment: .leading) {
                            HStack {
                                Text(log.exerciseType)
                                    .font(.subheadline)
                                Spacer()
                                Text("\(log.caloriesBurned) cal")
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("\(log.duration) min")
                                Text("•")
                                Text(log.intensity)
                                if let note = log.note {
                                    Text("•")
                                    Text(note)
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Delete Button
                        Button(action: {
                            selectedItem = log
                            showingDeleteAlert = true
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .padding(.leading, 8)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
        .alert("Delete Exercise Entry", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let item = selectedItem {
                    Task {
                        try? await ExerciseLogManager.shared.deleteExerciseLog(item.id)
                        onDelete()
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this exercise entry?")
        }
    }
}
