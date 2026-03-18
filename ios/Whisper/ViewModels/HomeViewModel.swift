import SwiftUI
import WidgetKit

@Observable
@MainActor
class HomeViewModel {
    var noteText = ""
    var isSending = false
    var latestReceivedNote: SupabaseNote?
    var sentNotes: [SupabaseNote] = []
    var errorMessage: String?
    var showSuccess = false

    private let supa = SupabaseService.shared

    var canSend: Bool {
        !noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending
    }

    var characterCount: Int { noteText.count }
    var characterLimit: Int { 200 }

    func sendNote(token: String, senderID: String, receiverID: String) async {
        guard canSend else { return }
        isSending = true
        errorMessage = nil
        defer { isSending = false }

        do {
            _ = try await supa.sendNote(
                content: noteText.trimmingCharacters(in: .whitespacesAndNewlines),
                senderID: senderID,
                receiverID: receiverID,
                accessToken: token
            )
            noteText = ""
            showSuccess = true
            await loadSentNotes(token: token, senderID: senderID)

            try? await Task.sleep(for: .seconds(2))
            showSuccess = false
        } catch let error as SupabaseError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Failed to send note"
        }
    }

    func loadLatestNote(token: String, receiverID: String) async {
        do {
            latestReceivedNote = try await supa.getLatestReceivedNote(receiverID: receiverID, accessToken: token)

            if let note = latestReceivedNote {
                SharedDataService.saveLatestNote(note.content, from: "your partner")
            }
        } catch {}
    }

    func loadSentNotes(token: String, senderID: String) async {
        do {
            sentNotes = try await supa.getSentNotes(senderID: senderID, accessToken: token)
        } catch {}
    }
}
