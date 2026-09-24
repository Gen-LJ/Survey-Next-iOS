import Foundation

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }

    /// Loose check, same spirit as Android's `Patterns.EMAIL_ADDRESS`;
    /// the backend does the strict validation.
    var isValidEmail: Bool {
        wholeMatch(of: /[^@\s]+@[^@\s]+\.[^@\s]+/) != nil
    }
}
