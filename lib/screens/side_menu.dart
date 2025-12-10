import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/syra_theme.dart';
import '../theme/design_system.dart';
import '../models/chat_session.dart';
import 'kim_daha_cok_screen.dart';

/// ═══════════════════════════════════════════════════════════════
/// SYRA SIDE MENU v3.0 – 2025 AI App Style
/// ═══════════════════════════════════════════════════════════════
/// Structure:
/// 1. Static shortcuts (New Chat, Tarot Mode)
/// 2. Recent chats list
/// 3. User profile row (opens Settings)
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

  SideMenu({
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
          width: 300,
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
              // ───────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildShortcutButton(
                      context: context,
                      icon: Icons.add_circle_outline,
                      label: 'New Chat',
                      onTap: () {
                        onClose();
                        onNewChat();
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildShortcutButton(
                      context: context,
                      icon: Icons.auto_awesome_outlined,
                      label: 'Tarot Mode',
                      onTap: () {
                        onClose();
                        onTarotMode();
                      },
                      isSpecial: true,
                    ),
                    const SizedBox(height: 8),
                    _buildShortcutButton(
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
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // ───────────────────────────────────────────────────
              // ───────────────────────────────────────────────────
              Expanded(
                child: chatSessions.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
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

              const Divider(height: 1),

              // ───────────────────────────────────────────────────
              // ───────────────────────────────────────────────────
              Material(
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
            ],
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════
  // ═════════════════════════════════════════════════════════════════

  Widget _buildShortcutButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isSpecial = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSpecial
                ? SyraColors.accent.withValues(alpha: 0.08)
                : Colors.transparent,
            border: Border.all(
              color: isSpecial ? SyraColors.accent : SyraColors.border,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSpecial ? SyraColors.accent : SyraColors.iconStroke,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: isSpecial ? SyraColors.accent : SyraColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatListItem({
    required BuildContext context,
    required ChatSession chat,
    required VoidCallback onTap,
    required VoidCallback onDelete,
  }) {
    return Dismissible(
      key: Key(chat.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        color: Colors.red.withValues(alpha: 0.1),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.red,
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: () => _showChatContextMenu(context, chat),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        chat.title.isEmpty ? 'New Chat' : chat.title,
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

  void _showChatContextMenu(BuildContext context, ChatSession chat) {
    showSyraContextMenu(
      context: context,
      actions: [
        SyraContextAction(
          icon: Icons.edit_outlined,
          label: 'Rename chat',
          onTap: () => _showRenameDialog(context, chat),
        ),
        SyraContextAction(
          icon: Icons.delete_outline,
          label: 'Delete chat',
          isDestructive: true,
          onTap: () => onDeleteChat(chat),
        ),
      ],
    );
  }

  void _showRenameDialog(BuildContext context, ChatSession chat) {
    final controller = TextEditingController(text: chat.title);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: SyraColors.surface.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SyraColors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rename Chat',
                    style: TextStyle(
                      color: SyraColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    style: const TextStyle(
                      color: SyraColors.textPrimary,
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter new title',
                      hintStyle: TextStyle(
                        color: SyraColors.textMuted,
                      ),
                      filled: true,
                      fillColor: SyraColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: SyraColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: SyraColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: SyraColors.accent),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
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
                            horizontal: 20,
                            vertical: 12,
                          ),
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
              color: SyraColors.divider,
            ),
            const SizedBox(height: 16),
            Text(
              'No chats yet',
              style: TextStyle(
                color: SyraColors.textMuted,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
