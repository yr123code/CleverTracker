//Login/ Regristierung Benutzeroberfläsche (View)
import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

// Verwaltet den Login-Zustand und den Zugriff auf Firebase Auth + Firestore.
class AuthViewModel: ObservableObject {
    
    // Aktuell angemeldeter Firebase-Nutzer.
    @Published var user: User?
    // Fehlertext für Login- oder Registrierungsprobleme.
    @Published var errorMessage: String = ""
    
    // Firestore-Referenz für das Speichern und Laden von Nutzerdaten.
    let db = Firestore.firestore()
    
    init() {
        // Übernimmt beim App-Start einen eventuell bereits eingeloggten Nutzer.
        self.user = Auth.auth().currentUser
    }
    
    // Erstellt einen neuen Nutzer in Firebase Authentication.
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
    
    // Meldet einen bestehenden Nutzer in Firebase Authentication an.
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
    
    // Meldet den aktuellen Nutzer ab und leert den lokalen Login-Zustand.
    func logout() {
        try? Auth.auth().signOut()
        self.user = nil
    }
    
    // MARK: - Firestore Speichern
    
    // Speichert die berechneten Nutzerdaten in Firestore unter der User-ID.
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

    // Speichert bereits eingegebene Zwischenschritte des Onboardings in Firebase.
    func saveOnboardingProgress(
        weight: Double?,
        height: Double?,
        age: Int?,
        gender: String?,
        activity: Double?,
        calories: Double?
    ) {
        guard let uid = user?.uid else { return }

        // Baut nur die Werte ins Dictionary ein, die bereits vorhanden sind.
        var data: [String: Any] = [:]

        if let weight { data["weight"] = weight }
        if let height { data["height"] = height }
        if let age { data["age"] = age }
        if let gender { data["gender"] = gender }
        if let activity { data["activityLevel"] = activity }
        if let calories, calories > 0 { data["calories"] = calories }
        
        // Wenn noch keine Daten vorhanden sind, wird nichts gespeichert.
        guard !data.isEmpty else { return }

        // Speichert die Teildaten in das Nutzerdokument, ohne bestehende Felder zu überschreiben.
        db.collection("users").document(uid).setData(data, merge: true)
    }
    
    // MARK: - Firestore Laden
    
    // Lädt bereits gespeicherte Nutzerdaten aus Firestore.
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
