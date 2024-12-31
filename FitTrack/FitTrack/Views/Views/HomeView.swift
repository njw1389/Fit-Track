//
//  HomeView.swift
//  FitTrack
//
//  Created by Nolan Wira on 11/4/24.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        TabView {
            DashboardPage()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
            
            ProgressPage()
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }
            
            LogPage()
                .tabItem {
                    Label("Log", systemImage: "calendar")
                }
            
            ProfilePage()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .padding(.top, 30)
    }
}

#Preview {
    HomeView()
        .preferredColorScheme(.dark)
}
