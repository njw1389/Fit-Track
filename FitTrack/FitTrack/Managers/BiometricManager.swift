//
//  BiometricManager.swift
//  FitTrack
//
//  Created by Nolan Wira on 11/4/24.
//

import LocalAuthentication
import SwiftUI

class BiometricManager: ObservableObject {
    @Published var isUnlocked = false
    private let context = LAContext()
    
    enum BiometricType {
        case none
        case touchID
        case faceID
        
        var title: String {
            switch self {
            case .none: return "None"
            case .touchID: return "Touch ID"
            case .faceID: return "Face ID"
            }
        }
        
        var iconName: String {
            switch self {
            case .none: return "xmark.circle"
            case .touchID: return "touchid"
            case .faceID: return "faceid"
            }
        }
    }
    
    var biometricType: BiometricType {
        context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch context.biometryType {
        case .none:
            return .none
        case .touchID:
            return .touchID
        case .faceID:
            return .faceID
        case .opticID:
            return .faceID  // Treat opticID (Vision Pro) as FaceID
        @unknown default:
            return .none
        }
    }
    
    func authenticate() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Unlock FitTrack"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                DispatchQueue.main.async {
                    self.isUnlocked = success
                }
            }
        }
    }
}
