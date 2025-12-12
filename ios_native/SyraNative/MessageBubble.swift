// MessageBubble.swift
// iOS-FULL-2: Chat message bubble with user/assistant styles

import SwiftUI

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack(alignment: .bottom, spacing: SyraTokens.Spacing.sm) {
            if message.isUser {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: SyraTokens.Spacing.xs) {
                // Message text
                Text(message.text)
                    .font(SyraTokens.Typography.messageText)
                    .foregroundColor(message.isUser ? .white : SyraTokens.Colors.textPrimary)
                    .padding(.horizontal, SyraTokens.Spacing.lg)
                    .padding(.vertical, SyraTokens.Spacing.md)
                    .background(
                        Group {
                            if message.isUser {
                                // User bubble (solid color)
                                RoundedRectangle(cornerRadius: SyraTokens.Radius.messageBubble)
                                    .fill(SyraTokens.Colors.primary)
                            } else {
                                // Assistant bubble (glass effect)
                                RoundedRectangle(cornerRadius: SyraTokens.Radius.messageBubble)
                                    .fill(SyraTokens.Colors.backgroundSecondary)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: SyraTokens.Radius.messageBubble)
                                            .stroke(SyraTokens.Colors.dividerSubtle, lineWidth: 1)
                                    )
                            }
                        }
                    )
                
                // Timestamp
                Text(timeString(from: message.timestamp))
                    .font(SyraTokens.Typography.messageTimestamp)
                    .foregroundColor(SyraTokens.Colors.textTertiary)
                    .padding(.horizontal, SyraTokens.Spacing.xs)
            }
            
            if !message.isUser {
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal, SyraTokens.Spacing.screenEdge)
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
                text: "Merhaba! SYRA ile tanışmana sevindim.",
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
