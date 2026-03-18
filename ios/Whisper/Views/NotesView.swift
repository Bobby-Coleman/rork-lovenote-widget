import SwiftUI

struct NotesView: View {
    let authViewModel: AuthViewModel
    let homeVM: HomeViewModel

    @State private var receivedNotes: [Note] = []
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

    private func noteRow(_ note: Note) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(note.content)
                .font(.system(.body, design: .serif))

            HStack {
                if let sender = note.sender {
                    Text("from \(sender.displayName ?? sender.username)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
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
        guard let token = authViewModel.accessToken else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await APIService.shared.getReceivedNotes(token: token)
            receivedNotes = response.notes
        } catch {
            // silently fail
        }
    }
}
