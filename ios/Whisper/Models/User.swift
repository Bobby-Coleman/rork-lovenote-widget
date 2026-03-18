import Foundation

nonisolated struct UserProfile: Codable, Sendable {
    let id: String
    let username: String
    let displayName: String?

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case displayName = "display_name"
    }
}

nonisolated struct AuthSession: Codable, Sendable {
    let accessToken: String
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }
}

nonisolated struct AuthResponse: Codable, Sendable {
    let user: UserResponse
    let session: AuthSession
}

nonisolated struct UserResponse: Codable, Sendable {
    let id: String
    let email: String?
    let username: String?
    let displayName: String?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case username
        case displayName = "display_name"
    }
}

nonisolated struct MeResponse: Codable, Sendable {
    let user: UserResponse
    let partner: UserResponse?
}
