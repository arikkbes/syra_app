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
            
            VStack(spacing: 28) {
                // SYRA Logo - Inline Canvas implementation
                ZStack {
                    // Subtle glow behind logo
                    Canvas { context, size in
                        drawSyraLogo(context: context, size: size, color: SyraTokens.Colors.primary)
                    }
                    .frame(width: 100, height: 100)
                    .blur(radius: 20)
                    .opacity(0.3)
                    
                    // Main logo
                    Canvas { context, size in
                        drawSyraLogo(context: context, size: size, color: SyraTokens.Colors.primary)
                    }
                    .frame(width: 100, height: 100)
                }
                .padding(.bottom, 8)
                
                // Title & Subtitle - Exact Flutter text
                VStack(spacing: 8) {
                    Text("Bugün neyi çözüyoruz?")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(SyraTokens.Colors.textPrimary)
                    
                    Text("Mesajını, ilişkinizi ya da aklındaki soruyu anlat.")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(SyraTokens.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.bottom, 16)
                
                // Suggestion Chips - Exact Flutter style
                VStack(spacing: 10) {
                    SuggestionChip(text: "Sevgilimin mesajını analiz et")
                    SuggestionChip(text: "İlişkimde bir konu var, yardım eder misin?")
                    SuggestionChip(text: "Bu durumda ne yapmalıyım?")
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
    
    // Helper function to draw SYRA logo
    private func drawSyraLogo(context: GraphicsContext, size: CGSize, color: Color) {
        let lineWidth: CGFloat = 8
        var path = Path()
        
        // Left vertical line
        path.move(to: CGPoint(x: size.width * 0.2, y: size.height * 0.2))
        path.addLine(to: CGPoint(x: size.width * 0.2, y: size.height * 0.8))
        
        // Center S-curve (flowing)
        path.move(to: CGPoint(x: size.width * 0.35, y: size.height * 0.3))
        path.addQuadCurve(
            to: CGPoint(x: size.width * 0.55, y: size.height * 0.5),
            control: CGPoint(x: size.width * 0.35, y: size.height * 0.4)
        )
        path.addQuadCurve(
            to: CGPoint(x: size.width * 0.35, y: size.height * 0.7),
            control: CGPoint(x: size.width * 0.55, y: size.height * 0.6)
        )
        
        // Right horizontal lines
        path.move(to: CGPoint(x: size.width * 0.65, y: size.height * 0.3))
        path.addLine(to: CGPoint(x: size.width * 0.85, y: size.height * 0.3))
        
        path.move(to: CGPoint(x: size.width * 0.65, y: size.height * 0.45))
        path.addLine(to: CGPoint(x: size.width * 0.8, y: size.height * 0.45))
        
        // Bottom P-like shape
        path.move(to: CGPoint(x: size.width * 0.7, y: size.height * 0.6))
        path.addLine(to: CGPoint(x: size.width * 0.7, y: size.height * 0.8))
        path.addArc(
            center: CGPoint(x: size.width * 0.75, y: size.height * 0.65),
            radius: size.width * 0.08,
            startAngle: .degrees(90),
            endAngle: .degrees(270),
            clockwise: false
        )
        
        context.stroke(path, with: .color(color), lineWidth: lineWidth)
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
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(SyraTokens.Colors.textSecondary.opacity(0.9))
                .padding(.horizontal, 18)
                .padding(.vertical, 11)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(SyraTokens.Colors.backgroundSecondary.opacity(0.4))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(
                                    SyraTokens.Colors.textSecondary.opacity(0.15),
                                    lineWidth: 0.5
                                )
                        )
                )
        }
        .buttonStyle(ChipPressStyle())
        .padding(.horizontal, 32)
    }
}

// Chip press style - very subtle
struct ChipPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
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
