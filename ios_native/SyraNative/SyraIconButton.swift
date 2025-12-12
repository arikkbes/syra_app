// SyraIconButton.swift
// iOS-FULL-2: Icon button with haptics and press feedback

import SwiftUI

struct SyraIconButton: View {
    let icon: String
    let size: CGFloat
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    init(
        icon: String,
        size: CGFloat = 44, // Apple HIG recommended minimum tap target
        onTap: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: {
            SyraHaptics.light()
            onTap()
        }) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(SyraTokens.Colors.textPrimary)
                .frame(width: size, height: size)
                .contentShape(Rectangle())
        }
        .buttonStyle(SyraButtonPressStyle())
    }
}

// MARK: - Button Press Style
/// Custom button style for press feedback
struct SyraButtonPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? SyraTokens.Opacity.pressed : 1.0)
            .animation(SyraAnimations.buttonPress, value: configuration.isPressed)
    }
}

struct SyraIconButton_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 20) {
            SyraIconButton(icon: "line.3.horizontal", onTap: {})
            SyraIconButton(icon: "square.and.pencil", onTap: {})
            SyraIconButton(icon: "ellipsis.circle", onTap: {})
        }
        .padding()
    }
}
