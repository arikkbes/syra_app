// SyraHaptics.swift
// iOS-FULL-2: Simple haptic feedback helpers

import UIKit

/// SYRA Haptics
/// Provides consistent haptic feedback across the app
enum SyraHaptics {
    
    // MARK: - Light Impact
    /// Light tap feedback (e.g., button press, selection)
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    // MARK: - Selection
    /// Selection changed feedback (e.g., switching tabs, selecting items)
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    // MARK: - Success
    /// Success notification (e.g., message sent)
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    // MARK: - Warning
    /// Warning notification (e.g., validation error)
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    // MARK: - Error
    /// Error notification (e.g., send failed)
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
}
