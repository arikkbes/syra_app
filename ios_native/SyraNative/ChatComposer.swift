// ChatComposer.swift
// iOS-FULL-2: Chat input bar with glass effect

import SwiftUI

struct ChatComposer: View {
    @Binding var text: String
    let onSend: () -> Void
    let onPlusAction: () -> Void
    
    @FocusState private var isFocused: Bool
    
    var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        HStack(spacing: SyraTokens.Spacing.md) {
            // Plus button
            Button(action: {
                SyraHaptics.light()
                onPlusAction()
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(SyraTokens.Colors.primary)
            }
            .buttonStyle(SyraButtonPressStyle())
            
            // Text field container
            HStack(spacing: SyraTokens.Spacing.sm) {
                TextField("Mesajınızı yazın...", text: $text, axis: .vertical)
                    .font(SyraTokens.Typography.bodyMedium)
                    .focused($isFocused)
                    .lineLimit(1...5)
                    .submitLabel(.send)
                    .onSubmit {
                        if canSend {
                            onSend()
                        }
                    }
            }
            .padding(.horizontal, SyraTokens.Spacing.lg)
            .padding(.vertical, SyraTokens.Spacing.md)
            .background(
                ZStack {
                    SyraGlassSurface(
                        cornerRadius: SyraTokens.Radius.xl,
                        borderOpacity: 0.1
                    )
                }
            )
            
            // Send button
            Button(action: {
                if canSend {
                    SyraHaptics.success()
                    onSend()
                }
            }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(canSend ? SyraTokens.Colors.primary : SyraTokens.Colors.textTertiary)
            }
            .buttonStyle(SyraButtonPressStyle())
            .disabled(!canSend)
        }
        .padding(.horizontal, SyraTokens.Spacing.screenEdge)
        .padding(.vertical, SyraTokens.Spacing.md)
        .background(
            SyraTokens.Colors.background
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

struct ChatComposer_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            ChatComposer(
                text: .constant("Merhaba!"),
                onSend: { print("Send") },
                onPlusAction: { print("Plus") }
            )
        }
        .background(SyraTokens.Colors.background)
    }
}
