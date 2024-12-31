//
//  NotificationManager.swift
//  FitTrack
//
//  Created by Nolan Wira on 12/7/24.
//

import UserNotifications
import FirebaseDatabase
import FirebaseAuth

class NotificationManager: NSObject, UNUserNotificationCenterDelegate, ObservableObject {
    static let shared = NotificationManager()
    private let notificationCenter = UNUserNotificationCenter.current()
    private let ref = Database.database().reference()
    private let auth = Auth.auth()
    @Published var isAuthorized = false
    
    override private init() {
        super.init()
        notificationCenter.delegate = self
        checkAuthorizationStatus()
    }
    
    private func checkAuthorizationStatus() {
       notificationCenter.getNotificationSettings { settings in
           DispatchQueue.main.async {
               self.isAuthorized = settings.authorizationStatus == .authorized
           }
       }
   }
    
    func requestAuthorization() {
        notificationCenter.requestAuthorization(options: [.alert, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                if granted {
                    print("Notification permission granted")
                    self.scheduleDailyCheckNotification()
                } else if let error = error {
                    print("Error requesting notification permission: \(error)")
                }
            }
        }
    }
    
    func scheduleDailyCheckNotification() {
        // Remove any existing notifications first
        notificationCenter.removeAllPendingNotificationRequests()
        
        // Create date components for noon
        var dateComponents = DateComponents()
        dateComponents.hour = 12
        dateComponents.minute = 0
        
        // Create the notification content
        let content = UNMutableNotificationContent()
        content.title = "Daily Health Check"
        content.body = "Don't forget to log your meals and activities today!"
        content.sound = .default
        
        // Create the trigger for noon
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // Create the request
        let request = UNNotificationRequest(
            identifier: "dailyCheck",
            content: content,
            trigger: trigger
        )
        
        // Schedule the notification with a custom check
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    // This delegate method will be called right before the notification is about to be presented
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Check if user has logged anything today before showing the notification
        Task {
            if await !hasUserLoggedToday() {
                completionHandler([.banner, .sound])
            } else {
                completionHandler([])
            }
        }
    }
    
    private func hasUserLoggedToday() async -> Bool {
        guard let userId = auth.currentUser?.uid else { return true } // If no user, consider it logged
        
        let dateString = formatDate(Date())
        
        do {
            // Check food logs
            let hasFoodLogs = try await checkLogs(path: "foodLogs", date: dateString, userId: userId)
            if hasFoodLogs { return true }
            
            // Check exercise logs
            let hasExerciseLogs = try await checkLogs(path: "exerciseLogs", date: dateString, userId: userId)
            if hasExerciseLogs { return true }
            
            // Check weight logs
            let hasWeightLogs = try await checkLogs(path: "weightLogs", date: dateString, userId: userId)
            if hasWeightLogs { return true }
            
            return false
        } catch {
            print("Error checking logs: \(error)")
            return true // On error, assume logged to prevent unnecessary notifications
        }
    }
    
    private func checkLogs(path: String, date: String, userId: String) async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            ref.child("users").child(userId).child(path)
                .queryOrdered(byChild: "date")
                .queryEqual(toValue: date)
                .observeSingleEvent(of: .value) { snapshot in
                    continuation.resume(returning: snapshot.exists())
                } withCancel: { error in
                    continuation.resume(throwing: error)
                }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
