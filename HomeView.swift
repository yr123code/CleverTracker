import SwiftUI
import FirebaseAuth

// Kurze Zwischenansicht nach dem Login mit automatischer Weiterleitung zur Hauptseite.
struct HomeView: View {
    
    @EnvironmentObject var authVM: AuthViewModel
    // Steuert die zeitverzögerte Navigation zur Hauptansicht.
    @State private var goToNext = false
    // Steuert das langsame Verblassen der Inhalte.
    @State private var contentOpacity = 1.0
    
    var body: some View {
        Group {
            // Sobald goToNext true ist, wird direkt die Hauptseite angezeigt.
            if goToNext {
                Hauptseite()
            } else {
            // Solange goToNext false ist, bleibt die HomeView sichtbar.
            ZStack {
                // Vollflächiger blauer Hintergrund wie in den anderen Views.
                Color.blue
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    Spacer()

                    // Zeigt das App-Icon groß und mittig auf dem Bildschirm an.
                    Image("HomeIconNew")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 220, maxHeight: 220)
                    
                    // Zeigt die E-Mail des aktuell angemeldeten Nutzers an.
                    Text(authVM.user?.email ?? "")
                        .foregroundColor(.white.opacity(0.9))
                    
                    // Meldet den Nutzer direkt aus der HomeView wieder ab.
                    Button("Logout") {
                        authVM.logout()
                    }
                    .foregroundColor(.red)

                    Spacer()
                }
                // Lässt den gesamten Inhalt weich ausblenden.
                .opacity(contentOpacity)
            }
            .onAppear {
                // Startet kurz vor der Weiterleitung eine Fade-Out-Animation.
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    withAnimation(.easeOut(duration: 1.0)) {
                        contentOpacity = 0
                    }
                }

                // Leitet den Nutzer nach dem Verblassen automatisch weiter.
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    goToNext = true
                }
            }
            }
        }
    }
}
