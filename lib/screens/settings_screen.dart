import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/syra_theme.dart';
import '../services/firestore_user.dart';
import 'premium_screen.dart';
import 'settings/theme_settings_screen.dart';
import 'settings/appearance_settings_screen.dart';
import 'settings/tone_settings_screen.dart';
import 'settings/message_length_screen.dart';
import 'settings/notifications_settings_screen.dart';
import 'settings/daily_tips_screen.dart';
import 'settings/archived_chats_screen.dart';
import 'settings/privacy_data_screen.dart';
import 'settings/account_screen.dart';

/// ═══════════════════════════════════════════════════════════════
/// SYRA SETTINGS SCREEN v3.0 - ChatGPT 2025 Style
/// ═══════════════════════════════════════════════════════════════
/// Modern, organized settings with multiple sections
/// ═══════════════════════════════════════════════════════════════

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isPremium = false;
  String _email = "";
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _email = user.email ?? "Misafir kullanıcı";

      final status = await FirestoreUser.getMessageStatus();
      _isPremium = status['isPremium'] ?? false;

      if (mounted) setState(() {});
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SyraColors.background,
      appBar: AppBar(
        backgroundColor: SyraColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          color: SyraColors.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ayarlar',
          style: TextStyle(
            color: SyraColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: SyraColors.accent),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ──────────────────────────────────────────────────
                // PERSONALIZATION SECTION
                // ──────────────────────────────────────────────────
                _buildSectionTitle('KİŞİSELLEŞTİRME'),
                const SizedBox(height: 12),
                _buildSettingsCard([
                  _buildSettingsItem(
                    icon: Icons.palette_rounded,
                    title: 'Tema',
                    subtitle: 'Açık, Koyu, Siyah',
                    onTap: () => _navigateTo(const ThemeSettingsScreen()),
                  ),
                  _buildDivider(),
                  _buildSettingsItem(
                    icon: Icons.brush_rounded,
                    title: 'Görünüm',
                    subtitle: 'Font boyutu, UI ölçeği',
                    onTap: () => _navigateTo(const AppearanceSettingsScreen()),
                  ),
                  _buildDivider(),
                  _buildSettingsItem(
                    icon: Icons.record_voice_over_rounded,
                    title: 'Ton',
                    subtitle: 'Enerji, kişilik, espri seviyesi',
                    onTap: () => _navigateTo(const ToneSettingsScreen()),
                  ),
                  _buildDivider(),
                  _buildSettingsItem(
                    icon: Icons.format_size_rounded,
                    title: 'Mesaj Uzunluğu',
                    subtitle: 'Kısa, Orta, Uzun, Adaptif',
                    onTap: () => _navigateTo(const MessageLengthScreen()),
                  ),
                ]),

                const SizedBox(height: 32),

                // ──────────────────────────────────────────────────
                // CHAT SETTINGS SECTION
                // ──────────────────────────────────────────────────
                _buildSectionTitle('CHAT AYARLARI'),
                const SizedBox(height: 12),
                _buildSettingsCard([
                  _buildSettingsItem(
                    icon: Icons.notifications_rounded,
                    title: 'Bildirimler',
                    subtitle: 'Push, hatırlatıcılar',
                    onTap: () =>
                        _navigateTo(const NotificationsSettingsScreen()),
                  ),
                  _buildDivider(),
                  _buildSettingsItem(
                    icon: Icons.lightbulb_rounded,
                    title: 'Günlük İpuçları',
                    subtitle: 'İlişki tavsiyeleri',
                    onTap: () => _navigateTo(const DailyTipsScreen()),
                  ),
                ]),

                const SizedBox(height: 32),

                // ──────────────────────────────────────────────────
                // DATA & PRIVACY SECTION
                // ──────────────────────────────────────────────────
                _buildSectionTitle('VERİ & GİZLİLİK'),
                const SizedBox(height: 12),
                _buildSettingsCard([
                  _buildSettingsItem(
                    icon: Icons.shield_rounded,
                    title: 'Gizlilik Ayarları',
                    subtitle: 'Geçmiş, veri silme, politika',
                    onTap: () => _navigateTo(const PrivacyDataScreen()),
                  ),
                  _buildDivider(),
                  _buildSettingsItem(
                    icon: Icons.archive_rounded,
                    title: 'Arşivlenmiş Sohbetler',
                    subtitle: 'Gizlenen konuşmalar',
                    onTap: () => _navigateTo(const ArchivedChatsScreen()),
                  ),
                ]),

                const SizedBox(height: 32),

                // ──────────────────────────────────────────────────
                // ACCOUNT SECTION
                // ──────────────────────────────────────────────────
                _buildSectionTitle('HESAP'),
                const SizedBox(height: 12),
                _buildSettingsCard([
                  _buildSettingsItem(
                    icon: Icons.person_rounded,
                    title: 'Hesap Bilgileri',
                    subtitle: _email,
                    onTap: () => _navigateTo(const AccountScreen()),
                  ),
                ]),

                const SizedBox(height: 32),

                // ──────────────────────────────────────────────────
                // PREMIUM SECTION
                // ──────────────────────────────────────────────────
                if (!_isPremium) ...[
                  _buildSectionTitle('PREMIUM'),
                  const SizedBox(height: 12),
                  _buildPremiumCard(),
                  const SizedBox(height: 32),
                ],

                // ──────────────────────────────────────────────────
                // VERSION INFO
                // ──────────────────────────────────────────────────
                _buildVersionInfo(),
                const SizedBox(height: 20),
              ],
            ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // HELPER METHODS
  // ──────────────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: SyraColors.textHint,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: SyraColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SyraColors.border, width: 0.5),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    (iconColor ?? SyraColors.textSecondary).withOpacity(0.12),
              ),
              child: Icon(
                icon,
                color: iconColor ?? SyraColors.textSecondary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: SyraColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: SyraColors.textMuted,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  color: SyraColors.textHint,
                  size: 20,
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 0.5,
      color: SyraColors.divider,
    );
  }

  Widget _buildPremiumCard() {
    return GestureDetector(
      onTap: () => _navigateTo(const PremiumScreen()),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.amber.withOpacity(0.15),
              Colors.amber.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.amber.withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.amber.withOpacity(0.2),
              ),
              child: Icon(
                Icons.workspace_premium_rounded,
                color: Colors.amber,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SYRA Plus',
                    style: TextStyle(
                      color: SyraColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sınırsız mesaj, gelişmiş özellikler',
                    style: TextStyle(
                      color: SyraColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.amber,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Column(
      children: [
        Text(
          'SYRA',
          style: TextStyle(
            color: SyraColors.textMuted,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Versiyon 2.0.0',
          style: TextStyle(
            color: SyraColors.textHint,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
