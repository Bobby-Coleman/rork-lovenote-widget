import Foundation

final class SupabaseService: Sendable {
    static let shared = SupabaseService()

    private let supabaseURL: String
    private let anonKey: String

    private init() {
        supabaseURL = Config.EXPO_PUBLIC_SUPABASE_URL
        anonKey = Config.EXPO_PUBLIC_SUPABASE_ANON_KEY
    }

    private var authURL: String { "\(supabaseURL)/auth/v1" }
    private var restURL: String { "\(supabaseURL)/rest/v1" }

    // MARK: - Auth

    func signUp(email: String, password: String) async throws -> SupabaseAuthResponse {
        let body: [String: String] = ["email": email, "password": password]
        return try await authRequest(path: "/signup", method: "POST", body: body)
    }

    func signIn(email: String, password: String) async throws -> SupabaseAuthResponse {
        let body: [String: String] = ["email": email, "password": password]
        return try await authRequest(path: "/token?grant_type=password", method: "POST", body: body)
    }

    func refreshSession(refreshToken: String) async throws -> SupabaseAuthResponse {
        let body: [String: String] = ["refresh_token": refreshToken]
        return try await authRequest(path: "/token?grant_type=refresh_token", method: "POST", body: body)
    }

    func getUser(accessToken: String) async throws -> SupabaseUser {
        let url = URL(string: "\(authURL)/user")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return try await perform(request)
    }

    // MARK: - Profiles

    func createProfile(id: String, username: String, displayName: String?, accessToken: String) async throws {
        var body: [String: String] = ["id": id, "username": username]
        if let displayName { body["display_name"] = displayName }
        let _: [SupabaseProfile] = try await restRequest(
            path: "/profiles",
            method: "POST",
            body: body,
            accessToken: accessToken,
            prefer: "return=representation"
        )
    }

    func getProfile(id: String, accessToken: String) async throws -> SupabaseProfile? {
        let profiles: [SupabaseProfile] = try await restGet(
            path: "/profiles?id=eq.\(id)&limit=1",
            accessToken: accessToken
        )
        return profiles.first
    }

    func searchProfiles(username: String, accessToken: String) async throws -> [SupabaseProfile] {
        let encoded = username.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? username
        return try await restGet(
            path: "/profiles?username=ilike.*\(encoded)*&limit=10",
            accessToken: accessToken
        )
    }

    // MARK: - Partnerships

    func getPartnership(userID: String, accessToken: String) async throws -> SupabasePartnership? {
        let partnerships: [SupabasePartnership] = try await restGet(
            path: "/partnerships?user_id=eq.\(userID)&limit=1",
            accessToken: accessToken
        )
        return partnerships.first
    }

    func addPartner(userID: String, partnerID: String, accessToken: String) async throws {
        let body: [String: String] = ["user_id": userID, "partner_id": partnerID]
        let _: [SupabasePartnership] = try await restRequest(
            path: "/partnerships",
            method: "POST",
            body: body,
            accessToken: accessToken,
            prefer: "return=representation"
        )
    }

    func removePartner(userID: String, accessToken: String) async throws {
        let url = URL(string: "\(restURL)/partnerships?user_id=eq.\(userID)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw SupabaseError.serverError("Failed to remove partner")
        }
    }

    // MARK: - Notes

    func sendNote(content: String, senderID: String, receiverID: String, accessToken: String) async throws -> SupabaseNote {
        let body: [String: String] = [
            "content": content,
            "sender_id": senderID,
            "receiver_id": receiverID,
        ]
        let notes: [SupabaseNote] = try await restRequest(
            path: "/notes",
            method: "POST",
            body: body,
            accessToken: accessToken,
            prefer: "return=representation"
        )
        guard let note = notes.first else { throw SupabaseError.serverError("Failed to create note") }
        return note
    }

    func getLatestReceivedNote(receiverID: String, accessToken: String) async throws -> SupabaseNote? {
        let notes: [SupabaseNote] = try await restGet(
            path: "/notes?receiver_id=eq.\(receiverID)&order=created_at.desc&limit=1",
            accessToken: accessToken
        )
        return notes.first
    }

    func getSentNotes(senderID: String, accessToken: String) async throws -> [SupabaseNote] {
        return try await restGet(
            path: "/notes?sender_id=eq.\(senderID)&order=created_at.desc&limit=50",
            accessToken: accessToken
        )
    }

    func getReceivedNotes(receiverID: String, accessToken: String) async throws -> [SupabaseNote] {
        return try await restGet(
            path: "/notes?receiver_id=eq.\(receiverID)&order=created_at.desc&limit=50",
            accessToken: accessToken
        )
    }

    // MARK: - Private Helpers

    private func authRequest<T: Decodable>(path: String, method: String, body: [String: String]) async throws -> T {
        let url = URL(string: "\(authURL)\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.httpBody = try JSONEncoder().encode(body)
        return try await perform(request)
    }

    private func restGet<T: Decodable>(path: String, accessToken: String) async throws -> T {
        let url = URL(string: "\(restURL)\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return try await perform(request)
    }

    private func restRequest<T: Decodable>(path: String, method: String, body: [String: String], accessToken: String, prefer: String? = nil) async throws -> T {
        let url = URL(string: "\(restURL)\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        if let prefer {
            request.setValue(prefer, forHTTPHeaderField: "Prefer")
        }
        request.httpBody = try JSONEncoder().encode(body)
        return try await perform(request)
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw SupabaseError.networkError("Invalid response")
        }

        switch http.statusCode {
        case 200...299:
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                return try decoder.decode(T.self, from: data)
            } catch {
                throw SupabaseError.decodingError
            }
        case 401:
            throw SupabaseError.unauthorized
        case 409, 422:
            if let errBody = try? JSONDecoder().decode(SupabaseErrorBody.self, from: data) {
                throw SupabaseError.conflict(errBody.message ?? errBody.msg ?? errBody.errorDescription ?? "Conflict")
            }
            throw SupabaseError.conflict("Already exists")
        case 400:
            if let errBody = try? JSONDecoder().decode(SupabaseErrorBody.self, from: data) {
                throw SupabaseError.badRequest(errBody.message ?? errBody.msg ?? errBody.errorDescription ?? "Bad request")
            }
            throw SupabaseError.badRequest("Bad request")
        default:
            if let errBody = try? JSONDecoder().decode(SupabaseErrorBody.self, from: data) {
                throw SupabaseError.serverError(errBody.message ?? errBody.msg ?? errBody.errorDescription ?? "Server error")
            }
            throw SupabaseError.serverError("Something went wrong (\(http.statusCode))")
        }
    }
}
