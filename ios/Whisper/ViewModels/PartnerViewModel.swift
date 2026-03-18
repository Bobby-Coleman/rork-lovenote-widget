import SwiftUI

@Observable
@MainActor
class PartnerViewModel {
    var searchText = ""
    var searchResults: [SupabaseProfile] = []
    var isSearching = false
    var isAdding = false
    var errorMessage: String?
    var successMessage: String?

    private let supa = SupabaseService.shared

    func search(token: String, currentUserID: String) async {
        guard searchText.count >= 2 else {
            searchResults = []
            return
        }
        isSearching = true
        defer { isSearching = false }

        do {
            let results = try await supa.searchProfiles(username: searchText, accessToken: token)
            searchResults = results.filter { $0.id != currentUserID }
        } catch {
            searchResults = []
        }
    }

    func addPartner(userID: String, partnerID: String, token: String) async {
        isAdding = true
        errorMessage = nil
        successMessage = nil
        defer { isAdding = false }

        do {
            try await supa.addPartner(userID: userID, partnerID: partnerID, accessToken: token)
            successMessage = "Partner added!"
            searchText = ""
            searchResults = []
        } catch let error as SupabaseError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Failed to add partner"
        }
    }

    func removePartner(userID: String, token: String) async {
        do {
            try await supa.removePartner(userID: userID, accessToken: token)
        } catch {
            errorMessage = "Failed to remove partner"
        }
    }
}
