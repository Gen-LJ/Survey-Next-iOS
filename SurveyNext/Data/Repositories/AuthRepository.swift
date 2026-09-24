import Foundation

/// A protocol is Swift's interface. Views depend on this, so previews and
/// tests can pass a fake.
protocol AuthRepository {
    /// Signs in and persists the session.
    func login(email: String, password: String) async throws -> User

    /// Creates the account. The backend returns no token, so call `login` after.
    func register(_ request: RegisterRequest) async throws -> User

    /// Active countries with their regions, for the register pickers.
    func registerForm() async throws -> [Country]

    /// Re-reads the signed-in user, keeping the saved session current.
    func refreshUser() async throws -> User

    /// "Region, Country" for the ids, or nil when the lookup fails.
    func locationName(countryId: Int, regionId: Int) async -> String?

    func logout()
}

final class DefaultAuthRepository: AuthRepository {
    private let api: APIClient
    private let session: SessionStore
    private var cachedCountries: [Country]?

    init(api: APIClient, session: SessionStore) {
        self.api = api
        self.session = session
    }

    func login(email: String, password: String) async throws -> User {
        let data: LoginData = try await api.send(.login(LoginRequest(email: email, password: password)))
        session.save(token: data.token, user: data.user)
        return data.user
    }

    func register(_ request: RegisterRequest) async throws -> User {
        try await api.send(.register(request))
    }

    func registerForm() async throws -> [Country] {
        if let cachedCountries { return cachedCountries }
        let countries: [Country] = try await api.send(.registerForm)
        cachedCountries = countries
        return countries
    }

    func refreshUser() async throws -> User {
        let user: User = try await api.send(.me)
        session.update(user: user)
        return user
    }

    func locationName(countryId: Int, regionId: Int) async -> String? {
        guard let countries = try? await registerForm(),
              let country = countries.first(where: { $0.id == countryId }) else { return nil }
        let region = country.regions?.first { $0.id == regionId }
        return [region?.name, country.name].compactMap { $0 }.joined(separator: ", ")
    }

    func logout() {
        session.clear()
    }
}
