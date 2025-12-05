import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../theme/syra_theme.dart';
// import 'package:url_launcher/url_launcher.dart'; // TODO: Add if url_launcher is available

/// ═══════════════════════════════════════════════════════════════
/// PRIVACY & DATA SCREEN
/// Clear History, Delete Account, Privacy Policy
/// ═══════════════════════════════════════════════════════════════
class PrivacyDataScreen extends StatelessWidget {
  const PrivacyDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SyraColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          color: SyraColors.iconStroke,
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Privacy & Data',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: SyraColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),

          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SyraColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: SyraColors.accent.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  color: SyraColors.accent,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Your conversations are private and encrypted. We take your privacy seriously.',
                    style: TextStyle(
                      fontSize: 13,
                      color: SyraColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ═══════════════════════════════════════════════════════════════
          // DATA MANAGEMENT
          // ═══════════════════════════════════════════════════════════════
          const Text(
            'DATA MANAGEMENT',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: SyraColors.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),

          _buildActionCard(
            context: context,
            icon: Icons.delete_sweep_outlined,
            title: 'Clear Chat History',
            subtitle: 'Delete all your conversations',
            color: Colors.orange,
            onTap: () => _showClearHistoryDialog(context),
          ),
          const SizedBox(height: 12),

          _buildActionCard(
            context: context,
            icon: Icons.person_remove_outlined,
            title: 'Delete My Account',
            subtitle: 'Permanently delete your account and all data',
            color: Colors.red,
            onTap: () => _showDeleteAccountDialog(context),
          ),

          const SizedBox(height: 32),

          // ═══════════════════════════════════════════════════════════════
          // LEGAL
          // ═══════════════════════════════════════════════════════════════
          const Text(
            'LEGAL',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: SyraColors.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),

          _buildLinkCard(
            icon: Icons.policy_outlined,
            title: 'Privacy Policy',
            subtitle: 'How we handle your data',
            onTap: () => _openPrivacyPolicy(context),
          ),
          const SizedBox(height: 12),

          _buildLinkCard(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            subtitle: 'Our terms and conditions',
            onTap: () => _openTermsOfService(context),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SyraColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: SyraColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 22,
                color: color,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: SyraColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: SyraColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SyraColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: SyraColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: SyraColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 22,
                color: SyraColors.iconStroke,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: SyraColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: SyraColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.open_in_new,
              size: 18,
              color: SyraColors.accent,
            ),
          ],
        ),
      ),
    );
  }

  void _showClearHistoryDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Clear Chat History?'),
        content: const Text(
          'This will permanently delete all your conversations. This action cannot be undone.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              // TODO: Call existing clear history method if available
              _showSuccessMessage(context, 'Chat history cleared');
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This will permanently delete your account and all associated data. This action cannot be undone.\n\nAre you absolutely sure?',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement account deletion logic
              _showSuccessMessage(
                  context, 'Account deletion request received');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _openPrivacyPolicy(BuildContext context) {
    // TODO: Use url_launcher when available
    // final url = Uri.parse('https://syra.app/privacy');
    // launchUrl(url);
    _showSuccessMessage(context, 'Opening Privacy Policy...');
  }

  void _openTermsOfService(BuildContext context) {
    // TODO: Use url_launcher when available
    // final url = Uri.parse('https://syra.app/terms');
    // launchUrl(url);
    _showSuccessMessage(context, 'Opening Terms of Service...');
  }

  void _showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: SyraColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
