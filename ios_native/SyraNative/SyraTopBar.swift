// SyraTopBar.swift
// iOS-FULL-2.5: Premium top navigation bar - clean and sophisticated

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
            // Left button (Menu) - perfect 44x44 hit area
            SyraIconButton(
                icon: "line.3.horizontal",
                onTap: {
                    SyraHaptics.light()
                    onLeftTap()
                }
            )
            .padding(.leading, 8)
            
            Spacer()
            
            // Center title
            Text(title)
                .font(SyraTokens.Typography.titleSmall)
                .foregroundColor(SyraTokens.Colors.textPrimary)
            
            Spacer()
            
            // Right button (Action placeholder) - perfect 44x44 hit area
            SyraIconButton(
                icon: "ellipsis.circle",
                onTap: {
                    SyraHaptics.light()
                    onRightTap()
                }
            )
            .padding(.trailing, 8)
        }
        .frame(height: 56)
        .background(
            SyraTokens.Colors.background
                // Soft, realistic shadow (no harsh borders)
                .shadow(
                    color: Color.black.opacity(0.03),
                    radius: 1,
                    x: 0,
                    y: 1
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
