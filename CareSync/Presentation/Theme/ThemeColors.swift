import SwiftUI

/// Theme colors based on the CareSync app logo
struct ThemeColors {
    // MARK: - Primary Colors

    /// Coral red - primary brand color from logo
    static let coral = Color(red: 1.0, green: 0.42, blue: 0.42)

    /// Dark teal - secondary brand color from logo
    static let teal = Color(red: 0.18, green: 0.36, blue: 0.36)

    /// Cream/beige - tertiary brand color from logo
    static let cream = Color(red: 0.96, green: 0.90, blue: 0.83)

    // MARK: - Semantic Colors

    /// Primary action color (buttons, links, etc.)
    static let primary = coral

    /// Secondary/supporting color
    static let secondary = teal

    /// Accent color for highlights and selection states
    static let accent = coral

    /// Background tint color
    static let backgroundTint = cream

    /// Success state color (completed medications, etc.)
    static let success = Color(red: 0.20, green: 0.78, blue: 0.35)

    /// Warning state color
    static let warning = Color(red: 1.0, green: 0.58, blue: 0.0)

    /// Error/alert color
    static let error = Color(red: 1.0, green: 0.23, blue: 0.19)

    // MARK: - UI Component Colors

    /// Card background color
    static let cardBackground = Color(.systemGray6)

    /// Inactive/disabled state
    static let inactive = Color.gray.opacity(0.5)
}

// MARK: - Color Extension for Convenience

extension Color {
    struct Theme {
        static let coral = ThemeColors.coral
        static let teal = ThemeColors.teal
        static let cream = ThemeColors.cream
        static let primary = ThemeColors.primary
        static let secondary = ThemeColors.secondary
        static let accent = ThemeColors.accent
        static let success = ThemeColors.success
        static let warning = ThemeColors.warning
        static let error = ThemeColors.error
    }
}
