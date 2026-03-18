import Foundation

nonisolated struct APIErrorResponse: Codable, Sendable {
    let error: String
}

nonisolated enum APIError: Error, Sendable, LocalizedError {
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
