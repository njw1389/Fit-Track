import FirebaseCore
import FirebaseDatabase
import FirebaseAuth
import SwiftUI

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    private let ref: DatabaseReference
    
    @Published var lastSavedText: String = ""
    @Published var savedItems: [String] = []
    @Published var isAuthenticated = false
    @Published var authError: String?
    
    init() {
        ref = Database.database().reference()
        authenticateAnonymously()
    }
    
    private func authenticateAnonymously() {
        Auth.auth().signInAnonymously { [weak self] authResult, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.authError = error.localizedDescription
                    self?.isAuthenticated = false
                    print("Auth Error: \(error.localizedDescription)")
                    return
                }
                
                if let user = authResult?.user {
                    print("Authenticated with UID: \(user.uid)")
                    self?.isAuthenticated = true
                    // Start listening for data after authentication
                    self?.fetchSavedItems()
                }
            }
        }
    }
    
    func saveText(_ text: String) {
        guard isAuthenticated else {
            print("Not authenticated")
            return
        }
        
        // Create a unique key for each entry
        let key = ref.child("tests").childByAutoId().key ?? UUID().uuidString
        
        // Get current user ID
        let userId = Auth.auth().currentUser?.uid ?? "unknown"
        
        // Create the data structure with user ID
        let data = [
            "text": text,
            "timestamp": ServerValue.timestamp(),
            "userId": userId
        ] as [String : Any]
        
        // Save to Firebase
        ref.child("tests").child(key).setValue(data) { [weak self] error, _ in
            if let error = error {
                print("Error saving data: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    self?.lastSavedText = text
                }
                print("Data saved successfully!")
            }
        }
    }
    
    func fetchSavedItems() {
        guard isAuthenticated else {
            print("Not authenticated")
            return
        }
        
        ref.child("tests").observe(.value) { [weak self] snapshot in
            var items: [String] = []
            
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let value = snapshot.value as? [String: Any],
                   let text = value["text"] as? String {
                    items.append(text)
                }
            }
            
            DispatchQueue.main.async {
                self?.savedItems = items
            }
        }
    }
}
