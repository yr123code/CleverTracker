import SwiftUI
import FirebaseAuth
struct RootView: View {
    
    @EnvironmentObject var authVM: AuthViewModel
    
    var body: some View {
        if authVM.user != nil {
            HomeView()
        } else {
            AuthView()
        }
    }
}
