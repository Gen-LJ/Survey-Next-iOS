import Foundation

// Display helpers, from `Format.kt` on Android.

extension Int {
    /// "1,250" in the user's locale.
    var pointsText: String { formatted() }
}

/// "1 spot" / "3 spots".
func pluralize(_ count: Int, _ singular: String, _ plural: String? = nil) -> String {
    "\(count) \(count == 1 ? singular : (plural ?? singular + "s"))"
}

enum DateText {
    /// "Sep 23, 2026", or "—" when there is no date.
    static func medium(_ date: Date?) -> String {
        date?.formatted(date: .abbreviated, time: .omitted) ?? "—"
    }

    /// "just now", "5m ago", "3h ago", "2d ago", then the date.
    static func relative(_ date: Date?) -> String {
        guard let date else { return "—" }
        let elapsed = Date.now.timeIntervalSince(date)
        switch elapsed {
        case ..<60: return "just now"
        case ..<3_600: return "\(Int(elapsed / 60))m ago"
        case ..<86_400: return "\(Int(elapsed / 3_600))h ago"
        case ..<(86_400 * 7): return "\(Int(elapsed / 86_400))d ago"
        default: return medium(date)
        }
    }
}

extension String {
    /// "Ray" from "Ray Moe".
    var firstName: String {
        split(separator: " ").first.map(String.init) ?? self
    }

    /// "RM" from "Ray Moe".
    var initials: String {
        let letters = split(separator: " ").prefix(2).compactMap(\.first).map { String($0).uppercased() }
        return letters.isEmpty ? "?" : letters.joined()
    }
}
