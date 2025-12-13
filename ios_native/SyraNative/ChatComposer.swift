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
        HStack(spacing: 8) {
            // Plus button (left)
            Button(action: {
                SyraHaptics.light()
                onPlusAction()
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(SyraTokens.Colors.textSecondary.opacity(0.7))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(PremiumPressStyle())
            
            // Main input container
            HStack(spacing: 8) {
                // Text input
                TextField("SYRA'ya sor", text: $text, axis: .vertical)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(SyraTokens.Colors.textPrimary)
                    .focused($isFocused)
                    .lineLimit(1...5)
                    .submitLabel(.send)
                    .onSubmit {
                        if canSend {
                            sendWithAnimation()
                        }
                    }
                    .accentColor(SyraTokens.Colors.primary)
                    .padding(.leading, 4)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(SyraTokens.Colors.backgroundSecondary.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(
                                SyraTokens.Colors.textSecondary.opacity(0.1),
                                lineWidth: 0.5
                            )
                    )
            )
            
            // Mode selector dropdown (Flutter style)
            HStack(spacing: 4) {
                Text("Normal")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(SyraTokens.Colors.textSecondary)
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(SyraTokens.Colors.textSecondary.opacity(0.7))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(SyraTokens.Colors.backgroundSecondary.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(
                                SyraTokens.Colors.textSecondary.opacity(0.1),
                                lineWidth: 0.5
                            )
                    )
            )
            .onTapGesture {
                SyraHaptics.light()
                // Mode selector action
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            SyraTokens.Colors.background
                .ignoresSafeArea(edges: .bottom)
        )
    }
    
    private func sendWithAnimation() {
        guard !isSending, canSend else { return }
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
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
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
