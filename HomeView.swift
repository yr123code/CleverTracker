import SwiftUI
import FirebaseAuth

// Kurze Zwischenansicht nach dem Login mit automatischer Weiterleitung zur Hauptseite.
struct HomeView: View {
    
    @EnvironmentObject var authVM: AuthViewModel
    // Steuert die zeitverzögerte Navigation zur Hauptansicht.
    @State private var goToNext = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                
                Text("Willkommen 👋")
                    .font(.largeTitle)
                
                Text("Du wirst in Kürze weitergeleitet...")
                    .font(.title)
                
                Text(authVM.user?.email ?? "")
                    .foregroundColor(.gray)
                
                Button("Logout") {
                    authVM.logout()
                }
                .foregroundColor(.red)
                
                // Unsichtbarer Navigationsanker über einen String-Wert.
                NavigationLink(value: "hauptseite") {
                    EmptyView()
                }
            }
            .padding()
            // Löst Navigation anhand des übergebenen Wertes aus.
            .navigationDestination(for: String.self) { value in
                if value == "hauptseite" {
                    Hauptseite()
                }
            }
            .onAppear {
                // Leitet den Nutzer nach 5 Sekunden automatisch weiter.
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    goToNext = true
                }
            }
            // Zweite Navigation, diesmal direkt über ein Bool-State.
            .navigationDestination(isPresented: $goToNext) {
                Hauptseite()
            }
        }
    }
}
