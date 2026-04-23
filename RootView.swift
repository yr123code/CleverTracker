import SwiftUI
import FirebaseAuth

// Entscheidet, ob der Nutzer die Login-Ansicht oder den App-Inhalt sieht.
struct RootView: View {
    
    @EnvironmentObject var authVM: AuthViewModel
    
    var body: some View {
        // Wenn ein Firebase-User vorhanden ist, geht es in die App. Sonst bleibt man im Auth-Screen.
        if authVM.user != nil {
            HomeView()
        } else {
            AuthView()
        }
    }
}
