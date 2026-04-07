import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

class AuthViewModel: ObservableObject {
    
    @Published var user: User?
    @Published var errorMessage: String = ""
    
    let db = Firestore.firestore()
    
    init() {
        self.user = Auth.auth().currentUser
    }
    
    func register(email: String, password: String) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                self.user = result?.user
            }
        }
    }
    
    func login(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                self.user = result?.user
            }
        }
    }
    
    func logout() {
        try? Auth.auth().signOut()
        self.user = nil
    }
    
    // MARK: - Firestore Speichern
    
    func saveUserData(weight: Double, height: Double, age: Int, gender: String, activity: Double, calories: Double) {
        
        guard let uid = user?.uid else { return }
        
        db.collection("users").document(uid).setData([
            "weight": weight,
            "height": height,
            "age": age,
            "gender": gender,
            "activityLevel": activity,
            "calories": calories
        ]) { error in
            if let error = error {
                print("Speicherfehler:", error)
            }
        }
    }
    
    // MARK: - Firestore Laden
    
    func loadUserData(completion: @escaping ([String: Any]?) -> Void) {
        
        guard let uid = user?.uid else { return }
        
        db.collection("users").document(uid).getDocument { document, error in
            if let data = document?.data() {
                completion(data)
            } else {
                completion(nil)
            }
        }
    }
}
