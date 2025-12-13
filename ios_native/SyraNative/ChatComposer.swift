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
            // Plus button (attachment) - subtle
            Button(action: {
                SyraHaptics.light()
                onPlusAction()
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundColor(SyraTokens.Colors.textSecondary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(PremiumPressStyle())
            
            // Text field container (premium glass pill)
            HStack(spacing: 8) {
                // Optional: photo icon
                Button(action: {
                    SyraHaptics.light()
                }) {
                    Image(systemName: "photo")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(SyraTokens.Colors.textSecondary.opacity(0.6))
                }
                .buttonStyle(PremiumPressStyle())
                
                // Text input
                TextField("SYRA'ya sor", text: $text, axis: .vertical)
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
                    // Placeholder color override
                    .accentColor(SyraTokens.Colors.primary)
                
                // Mic icon
                Button(action: {
                    SyraHaptics.light()
                }) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(SyraTokens.Colors.textSecondary.opacity(0.6))
                }
                .buttonStyle(PremiumPressStyle())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(SyraTokens.Colors.backgroundSecondary.opacity(0.3))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.15),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
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
                            .fill(SyraTokens.Colors.primary.opacity(0.25))
                            .frame(width: 44, height: 44)
                            .blur(radius: 10)
                    }
                    
                    // Button icon
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(canSend ? SyraTokens.Colors.primary : SyraTokens.Colors.textSecondary.opacity(0.4))
                        .frame(width: 44, height: 44)
                }
            }
            .buttonStyle(PremiumPressStyle())
            .disabled(!canSend)
            .animation(.easeOut(duration: 0.25), value: canSend)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
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
