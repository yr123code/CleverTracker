//Login, Regrerstrierung, Daten laden und speichern
import SwiftUI
import FirebaseAuth

// Login- und Registrierungsmaske für den Nutzer.
struct AuthView: View {
    
    // Zugriff auf die zentrale Auth-Logik.
    @EnvironmentObject var authVM: AuthViewModel
    
    // Eingaben aus den Textfeldern.
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        
        ZStack {
            
            // Hintergrund
            Color.blue
                .ignoresSafeArea()
            
            // Inhalt mittig
            VStack(spacing: 20) {
                
                Text("Willkommen bei CleverTracker!")
                    .font(.largeTitle)
                    .bold()
                    
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                
                SecureField("Passwort", text: $password)
                    .textFieldStyle(.roundedBorder)
                
                if !authVM.errorMessage.isEmpty {
                    Text(authVM.errorMessage)
                        .foregroundColor(.red)
                }
                
                // Startet den Login über das ViewModel.
                Button("Login") {
                    authVM.login(email: email, password: password)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.white)
                .foregroundStyle(.black)
                
                // Erstellt einen neuen Account über das ViewModel.
                Button("Registrieren") {
                    authVM.register(email: email, password: password)
                }
                .buttonStyle(.bordered)
                .foregroundStyle(Color.black)
                .tint(Color.white)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            
            // Logo oben rechts (Overlay)
            VStack {
                HStack {
                    Image("HomeIconNew")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                    Spacer()
                    Image("logo-colored-icons")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                }
                .padding()
                Spacer()
            }
        }
    }
}
