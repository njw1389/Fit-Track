//
//  FitTrackApp.swift
//  FitTrack
//
//  Created by Nolan Wira on 11/3/24.
//

import SwiftUI
import FirebaseCore

@main
struct FitTrackApp: App {
    init() {
        FirebaseApp.configure()  // Initialize Firebase
    }
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            SplashScreenView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        return true
    }
}
