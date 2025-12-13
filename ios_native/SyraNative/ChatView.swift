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
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: SyraTokens.Spacing.xxl) {
                // Logo/Mark Area - Premium circular container with glow
                ZStack {
                    // Accent glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    SyraTokens.Colors.primary.opacity(0.3),
                                    SyraTokens.Colors.primary.opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 30,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .blur(radius: 20)
                    
                    // Main container
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        SyraTokens.Colors.backgroundSecondary,
                                        SyraTokens.Colors.background
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        // Inner accent circle
                        Circle()
                            .fill(SyraTokens.Colors.primary.opacity(0.15))
                            .frame(width: 70, height: 70)
                        
                        // Icon
                        Image(systemName: "sparkles")
                            .font(.system(size: 36, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        SyraTokens.Colors.primary,
                                        SyraTokens.Colors.primary.opacity(0.8)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .frame(width: 100, height: 100)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        SyraTokens.Colors.primary.opacity(0.3),
                                        SyraTokens.Colors.primary.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: SyraTokens.Colors.primary.opacity(0.2), radius: 16, x: 0, y: 8)
                }
                .padding(.bottom, SyraTokens.Spacing.md)
                
                // Title & Subtitle
                VStack(spacing: SyraTokens.Spacing.sm) {
                    Text("Bugün neyi çözüyoruz?")
                        .font(SyraTokens.Typography.titleMedium)
                        .foregroundColor(SyraTokens.Colors.textPrimary)
                    
                    Text("Mesajını, ilişkinizi ya da aklındaki soruyu anlat.")
                        .font(SyraTokens.Typography.bodyMedium)
                        .foregroundColor(SyraTokens.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, SyraTokens.Spacing.xxl)
                }
                
                // Suggestion Chips
                VStack(spacing: SyraTokens.Spacing.md) {
                    SuggestionChip(text: "Sevgilimin mesajını analiz et")
                    SuggestionChip(text: "İlişkimde bir konu var, yardım eder misin?")
                    SuggestionChip(text: "Bu durumda ne yapmalıyım?")
                }
                .padding(.top, SyraTokens.Spacing.lg)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
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

// MARK: - Suggestion Chip Component
struct SuggestionChip: View {
    let text: String
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            SyraHaptics.light()
            // Action will be handled by parent
        }) {
            Text(text)
                .font(SyraTokens.Typography.bodyMedium)
                .foregroundColor(SyraTokens.Colors.textSecondary)
                .padding(.horizontal, SyraTokens.Spacing.lg)
                .padding(.vertical, SyraTokens.Spacing.md)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(SyraTokens.Colors.backgroundSecondary.opacity(0.6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(
                                    SyraTokens.Colors.divider.opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                )
        }
        .buttonStyle(ChipPressStyle())
        .padding(.horizontal, SyraTokens.Spacing.xxl)
    }
}

// Chip press style
struct ChipPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
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
