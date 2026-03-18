import SwiftUI

struct AddPartnerSheet: View {
    let authViewModel: AuthViewModel
    @Bindable var partnerVM: PartnerViewModel

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    TextField("search by username", text: $partnerVM.searchText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(.rect(cornerRadius: 12))
                        .onChange(of: partnerVM.searchText) { _, _ in
                            Task {
                                if let token = authViewModel.accessToken {
                                    await partnerVM.search(token: token)
                                }
                            }
                        }

                    if let success = partnerVM.successMessage {
                        Label(success, systemImage: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                    }

                    if let error = partnerVM.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                if partnerVM.searchResults.isEmpty && !partnerVM.searchText.isEmpty && !partnerVM.isSearching {
                    ContentUnavailableView.search(text: partnerVM.searchText)
                } else {
                    List(partnerVM.searchResults, id: \.id) { user in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.displayName ?? user.username ?? "—")
                                    .font(.body.weight(.medium))
                                if let username = user.username {
                                    Text("@\(username)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            Button {
                                Task {
                                    if let token = authViewModel.accessToken, let username = user.username {
                                        await partnerVM.addPartner(username: username, token: token)
                                    }
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                            }
                            .disabled(partnerVM.isAdding)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Add Partner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
