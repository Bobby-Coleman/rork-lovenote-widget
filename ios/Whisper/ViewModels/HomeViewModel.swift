import SwiftUI
import WidgetKit

@Observable
@MainActor
class HomeViewModel {
    var noteText = ""
    var isSending = false
    var latestReceivedNote: Note?
    var sentNotes: [Note] = []
    var errorMessage: String?
    var showSuccess = false

    private let api = APIService.shared

    var canSend: Bool {
        !noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending
    }

    var characterCount: Int {
        noteText.count
    }

    var characterLimit: Int { 200 }

    func sendNote(token: String) async {
        guard canSend else { return }
        isSending = true
        errorMessage = nil
        defer { isSending = false }

        do {
            _ = try await api.sendNote(content: noteText.trimmingCharacters(in: .whitespacesAndNewlines), token: token)
            noteText = ""
            showSuccess = true
            await loadSentNotes(token: token)

            try? await Task.sleep(for: .seconds(2))
            showSuccess = false
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Failed to send note"
        }
    }

    func loadLatestNote(token: String) async {
        do {
            let response = try await api.getLatestNote(token: token)
            latestReceivedNote = response.note

            if let note = response.note {
                SharedDataService.saveLatestNote(
                    note.content,
                    from: note.sender?.displayName ?? note.sender?.username ?? "Someone"
                )
            }
        } catch {
            // silently fail
        }
    }

    func loadSentNotes(token: String) async {
        do {
            let response = try await api.getSentNotes(token: token)
            sentNotes = response.notes
        } catch {
            // silently fail
        }
    }
}
