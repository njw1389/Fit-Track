//
//  MealSectionView.swift
//  FitTrack
//
//  Created by Nolan Wira on 12/9/24.
//

import SwiftUI

struct MealSectionView: View {
    let section: MealSection
    @State private var showingDeleteAlert = false
    @State private var selectedItem: FoodItem?
    @Environment(\.dismiss) private var dismiss
    
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(section.name)
                .font(.headline)
            
            ForEach(section.items) { item in
                if item.name != "Not logged yet" {
                    HStack {
                        Text(item.name)
                        Spacer()
                        Text("\(item.calories) cal")
                            .foregroundColor(.secondary)
                        
                        // Delete Button
                        Button(action: {
                            selectedItem = item
                            showingDeleteAlert = true
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .padding(.leading, 8)
                    }
                    .padding(.vertical, 4)
                } else {
                    HStack {
                        Text(item.name)
                        Spacer()
                        Text("\(item.calories) cal")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
        .alert("Delete Food Item", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let item = selectedItem {
                    Task {
                        do {
                            try await FoodLogManager.shared.deleteFoodLog(item.id)
                            onDelete()
                        } catch {
                            print("Error deleting food log: \(error)")
                        }
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this food item?")
        }
    }
}
