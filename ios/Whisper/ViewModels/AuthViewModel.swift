import SwiftUI

@Observable
@MainActor
class AuthViewModel {
    var isAuthenticated = false
    var isLoading = false
    var currentUser: UserResponse?
    var partner: UserResponse?
    var errorMessage: String?

    private let api = APIService.shared

    var accessToken: String? {
        KeychainService.load(key: "access_token")
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
            let response = try await api.register(email: email, password: password, username: username)
            saveSession(response)
            isAuthenticated = true
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Connection failed. Please try again."
        }
    }

    func login(identifier: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await api.login(identifier: identifier, password: password)
            saveSession(response)
            isAuthenticated = true
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Connection failed. Please try again."
        }
    }

    func loadProfile() async {
        guard let token = accessToken else {
            isAuthenticated = false
            return
        }

        do {
            let response = try await api.getMe(token: token)
            currentUser = response.user
            partner = response.partner

            if let note = try? await api.getLatestNote(token: token),
               let noteData = note.note {
                SharedDataService.saveLatestNote(
                    noteData.content,
                    from: noteData.sender?.displayName ?? noteData.sender?.username ?? "Someone"
                )
            }
        } catch is APIError {
            await tryRefreshOrLogout()
        } catch {
            // silently fail
        }
    }

    func logout() {
        KeychainService.deleteAll()
        SharedDataService.clearData()
        currentUser = nil
        partner = nil
        isAuthenticated = false
    }

    private func saveSession(_ response: AuthResponse) {
        KeychainService.save(key: "access_token", value: response.session.accessToken)
        KeychainService.save(key: "refresh_token", value: response.session.refreshToken)
        KeychainService.save(key: "user_id", value: response.user.id)
        if let username = response.user.username {
            KeychainService.save(key: "username", value: username)
        }
        currentUser = response.user
    }

    private func tryRefreshOrLogout() async {
        guard let refreshToken = KeychainService.load(key: "refresh_token") else {
            logout()
            return
        }

        do {
            let response = try await api.refreshToken(refreshToken)
            KeychainService.save(key: "access_token", value: response.session.accessToken)
            KeychainService.save(key: "refresh_token", value: response.session.refreshToken)
            await loadProfile()
        } catch {
            logout()
        }
    }
}
