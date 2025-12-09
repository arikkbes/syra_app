import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/syra_theme.dart';
import '../theme/syra_tokens.dart';
import '../theme/syra_context_menu.dart';
import '../models/chat_session.dart';
import 'kim_daha_cok_screen.dart';

/// ═══════════════════════════════════════════════════════════════
/// SYRA SIDE MENU v4.0 – Premium Glass Drawer
/// ═══════════════════════════════════════════════════════════════
/// Features:
/// - Glass panel overlay with backdrop blur
/// - Premium action cards with active states
/// - Clean chat list with section label
/// - Polished rename/delete bottom sheet
/// ═══════════════════════════════════════════════════════════════

class SideMenuNew extends StatelessWidget {
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

  const SideMenuNew({
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
      child: Container(
        width: 300,
        decoration: BoxDecoration(
          color: SyraColors.surface.withOpacity(0.94),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.04),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.65),
              blurRadius: 32,
              offset: const Offset(4, 0),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ───────────────────────────────────────────────────
              // PRIMARY ACTION CARDS
              // ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildActionCard(
                      context: context,
                      icon: Icons.add_circle_outline,
                      label: 'New Chat',
                      onTap: () {
                        onClose();
                        onNewChat();
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildActionCard(
                      context: context,
                      icon: Icons.auto_awesome_outlined,
                      label: 'Tarot Mode',
                      subtitle: 'Karş gelecekten haberler',
                      onTap: () {
                        onClose();
                        onTarotMode();
                      },
                      isActive: false, // TODO: Tarot mode aktif mi kontrol et
                    ),
                    const SizedBox(height: 10),
                    _buildActionCard(
                      context: context,
                      icon: Icons.analytics_outlined,
                      label: 'Kim Daha Çok?',
                      subtitle: 'İlişki istatistikleri',
                      onTap: () {
                        onClose();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const KimDahaCokScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // ───────────────────────────────────────────────────
              // CHAT SESSIONS LIST
              // ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Text(
                      'SOHBETLER',
                      style: TextStyle(
                        color: SyraColors.textMuted.withOpacity(0.6),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: SyraColors.divider.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: chatSessions.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        itemCount: chatSessions.length,
                        itemBuilder: (context, index) {
                          final chat = chatSessions[index];
                          return _buildChatListItem(
                            context: context,
                            chat: chat,
                            onTap: () {
                              onClose();
                              onSelectChat(chat);
                            },
                            onDelete: () => onDeleteChat(chat),
                          );
                        },
                      ),
              ),

              // ───────────────────────────────────────────────────
              // USER PROFILE ROW
              // ───────────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: SyraColors.divider.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      onClose();
                      onOpenSettings();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: SyraColors.accent,
                            child: Text(
                              userInitials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: const TextStyle(
                                    color: SyraColors.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isPremium ? 'SYRA Plus' : 'Free Plan',
                                  style: TextStyle(
                                    color: isPremium
                                        ? SyraColors.accent
                                        : SyraColors.textMuted,
                                    fontSize: 12,
                                  ),
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════
  // PREMIUM ACTION CARD
  // ═════════════════════════════════════════════════════════════════

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    String? subtitle,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isActive
                ? SyraColors.surfaceLight.withOpacity(0.98)
                : SyraColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isActive
                  ? SyraColors.accent.withOpacity(0.9)
                  : Colors.white.withOpacity(0.06),
              width: isActive ? 1.3 : 1,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: SyraColors.accent.withOpacity(0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isActive ? SyraColors.accent : SyraColors.iconStroke,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: isActive
                            ? SyraColors.textPrimary
                            : SyraColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: isActive
                              ? SyraColors.textSecondary
                              : SyraColors.textMuted,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
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
    required VoidCallback onTap,
    required VoidCallback onDelete,
    bool isSelected = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: () => _showChatContextMenu(context, chat),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isSelected
                  ? Colors.white.withOpacity(0.04)
                  : Colors.transparent,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 18,
                  color: SyraColors.iconMuted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chat.title.isEmpty ? 'Yeni Sohbet' : chat.title,
                        style: const TextStyle(
                          color: SyraColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (chat.lastMessage != null &&
                          chat.lastMessage!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          chat.lastMessage!,
                          style: const TextStyle(
                            color: SyraColors.textMuted,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════
  // CONTEXT MENU (RENAME/DELETE)
  // ═════════════════════════════════════════════════════════════════

  void _showChatContextMenu(BuildContext context, ChatSession chat) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildContextSheet(context, chat),
    );
  }

  Widget _buildContextSheet(BuildContext context, ChatSession chat) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          color: SyraColors.surface.withOpacity(0.96),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grab handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: SyraColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Text(
                  chat.title.isEmpty ? 'Yeni Sohbet' : chat.title,
                  style: const TextStyle(
                    color: SyraColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Actions
              _buildSheetAction(
                context: context,
                icon: Icons.edit_outlined,
                label: 'Rename chat',
                onTap: () {
                  Navigator.pop(context);
                  _showRenameDialog(context, chat);
                },
              ),

              _buildSheetAction(
                context: context,
                icon: Icons.delete_outline,
                label: 'Delete chat',
                isDestructive: true,
                onTap: () {
                  Navigator.pop(context);
                  onDeleteChat(chat);
                },
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetAction({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Icon(
                icon,
                color: isDestructive
                    ? Colors.red.withOpacity(0.9)
                    : SyraColors.iconStroke,
                size: 22,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isDestructive
                        ? Colors.red.withOpacity(0.9)
                        : SyraColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════
  // RENAME DIALOG
  // ═════════════════════════════════════════════════════════════════

  void _showRenameDialog(BuildContext context, ChatSession chat) {
    final controller = TextEditingController(text: chat.title);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: SyraColors.surface.withOpacity(0.96),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rename Chat',
                    style: TextStyle(
                      color: SyraColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    style: const TextStyle(
                      color: SyraColors.textPrimary,
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter new title',
                      hintStyle: const TextStyle(
                        color: SyraColors.textMuted,
                      ),
                      filled: true,
                      fillColor: SyraColors.background.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: SyraColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: SyraColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: SyraColors.accent,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: SyraColors.textMuted,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          final newTitle = controller.text.trim();
                          if (newTitle.isNotEmpty) {
                            onRenameChat(chat, newTitle);
                          }
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SyraColors.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Rename',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_outlined,
              size: 48,
              color: SyraColors.divider.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No chats yet',
              style: TextStyle(
                color: SyraColors.textMuted,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a conversation',
              style: TextStyle(
                color: SyraColors.textMuted.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════
  // HELPERS
  // ═════════════════════════════════════════════════════════════════

  String _getUserInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].length >= 2) {
      return parts[0].substring(0, 2).toUpperCase();
    }
    return 'U';
  }
}
