import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/firestore_user.dart';
import '../theme/syra_theme.dart';
import '../widgets/glass_background.dart';
import '../widgets/neon_ring.dart';

// Import for premium management screen

import 'chat_screen.dart';
import 'premium_management_screen.dart';
import 'premium_screen.dart';
import 'login_screen.dart';
import 'chat_behavior_screen.dart';
import 'appearance_settings_screen.dart';
import 'notifications_settings_screen.dart';
import 'account_settings_screen.dart';
import 'privacy_settings_screen.dart';

/// ═══════════════════════════════════════════════════════════════
/// SYRA SETTINGS SCREEN
/// ═══════════════════════════════════════════════════════════════
/// Premium glassmorphism ayarlar ekranı.
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

  // Günlük limit kitapçık bilgisi
  int _dailyLimit = 10;
  int _usedToday = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _email = user.email ?? "Misafir kullanıcı";

      // Tüm mesaj kullanım durumunu tek seferde çekiyoruz
      final status = await FirestoreUser.getMessageStatus();

      _isPremium = status['isPremium'] ?? false;
      _dailyLimit = status['limit'] ?? 10;
      _usedToday = status['count'] ?? 0;

      if (mounted) setState(() {});
    }
  }

  // ─────────────────────────────────────────────────────────────
  // MESAJ SİL
  // ─────────────────────────────────────────────────────────────
  Future<void> _clearChatHistory() async {
    final confirm = await _showConfirmDialog(
      title: "Mesaj Geçmişini Sil",
      content: "Tüm mesaj geçmişini silmek istediğine emin misin?",
      confirmText: "Sil",
      isDanger: true,
    );

    if (confirm != true) return;

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection("conversation_history")
            .doc(user.uid)
            .delete();

        final messagesCollection = FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .collection("messages");

        final docs = await messagesCollection.get();
        for (var d in docs.docs) {
          await d.reference.delete();
        }
      }

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ChatScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      _showError("Hata: $e");
    }

    if (mounted) setState(() => _loading = false);
  }

  // ─────────────────────────────────────────────────────────────
  // HESABI SİL
  // ─────────────────────────────────────────────────────────────
  Future<void> _deleteAccount() async {
    final confirm = await _showConfirmDialog(
      title: "Hesabı Sil",
      content:
          "Hesabın tamamen silinecek. Bu işlem geri alınamaz.\n\nDevam etmek istediğinden emin misin?",
      confirmText: "Evet, Sil",
      isDanger: true,
    );

    if (confirm != true) return;

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .delete();

      await user.delete();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      _showError("Hata: $e");
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String content,
    required String confirmText,
    bool isDanger = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: SyraColors.surface.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    content,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context, false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                "İptal",
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context, true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: isDanger
                                  ? Colors.redAccent.withValues(alpha: 0.2)
                                  : const Color(0xFF00D4FF).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDanger
                                    ? Colors.redAccent.withValues(alpha: 0.5)
                                    : const Color(0xFF00D4FF).withValues(alpha: 0.5),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                confirmText,
                                style: TextStyle(
                                  color: isDanger
                                      ? Colors.redAccent
                                      : const Color(0xFF00D4FF),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
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

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: SyraColors.surface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD UI
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background
          const SyraBackground(),

          // Content
          SafeArea(
            child: Column(
              children: [
                // App Bar
                _buildAppBar(),

                // Settings List
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                    child: Column(
                      children: [
                        // Profile Section
                        _buildProfileSection(),

                        const SizedBox(height: 20),

                        // Premium Section
                        _buildPremiumSection(),

                        const SizedBox(height: 20),

                        // Usage Section (kitapçık gibi isteyen bakar)
                        _buildUsageSection(),

                        const SizedBox(height: 20),

                        // Chat Behavior Section
                        _buildChatBehaviorSection(),

                        const SizedBox(height: 12),

                        // New Settings Sections
                        _buildNewSettingsSection(),

                        const SizedBox(height: 20),

                        // Privacy Section
                        _buildPrivacySection(),

                        const SizedBox(height: 28),

                        // Logout Button
                        _buildLogoutButton(),

                        const SizedBox(height: 32),

                        // Version Info
                        _buildVersionInfo(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Loading overlay
          if (_loading)
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: const Center(
                child: CompactAuraRing(size: 50, isActive: true),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // APP BAR
  // ─────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
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
              // Back button
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),

              // Title
              const Expanded(
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.settings_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Ayarlar",
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

  // ─────────────────────────────────────────────────────────────
  // PROFILE SECTION
  // ─────────────────────────────────────────────────────────────
  Widget _buildProfileSection() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B9D), Color(0xFF00D4FF)],
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _email.isEmpty ? "Kullanıcı" : _email,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _isPremium ? "Premium Üye ✨" : "Ücretsiz Plan",
                  style: TextStyle(
                    color: _isPremium
                        ? const Color(0xFFFFD54F)
                        : Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                    fontWeight: _isPremium ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // PREMIUM SECTION
  // ─────────────────────────────────────────────────────────────
  Widget _buildPremiumSection() {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: _buildSettingsItem(
        icon: Icons.workspace_premium_rounded,
        iconColor: const Color(0xFFFFD54F),
        title: _isPremium ? "Premium Aktif 🎉" : "Premium'a Geç",
        subtitle: _isPremium
            ? "Sınırsız sohbet ve analiz aktif"
            : "Sınırsız mesaj ve özel özellikler",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _isPremium
                  ? const PremiumManagementScreen()
                  : const PremiumScreen(),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // USAGE SECTION (Günlük mesaj hakkın)
  // ─────────────────────────────────────────────────────────────
  Widget _buildUsageSection() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Günlük mesaj hakkın",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          if (_isPremium)
            const Text(
              "Premium üyesin, mesajların sınırsız ✨",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: (_dailyLimit <= 0)
                        ? 0
                        : (_usedToday / _dailyLimit).clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: Colors.white.withValues(alpha: 0.10),
                    valueColor: const AlwaysStoppedAnimation(
                      Color(0xFFFF6B9D),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "$_usedToday / $_dailyLimit",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // CHAT BEHAVIOR SECTION
  // ─────────────────────────────────────────────────────────────
  Widget _buildChatBehaviorSection() {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: _buildSettingsItem(
        icon: Icons.psychology_rounded,
        iconColor: const Color(0xFF76E4FF),
        title: "Sohbet Davranışı",
        subtitle: "Ton, enerji ve stil ayarları",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ChatBehaviorScreen(),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // NEW SETTINGS SECTION
  // ─────────────────────────────────────────────────────────────
  Widget _buildNewSettingsSection() {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildSettingsItem(
            icon: Icons.palette_rounded,
            iconColor: const Color(0xFFB388FF),
            title: "Görünüm",
            subtitle: "Tema, parlaklık ve animasyon",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AppearanceSettingsScreen(),
                ),
              );
            },
          ),
          _buildDivider(),
          _buildSettingsItem(
            icon: Icons.notifications_rounded,
            iconColor: const Color(0xFFFFD54F),
            title: "Bildirimler",
            subtitle: "Bildirim tercihleri",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationsSettingsScreen(),
                ),
              );
            },
          ),
          _buildDivider(),
          _buildSettingsItem(
            icon: Icons.person_rounded,
            iconColor: const Color(0xFF64B5F6),
            title: "Hesap",
            subtitle: "Hesap bilgileri ve değişiklikler",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AccountSettingsScreen(),
                ),
              );
            },
          ),
          _buildDivider(),
          _buildSettingsItem(
            icon: Icons.shield_rounded,
            iconColor: const Color(0xFF4DB6AC),
            title: "Gizlilik ve Veri",
            subtitle: "Veri yönetimi ve gizlilik",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PrivacySettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // PRIVACY SECTION
  // ─────────────────────────────────────────────────────────────
  Widget _buildPrivacySection() {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildSettingsItem(
            icon: Icons.privacy_tip_rounded,
            iconColor: const Color(0xFF00D4FF),
            title: "Gizlilik Politikası",
            subtitle: "Politikayı görüntüle",
            onTap: () async {
              final url =
                  Uri.parse("https://ariksoftware.com.tr/privacy-policy.html");
              await launchUrl(url, mode: LaunchMode.externalApplication);
            },
          ),
          _buildDivider(),
          _buildSettingsItem(
            icon: Icons.delete_outline_rounded,
            iconColor: Colors.orangeAccent,
            title: "Mesaj Geçmişini Sil",
            subtitle: "Tüm konuşmalar silinir",
            onTap: _clearChatHistory,
          ),
          _buildDivider(),
          _buildSettingsItem(
            icon: Icons.delete_forever_rounded,
            iconColor: Colors.redAccent,
            title: "Hesabı Sil",
            subtitle: "Geri alınamaz işlem",
            onTap: _deleteAccount,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withValues(alpha: 0.15),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),

            const SizedBox(width: 14),

            // Text
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
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.3),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 0.5,
      color: Colors.white.withValues(alpha: 0.08),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // LOGOUT BUTTON
  // ─────────────────────────────────────────────────────────────
  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: () async {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.redAccent.withValues(alpha: 0.3),
          ),
        ),
        child: const Center(
          child: Text(
            "Çıkış Yap",
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // VERSION INFO - Long press for Developer Tools
  // ─────────────────────────────────────────────────────────────
  Widget _buildVersionInfo() {
    return Column(
      children: [
        const SyraLogo(fontSize: 18),
        const SizedBox(height: 8),
        Text(
          "Versiyon 1.0.1",
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
