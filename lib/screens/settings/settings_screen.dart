import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../theme/syra_page.dart';
import '../../theme/syra_theme.dart';
import '../../utils/syra_prefs.dart';
import 'theme_settings_screen.dart';
import 'appearance_settings_screen.dart';
import 'tone_settings_screen.dart';
import 'message_length_screen.dart';
import 'notifications_settings_screen.dart';
import 'daily_tips_screen.dart';
import 'archived_chats_screen.dart';
import 'privacy_data_screen.dart';
import 'account_screen.dart';
import '../premium_screen.dart';

/// ═══════════════════════════════════════════════════════════════
/// SETTINGS SCREEN - Main Settings Hub
/// ═══════════════════════════════════════════════════════════════
/// Module 4: Now using SyraPage + SyraTokens for consistency
/// ═══════════════════════════════════════════════════════════════
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _loadPremiumStatus();
  }

  Future<void> _loadPremiumStatus() async {
    final isPremium = SyraPrefs.getBool('isPremium', defaultValue: false);
    if (mounted) {
      setState(() {
        _isPremium = isPremium;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SyraPage(
      title: 'Settings',
      maxWidth: 720,
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ═══════════════════════════════════════════════════════════════
          // PERSONALIZATION
          // ═══════════════════════════════════════════════════════════════
          _buildSectionHeader('PERSONALIZATION'),
          SizedBox(height: SyraSpacing.sm),
          _buildSettingsTile(
            icon: Icons.palette_outlined,
            title: 'Theme',
            subtitle: 'Dark, Light, Pure Black',
            onTap: () => _navigateTo(const ThemeSettingsScreen()),
          ),
          SizedBox(height: SyraSpacing.xs),
          _buildSettingsTile(
            icon: Icons.format_size,
            title: 'Appearance',
            subtitle: 'Font size, UI scale',
            onTap: () => _navigateTo(const AppearanceSettingsScreen()),
          ),
          SizedBox(height: SyraSpacing.xs),
          _buildSettingsTile(
            icon: Icons.mood_outlined,
            title: 'Tone',
            subtitle: 'Energy, personality, humor',
            onTap: () => _navigateTo(const ToneSettingsScreen()),
          ),
          SizedBox(height: SyraSpacing.xs),
          _buildSettingsTile(
            icon: Icons.text_fields,
            title: 'Message Length',
            subtitle: 'Short, Medium, Long, Adaptive',
            onTap: () => _navigateTo(const MessageLengthScreen()),
          ),
          SizedBox(height: SyraSpacing.lg),

          // ═══════════════════════════════════════════════════════════════
          // CHAT SETTINGS
          // ═══════════════════════════════════════════════════════════════
          _buildSectionHeader('CHAT SETTINGS'),
          SizedBox(height: SyraSpacing.sm),
          _buildSettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Push, reminders, tips',
            onTap: () => _navigateTo(const NotificationsSettingsScreen()),
          ),
          SizedBox(height: SyraSpacing.xs),
          _buildSettingsTile(
            icon: Icons.lightbulb_outline,
            title: 'Daily Tips',
            subtitle: 'Basic and personalized tips',
            onTap: () => _navigateTo(const DailyTipsScreen()),
          ),
          SizedBox(height: SyraSpacing.lg),

          // ═══════════════════════════════════════════════════════════════
          // DATA & PRIVACY
          // ═══════════════════════════════════════════════════════════════
          _buildSectionHeader('DATA & PRIVACY'),
          SizedBox(height: SyraSpacing.sm),
          _buildSettingsTile(
            icon: Icons.shield_outlined,
            title: 'Privacy & Data',
            subtitle: 'Clear history, delete account',
            onTap: () => _navigateTo(const PrivacyDataScreen()),
          ),
          SizedBox(height: SyraSpacing.xs),
          _buildSettingsTile(
            icon: Icons.archive_outlined,
            title: 'Archived Chats',
            subtitle: 'View archived conversations',
            onTap: () => _navigateTo(const ArchivedChatsScreen()),
          ),
          SizedBox(height: SyraSpacing.lg),

          // ═══════════════════════════════════════════════════════════════
          // ACCOUNT
          // ═══════════════════════════════════════════════════════════════
          _buildSectionHeader('ACCOUNT'),
          SizedBox(height: SyraSpacing.sm),
          _buildSettingsTile(
            icon: Icons.person_outline,
            title: 'Account',
            subtitle: 'Profile, plan, sign out',
            onTap: () => _navigateTo(const AccountScreen()),
          ),

          // ═══════════════════════════════════════════════════════════════
          // PREMIUM (only show for free users)
          // ═══════════════════════════════════════════════════════════════
          if (!_isPremium) ...[
            SizedBox(height: SyraSpacing.lg),
            _buildSectionHeader('PREMIUM'),
            SizedBox(height: SyraSpacing.sm),
            _buildSettingsTile(
              icon: Icons.star_outline,
              title: 'SYRA Plus',
              subtitle: 'Unlock unlimited features',
              onTap: () => _navigateTo(const PremiumScreen()),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SyraSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: SyraColors.accent,
                  borderRadius: BorderRadius.circular(SyraRadius.sm),
                ),
                child: const Text(
                  'UPGRADE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],

          SizedBox(height: SyraSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(
        top: SyraSpacing.md,
        bottom: SyraSpacing.xs,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: SyraColors.textMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: SyraColors.surface,
        borderRadius: BorderRadius.circular(SyraRadius.md),
        border: Border.all(
          color: SyraColors.border,
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: SyraColors.surfaceLight,
            borderRadius: BorderRadius.circular(SyraRadius.sm),
          ),
          child: Icon(
            icon,
            size: 20,
            color: SyraColors.accent,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: SyraColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: SyraColors.textSecondary,
          ),
        ),
        trailing: trailing ??
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: SyraColors.textMuted,
            ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SyraSpacing.md,
          vertical: SyraSpacing.sm,
        ),
      ),
    );
  }

  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => screen),
    );
  }
}
