// SyraTopBar.swift
// iOS-FULL-2: Reusable top navigation bar with design tokens

import SwiftUI

struct SyraTopBar: View {
    let title: String
    let onLeftTap: () -> Void
    let onRightTap: () -> Void
    
    init(
        title: String = "SYRA",
        onLeftTap: @escaping () -> Void,
        onRightTap: @escaping () -> Void
    ) {
        self.title = title
        self.onLeftTap = onLeftTap
        self.onRightTap = onRightTap
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Left button (Menu)
            SyraIconButton(
                icon: "line.3.horizontal",
                onTap: onLeftTap
            )
            .padding(.leading, SyraTokens.Spacing.sm)
            
            Spacer()
            
            // Center title
            Text(title)
                .font(SyraTokens.Typography.titleSmall)
                .foregroundColor(SyraTokens.Colors.textPrimary)
            
            Spacer()
            
            // Right button (Action placeholder)
            SyraIconButton(
                icon: "ellipsis.circle",
                onTap: onRightTap
            )
            .padding(.trailing, SyraTokens.Spacing.sm)
        }
        .frame(height: 56)
        .background(
            SyraTokens.Colors.background
                .shadow(
                    color: SyraTokens.Shadow.small.color,
                    radius: SyraTokens.Shadow.small.radius,
                    x: SyraTokens.Shadow.small.x,
                    y: SyraTokens.Shadow.small.y
                )
        )
    }
}

struct SyraTopBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            SyraTopBar(
                onLeftTap: { print("Left tapped") },
                onRightTap: { print("Right tapped") }
            )
            Spacer()
        }
    }
}
