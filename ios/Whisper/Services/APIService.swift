import Foundation

final class APIService: Sendable {
    static let shared = APIService()

    private let baseURL: String

    private init() {
        let configURL = Config.EXPO_PUBLIC_RORK_API_BASE_URL
        baseURL = configURL.isEmpty ? "https://api.example.com" : configURL
    }

    private var apiURL: String { "\(baseURL)/api" }

    func register(email: String, password: String, username: String) async throws -> AuthResponse {
        let body: [String: String] = [
            "email": email,
            "password": password,
            "username": username,
        ]
        return try await post(path: "/auth/register", body: body)
    }

    func login(identifier: String, password: String) async throws -> AuthResponse {
        let body: [String: String] = [
            "identifier": identifier,
            "password": password,
        ]
        return try await post(path: "/auth/login", body: body)
    }

    func getMe(token: String) async throws -> MeResponse {
        return try await get(path: "/auth/me", token: token)
    }

    func refreshToken(_ refreshToken: String) async throws -> RefreshResponse {
        let body: [String: String] = ["refresh_token": refreshToken]
        return try await post(path: "/auth/refresh", body: body)
    }

    func searchUsers(username: String, token: String) async throws -> SearchUsersResponse {
        return try await get(path: "/partner/search?username=\(username)", token: token)
    }

    func addPartner(username: String, token: String) async throws -> AddPartnerResponse {
        let body: [String: String] = ["partner_username": username]
        return try await post(path: "/partner/add", body: body, token: token)
    }

    func removePartner(token: String) async throws {
        let _: EmptyResponse = try await delete(path: "/partner/remove", token: token)
    }

    func sendNote(content: String, token: String) async throws -> SendNoteResponse {
        let body: [String: String] = ["content": content]
        return try await post(path: "/notes/send", body: body, token: token)
    }

    func getLatestNote(token: String) async throws -> NoteResponse {
        return try await get(path: "/notes/latest", token: token)
    }

    func getSentNotes(token: String) async throws -> NotesListResponse {
        return try await get(path: "/notes/sent", token: token)
    }

    func getReceivedNotes(token: String) async throws -> NotesListResponse {
        return try await get(path: "/notes/received", token: token)
    }

    private func get<T: Decodable>(path: String, token: String? = nil) async throws -> T {
        let url = URL(string: "\(apiURL)\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return try await perform(request)
    }

    private func post<T: Decodable>(path: String, body: [String: String], token: String? = nil) async throws -> T {
        let url = URL(string: "\(apiURL)\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONEncoder().encode(body)
        return try await perform(request)
    }

    private func delete<T: Decodable>(path: String, token: String? = nil) async throws -> T {
        let url = URL(string: "\(apiURL)\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return try await perform(request)
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError("Invalid response")
        }

        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                throw APIError.decodingError
            }
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        case 409:
            if let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                throw APIError.conflict(errorResponse.error)
            }
            throw APIError.conflict("Conflict")
        case 400:
            if let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                throw APIError.badRequest(errorResponse.error)
            }
            throw APIError.badRequest("Bad request")
        default:
            if let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                throw APIError.serverError(errorResponse.error)
            }
            throw APIError.serverError("Something went wrong")
        }
    }
}

nonisolated struct SearchUsersResponse: Codable, Sendable {
    let users: [UserResponse]
}

nonisolated struct AddPartnerResponse: Codable, Sendable {
    let partner: UserResponse
}

nonisolated struct RefreshResponse: Codable, Sendable {
    let session: AuthSession
}

nonisolated struct EmptyResponse: Codable, Sendable {
    let success: Bool?
}
