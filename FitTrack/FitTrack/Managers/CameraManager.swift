//
//  CameraManager.swift
//  FitTrack
//
//  Created by Nolan Wira on 12/7/24.
//

import AVFoundation
import SwiftUI

class CameraManager: ObservableObject {
    static let shared = CameraManager()
    @Published var isAuthorized = false
    
    init() {
        checkAuthorizationStatus()
    }
    
    private func checkAuthorizationStatus() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
        case .notDetermined, .denied, .restricted:
            isAuthorized = false
        @unknown default:
            isAuthorized = false
        }
    }
    
    func requestAuthorization() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
            }
        }
    }
}
