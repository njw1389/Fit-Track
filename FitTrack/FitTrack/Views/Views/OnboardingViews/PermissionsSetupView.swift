//
//  PermissionsSetupView.swift
//  FitTrack
//
//  Created by Nolan Wira on 12/7/24.
//

import SwiftUI
import HealthKit

struct PermissionsSetupView: View {
    @StateObject private var healthKitManager = HealthKitManager.shared
    @ObservedObject var biometricManager: BiometricManager
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var cameraManager = CameraManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Biometric authentication card (required)
                PermissionCard(
                    title: biometricManager.biometricType.title,
                    description: "Secure access to your data (Required)",
                    isEnabled: biometricManager.isUnlocked,
                    isRequired: true,
                    action: { biometricManager.authenticate() }
                )
                
                // Optional permissions
                PermissionCard(
                    title: "Camera Access",
                    description: "Scan barcodes to log food items",
                    isEnabled: cameraManager.isAuthorized,
                    isRequired: false,
                    action: { cameraManager.requestAuthorization() }
                )
                
                PermissionCard(
                    title: "HealthKit Access",
                    description: "Track steps, energy, and sync health data",
                    isEnabled: healthKitManager.isAuthorized,
                    isRequired: false,
                    action: { healthKitManager.requestAuthorization() }
                )
                
                PermissionCard(
                    title: "Notifications",
                    description: "Get reminders and progress updates",
                    isEnabled: notificationManager.isAuthorized,
                    isRequired: false,
                    action: { notificationManager.requestAuthorization() }
                )
            }
            .padding()
        }
    }
}

struct PermissionCard: View {
    let title: String
    let description: String
    let isEnabled: Bool
    let isRequired: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(title)
                            .font(.headline)
                        if isRequired {
                            Text("(Required)")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Status indicator
                if isEnabled {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Text("Enable")
                        .foregroundColor(isRequired ? .red : .blue)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .contentShape(Rectangle())  // Makes entire card tappable
        }
        .buttonStyle(PermissionCardButtonStyle(isRequired: isRequired, isEnabled: isEnabled))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isRequired && !isEnabled ? Color.red : Color.clear, lineWidth: 1)
        )
    }
}

struct PermissionCardButtonStyle: ButtonStyle {
    let isRequired: Bool
    let isEnabled: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemBackground))
                    .shadow(radius: 2)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)  // Visual feedback
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)  // Subtle scale animation
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}
