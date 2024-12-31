//
//  BiometricUnlockView.swift
//  FitTrack
//
//  Created by Nolan Wira on 11/4/24.
//

import SwiftUI

struct BiometricUnlockView: View {
    @EnvironmentObject var biometricManager: BiometricManager
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "figure.run.circle.fill") // Match splash screen logo
                .font(.system(size: 70))
                .foregroundColor(.blue)
            
            Text("FitTrack")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Your Journey, Tracked") // Match splash screen tagline
                .font(.headline)
                .foregroundColor(.secondary)
            
            Spacer()
                .frame(height: 20)
            
            Button(action: {
                biometricManager.authenticate()
            }) {
                HStack {
                    Image(systemName: "lock.open.fill")
                    Text("Login with \(biometricManager.biometricType.title)")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal, 50)
        }
    }
}
