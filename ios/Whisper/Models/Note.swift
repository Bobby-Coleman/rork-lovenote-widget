import Foundation

nonisolated struct Note: Codable, Sendable, Identifiable {
    let id: String
    let senderID: String
    let receiverID: String
    let content: String
    let createdAt: String
    let sender: NoteSender?

    enum CodingKeys: String, CodingKey {
        case id
        case senderID = "sender_id"
        case receiverID = "receiver_id"
        case content
        case createdAt = "created_at"
        case sender
    }

    var formattedDate: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: createdAt) else {
            let fallback = ISO8601DateFormatter()
            guard let d = fallback.date(from: createdAt) else { return "" }
            return d.formatted(.relative(presentation: .named))
        }
        return date.formatted(.relative(presentation: .named))
    }
}

nonisolated struct NoteSender: Codable, Sendable {
    let username: String
    let displayName: String?

    enum CodingKeys: String, CodingKey {
        case username
        case displayName = "display_name"
    }
}

nonisolated struct NoteResponse: Codable, Sendable {
    let note: Note?
}

nonisolated struct NotesListResponse: Codable, Sendable {
    let notes: [Note]
}

nonisolated struct SendNoteResponse: Codable, Sendable {
    let note: SendNoteData
}

nonisolated struct SendNoteData: Codable, Sendable {
    let id: String
    let content: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case content
        case createdAt = "created_at"
    }
}
