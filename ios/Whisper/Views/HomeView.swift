import SwiftUI

struct HomeView: View {
    let authViewModel: AuthViewModel

    @State private var homeVM = HomeViewModel()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Compose", systemImage: "pencil.line", value: 0) {
                ComposeView(authViewModel: authViewModel, homeVM: homeVM)
            }

            Tab("Notes", systemImage: "heart.text.clipboard", value: 1) {
                NotesView(authViewModel: authViewModel, homeVM: homeVM)
            }

            Tab("Settings", systemImage: "person.circle", value: 2) {
                SettingsView(authViewModel: authViewModel)
            }
        }
        .tint(.black)
        .task {
            await authViewModel.loadProfile()
            if let token = authViewModel.accessToken, let uid = authViewModel.userID {
                await homeVM.loadLatestNote(token: token, receiverID: uid)
                await homeVM.loadSentNotes(token: token, senderID: uid)
            }
        }
    }
}
