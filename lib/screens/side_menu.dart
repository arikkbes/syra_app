import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/syra_theme.dart';

/// ═══════════════════════════════════════════════════════════════
/// SYRA SIDE MENU v4.0 – Simplified & Clean
/// ═══════════════════════════════════════════════════════════════

class SideMenu extends StatelessWidget {
  final bool isPremium;
  final int messageCount;
  final int dailyLimit;
  final VoidCallback onClose;
  final VoidCallback onNewChat;
  final VoidCallback onChatHistory;
  final VoidCallback onSettings;
  final VoidCallback onPremium;

  const SideMenu({
    super.key,
    required this.isPremium,
    required this.messageCount,
    required this.dailyLimit,
    required this.onClose,
    required this.onNewChat,
    required this.onChatHistory,
    required this.onSettings,
    required this.onPremium,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName =
        user?.displayName ?? user?.email?.split('@').first ?? "User";
    final userInitials = _getUserInitials(userName);

    return SafeArea(
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
            // Header shortcuts
            // ───────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildShortcutButton(
                    context: context,
                    icon: Icons.add_circle_outline,
                    label: 'New Chat',
                    onTap: onNewChat,
                  ),
                  const SizedBox(height: 8),
                  _buildShortcutButton(
                    context: context,
                    icon: Icons.history,
                    label: 'Chat History',
                    onTap: onChatHistory,
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // ───────────────────────────────────────────────────
            // Premium / Limit status
            // ───────────────────────────────────────────────────
            if (!isPremium)
              Container(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SyraColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SyraColors.border),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${dailyLimit - messageCount} / $dailyLimit',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: SyraColors.accent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Mesaj kaldı',
                        style: TextStyle(
                          fontSize: 12,
                          color: SyraColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: onPremium,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SyraColors.accent,
                            foregroundColor: SyraColors.background,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Premium\'a Geç'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const Spacer(),

            // ───────────────────────────────────────────────────
            // Bottom section
            // ───────────────────────────────────────────────────
            const Divider(height: 1),
            _buildMenuItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: onSettings,
            ),
            _buildUserProfile(userName, userInitials, context),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Helper widgets
  // ═══════════════════════════════════════════════════════════════

  Widget _buildShortcutButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: SyraColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SyraColors.border),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: SyraColors.accent,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: SyraColors.textPrimary,
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

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                icon,
                color: SyraColors.textSecondary,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: SyraColors.textPrimary,
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

  Widget _buildUserProfile(
    String userName,
    String userInitials,
    BuildContext context,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSettings,
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
              const Icon(
                Icons.chevron_right,
                color: SyraColors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Helper methods
  // ═══════════════════════════════════════════════════════════════

  String _getUserInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].length >= 2) {
      return parts[0].substring(0, 2).toUpperCase();
    }
    return 'U';
  }
}
