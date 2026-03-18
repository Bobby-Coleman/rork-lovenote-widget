import SwiftUI

@Observable
@MainActor
class AuthViewModel {
    var isAuthenticated = false
    var isLoading = false
    var currentUser: SupabaseProfile?
    var partner: SupabaseProfile?
    var errorMessage: String?

    private let supa = SupabaseService.shared

    var accessToken: String? {
        KeychainService.load(key: "access_token")
    }

    var userID: String? {
        KeychainService.load(key: "user_id")
    }

    init() {
        if KeychainService.load(key: "access_token") != nil {
            isAuthenticated = true
        }
    }

    func register(email: String, password: String, username: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let authResponse = try await supa.signUp(email: email, password: password)
            saveSession(authResponse)

            try await supa.createProfile(
                id: authResponse.user.id,
                username: username.lowercased(),
                displayName: username,
                accessToken: authResponse.accessToken
            )

            KeychainService.save(key: "username", value: username.lowercased())
            await loadProfile()
            isAuthenticated = true
        } catch let error as SupabaseError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Connection failed. Please try again."
        }
    }

    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let authResponse = try await supa.signIn(email: email, password: password)
            saveSession(authResponse)
            await loadProfile()
            isAuthenticated = true
        } catch let error as SupabaseError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Connection failed. Please try again."
        }
    }

    func loadProfile() async {
        guard let token = accessToken, let uid = userID else {
            isAuthenticated = false
            return
        }

        do {
            currentUser = try await supa.getProfile(id: uid, accessToken: token)

            if let partnership = try await supa.getPartnership(userID: uid, accessToken: token) {
                partner = try await supa.getProfile(id: partnership.partnerId, accessToken: token)
            } else {
                partner = nil
            }

            if let partnerProfile = partner {
                if let latestNote = try await supa.getLatestReceivedNote(receiverID: uid, accessToken: token) {
                    let senderName = currentUser?.displayName ?? currentUser?.username ?? "Someone"
                    let _ = partnerProfile
                    SharedDataService.saveLatestNote(
                        latestNote.content,
                        from: senderName
                    )
                }
            }
        } catch is SupabaseError {
            await tryRefreshOrLogout()
        } catch {}
    }

    func logout() {
        KeychainService.deleteAll()
        SharedDataService.clearData()
        currentUser = nil
        partner = nil
        isAuthenticated = false
    }

    private func saveSession(_ response: SupabaseAuthResponse) {
        KeychainService.save(key: "access_token", value: response.accessToken)
        KeychainService.save(key: "refresh_token", value: response.refreshToken)
        KeychainService.save(key: "user_id", value: response.user.id)
    }

    private func tryRefreshOrLogout() async {
        guard let refreshToken = KeychainService.load(key: "refresh_token") else {
            logout()
            return
        }

        do {
            let response = try await supa.refreshSession(refreshToken: refreshToken)
            KeychainService.save(key: "access_token", value: response.accessToken)
            KeychainService.save(key: "refresh_token", value: response.refreshToken)
            await loadProfile()
        } catch {
            logout()
        }
    }
}
