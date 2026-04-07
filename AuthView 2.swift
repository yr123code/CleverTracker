import SwiftUI
import FirebaseAuth

struct AuthView: View {
    
    @EnvironmentObject var authVM: AuthViewModel
    
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        
        ZStack {
            
            // 🔹 Hintergrund
            Color.blue
                .ignoresSafeArea()
            
            // 🔹 Inhalt mittig
            VStack(spacing: 20) {
                
                Text("Kalorien App")
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
                
                Button("Login") {
                    authVM.login(email: email, password: password)
                }
                .buttonStyle(.borderedProminent)
                
                Button("Registrieren") {
                    authVM.register(email: email, password: password)
                }
                .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            
            // 🔹 Logo oben rechts (Overlay)
            VStack {
                HStack {
                    Spacer()
                    
                    Image("logo-colored-icons")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .padding()
                }
                Spacer()
            }
        }
    }
}
