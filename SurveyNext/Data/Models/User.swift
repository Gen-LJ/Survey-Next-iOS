import Foundation

/// Mirrors the backend's `UserResponse`. Property names are camelCase;
/// `APIClient` converts from snake_case (`pending_points` -> `pendingPoints`).
struct User: Codable, Equatable, Identifiable {
    let id: Int
    let name: String
    let email: String
    let role: Role
    let points: Int
    let pendingPoints: Int
    let countryId: Int
    let regionId: Int
}
