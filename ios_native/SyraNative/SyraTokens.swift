// SyraTokens.swift
// iOS-FULL-2: Design system tokens for Apple-grade consistency

import SwiftUI

/// SYRA Design Tokens
/// Centralized design values for consistent UI across the app
enum SyraTokens {
    
    // MARK: - Colors
    enum Colors {
        // Primary brand colors
        static let primary = Color(hex: "8B5CF6") // Purple
        static let primaryDark = Color(hex: "7C3AED")
        
        // Background hierarchy
        static let background = Color(uiColor: .systemBackground)
        static let backgroundSecondary = Color(uiColor: .secondarySystemBackground)
        static let backgroundTertiary = Color(uiColor: .tertiarySystemBackground)
        
        // Text hierarchy
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
        static let textTertiary = Color(uiColor: .tertiaryLabel)
        
        // Semantic colors
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        
        // Glass/overlay
        static let glassOverlay = Color.white.opacity(0.05)
        static let glassBorder = Color.white.opacity(0.15)
        
        // Divider
        static let divider = Color(uiColor: .separator)
        static let dividerSubtle = Color(uiColor: .separator).opacity(0.5)
    }
    
    // MARK: - Spacing
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
        
        // Specific use cases
        static let buttonPadding: CGFloat = 12
        static let cardPadding: CGFloat = 16
        static let screenEdge: CGFloat = 16
    }
    
    // MARK: - Corner Radius
    enum Radius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        
        // Specific components
        static let button: CGFloat = 12
        static let card: CGFloat = 16
        static let messageBubble: CGFloat = 18
        static let sheet: CGFloat = 20
    }
    
    // MARK: - Typography
    enum Typography {
        // Title hierarchy
        static let titleLarge = Font.system(size: 28, weight: .bold)
        static let titleMedium = Font.system(size: 22, weight: .semibold)
        static let titleSmall = Font.system(size: 18, weight: .semibold)
        
        // Body text
        static let bodyLarge = Font.system(size: 17, weight: .regular)
        static let bodyMedium = Font.system(size: 15, weight: .regular)
        static let bodySmall = Font.system(size: 13, weight: .regular)
        
        // UI elements
        static let button = Font.system(size: 16, weight: .medium)
        static let caption = Font.system(size: 12, weight: .regular)
        static let captionBold = Font.system(size: 12, weight: .semibold)
        
        // Chat specific
        static let messageText = Font.system(size: 16, weight: .regular)
        static let messageTimestamp = Font.system(size: 11, weight: .regular)
    }
    
    // MARK: - Shadows
    enum Shadow {
        static let small = (color: Color.black.opacity(0.05), radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2))
        static let medium = (color: Color.black.opacity(0.1), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
        static let large = (color: Color.black.opacity(0.15), radius: CGFloat(16), x: CGFloat(0), y: CGFloat(8))
    }
    
    // MARK: - Opacity
    enum Opacity {
        static let pressed: CGFloat = 0.6
        static let disabled: CGFloat = 0.4
        static let subtle: CGFloat = 0.8
    }
}

// MARK: - Color Extension for Hex Support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
