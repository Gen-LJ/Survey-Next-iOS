import Foundation

/// `data` of `POST /auth/login`.
struct LoginData: Decodable {
    let token: String
    let user: User
}
