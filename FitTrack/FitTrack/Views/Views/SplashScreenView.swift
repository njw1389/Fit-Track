//
//  SplashScreenView.swift
//  FitTrack
//
//  Created by Nolan Wira on 11/4/24.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var opacity = 0.5
    @State private var scale = 0.8
    
    var body: some View {
        if isActive {
            ContentView()
        } else {
            VStack(spacing: 20) {
                Image(systemName: "figure.run.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("FitTrack")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Your Journey, Tracked")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: 1.2)) {
                    self.opacity = 1
                    self.scale = 1
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        self.isActive = true
                    }
                }
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
