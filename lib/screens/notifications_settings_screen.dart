import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/syra_theme.dart';
import '../widgets/glass_background.dart';

/// ═══════════════════════════════════════════════════════════════
/// NOTIFICATIONS SETTINGS SCREEN
/// ═══════════════════════════════════════════════════════════════
/// Bildirim ayarları - Tüm bildirim kontrolleri.
/// ═══════════════════════════════════════════════════════════════

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  bool _syraResponseNotification = true;
  bool _dailyTipNotification = true;
  bool _tacticalMovesReminder = false;
  bool _premiumCampaignNotification = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const SyraBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoCard(),
                        const SizedBox(height: 24),
                        _buildSectionTitle("Sohbet Bildirimleri"),
                        const SizedBox(height: 12),
                        _buildNotificationCard(
                          icon: Icons.chat_bubble_rounded,
                          iconColor: const Color(0xFF00D4FF),
                          title: "SYRA Cevap Hazır",
                          subtitle:
                              "SYRA sana cevap yazdığında bildirim al",
                          value: _syraResponseNotification,
                          onChanged: (v) =>
                              setState(() => _syraResponseNotification = v),
                        ),
                        const SizedBox(height: 24),
                        _buildSectionTitle("Günlük Bildirimler"),
                        const SizedBox(height: 12),
                        _buildNotificationCard(
                          icon: Icons.tips_and_updates_rounded,
                          iconColor: const Color(0xFFFF6B9D),
                          title: "Günlük Tavsiye",
                          subtitle: "Her gün yeni bir tavsiye bildirimi al",
                          value: _dailyTipNotification,
                          onChanged: (v) =>
                              setState(() => _dailyTipNotification = v),
                        ),
                        const SizedBox(height: 12),
                        _buildNotificationCard(
                          icon: Icons.flash_on_rounded,
                          iconColor: const Color(0xFFFFD54F),
                          title: "Tactical Moves Hatırlatma",
                          subtitle:
                              "Yeni taktik önerileri için hatırlatma al",
                          value: _tacticalMovesReminder,
                          onChanged: (v) =>
                              setState(() => _tacticalMovesReminder = v),
                        ),
                        const SizedBox(height: 24),
                        _buildSectionTitle("Promosyonlar"),
                        const SizedBox(height: 12),
                        _buildNotificationCard(
                          icon: Icons.local_offer_rounded,
                          iconColor: const Color(0xFFB388FF),
                          title: "Premium Kampanya",
                          subtitle:
                              "Özel indirimler ve kampanyalardan haberdar ol",
                          value: _premiumCampaignNotification,
                          onChanged: (v) =>
                              setState(() => _premiumCampaignNotification = v),
                        ),
                        const SizedBox(height: 32),
                        _buildInfoNote(),
                      ],
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

  Widget _buildAppBar(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.25),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.06),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const Expanded(
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.notifications_rounded,
                        color: Color(0xFFFFD54F),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Bildirimler",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFD54F).withValues(alpha: 0.15),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: Color(0xFFFFD54F),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Bildirim Tercihlerin",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Hangi bildirimleri almak istediğini seç.",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildNotificationCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withValues(alpha: 0.15),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF00D4FF),
            activeTrackColor: const Color(0xFF00D4FF).withValues(alpha: 0.3),
            inactiveThumbColor: Colors.white.withValues(alpha: 0.5),
            inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
        color: Colors.white.withValues(alpha: 0.03),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Colors.white.withValues(alpha: 0.4),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Bildirim ayarları şimdilik sadece bu oturumda geçerli. Push notification desteği SYRA 1.1'de eklenecek.",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
