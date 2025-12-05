import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/syra_theme.dart';
import '../../utils/syra_prefs.dart';

/// ═══════════════════════════════════════════════════════════════
/// ACCOUNT SCREEN
/// Show user email, plan info, and sign out button
/// ═══════════════════════════════════════════════════════════════
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String _userEmail = '';
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    final isPremium = SyraPrefs.getBool('isPremium', defaultValue: false);

    if (mounted) {
      setState(() {
        _userEmail = user?.email ?? 'Not signed in';
        _isPremium = isPremium;
      });
    }
  }

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
          'Account',
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

          // ═══════════════════════════════════════════════════════════════
          // USER INFO CARD
          // ═══════════════════════════════════════════════════════════════
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  SyraColors.accent.withValues(alpha: 0.05),
                  SyraColors.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: SyraColors.border,
              ),
            ),
            child: Column(
              children: [
                // Avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: SyraColors.accentGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(_userEmail),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Email
                Text(
                  _userEmail,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: SyraColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Plan badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: _isPremium ? SyraColors.accentGradient : null,
                    color: _isPremium ? null : SyraColors.surfaceLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          _isPremium ? Colors.transparent : SyraColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isPremium ? Icons.star : Icons.person,
                        size: 14,
                        color: _isPremium
                            ? Colors.white
                            : SyraColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isPremium ? 'SYRA Plus' : 'Free Plan',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _isPremium
                              ? Colors.white
                              : SyraColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ═══════════════════════════════════════════════════════════════
          // ACCOUNT ACTIONS
          // ═══════════════════════════════════════════════════════════════
          const Text(
            'ACCOUNT ACTIONS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: SyraColors.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),

          _buildActionCard(
            icon: Icons.email_outlined,
            title: 'Change Email',
            subtitle: 'Update your email address',
            onTap: () => _showComingSoon(context),
          ),
          const SizedBox(height: 12),

          _buildActionCard(
            icon: Icons.lock_outline,
            title: 'Change Password',
            subtitle: 'Update your password',
            onTap: () => _showComingSoon(context),
          ),
          const SizedBox(height: 12),

          _buildActionCard(
            icon: Icons.logout,
            title: 'Sign Out',
            subtitle: 'Sign out of your account',
            color: Colors.red,
            onTap: () => _showSignOutDialog(context),
          ),

          const SizedBox(height: 32),

          // App version info
          Center(
            child: Column(
              children: [
                Text(
                  'SYRA v1.0.0',
                  style: const TextStyle(
                    fontSize: 12,
                    color: SyraColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Made with ❤️ for better relationships',
                  style: const TextStyle(
                    fontSize: 11,
                    color: SyraColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    final actionColor = color ?? SyraColors.iconStroke;

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
                color: color != null
                    ? color.withValues(alpha: 0.1)
                    : SyraColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 22,
                color: actionColor,
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
                      color: color ?? SyraColors.textPrimary,
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

  String _getInitials(String email) {
    if (email.isEmpty || email == 'Not signed in') return 'U';
    final name = email.split('@').first;
    if (name.isEmpty) return 'U';
    return name.substring(0, 1).toUpperCase();
  }

  void _showSignOutDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Sign Out?'),
        content: const Text(
          'Are you sure you want to sign out?',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context);
              await _signOut(context);
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        // Pop back to login screen or show success
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coming soon!'),
        backgroundColor: SyraColors.surface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
