import Foundation

/// Everything `APIClient` can throw. `errorDescription` is what the UI shows,
/// so `error.localizedDescription` is always a readable sentence.
enum APIError: LocalizedError {
    /// The backend answered but refused, e.g. "invalid credentials".
    case server(String)
    /// The token was rejected; the session has been cleared.
    case unauthorized
    /// No connection, DNS failure, timeout...
    case network
    /// The response didn't match the model.
    case decoding

    var errorDescription: String? {
        switch self {
        case .server(let message):
            return message.prefix(1).uppercased() + message.dropFirst()
        case .unauthorized:
            return "Your session has expired. Please log in again."
        case .network:
            return "Can't reach the server. Check your connection."
        case .decoding:
            return "Unexpected response from the server."
        }
    }
}
