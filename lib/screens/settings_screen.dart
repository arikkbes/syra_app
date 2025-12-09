// lib/screens/settings_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../theme/syra_theme.dart';
import '../../theme/design_system.dart';
import '../../utils/syra_prefs.dart';

import 'theme_settings_screen.dart';
import 'appearance_settings_screen.dart';
import 'notifications_settings_screen.dart';

/// ═══════════════════════════════════════════════════════════════
/// SETTINGS SCREEN - Main Settings Hub (simplified, no missing screens)
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
    if (!mounted) return;
    setState(() {
      _isPremium = isPremium;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SyraPage(
      title: 'Settings',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ═══════════════════════════════════════════════════════
          // PERSONALIZATION
          // ═══════════════════════════════════════════════════════
          _buildSectionHeader('PERSONALIZATION'),
          _buildSettingsTile(
            icon: Icons.palette_outlined,
            title: 'Theme',
            subtitle: 'Dark, Light, Pure Black',
            onTap: () => _navigateTo(const ThemeSettingsScreen()),
          ),
          _buildSettingsTile(
            icon: Icons.format_size,
            title: 'Appearance',
            subtitle: 'Font size, UI scale',
            onTap: () => _navigateTo(const AppearanceSettingsScreen()),
          ),
          const SizedBox(height: SyraTokens.paddingSm),

          // ═══════════════════════════════════════════════════════
          // CHAT SETTINGS
          // ═══════════════════════════════════════════════════════
          _buildSectionHeader('CHAT SETTINGS'),
          _buildSettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Push, reminders, tips',
            onTap: () => _navigateTo(const NotificationsSettingsScreen()),
          ),

          const SizedBox(height: SyraTokens.paddingLg * 1.5),

          // İstersen burada ileride Premium / Account / Privacy
          // gibi ekstra bölümleri tekrar ekleyebiliriz.
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        SyraTokens.pagePadding,
        SyraTokens.paddingLg,
        SyraTokens.pagePadding,
        SyraTokens.paddingXs,
      ),
      child: Text(
        title,
        style: SyraTokens.label.copyWith(
          color: SyraTokens.textTertiary,
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
      margin: EdgeInsets.symmetric(
        horizontal: SyraTokens.pagePadding,
        vertical: SyraTokens.paddingXxs,
      ),
      decoration: BoxDecoration(
        color: SyraTokens.card,
        borderRadius: BorderRadius.circular(SyraTokens.radiusMd),
        border: Border.all(
          color: SyraTokens.borderSubtle,
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: SyraTokens.cardElevated,
            borderRadius: BorderRadius.circular(SyraTokens.radiusXs),
          ),
          child: Icon(
            icon,
            size: 20,
            color: SyraTokens.accent,
          ),
        ),
        title: Text(
          title,
          style: SyraTokens.bodyMd.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: SyraTokens.bodySm,
        ),
        trailing: trailing ??
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: SyraTokens.textTertiary,
            ),
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(
          horizontal: SyraTokens.paddingSm,
          vertical: SyraTokens.paddingXs,
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
