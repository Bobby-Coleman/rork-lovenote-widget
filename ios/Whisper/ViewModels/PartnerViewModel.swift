import SwiftUI

@Observable
@MainActor
class PartnerViewModel {
    var searchText = ""
    var searchResults: [UserResponse] = []
    var isSearching = false
    var isAdding = false
    var errorMessage: String?
    var successMessage: String?

    private let api = APIService.shared

    func search(token: String) async {
        guard searchText.count >= 2 else {
            searchResults = []
            return
        }
        isSearching = true
        defer { isSearching = false }

        do {
            let response = try await api.searchUsers(username: searchText, token: token)
            searchResults = response.users
        } catch {
            searchResults = []
        }
    }

    func addPartner(username: String, token: String) async {
        isAdding = true
        errorMessage = nil
        successMessage = nil
        defer { isAdding = false }

        do {
            _ = try await api.addPartner(username: username, token: token)
            successMessage = "Partner added!"
            searchText = ""
            searchResults = []
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Failed to add partner"
        }
    }

    func removePartner(token: String) async {
        do {
            try await api.removePartner(token: token)
        } catch {
            errorMessage = "Failed to remove partner"
        }
    }
}
