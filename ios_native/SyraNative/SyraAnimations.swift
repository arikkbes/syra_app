// SyraAnimations.swift
// iOS-FULL-2: Animation durations and easing curves

import SwiftUI

/// SYRA Animations
/// Centralized animation timing and curves for consistent motion
enum SyraAnimations {
    
    // MARK: - Durations
    enum Duration {
        static let instant: TimeInterval = 0.15
        static let fast: TimeInterval = 0.2
        static let normal: TimeInterval = 0.3
        static let slow: TimeInterval = 0.4
        static let verySlow: TimeInterval = 0.6
    }
    
    // MARK: - Spring Animations
    enum Spring {
        // Bouncy (for delightful interactions)
        static let bouncy = Animation.spring(response: 0.3, dampingFraction: 0.6)
        
        // Smooth (for most UI transitions)
        static let smooth = Animation.spring(response: 0.3, dampingFraction: 0.8)
        
        // Snappy (for instant feedback)
        static let snappy = Animation.spring(response: 0.2, dampingFraction: 0.9)
    }
    
    // MARK: - Easing Curves
    enum Easing {
        static let easeIn = Animation.easeIn(duration: Duration.normal)
        static let easeOut = Animation.easeOut(duration: Duration.normal)
        static let easeInOut = Animation.easeInOut(duration: Duration.normal)
        static let linear = Animation.linear(duration: Duration.normal)
    }
    
    // MARK: - Specific Use Cases
    
    /// Animation for button press feedback
    static let buttonPress = Animation.easeOut(duration: Duration.fast)
    
    /// Animation for menu slide in/out
    static let menuSlide = Spring.smooth
    
    /// Animation for sheet presentation
    static let sheetPresent = Spring.smooth
    
    /// Animation for keyboard appearance
    static let keyboard = Animation.easeOut(duration: Duration.normal)
    
    /// Animation for message appearance
    static let messageAppear = Spring.snappy
    
    /// Animation for fade transitions
    static let fade = Animation.easeInOut(duration: Duration.normal)
}

// MARK: - View Extensions for Common Animations

extension View {
    /// Apply button press scale effect
    func buttonPressEffect(isPressed: Bool) -> some View {
        self
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .opacity(isPressed ? SyraTokens.Opacity.pressed : 1.0)
            .animation(SyraAnimations.buttonPress, value: isPressed)
    }
    
    /// Apply fade in animation
    func fadeIn(delay: TimeInterval = 0) -> some View {
        self
            .opacity(0)
            .animation(
                SyraAnimations.fade.delay(delay),
                value: true
            )
            .onAppear {
                // Trigger animation
            }
    }
}
