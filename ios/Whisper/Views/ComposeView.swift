import SwiftUI

struct ComposeView: View {
    let authViewModel: AuthViewModel
    @Bindable var homeVM: HomeViewModel

    @FocusState private var isEditing: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 32) {
                        if authViewModel.partner == nil {
                            noPartnerCard
                        } else {
                            receivedNoteCard
                            composeCard
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("whisper")
            .navigationBarTitleDisplayMode(.large)
            .sensoryFeedback(.success, trigger: homeVM.showSuccess)
        }
    }

    private var noPartnerCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.slash")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)

            Text("no partner yet")
                .font(.headline)

            Text("add your partner in Settings to start sending whispers")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 16))
    }

    private var receivedNoteCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.pink)
                    .font(.caption)

                Text("latest from \(authViewModel.partner?.displayName ?? authViewModel.partner?.username ?? "partner")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let note = homeVM.latestReceivedNote {
                Text(note.content)
                    .font(.system(.body, design: .serif))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(note.formattedDate)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            } else {
                Text("no whispers yet...")
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(.tertiary)
                    .italic()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 16))
    }

    private var composeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("write a whisper")
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(1)

            TextField("say something sweet...", text: $homeVM.noteText, axis: .vertical)
                .font(.system(.body, design: .serif))
                .lineLimit(4...8)
                .focused($isEditing)

            HStack {
                Text("\(homeVM.characterCount)/\(homeVM.characterLimit)")
                    .font(.caption2)
                    .foregroundStyle(homeVM.characterCount > homeVM.characterLimit ? Color.red : Color(.tertiaryLabel))

                Spacer()

                if homeVM.showSuccess {
                    Label("sent", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                        .transition(.opacity.combined(with: .scale))
                }

                Button {
                    isEditing = false
                    Task {
                        if let token = authViewModel.accessToken {
                            await homeVM.sendNote(token: token)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        if homeVM.isSending {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.caption)
                        }
                        Text("send")
                            .font(.subheadline.weight(.semibold))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .tint(.black)
                .clipShape(Capsule())
                .disabled(!homeVM.canSend || homeVM.characterCount > homeVM.characterLimit)
            }

            if let error = homeVM.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 16))
    }
}
