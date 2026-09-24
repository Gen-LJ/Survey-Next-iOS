import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

/// One API call: path, method and body. The static factories (here and in the
/// `Endpoint+…` files) play the role of the Retrofit `RestApi` interfaces.
struct Endpoint {
    let path: String
    var method: HTTPMethod = .get
    var body: (any Encodable)?
    var query: [URLQueryItem] = []
    /// Public endpoints send no token, and a 401 from them (wrong password)
    /// must not end the session.
    var requiresAuth = true
}

// MARK: - Auth and shared

extension Endpoint {
    static func login(_ request: LoginRequest) -> Endpoint {
        Endpoint(path: "auth/login", method: .post, body: request, requiresAuth: false)
    }

    static func register(_ request: RegisterRequest) -> Endpoint {
        Endpoint(path: "auth/register", method: .post, body: request, requiresAuth: false)
    }

    static var registerForm: Endpoint {
        Endpoint(path: "auth/register-form", requiresAuth: false)
    }

    static var me: Endpoint {
        Endpoint(path: "me")
    }

    /// Active regions of a country; any signed-in user.
    static func regions(countryId: Int) -> Endpoint {
        Endpoint(path: "regions/\(countryId)")
    }
}

extension [URLQueryItem] {
    static func page(_ page: Int, limit: Int) -> [URLQueryItem] {
        [URLQueryItem(name: "page", value: String(page)), URLQueryItem(name: "limit", value: String(limit))]
    }
}
