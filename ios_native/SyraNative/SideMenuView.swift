// SideMenuView.swift
// iOS-FULL-2: Side menu with real chat sessions from AppState

import SwiftUI

struct SideMenuView: View {
    @EnvironmentObject var appState: AppState
    @Binding var isOpen: Bool
    let onClose: () -> Void
    
    var body: some View {
        ZStack {
            // Background
            SyraTokens.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Header (Search + Compose)
                HStack(spacing: SyraTokens.Spacing.md) {
                    // Search bar placeholder
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(SyraTokens.Colors.textSecondary)
                        Text("Ara...")
                            .foregroundColor(SyraTokens.Colors.textSecondary)
                        Spacer()
                    }
                    .padding(.horizontal, SyraTokens.Spacing.md)
                    .frame(height: 40)
                    .background(SyraTokens.Colors.backgroundSecondary)
                    .cornerRadius(SyraTokens.Radius.md)
                    
                    // Compose button
                    SyraIconButton(
                        icon: "square.and.pencil",
                        onTap: {
                            appState.createNewChat()
                            onClose()
                        }
                    )
                }
                .padding(.horizontal, SyraTokens.Spacing.screenEdge)
                .padding(.top, SyraTokens.Spacing.screenEdge)
                .padding(.bottom, SyraTokens.Spacing.sm)
                
                // MARK: - Primary Actions Section
                VStack(alignment: .leading, spacing: 0) {
                    Text("Sohbetler")
                        .font(SyraTokens.Typography.titleMedium)
                        .padding(.horizontal, SyraTokens.Spacing.screenEdge)
                        .padding(.bottom, SyraTokens.Spacing.sm)
                    
                    SideMenuItem(
                        icon: "plus.circle",
                        label: "Yeni Sohbet",
                        onTap: {
                            appState.createNewChat()
                            onClose()
                        }
                    )
                    
                    SideMenuItem(
                        icon: "sparkles",
                        label: "Tarot Modu",
                        onTap: {
                            print("Tarot mode")
                            onClose()
                        }
                    )
                    
                    SideMenuItem(
                        icon: "chart.bar",
                        label: "Kim Daha Çok?",
                        onTap: {
                            print("Kim Daha Çok")
                            onClose()
                        }
                    )
                }
                .padding(.bottom, SyraTokens.Spacing.lg)
                
                // MARK: - Divider
                Rectangle()
                    .fill(SyraTokens.Colors.divider)
                    .frame(height: 1)
                    .padding(.horizontal, SyraTokens.Spacing.screenEdge)
                
                // MARK: - Recent Chats Section
                VStack(alignment: .leading, spacing: 0) {
                    Text("GEÇMİŞ")
                        .font(SyraTokens.Typography.captionBold)
                        .foregroundColor(SyraTokens.Colors.textSecondary)
                        .padding(.horizontal, SyraTokens.Spacing.screenEdge)
                        .padding(.top, SyraTokens.Spacing.lg)
                        .padding(.bottom, SyraTokens.Spacing.sm)
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(appState.chatSessions) { session in
                                ChatListItem(
                                    session: session,
                                    isSelected: session.id == appState.selectedSessionId,
                                    onTap: {
                                        appState.selectSession(session)
                                        onClose()
                                    },
                                    onDelete: {
                                        appState.deleteSession(session)
                                    }
                                )
                            }
                        }
                    }
                }
                
                Spacer()
                
                // MARK: - Bottom Profile Section
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(SyraTokens.Colors.divider)
                        .frame(height: 1)
                        .padding(.horizontal, SyraTokens.Spacing.screenEdge)
                    
                    Button(action: {
                        print("Settings")
                        onClose()
                    }) {
                        HStack(spacing: SyraTokens.Spacing.md) {
                            // User avatar
                            Circle()
                                .fill(LinearGradient(
                                    colors: [SyraTokens.Colors.primary, Color.pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text("U")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Kullanıcı")
                                    .font(SyraTokens.Typography.bodyMedium)
                                    .foregroundColor(SyraTokens.Colors.textPrimary)
                                
                                Text("Profil & Ayarlar")
                                    .font(SyraTokens.Typography.bodySmall)
                                    .foregroundColor(SyraTokens.Colors.textSecondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(SyraTokens.Colors.textSecondary)
                        }
                        .padding(.horizontal, SyraTokens.Spacing.screenEdge)
                        .padding(.vertical, SyraTokens.Spacing.md)
                    }
                    .buttonStyle(SyraButtonPressStyle())
                }
                .padding(.bottom, SyraTokens.Spacing.sm)
            }
        }
    }
}

// MARK: - Side Menu Item Component
struct SideMenuItem: View {
    let icon: String
    let label: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: SyraTokens.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(SyraTokens.Colors.textPrimary)
                    .frame(width: 24)
                
                Text(label)
                    .font(SyraTokens.Typography.bodyMedium)
                    .foregroundColor(SyraTokens.Colors.textPrimary)
                
                Spacer()
            }
            .padding(.horizontal, SyraTokens.Spacing.screenEdge)
            .padding(.vertical, SyraTokens.Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(SyraButtonPressStyle())
    }
}

// MARK: - Chat List Item Component
struct ChatListItem: View {
    let session: ChatSession
    let isSelected: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: SyraTokens.Spacing.md) {
                Image(systemName: "message")
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? SyraTokens.Colors.primary : SyraTokens.Colors.textSecondary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.title)
                        .font(SyraTokens.Typography.bodyMedium)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundColor(SyraTokens.Colors.textPrimary)
                        .lineLimit(1)
                    
                    Text(session.timeAgo)
                        .font(SyraTokens.Typography.caption)
                        .foregroundColor(SyraTokens.Colors.textTertiary)
                }
                
                Spacer()
            }
            .padding(.horizontal, SyraTokens.Spacing.screenEdge)
            .padding(.vertical, SyraTokens.Spacing.md)
            .background(
                isSelected ? SyraTokens.Colors.backgroundSecondary : Color.clear
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Sil", systemImage: "trash")
            }
        }
    }
}

struct SideMenuView_Previews: PreviewProvider {
    static var previews: some View {
        SideMenuView(
            isOpen: .constant(true),
            onClose: { print("Close") }
        )
        .environmentObject(AppState())
    }
}
