// ChatView.swift
// iOS-FULL-2: Chat screen with real message list and composer

import SwiftUI

struct ChatView: View {
    @EnvironmentObject var appState: AppState
    @State private var messageText = ""
    @State private var scrollProxy: ScrollViewProxy?
    
    let onMenuTap: () -> Void
    let onActionTap: () -> Void
    
    var body: some View {
        ZStack {
            // Background
            SyraTokens.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Top Bar
                SyraTopBar(
                    title: appState.selectedSession?.title ?? "SYRA",
                    onLeftTap: onMenuTap,
                    onRightTap: onActionTap
                )
                
                // MARK: - Messages List
                if appState.selectedMessages.isEmpty {
                    emptyState
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: SyraTokens.Spacing.md) {
                                ForEach(appState.selectedMessages) { message in
                                    MessageBubble(message: message)
                                        .id(message.id)
                                }
                            }
                            .padding(.top, SyraTokens.Spacing.lg)
                            .padding(.bottom, SyraTokens.Spacing.xl)
                        }
                        .onAppear {
                            scrollProxy = proxy
                            scrollToBottom()
                        }
                        .onChange(of: appState.selectedMessages.count) { _ in
                            scrollToBottom()
                        }
                    }
                }
                
                // MARK: - Composer
                ChatComposer(
                    text: $messageText,
                    onSend: {
                        sendMessage()
                    },
                    onPlusAction: {
                        print("Plus action")
                    }
                )
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack {
            Spacer()
            
            VStack(spacing: SyraTokens.Spacing.lg) {
                Image(systemName: "message.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(SyraTokens.Colors.textTertiary)
                
                Text("SYRA")
                    .font(SyraTokens.Typography.titleLarge)
                    .foregroundColor(SyraTokens.Colors.textPrimary)
                
                Text("İlişki Koçu")
                    .font(SyraTokens.Typography.bodyLarge)
                    .foregroundColor(SyraTokens.Colors.textSecondary)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Actions
    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        appState.sendMessage(text)
        messageText = ""
        
        // Scroll to bottom after sending
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            scrollToBottom()
        }
    }
    
    private func scrollToBottom() {
        guard let lastMessage = appState.selectedMessages.last else { return }
        withAnimation(SyraAnimations.messageAppear) {
            scrollProxy?.scrollTo(lastMessage.id, anchor: .bottom)
        }
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView(
            onMenuTap: { print("Menu") },
            onActionTap: { print("Action") }
        )
        .environmentObject(AppState())
    }
}
