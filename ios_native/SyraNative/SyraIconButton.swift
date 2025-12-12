// SyraIconButton.swift
// iOS-FULL-2.5: Premium icon button with perfect hit area and micro-interactions

import SwiftUI

struct SyraIconButton: View {
    let icon: String
    let size: CGFloat
    let onTap: () -> Void
    
    init(
        icon: String,
        size: CGFloat = 44, // Apple HIG recommended minimum (unchanged)
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
                .contentShape(Rectangle()) // Perfect hit area
        }
        .buttonStyle(PremiumIconPressStyle())
    }
}

/// Premium icon button press style - subtle highlight on press
struct PremiumIconPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .background(
                Circle()
                    .fill(SyraTokens.Colors.textPrimary.opacity(configuration.isPressed ? 0.08 : 0))
                    .frame(width: 44, height: 44)
            )
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
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
