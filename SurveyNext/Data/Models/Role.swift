import Foundation

enum Role: String, Codable, CaseIterable {
    case respondent
    case interviewer
    case admin

    var label: String {
        switch self {
        case .respondent: "Respondent"
        case .interviewer: "Interviewer"
        case .admin: "Admin"
        }
    }

    /// An unknown role from the backend falls back to respondent instead of
    /// failing the whole decode, same as `Role.from` on Android.
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = Role(rawValue: raw) ?? .respondent
    }
}
