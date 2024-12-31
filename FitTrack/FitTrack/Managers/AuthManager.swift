//
//  AuthManager.swift
//  FitTrack
//
//  Created by Nolan Wira on 11/4/24.
//

import CloudKit
import SwiftUI

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    private let container = CKContainer.default()
    
    @Published var isAuthenticated = false
    @Published var userRecord: CKRecord?
    @Published var errorMessage = ""
    
    init() {
        Task {
            await checkAuthStatus()
        }
    }
    
    func checkAuthStatus() async {
        do {
            let status = try await container.accountStatus()
            
            switch status {
            case .available:
                isAuthenticated = true
                await fetchUserRecord()
            case .noAccount:
                errorMessage = "Please sign in to iCloud in Settings"
                isAuthenticated = false
            case .restricted:
                errorMessage = "iCloud access is restricted"
                isAuthenticated = false
            case .couldNotDetermine:
                errorMessage = "Could not determine iCloud status"
                isAuthenticated = false
            case .temporarilyUnavailable:
                errorMessage = "iCloud is temporarily unavailable"
                isAuthenticated = false
            @unknown default:
                errorMessage = "Unexpected iCloud account status"
                isAuthenticated = false
            }
        } catch {
            errorMessage = error.localizedDescription
            isAuthenticated = false
        }
    }
    
    private func fetchUserRecord() async {
        do {
            let recordID = try await container.userRecordID()
            let record = try await container.privateCloudDatabase.record(for: recordID)
            
            userRecord = record
        } catch {
            errorMessage = "Failed to fetch user record: \(error.localizedDescription)"
        }
    }
}
