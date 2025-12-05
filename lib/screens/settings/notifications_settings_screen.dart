import 'package:flutter/material.dart';
import '../../theme/syra_theme.dart';
import '../../utils/syra_prefs.dart';

/// ═══════════════════════════════════════════════════════════════
/// NOTIFICATIONS SETTINGS SCREEN
/// Push Notifications, Chat Reminders, Daily Tips toggles
/// ═══════════════════════════════════════════════════════════════
class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  bool _pushNotifications = true;
  bool _chatReminders = true;
  bool _dailyTips = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final push = SyraPrefs.getBool('pushNotifications', defaultValue: true);
    final reminders = SyraPrefs.getBool('chatReminders', defaultValue: true);
    final tips = SyraPrefs.getBool('dailyTips', defaultValue: true);

    if (mounted) {
      setState(() {
        _pushNotifications = push;
        _chatReminders = reminders;
        _dailyTips = tips;
      });
    }
  }

  Future<void> _savePushNotifications(bool value) async {
    await SyraPrefs.setBool('pushNotifications', value);
    if (mounted) {
      setState(() {
        _pushNotifications = value;
      });
    }
  }

  Future<void> _saveChatReminders(bool value) async {
    await SyraPrefs.setBool('chatReminders', value);
    if (mounted) {
      setState(() {
        _chatReminders = value;
      });
    }
  }

  Future<void> _saveDailyTips(bool value) async {
    await SyraPrefs.setBool('dailyTips', value);
    if (mounted) {
      setState(() {
        _dailyTips = value;
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
          'Notifications',
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
          const Text(
            'Manage your notification preferences',
            style: TextStyle(
              fontSize: 14,
              color: SyraColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // ═══════════════════════════════════════════════════════════════
          // PUSH NOTIFICATIONS
          // ═══════════════════════════════════════════════════════════════
          _buildNotificationToggle(
            icon: Icons.notifications_outlined,
            title: 'Push Notifications',
            subtitle: 'Receive notifications on your device',
            value: _pushNotifications,
            onChanged: _savePushNotifications,
          ),
          const SizedBox(height: 12),

          // ═══════════════════════════════════════════════════════════════
          // CHAT REMINDERS
          // ═══════════════════════════════════════════════════════════════
          _buildNotificationToggle(
            icon: Icons.schedule,
            title: 'Chat Reminders',
            subtitle: 'Get reminded to continue conversations',
            value: _chatReminders,
            onChanged: _saveChatReminders,
          ),
          const SizedBox(height: 12),

          // ═══════════════════════════════════════════════════════════════
          // DAILY TIPS
          // ═══════════════════════════════════════════════════════════════
          _buildNotificationToggle(
            icon: Icons.lightbulb_outline,
            title: 'Daily Tips',
            subtitle: 'Receive daily relationship insights',
            value: _dailyTips,
            onChanged: _saveDailyTips,
          ),

          const SizedBox(height: 24),

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
                  Icons.info_outline,
                  color: SyraColors.accent,
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'You can manage system notification permissions in your device settings.',
                    style: TextStyle(
                      fontSize: 12,
                      color: SyraColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SyraColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SyraColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: value
                  ? SyraColors.accent.withValues(alpha: 0.1)
                  : SyraColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: value ? SyraColors.accent : SyraColors.iconStroke,
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
                    fontWeight: FontWeight.w500,
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
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
