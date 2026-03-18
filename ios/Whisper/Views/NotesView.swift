import SwiftUI

struct NotesView: View {
    let authViewModel: AuthViewModel
    let homeVM: HomeViewModel

    @State private var receivedNotes: [SupabaseNote] = []
    @State private var showingSent = false
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $showingSent) {
                    Text("Received").tag(false)
                    Text("Sent").tag(true)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

                let notes = showingSent ? homeVM.sentNotes : receivedNotes

                if notes.isEmpty {
                    ContentUnavailableView(
                        showingSent ? "No sent whispers" : "No whispers yet",
                        systemImage: showingSent ? "paperplane" : "heart.text.clipboard",
                        description: Text(showingSent ? "Send your first whisper from the Compose tab" : "Whispers from your partner will appear here")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(notes) { note in
                                noteRow(note)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("notes")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await loadNotes()
            }
            .refreshable {
                await loadNotes()
            }
        }
    }

    private func noteRow(_ note: SupabaseNote) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(note.content)
                .font(.system(.body, design: .serif))

            HStack {
                Spacer()
                Text(note.formattedDate)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 12))
    }

    private func loadNotes() async {
        guard let token = authViewModel.accessToken, let uid = authViewModel.userID else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            receivedNotes = try await SupabaseService.shared.getReceivedNotes(receiverID: uid, accessToken: token)
        } catch {}
    }
}
