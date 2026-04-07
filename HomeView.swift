import SwiftUI
import FirebaseAuth

struct HomeView: View {
    
    @EnvironmentObject var authVM: AuthViewModel
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
                
                NavigationLink(value: "hauptseite") {
                    EmptyView()
                }
            }
            .padding()
            .navigationDestination(for: String.self) { value in
                if value == "hauptseite" {
                    Hauptseite()
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    goToNext = true
                }
            }
            .navigationDestination(isPresented: $goToNext) {
                Hauptseite()
            }
        }
    }
}
