#if DEBUG
import Foundation

/// Canned data so SwiftUI previews render without the backend.
final class PreviewAuthRepository: AuthRepository {
    static let user = User(
        id: 1, name: "Ray Moe", email: "ray@example.com", role: .respondent,
        points: 250, pendingPoints: 0, countryId: 119, regionId: 1
    )

    static let interviewer = User(
        id: 2, name: "Iva Tun", email: "iva@example.com", role: .interviewer,
        points: 1_000, pendingPoints: 0, countryId: 119, regionId: 1
    )

    func login(email: String, password: String) async throws -> User { Self.user }

    func register(_ request: RegisterRequest) async throws -> User { Self.user }

    func registerForm() async throws -> [Country] {
        [
            Country(id: 119, name: "Myanmar", code: "MMR", regions: [
                Region(id: 1, name: "Yangon", code: "YGN"),
                Region(id: 2, name: "Mandalay", code: "MDY"),
            ]),
        ]
    }

    func refreshUser() async throws -> User { Self.user }

    func locationName(countryId: Int, regionId: Int) async -> String? { "Yangon, Myanmar" }

    func logout() {}
}

extension AppContainer {
    /// Fake repositories and a throwaway session, for `#Preview`s.
    static func preview(user: User? = PreviewAuthRepository.user) -> AppContainer {
        let session = SessionStore(
            defaults: UserDefaults(suiteName: "preview") ?? .standard,
            keychain: KeychainStorage(service: "com.lucilab.surveynext.preview")
        )
        if let user {
            session.save(token: "preview", user: user)
        }
        return AppContainer(
            session: session,
            notifier: DataChangeNotifier(),
            authRepository: PreviewAuthRepository(),
            interviewerRepository: PreviewInterviewerRepository(),
            respondentRepository: PreviewRespondentRepository()
        )
    }
}
#endif
