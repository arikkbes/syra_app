// MessageBubble.swift
// iOS-FULL-2.5: Premium message bubbles with glass effect and animations

import SwiftUI

struct MessageBubble: View {
    let message: Message
    @State private var appeared = false
    
    var body: some View {
        HStack(alignment: .bottom, spacing: SyraTokens.Spacing.sm) {
            if message.isUser {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                // Message text
                Text(message.text)
                    .font(SyraTokens.Typography.messageText)
                    .foregroundColor(message.isUser ? .white : SyraTokens.Colors.textPrimary.opacity(0.95))
                    .multilineTextAlignment(message.isUser ? .trailing : .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        Group {
                            if message.isUser {
                                // User bubble (solid with depth)
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(SyraTokens.Colors.primary)
                                    .shadow(
                                        color: SyraTokens.Colors.primary.opacity(0.3),
                                        radius: 8,
                                        x: 0,
                                        y: 3
                                    )
                                    .shadow(
                                        color: Color.black.opacity(0.08),
                                        radius: 2,
                                        x: 0,
                                        y: 1
                                    )
                            } else {
                                // Assistant bubble (premium glass)
                                SyraGlassSurface(
                                    cornerRadius: 18,
                                    blurIntensity: .ultraLight,
                                    tint: SyraTokens.Colors.primary
                                )
                            }
                        }
                    )
                
                // Timestamp
                Text(timeString(from: message.timestamp))
                    .font(SyraTokens.Typography.messageTimestamp)
                    .foregroundColor(SyraTokens.Colors.textTertiary)
                    .padding(.horizontal, 4)
            }
            
            if !message.isUser {
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal, SyraTokens.Spacing.screenEdge)
        // Message appear animation
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }
}

struct MessageBubble_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 12) {
            MessageBubble(message: Message(
                text: "Merhaba! SYRA ile tanışmana sevindim. Nasıl yardımcı olabilirim?",
                isUser: false
            ))
            
            MessageBubble(message: Message(
                text: "Sevgilimle bir sorunum var, tavsiye alabilir miyim?",
                isUser: true
            ))
        }
        .padding()
        .background(SyraTokens.Colors.background)
    }
}
