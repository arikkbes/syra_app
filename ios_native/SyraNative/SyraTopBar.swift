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
            // Left button (Hamburger Menu) - perfect 44x44 hit area
            SyraIconButton(
                icon: "line.3.horizontal",
                onTap: {
                    SyraHaptics.light()
                    onLeftTap()
                }
            )
            .padding(.leading, 8)
            
            Spacer()
            
            // Center: SYRA • Normal ˅
            HStack(spacing: 6) {
                Text("SYRA")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(SyraTokens.Colors.textPrimary)
                
                // Dot separator
                Text("•")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(SyraTokens.Colors.textSecondary.opacity(0.5))
                
                Text("Normal")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(SyraTokens.Colors.textSecondary)
                
                // Chevron down
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(SyraTokens.Colors.textSecondary)
            }
            
            Spacer()
            
            // Right button (Profile) - perfect 44x44 hit area
            SyraIconButton(
                icon: "person.circle",
                onTap: {
                    SyraHaptics.light()
                    onRightTap()
                }
            )
            .padding(.trailing, 8)
        }
        .frame(height: 56)
        .background(
            VStack(spacing: 0) {
                SyraTokens.Colors.background
                
                // Subtle bottom divider
                Rectangle()
                    .fill(SyraTokens.Colors.divider.opacity(0.2))
                    .frame(height: 0.5)
            }
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
