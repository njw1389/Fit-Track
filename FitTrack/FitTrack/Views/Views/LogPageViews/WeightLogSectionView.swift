//
//  WeightLogSectionView.swift
//  FitTrack
//
//  Created by Nolan Wira on 12/9/24.
//

import SwiftUI

struct WeightLogSectionView: View {
    let logs: [WeightLogItem]
    let selectedDate: Date
    @State private var showingDeleteAlert = false
    @State private var selectedItem: WeightLogItem?
    
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weight Log")
                .font(.headline)
            
            ForEach(logs) { log in
                HStack {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("\(String(format: "%.1f", log.weight)) lbs")
                            Text("•")
                            Text(log.timestamp.formatted(date: .omitted, time: .shortened))
                                .foregroundColor(.secondary)
                        }
                        if let note = log.note {
                            Text(note)
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
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
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
        .alert("Delete Weight Entry", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let item = selectedItem {
                    Task {
                        try? await WeightLogManager.shared.deleteWeightLog(item.id)
                        onDelete()
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this weight entry?")
        }
    }
}
