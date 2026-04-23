import SwiftUI
import Firebase
import FirebaseAuth
import UIKit

// Richtet Firebase beim Start der App ein.
class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        
        // Initialisiert Firebase, bevor Views oder Auth-Zugriffe verwendet werden.
        FirebaseApp.configure()
        return true
    }
}

@main
struct YourApp: App {
    
    // Bindet den UIKit-AppDelegate in die SwiftUI-App ein.
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // Zentrale Auth-Instanz, die der gesamten App per EnvironmentObject zur Verfügung steht.
    @StateObject var authVM = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            // Einstiegspunkt der App. Von hier aus wird je nach Login-Zustand weitergeleitet.
            RootView()
                .environmentObject(authVM)
        }
    }
}
