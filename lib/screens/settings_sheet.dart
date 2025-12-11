import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/syra_theme.dart';
import '../utils/syra_prefs.dart';
import '../widgets/syra_bottom_panel.dart';

/// ═══════════════════════════════════════════════════════════════
/// SYRA SETTINGS SHEET v3.0 – 2025 Modal Bottom Sheet
/// ═══════════════════════════════════════════════════════════════
/// Sections:
/// 1. Personalization (Theme, Appearance)
/// 2. Chat Behavior (Tone, Length)
/// 4. Data & Privacy (Clear, Archive, Delete)
/// 5. Account (Email, Logout)
/// 6. Premium (SYRA Plus)
/// ═══════════════════════════════════════════════════════════════

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({super.key});

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();

  /// Show the settings sheet
  static void show(BuildContext context) {
    SyraBottomPanel.show(
      context: context,
      padding: EdgeInsets.zero,
      child: const SettingsSheet(),
    );
  }
}

class _SettingsSheetState extends State<SettingsSheet> {
  bool _notificationsEnabled = true;
  bool _dailyTipsEnabled = false;
  String _selectedTone = 'Balanced';
  String _selectedLength = 'Normal';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // TODO: Load from SyraPrefs or Firestore
    setState(() {
      _notificationsEnabled = SyraPrefs.getBool('notificationsEnabled') ?? true;
      _dailyTipsEnabled = SyraPrefs.getBool('dailyTipsEnabled') ?? false;
      _selectedTone = SyraPrefs.getString('chatTone') ?? 'Balanced';
      _selectedLength = SyraPrefs.getString('messageLength') ?? 'Normal';
    });
  }

  Future<void> _saveSettings() async {
    await SyraPrefs.setBool('notificationsEnabled', _notificationsEnabled);
    await SyraPrefs.setBool('dailyTipsEnabled', _dailyTipsEnabled);
    await SyraPrefs.setString('chatTone', _selectedTone);
    await SyraPrefs.setString('messageLength', _selectedLength);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'Guest';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(
                'Settings',
                style: SyraTextStyles.headingMedium,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                color: SyraColors.iconStroke,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              _buildSection(
                title: 'PERSONALIZATION',
                children: [
                  _buildSettingsTile(
                    icon: Icons.palette_outlined,
                    title: 'Theme',
                    subtitle: 'Dark',
                    onTap: () {},
                  ),
                  _buildSettingsTile(
                    icon: Icons.brush_outlined,
                    title: 'Appearance',
                    onTap: () {
                      Navigator.pushNamed(context, '/appearance-settings');
                    },
                  ),
                ],
              ),
              _buildSection(
                title: 'CHAT BEHAVIOR',
                children: [
                  _buildSettingsTile(
                    icon: Icons.tune_outlined,
                    title: 'Tone',
                    subtitle: _selectedTone,
                    onTap: () => _showTonePicker(),
                  ),
                  _buildSettingsTile(
                    icon: Icons.short_text_outlined,
                    title: 'Message Length',
                    subtitle: _selectedLength,
                    onTap: () => _showLengthPicker(),
                  ),
                ],
              ),
              _buildSection(
                title: 'NOTIFICATIONS',
                children: [
                  _buildSettingsTile(
                    icon: Icons.notifications_outlined,
                    title: 'Push Notifications',
                    trailing: Switch(
                      value: _notificationsEnabled,
                      onChanged: (val) {
                        setState(() => _notificationsEnabled = val);
                        _saveSettings();
                      },
                    ),
                  ),
                  _buildSettingsTile(
                    icon: Icons.tips_and_updates_outlined,
                    title: 'Daily Tips',
                    subtitle: 'Get relationship insights every day',
                    trailing: Switch(
                      value: _dailyTipsEnabled,
                      onChanged: (val) {
                        setState(() => _dailyTipsEnabled = val);
                        _saveSettings();
                      },
                    ),
                  ),
                ],
              ),
              _buildSection(
                title: 'DATA & PRIVACY',
                children: [
                  _buildSettingsTile(
                    icon: Icons.delete_outline,
                    title: 'Clear History',
                    subtitle: 'Delete all messages',
                    onTap: () => _showClearHistoryDialog(),
                  ),
                  _buildSettingsTile(
                    icon: Icons.archive_outlined,
                    title: 'Archived Chats',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/chat-archive');
                    },
                  ),
                  _buildSettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () {},
                  ),
                  _buildSettingsTile(
                    icon: Icons.delete_forever_outlined,
                    title: 'Delete My Data',
                    subtitle: 'Permanently delete your account',
                    onTap: () => _showDeleteAccountDialog(),
                  ),
                ],
              ),
              _buildSection(
                title: 'ACCOUNT',
                children: [
                  _buildSettingsTile(
                    icon: Icons.person_outline,
                    title: 'Account',
                    subtitle: email,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/account-settings');
                    },
                  ),
                  _buildSettingsTile(
                    icon: Icons.logout_outlined,
                    title: 'Log Out',
                    onTap: () => _showLogoutDialog(),
                  ),
                ],
              ),
              _buildSection(
                title: 'PREMIUM',
                children: [
                  _buildSettingsTile(
                    icon: Icons.workspace_premium_outlined,
                    title: 'SYRA Plus',
                    subtitle: 'Unlimited messages & advanced features',
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: SyraColors.accent,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/premium');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════════
  // ═════════════════════════════════════════════════════════════════

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: SyraTextStyles.overline,
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: SyraColors.iconStroke, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: SyraColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: SyraColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing,
              ] else if (onTap != null)
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: SyraColors.iconMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════
  // ═════════════════════════════════════════════════════════════════

  void _showTonePicker() {
    SyraBottomPanel.show(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 16, top: 8),
            child: Text(
              'Select Tone',
              style: SyraTextStyles.headingSmall,
            ),
          ),
          const Divider(height: 1),
          ...[
            'Balanced',
            'Calm',
            'Direct',
            'Street',
          ].map((tone) {
            return ListTile(
              title: Text(
                tone,
                style: TextStyle(color: SyraColors.textPrimary),
              ),
              trailing: _selectedTone == tone
                  ? Icon(Icons.check, color: SyraColors.accent)
                  : null,
              onTap: () {
                setState(() => _selectedTone = tone);
                _saveSettings();
                Navigator.pop(context);
              },
            );
          }),
        ],
      ),
    );
  }

  void _showLengthPicker() {
    SyraBottomPanel.show(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 16, top: 8),
            child: Text(
              'Message Length',
              style: SyraTextStyles.headingSmall,
            ),
          ),
          const Divider(height: 1),
          ...['Short', 'Normal', 'Detailed'].map((length) {
            return ListTile(
              title: Text(
                length,
                style: TextStyle(color: SyraColors.textPrimary),
              ),
              trailing: _selectedLength == length
                  ? Icon(Icons.check, color: SyraColors.accent)
                  : null,
              onTap: () {
                setState(() => _selectedLength = length);
                _saveSettings();
                Navigator.pop(context);
              },
            );
          }),
        ],
      ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: SyraColors.surface,
          title: const Text(
            'Clear History?',
            style: TextStyle(color: SyraColors.textPrimary),
          ),
          content: const Text(
            'This will delete all your messages. This action cannot be undone.',
            style: TextStyle(color: SyraColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // TODO: Clear history
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('History cleared')),
                );
              },
              child: const Text(
                'Clear',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: SyraColors.surface,
          title: const Text(
            'Delete Account?',
            style: TextStyle(color: SyraColors.textPrimary),
          ),
          content: const Text(
            'This will permanently delete your account and all data. This action cannot be undone.',
            style: TextStyle(color: SyraColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // TODO: Delete account
                Navigator.pop(context);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: SyraColors.surface,
          title: const Text(
            'Log Out?',
            style: TextStyle(color: SyraColors.textPrimary),
          ),
          content: const Text(
            'Are you sure you want to log out?',
            style: TextStyle(color: SyraColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close settings sheet
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );
  }
}
