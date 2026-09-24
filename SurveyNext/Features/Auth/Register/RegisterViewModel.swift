import Foundation
import Observation

/// Equivalent of `RegisterViewModel`.
@Observable
final class RegisterViewModel {
    /// Loading the countries the pickers need. Swift enums with associated
    /// values are the `sealed class` of Swift.
    enum FormState {
        case loading
        case loaded([Country])
        case failed(String)
    }

    enum Field {
        case name, email, country, region, password, confirmPassword
    }

    private(set) var formState: FormState = .loading

    var role: Role = .respondent
    var name = "" { didSet { errors[.name] = nil } }
    var email = "" { didSet { errors[.email] = nil } }
    var password = "" { didSet { errors[.password] = nil } }
    var confirmPassword = "" { didSet { errors[.confirmPassword] = nil } }

    var selectedCountry: Country? {
        didSet {
            errors[.country] = nil
            // Regions belong to a country, so a new country resets the region.
            if oldValue != selectedCountry { selectedRegion = nil }
        }
    }

    var selectedRegion: Region? { didSet { errors[.region] = nil } }

    private(set) var errors: [Field: String] = [:]
    private(set) var isSubmitting = false

    /// Backend or network error, shown in an alert.
    var errorMessage: String?

    var countries: [Country] {
        if case .loaded(let countries) = formState { countries } else { [] }
    }

    var regions: [Region] { selectedCountry?.regions ?? [] }

    private let repository: any AuthRepository

    init(repository: any AuthRepository) {
        self.repository = repository
    }

    func loadForm() async {
        formState = .loading
        do {
            formState = .loaded(try await repository.registerForm())
        } catch is CancellationError {
        } catch {
            formState = .failed(error.localizedDescription)
        }
    }

    func register() async {
        guard validate(), !isSubmitting,
              let country = selectedCountry, let region = selectedRegion else { return }

        isSubmitting = true
        defer { isSubmitting = false }

        let email = email.trimmed
        do {
            _ = try await repository.register(RegisterRequest(
                name: name.trimmed,
                email: email,
                password: password,
                role: role,
                countryId: country.id,
                regionId: region.id
            ))
            // Registration returns no token, so sign straight in. That saves
            // the session and `RootView` switches to Home.
            _ = try await repository.login(email: email, password: password)
        } catch is CancellationError {
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func validate() -> Bool {
        var errors: [Field: String] = [:]
        let email = email.trimmed

        if name.trimmed.isEmpty { errors[.name] = "Name is required" }

        if email.isEmpty {
            errors[.email] = "Email is required"
        } else if !email.isValidEmail {
            errors[.email] = "Invalid email"
        }

        if selectedCountry == nil { errors[.country] = "Please select a country" }
        if selectedRegion == nil { errors[.region] = "Please select a region" }

        if password.isEmpty {
            errors[.password] = "Password is required"
        } else if password.count < 6 {
            errors[.password] = "Password must be at least 6 characters"
        }

        if confirmPassword != password { errors[.confirmPassword] = "Passwords do not match" }

        self.errors = errors
        return errors.isEmpty
    }
}
