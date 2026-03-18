import SwiftUI

@main
struct WhisperApp: App {
    @State private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(authViewModel: authViewModel)
        }
    }
}
