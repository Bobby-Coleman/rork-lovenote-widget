import SwiftUI

struct SettingsView: View {
    let authViewModel: AuthViewModel

    @State private var partnerVM = PartnerViewModel()
    @State private var showAddPartner = false
    @State private var showLogoutConfirm = false
    @State private var showRemovePartner = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(authViewModel.currentUser?.displayName ?? authViewModel.currentUser?.username ?? "—")
                                .font(.headline)

                            if let username = authViewModel.currentUser?.username {
                                Text("@\(username)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Partner") {
                    if let partner = authViewModel.partner {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(partner.displayName ?? partner.username)
                                    .font(.body.weight(.medium))
                                Text("@\(partner.username)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "heart.fill")
                                .foregroundStyle(.pink)
                        }

                        Button("Remove Partner", role: .destructive) {
                            showRemovePartner = true
                        }
                    } else {
                        Button {
                            showAddPartner = true
                        } label: {
                            Label("Add Partner", systemImage: "person.badge.plus")
                        }
                    }
                }

                Section("Widget") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Home Screen Widget")
                            .font(.body.weight(.medium))
                        Text("Add the Whisper widget to your Home Screen to see your partner's latest note at a glance.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Button("Sign Out", role: .destructive) {
                        showLogoutConfirm = true
                    }
                }
            }
            .navigationTitle("settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showAddPartner) {
                AddPartnerSheet(authViewModel: authViewModel, partnerVM: partnerVM)
            }
            .alert("Sign Out?", isPresented: $showLogoutConfirm) {
                Button("Sign Out", role: .destructive) {
                    authViewModel.logout()
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Remove Partner?", isPresented: $showRemovePartner) {
                Button("Remove", role: .destructive) {
                    Task {
                        if let token = authViewModel.accessToken, let uid = authViewModel.userID {
                            await partnerVM.removePartner(userID: uid, token: token)
                            await authViewModel.loadProfile()
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You won't be able to send or receive whispers until you add a new partner.")
            }
            .onChange(of: showAddPartner) { _, isShowing in
                if !isShowing {
                    Task { await authViewModel.loadProfile() }
                }
            }
        }
    }
}
