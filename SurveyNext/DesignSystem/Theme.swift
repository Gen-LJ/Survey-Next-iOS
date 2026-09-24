import SwiftUI
import UIKit

/// Brand colors from SurveyNext's `Color.kt` / `Theme.kt`: indigo primary,
/// gold accent for points. Each color has a light and a dark value and
/// switches automatically with the system appearance.
extension Color {
    static let brandPrimary = Color(light: 0x4052D6, dark: 0xBCC2FF)
    static let brandOnPrimary = Color(light: 0xFFFFFF, dark: 0x0A1F8F)
    static let brandPrimaryContainer = Color(light: 0xDFE0FF, dark: 0x2536B8)
    static let brandOnPrimaryContainer = Color(light: 0x000F5C, dark: 0xDFE0FF)
    static let brandSecondary = Color(light: 0x5B5D72, dark: 0xC4C5DD)

    /// Points and rewards (Material "tertiary").
    static let brandGold = Color(light: 0x7C5800, dark: 0xF8BD48)
    static let brandGoldContainer = Color(light: 0xFFDEA8, dark: 0x5E4200)
    static let brandOnGoldContainer = Color(light: 0x271900, dark: 0xFFDEA8)

    /// The gradient behind balances.
    static let heroStart = Color(hex: 0x4052D6)
    static let heroEnd = Color(hex: 0x7B4DDB)
    static let heroStar = Color(hex: 0xFFD27A)

    static let appBackground = Color(light: 0xFAF9FF, dark: 0x121318)
    static let appSurfaceLow = Color(light: 0xF4F3FA, dark: 0x1A1B21)
    static let appSurfaceHigh = Color(light: 0xE8E7EF, dark: 0x292A2F)
    static let appSurfaceHighest = Color(light: 0xE3E1E9, dark: 0x34343A)
    static let appOnSurface = Color(light: 0x1A1B21, dark: 0xE3E1E9)
    static let appOnSurfaceVariant = Color(light: 0x45464F, dark: 0xC6C5D0)
    static let appOutline = Color(light: 0x767680, dark: 0x90909A)
    static let appOutlineVariant = Color(light: 0xC6C5D0, dark: 0x45464F)
    static let appError = Color(light: 0xBA1A1A, dark: 0xFFB4AB)

    /// Toasts: dark on light mode, light on dark mode.
    static let appInverseSurface = Color(light: 0x2F3036, dark: 0xE3E1E9)
    static let appInverseOnSurface = Color(light: 0xF2F0F7, dark: 0x2F3036)
}

extension SurveyState {
    /// Badge colors, from `StatusPalette` on Android.
    var badgeBackground: Color {
        switch self {
        case .draft: Color(light: 0xE8E7EF, dark: 0x34343A)
        case .published: Color(light: 0xD5F5DF, dark: 0x14432A)
        case .paused: Color(light: 0xFFE9C7, dark: 0x4A3100)
        case .completed: Color(light: 0xDFE0FF, dark: 0x26307A)
        }
    }

    var badgeForeground: Color {
        switch self {
        case .draft: Color(light: 0x45464F, dark: 0xC6C5D0)
        case .published: Color(light: 0x0B6B35, dark: 0x8FDDAB)
        case .paused: Color(light: 0x7A4B00, dark: 0xFFC56B)
        case .completed: Color(light: 0x2536B8, dark: 0xBCC2FF)
        }
    }
}

/// Spacing and corner radius, in points (iOS's dp).
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

enum Radius {
    static let small: CGFloat = 12
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
}

extension Color {
    init(hex: UInt32) {
        self.init(uiColor: UIColor(hex: hex))
    }

    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
