import Foundation
import Observation

/// Equivalent of `LoginViewModel`. With `@Observable`, plain `var`s play the
/// role of `mutableStateOf`: the view redraws when one it reads changes.
@Observable
final class LoginViewModel {
    var email = "" { didSet { emailError = nil } }
    var password = "" { didSet { passwordError = nil } }

    private(set) var emailError: String?
    private(set) var passwordError: String?
    private(set) var isLoading = false

    /// Backend or network error, shown in an alert.
    var errorMessage: String?

    private let repository: any AuthRepository

    init(repository: any AuthRepository) {
        self.repository = repository
    }

    /// On success the session changes and `RootView` shows Home by itself,
    /// so there's no success state to navigate from.
    func login() async {
        guard validate(), !isLoading else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await repository.login(email: email.trimmed, password: password)
        } catch is CancellationError {
            // The screen went away; nothing to show.
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func validate() -> Bool {
        let email = email.trimmed
        if email.isEmpty {
            emailError = "Email cannot be empty"
        } else if !email.isValidEmail {
            emailError = "Invalid email format"
        }
        if password.isEmpty {
            passwordError = "Password cannot be empty"
        }
        return emailError == nil && passwordError == nil
    }
}
