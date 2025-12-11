// LEGACY / UNUSED COPY – canonical version lives under lib/screens/side_menu.dart
// Kept only as backup. Do not import this file from production code.

// lib/screens/side_menu.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/syra_theme.dart';
import '../theme/syra_glass.dart';
import '../theme/syra_animations.dart';
import '../models/chat_session.dart';
import '../screens/kim_daha_cok_screen.dart';

/// ═══════════════════════════════════════════════════════════════
/// SYRA SIDE MENU v4.0 – Premium Glass Design
/// ═══════════════════════════════════════════════════════════════
/// Structure:
/// 1. Primary CTA: New Chat
/// 2. Features: Tarot Mode, Kim Daha Çok
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
          decoration: BoxDecoration(
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
              // HEADER: Logo + Close
              // ───────────────────────────────────────────────────
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: SyraSpacing.md,
                  vertical: SyraSpacing.md,
                ),
                child: Row(
                  children: [
                    Text(
                      'SYRA',
                      style: SyraTextStyles.logoStyle(fontSize: 22),
                    ),
                    Spacer(),
                    IconButton(
                      onPressed: onClose,
                      icon: Icon(
                        Icons.close,
                        color: SyraColors.iconMuted,
                        size: 20,
                      ),
                      padding: EdgeInsets.all(SyraSpacing.xs),
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: SyraSpacing.md),
                child: Divider(height: 1, color: SyraColors.divider),
              ),

              // ───────────────────────────────────────────────────
              // PRIMARY CTA: New Chat
              // ───────────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.all(SyraSpacing.md),
                child: _buildPrimaryCTA(
                  context: context,
                  icon: Icons.add_circle_outline,
                  label: 'Yeni Sohbet',
                  onTap: () {
                    onClose();
                    onNewChat();
                  },
                ).fadeInSlide(delay: Duration(milliseconds: 50)),
              ),

              // ───────────────────────────────────────────────────
              // FEATURES SECTION
              // ───────────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: SyraSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ÖZELLIKLER',
                      style: SyraTextStyles.overline,
                    ),
                    SizedBox(height: SyraSpacing.sm),
                    _buildFeatureItem(
                      context: context,
                      icon: Icons.auto_awesome_outlined,
                      label: 'Tarot Modu',
                      accent: true,
                      onTap: () {
                        onClose();
                        onTarotMode();
                      },
                    ).fadeInSlide(delay: Duration(milliseconds: 100)),
                    SizedBox(height: SyraSpacing.xs),
                    _buildFeatureItem(
                      context: context,
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
                    ).fadeInSlide(delay: Duration(milliseconds: 150)),
                  ],
                ),
              ),

              SizedBox(height: SyraSpacing.lg),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: SyraSpacing.md),
                child: Divider(height: 1, color: SyraColors.divider),
              ),

              SizedBox(height: SyraSpacing.md),

              // ───────────────────────────────────────────────────
              // RECENT CHATS LIST
              // ───────────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: SyraSpacing.md),
                child: Row(
                  children: [
                    Text(
                      'SON SOHBETLER',
                      style: SyraTextStyles.overline,
                    ),
                    Spacer(),
                    Text(
                      '${chatSessions.length}',
                      style: SyraTextStyles.caption,
                    ),
                  ],
                ),
              ),

              SizedBox(height: SyraSpacing.sm),

              Expanded(
                child: chatSessions.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: SyraSpacing.md,
                          vertical: SyraSpacing.xs,
                        ),
                        itemCount: chatSessions.length,
                        itemBuilder: (context, index) {
                          final chat = chatSessions[index];
                          return _buildChatListItem(
                            context: context,
                            chat: chat,
                            index: index,
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
                padding: EdgeInsets.symmetric(horizontal: SyraSpacing.md),
                child: Divider(height: 1, color: SyraColors.divider),
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
  // PRIMARY CTA BUTTON
  // ═════════════════════════════════════════════════════════════════

  Widget _buildPrimaryCTA({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SyraGlassCard(
      padding: EdgeInsets.symmetric(
        horizontal: SyraSpacing.md,
        vertical: 14,
      ),
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: SyraColors.accent,
            size: 20,
          ),
          SizedBox(width: SyraSpacing.sm),
          Text(
            label,
            style: SyraTextStyles.labelLarge.copyWith(
              color: SyraColors.accent,
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════
  // FEATURE ITEM
  // ═════════════════════════════════════════════════════════════════

  Widget _buildFeatureItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool accent = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SyraRadius.sm),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: SyraSpacing.md,
            vertical: SyraSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            color: accent
                ? SyraColors.accent.withValues(alpha: 0.05)
                : Colors.transparent,
            border: Border.all(
              color: accent
                  ? SyraColors.accent.withValues(alpha: 0.3)
                  : SyraColors.border,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(SyraRadius.sm),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: accent ? SyraColors.accent : SyraColors.iconStroke,
                size: 18,
              ),
              SizedBox(width: SyraSpacing.sm),
              Text(
                label,
                style: SyraTextStyles.bodyMedium.copyWith(
                  color: accent ? SyraColors.accent : SyraColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════
  // CHAT LIST ITEM
  // ═════════════════════════════════════════════════════════════════

  Widget _buildChatListItem({
    required BuildContext context,
    required ChatSession chat,
    required int index,
    required VoidCallback onTap,
    required VoidCallback onDelete,
    required Function(String) onRename,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: SyraSpacing.xs),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(SyraRadius.sm),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: SyraSpacing.sm,
              vertical: SyraSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(SyraRadius.sm),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  color: SyraColors.iconMuted,
                  size: 16,
                ),
                SizedBox(width: SyraSpacing.sm),
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
                _buildChatActions(
                  context: context,
                  chat: chat,
                  onDelete: onDelete,
                  onRename: onRename,
                ),
              ],
            ),
          ),
        ),
      ),
    ).fadeInSlide(delay: Duration(milliseconds: 200 + (index * 30)));
  }

  Widget _buildChatActions({
    required BuildContext context,
    required ChatSession chat,
    required VoidCallback onDelete,
    required Function(String) onRename,
  }) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_horiz,
        color: SyraColors.iconMuted,
        size: 16,
      ),
      color: SyraColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SyraRadius.md),
        side: BorderSide(
          color: SyraColors.border,
          width: 1,
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'rename',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 16, color: SyraColors.iconStroke),
              SizedBox(width: SyraSpacing.sm),
              Text('Yeniden Adlandır', style: SyraTextStyles.bodySmall),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 16, color: SyraColors.error),
              SizedBox(width: SyraSpacing.sm),
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
    );
  }

  // ═════════════════════════════════════════════════════════════════
  // EMPTY STATE
  // ═════════════════════════════════════════════════════════════════

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(SyraSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              color: SyraColors.iconMuted,
              size: 48,
            ),
            SizedBox(height: SyraSpacing.md),
            Text(
              'Henüz sohbet yok',
              style: SyraTextStyles.bodyMedium.copyWith(
                color: SyraColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: SyraSpacing.xs),
            Text(
              'Yeni bir sohbet başlatın',
              style: SyraTextStyles.caption,
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
          padding: EdgeInsets.all(SyraSpacing.md),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: SyraColors.accentGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    userInitials,
                    style: SyraTextStyles.labelLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(width: SyraSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: SyraTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Row(
                      children: [
                        if (isPremium) ...[
                          Icon(
                            Icons.workspace_premium,
                            size: 12,
                            color: SyraColors.accent,
                          ),
                          SizedBox(width: 4),
                        ],
                        Text(
                          isPremium ? 'SYRA Plus' : 'Ücretsiz Plan',
                          style: SyraTextStyles.caption.copyWith(
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
              Icon(
                Icons.settings_outlined,
                color: SyraColors.iconMuted,
                size: 20,
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
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
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
          side: BorderSide(color: SyraColors.border, width: 1),
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
