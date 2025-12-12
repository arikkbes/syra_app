// ChatComposer.swift
// iOS-FULL-2.5: Premium chat composer - Claude/ChatGPT iOS vibe

import SwiftUI

struct ChatComposer: View {
    @Binding var text: String
    let onSend: () -> Void
    let onPlusAction: () -> Void
    
    @FocusState private var isFocused: Bool
    @State private var isSending = false
    
    var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        HStack(spacing: 10) {
            // Plus button (pixel-perfect)
            Button(action: {
                SyraHaptics.light()
                onPlusAction()
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundColor(SyraTokens.Colors.primary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(PremiumPressStyle())
            
            // Text field container (pill shape)
            HStack(spacing: 12) {
                TextField("Mesajınızı yazın...", text: $text, axis: .vertical)
                    .font(SyraTokens.Typography.bodyMedium)
                    .foregroundColor(SyraTokens.Colors.textPrimary)
                    .focused($isFocused)
                    .lineLimit(1...5)
                    .submitLabel(.send)
                    .onSubmit {
                        if canSend {
                            sendWithAnimation()
                        }
                    }
                    // Baseline alignment fix
                    .alignmentGuide(.firstTextBaseline) { d in
                        d[.firstTextBaseline]
                    }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(minHeight: 44) // Ensure proper height
            .background(
                SyraGlassSurface(
                    cornerRadius: 22, // Perfect pill
                    blurIntensity: .ultraLight
                )
            )
            
            // Send button (premium states + glow)
            Button(action: {
                if canSend {
                    sendWithAnimation()
                }
            }) {
                ZStack {
                    // Glow effect when enabled
                    if canSend {
                        Circle()
                            .fill(SyraTokens.Colors.primary.opacity(0.2))
                            .frame(width: 44, height: 44)
                            .blur(radius: 8)
                    }
                    
                    // Button icon
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(canSend ? SyraTokens.Colors.primary : SyraTokens.Colors.textTertiary)
                        .frame(width: 44, height: 44)
                }
            }
            .buttonStyle(PremiumPressStyle())
            .disabled(!canSend)
            .animation(.easeOut(duration: 0.2), value: canSend)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            SyraTokens.Colors.background
                .ignoresSafeArea(edges: .bottom)
        )
    }
    
    private func sendWithAnimation() {
        guard !isSending else { return }
        isSending = true
        SyraHaptics.success()
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            onSend()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isSending = false
        }
    }
}

/// Premium press style with scale + opacity feedback
struct PremiumPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
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
