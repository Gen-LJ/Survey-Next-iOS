import Foundation
import Observation

/// Holds the signed-in user and their token, and survives app restarts.
/// Equivalent of `SessionManager` on Android.
///
/// `@Observable` works like a StateFlow: any view that reads `user` redraws
/// when it changes. `RootView` relies on that to swap Login ⇄ Main.
@Observable
final class SessionStore {
    /// Nil when signed out, including after the backend rejects the token.
    private(set) var user: User?

    /// Read by `APIClient` on every request; views don't need to observe it.
    @ObservationIgnored private(set) var token: String?

    @ObservationIgnored private let keychain: KeychainStorage
    @ObservationIgnored private let defaults: UserDefaults

    init(
        defaults: UserDefaults = .standard,
        keychain: KeychainStorage = KeychainStorage(service: "com.lucilab.surveynext")
    ) {
        self.defaults = defaults
        self.keychain = keychain

        let savedUser = defaults.data(forKey: Keys.user)
            .flatMap { try? JSONDecoder().decode(User.self, from: $0) }

        if let savedUser, let savedToken = keychain.string(for: Keys.token) {
            user = savedUser
            token = savedToken
        } else {
            // The Keychain outlives an uninstall; drop a token left by a previous install.
            clear()
        }
    }

    var isLoggedIn: Bool { user != nil }

    func save(token: String, user: User) {
        keychain.set(token, for: Keys.token)
        defaults.set(try? JSONEncoder().encode(user), forKey: Keys.user)
        self.token = token
        self.user = user
    }

    /// Keeps points etc. current after a `/me` refresh.
    func update(user: User) {
        guard token != nil else { return }
        defaults.set(try? JSONEncoder().encode(user), forKey: Keys.user)
        self.user = user
    }

    func clear() {
        keychain.set(nil, for: Keys.token)
        defaults.removeObject(forKey: Keys.user)
        token = nil
        user = nil
    }

    private enum Keys {
        static let token = "token"
        static let user = "user"
    }
}
