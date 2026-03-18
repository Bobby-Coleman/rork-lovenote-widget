import Foundation

nonisolated struct SupabaseAuthResponse: Codable, Sendable {
    let accessToken: String
    let refreshToken: String
    let user: SupabaseUser
}

nonisolated struct SupabaseUser: Codable, Sendable {
    let id: String
    let email: String?
}

nonisolated struct SupabaseProfile: Codable, Sendable, Identifiable {
    let id: String
    let username: String
    let displayName: String?
    let createdAt: String?
}

nonisolated struct SupabasePartnership: Codable, Sendable, Identifiable {
    let id: String
    let userId: String
    let partnerId: String
}

nonisolated struct SupabaseNote: Codable, Sendable, Identifiable {
    let id: String
    let senderId: String
    let receiverId: String
    let content: String
    let createdAt: String

    var formattedDate: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: createdAt) {
            return date.formatted(.relative(presentation: .named))
        }
        let fallback = ISO8601DateFormatter()
        if let date = fallback.date(from: createdAt) {
            return date.formatted(.relative(presentation: .named))
        }
        return ""
    }
}

nonisolated struct SupabaseErrorBody: Codable, Sendable {
    let message: String?
    let msg: String?
    let errorDescription: String?

    enum CodingKeys: String, CodingKey {
        case message
        case msg
        case errorDescription = "error_description"
    }
}

nonisolated enum SupabaseError: Error, Sendable, LocalizedError {
    case networkError(String)
    case unauthorized
    case notFound
    case conflict(String)
    case badRequest(String)
    case serverError(String)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .networkError(let msg): return msg
        case .unauthorized: return "Please sign in again"
        case .notFound: return "Not found"
        case .conflict(let msg): return msg
        case .badRequest(let msg): return msg
        case .serverError(let msg): return msg
        case .decodingError: return "Something went wrong"
        }
    }
}
