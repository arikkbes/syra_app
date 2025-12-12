// lib/screens/side_menu.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/syra_theme.dart';
import '../theme/syra_glass.dart';
import '../theme/syra_animations.dart';
import '../models/chat_session.dart';
import 'kim_daha_cok_screen.dart';

/// ═══════════════════════════════════════════════════════════════
/// SYRA SIDE MENU v5.0 – ChatGPT-Style List Design
/// ═══════════════════════════════════════════════════════════════
/// Structure:
/// 1. Search bar at top
/// 2. Primary actions (list-based, no big pills)
/// 3. Recent chats list
/// 4. Bottom: User profile + Settings
/// ═══════════════════════════════════════════════════════════════

class SideMenu extends StatelessWidget {
  final Animation<Offset> slideAnimation;
  final bool isPremium;
  final List<ChatSession> chatSessions;

  final VoidCallback onNewChat;
  final VoidCallback onTarotMode;
  final Function(ChatSession) onSelectChat;
  final Function(ChatSession) onDeleteChat;
  final Function(ChatSession, String) onRenameChat;
  final VoidCallback onOpenSettings;
  final VoidCallback onClose;

  const SideMenu({
    super.key,
    required this.slideAnimation,
    required this.isPremium,
    required this.chatSessions,
    required this.onNewChat,
    required this.onTarotMode,
    required this.onSelectChat,
    required this.onDeleteChat,
    required this.onRenameChat,
    required this.onOpenSettings,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName =
        user?.displayName ?? user?.email?.split('@').first ?? "User";
    final userInitials = _getUserInitials(userName);

    return SlideTransition(
      position: slideAnimation,
      child: SafeArea(
        child: Container(
          width: 340,
          decoration: const BoxDecoration(
            color: SyraColors.background,
            border: Border(
              right: BorderSide(
                color: SyraColors.divider,
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              // ───────────────────────────────────────────────────
              // HEADER: Search bar + Compose button
              // ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  SyraSpacing.md,
                  SyraSpacing.md,
                  SyraSpacing.md,
                  SyraSpacing.sm,
                ),
                child: Row(
                  children: [
                    // Search bar
                    Expanded(
                      child: const _SyraDrawerSearch(),
                    ),
                    const SizedBox(width: 12),
                    // Compose button
                    _buildComposeButton(
                      onTap: () {
                        onClose();
                        onNewChat();
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: SyraSpacing.sm),

              // ───────────────────────────────────────────────────
              // PRIMARY ACTIONS SECTION
              // ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: SyraSpacing.md),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Sohbetler',
                    style: SyraTextStyles.headingMedium.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: SyraSpacing.sm),

              _SyraDrawerItem(
                icon: Icons.add_circle_outline,
                label: 'Yeni Sohbet',
                onTap: () {
                  onClose();
                  onNewChat();
                },
              ).fadeInSlide(delay: const Duration(milliseconds: 50)),

              _SyraDrawerItem(
                icon: Icons.auto_awesome_outlined,
                label: 'Tarot Modu',
                onTap: () {
                  onClose();
                  onTarotMode();
                },
              ).fadeInSlide(delay: const Duration(milliseconds: 100)),

              _SyraDrawerItem(
                icon: Icons.analytics_outlined,
                label: 'Kim Daha Çok?',
                onTap: () {
                  onClose();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const KimDahaCokScreen(),
                    ),
                  );
                },
              ).fadeInSlide(delay: const Duration(milliseconds: 150)),

              const SizedBox(height: SyraSpacing.lg),

              // ───────────────────────────────────────────────────
              // SECTION DIVIDER
              // ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: SyraSpacing.md),
                child: Container(
                  height: 1,
                  color: SyraColors.divider.withOpacity(0.5),
                ),
              ),

              const SizedBox(height: SyraSpacing.md),

              // ───────────────────────────────────────────────────
              // RECENT CHATS SECTION HEADER
              // ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: SyraSpacing.md),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Geçmiş',
                    style: SyraTextStyles.caption.copyWith(
                      color: SyraColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: SyraSpacing.sm),

              // ───────────────────────────────────────────────────
              // RECENT CHATS LIST
              // ───────────────────────────────────────────────────
              Expanded(
                child: chatSessions.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: chatSessions.length,
                        itemBuilder: (context, index) {
                          final chat = chatSessions[index];
                          return _SyraChatListItem(
                            chat: chat,
                            onTap: () {
                              onClose();
                              onSelectChat(chat);
                            },
                            onDelete: () => onDeleteChat(chat),
                            onRename: (newTitle) =>
                                onRenameChat(chat, newTitle),
                          );
                        },
                      ),
              ),

              // ───────────────────────────────────────────────────
              // BOTTOM: User Profile + Settings
              // ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: SyraSpacing.md),
                child: Container(
                  height: 1,
                  color: SyraColors.divider.withOpacity(0.5),
                ),
              ),

              _buildUserProfile(
                context: context,
                userName: userName,
                userInitials: userInitials,
                isPremium: isPremium,
                onTap: () {
                  onClose();
                  onOpenSettings();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════
  // COMPOSE BUTTON (matches search bar style)
  // ═════════════════════════════════════════════════════════════════

  Widget _buildComposeButton({
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.09),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.edit_square,
            size: 20,
            color: Color(0xFF9CA3AF),
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════
  // EMPTY STATE
  // ═════════════════════════════════════════════════════════════════

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SyraSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              color: SyraColors.iconMuted.withOpacity(0.5),
              size: 40,
            ),
            const SizedBox(height: SyraSpacing.md),
            Text(
              'Henüz sohbet yok',
              style: SyraTextStyles.bodySmall.copyWith(
                color: SyraColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════
  // USER PROFILE
  // ═════════════════════════════════════════════════════════════════

  Widget _buildUserProfile({
    required BuildContext context,
    required String userName,
    required String userInitials,
    required bool isPremium,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(SyraSpacing.md),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  gradient: SyraColors.accentGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    userInitials,
                    style: SyraTextStyles.labelMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: SyraSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: SyraTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w500,
                        color: SyraColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (isPremium) ...[
                          const Icon(
                            Icons.workspace_premium,
                            size: 11,
                            color: SyraColors.accent,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          isPremium ? 'Plus' : 'Ücretsiz',
                          style: SyraTextStyles.caption.copyWith(
                            fontSize: 11,
                            color: isPremium
                                ? SyraColors.accent
                                : SyraColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.settings_outlined,
                color: SyraColors.iconMuted,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════
  // HELPERS
  // ═════════════════════════════════════════════════════════════════

  String _getUserInitials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
    }
    final first = parts[0].isNotEmpty ? parts[0][0] : '';
    final second = parts[1].isNotEmpty ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }
}

// ═══════════════════════════════════════════════════════════════
// SEARCH BAR WIDGET - ChatGPT iOS Quality
// ═══════════════════════════════════════════════════════════════

class _SyraDrawerSearch extends StatelessWidget {
  const _SyraDrawerSearch();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.09),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(
            Icons.search,
            size: 20,
            color: SyraColors.textMuted.withOpacity(0.7),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              style: SyraTextStyles.bodyMedium.copyWith(
                fontSize: 16,
                color: SyraColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Ara',
                hintStyle: SyraTextStyles.bodyMedium.copyWith(
                  fontSize: 16,
                  color: SyraColors.textMuted.withOpacity(0.55),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// DRAWER LIST ITEM (ChatGPT-style)
// ═══════════════════════════════════════════════════════════════

class _SyraDrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  const _SyraDrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: SyraSpacing.md),
          decoration: BoxDecoration(
            // Subtle left accent line when active
            border: isActive
                ? const Border(
                    left: BorderSide(
                      color: SyraColors.accent,
                      width: 2,
                    ),
                  )
                : null,
            color: isActive
                ? SyraColors.surfaceLight.withOpacity(0.3)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive ? SyraColors.accent : SyraColors.iconMuted,
              ),
              const SizedBox(width: SyraSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: SyraTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isActive
                        ? SyraColors.textPrimary
                        : SyraColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CHAT LIST ITEM (Clean list style)
// ═══════════════════════════════════════════════════════════════

class _SyraChatListItem extends StatelessWidget {
  final ChatSession chat;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Function(String) onRename;

  const _SyraChatListItem({
    required this.chat,
    required this.onTap,
    required this.onDelete,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: SyraSpacing.md),
          child: Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 16,
                color: SyraColors.iconMuted.withOpacity(0.6),
              ),
              const SizedBox(width: SyraSpacing.sm),
              Expanded(
                child: Text(
                  chat.title,
                  style: SyraTextStyles.bodySmall.copyWith(
                    color: SyraColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Options menu
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_horiz,
                  size: 16,
                  color: SyraColors.iconMuted.withOpacity(0.5),
                ),
                color: SyraColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(SyraRadius.md),
                  side: const BorderSide(
                    color: SyraColors.border,
                    width: 1,
                  ),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'rename',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined,
                            size: 16, color: SyraColors.iconStroke),
                        const SizedBox(width: SyraSpacing.sm),
                        Text('Yeniden Adlandır',
                            style: SyraTextStyles.bodySmall),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline,
                            size: 16, color: SyraColors.error),
                        const SizedBox(width: SyraSpacing.sm),
                        Text(
                          'Sil',
                          style: SyraTextStyles.bodySmall.copyWith(
                            color: SyraColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'delete') {
                    onDelete();
                  } else if (value == 'rename') {
                    _showRenameDialog(context, chat, onRename);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRenameDialog(
    BuildContext context,
    ChatSession chat,
    Function(String) onRename,
  ) {
    final controller = TextEditingController(text: chat.title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SyraColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SyraRadius.lg),
          side: const BorderSide(color: SyraColors.border, width: 1),
        ),
        title: Text(
          'Sohbeti Yeniden Adlandır',
          style: SyraTextStyles.headingSmall,
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: SyraTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Yeni başlık',
            hintStyle: SyraTextStyles.bodyMedium.copyWith(
              color: SyraColors.textMuted,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: SyraTextStyles.button.copyWith(
                color: SyraColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                onRename(newTitle);
                Navigator.pop(context);
              }
            },
            child: Text(
              'Kaydet',
              style: SyraTextStyles.button.copyWith(
                color: SyraColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
