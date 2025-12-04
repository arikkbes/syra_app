import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_user.dart';
import '../theme/syra_theme.dart';
import '../widgets/glass_background.dart';
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
/// SYRA SETTINGS SCREEN v2.0 - ChatGPT 2025 Style
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

      final status = await FirestoreUser.getMessageStatus();

      _isPremium = status['isPremium'] ?? false;
      _dailyLimit = status['limit'] ?? 10;
      _usedToday = status['count'] ?? 0;

      if (mounted) setState(() {});
    }
  }

  // ─────────────────────────────────────────────────────────────
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
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: SyraColors.surface.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: SyraColors.border,
                  width: 0.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: SyraColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    content,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: SyraColors.textSecondary,
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
                              color: SyraColors.glassBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: SyraColors.border),
                            ),
                            child: Center(
                              child: Text(
                                "İptal",
                                style: TextStyle(
                                  color: SyraColors.textSecondary,
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
                                  ? Colors.redAccent.withOpacity(0.2)
                                  : SyraColors.accent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDanger
                                    ? Colors.redAccent.withOpacity(0.5)
                                    : SyraColors.accent.withOpacity(0.5),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                confirmText,
                                style: TextStyle(
                                  color: isDanger
                                      ? Colors.redAccent
                                      : SyraColors.accent,
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
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SyraColors.background,
      body: Stack(
        children: [
          const SyraBackground(),

          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfileSection(),

                        const SizedBox(height: 24),

                        _buildPremiumSection(),

                        const SizedBox(height: 16),

                        _buildUsageSection(),

                        const SizedBox(height: 28),

                        // ─────────────────────────────────────────
                        // ─────────────────────────────────────────
                        _buildSectionTitle("Görünüm"),
                        const SizedBox(height: 8),
                        _buildSettingsCard([
                          _buildSettingsItem(
                            icon: Icons.palette_outlined,
                            title: "Tema",
                            subtitle: "Koyu mavi tema aktif",
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AppearanceSettingsScreen(),
                              ),
                            ),
                          ),
                          _buildDivider(),
                          _buildSettingsItem(
                            icon: Icons.text_fields_rounded,
                            title: "Yazı Boyutu",
                            subtitle: "Normal",
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AppearanceSettingsScreen(),
                              ),
                            ),
                          ),
                        ]),

                        const SizedBox(height: 24),

                        // ─────────────────────────────────────────
                        // ─────────────────────────────────────────
                        _buildSectionTitle("Sohbet Davranışı"),
                        const SizedBox(height: 8),
                        _buildSettingsCard([
                          _buildSettingsItem(
                            icon: Icons.psychology_outlined,
                            title: "Ton ve Stil",
                            subtitle: "SYRA'nın konuşma tarzını ayarla",
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ChatBehaviorScreen(),
                              ),
                            ),
                          ),
                          _buildDivider(),
                          _buildSettingsItem(
                            icon: Icons.vibration_rounded,
                            title: "Dokunsal Geri Bildirim",
                            subtitle: "Açık",
                            onTap: () {},
                            trailing: Switch(
                              value: true,
                              onChanged: (_) {},
                              activeColor: SyraColors.accent,
                            ),
                          ),
                          _buildDivider(),
                          _buildSettingsItem(
                            icon: Icons.schedule_rounded,
                            title: "Zaman Damgalarını Göster",
                            subtitle: "Mesaj zamanlarını göster",
                            onTap: () {},
                            trailing: Switch(
                              value: true,
                              onChanged: (_) {},
                              activeColor: SyraColors.accent,
                            ),
                          ),
                        ]),

                        const SizedBox(height: 24),

                        // ─────────────────────────────────────────
                        // ─────────────────────────────────────────
                        _buildSectionTitle("Bildirimler"),
                        const SizedBox(height: 8),
                        _buildSettingsCard([
                          _buildSettingsItem(
                            icon: Icons.notifications_outlined,
                            title: "Push Bildirimleri",
                            subtitle: "Günlük tavsiyeler ve hatırlatmalar",
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NotificationsSettingsScreen(),
                              ),
                            ),
                          ),
                          _buildDivider(),
                          _buildSettingsItem(
                            icon: Icons.tips_and_updates_outlined,
                            title: "Günlük İpuçları",
                            subtitle: "Her gün bir ilişki ipucu al",
                            onTap: () {},
                            trailing: Switch(
                              value: true,
                              onChanged: (_) {},
                              activeColor: SyraColors.accent,
                            ),
                          ),
                        ]),

                        const SizedBox(height: 24),

                        // ─────────────────────────────────────────
                        // ─────────────────────────────────────────
                        _buildSectionTitle("Hesap"),
                        const SizedBox(height: 8),
                        _buildSettingsCard([
                          _buildSettingsItem(
                            icon: Icons.person_outline_rounded,
                            title: "Hesap Bilgileri",
                            subtitle: _email,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AccountSettingsScreen(),
                              ),
                            ),
                          ),
                          _buildDivider(),
                          _buildSettingsItem(
                            icon: Icons.key_rounded,
                            title: "Şifre Değiştir",
                            subtitle: "Hesap güvenliği",
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AccountSettingsScreen(),
                              ),
                            ),
                          ),
                        ]),

                        const SizedBox(height: 24),

                        // ─────────────────────────────────────────
                        // ─────────────────────────────────────────
                        _buildSectionTitle("Gizlilik ve Veri"),
                        const SizedBox(height: 8),
                        _buildSettingsCard([
                          _buildSettingsItem(
                            icon: Icons.shield_outlined,
                            title: "Gizlilik Ayarları",
                            subtitle: "Veri yönetimi ve gizlilik",
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PrivacySettingsScreen(),
                              ),
                            ),
                          ),
                          _buildDivider(),
                          _buildSettingsItem(
                            icon: Icons.description_outlined,
                            title: "Gizlilik Politikası",
                            subtitle: "Politikayı görüntüle",
                            onTap: () async {
                              final url = Uri.parse(
                                  "https://ariksoftware.com.tr/privacy-policy.html");
                              await launchUrl(url,
                                  mode: LaunchMode.externalApplication);
                            },
                          ),
                          _buildDivider(),
                          _buildSettingsItem(
                            icon: Icons.download_outlined,
                            title: "Verilerimi İndir",
                            subtitle: "Tüm verilerinin bir kopyasını al",
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                      "Bu özellik yakında aktif olacak"),
                                  backgroundColor: SyraColors.surface,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                          _buildDivider(),
                          _buildSettingsItem(
                            icon: Icons.delete_outline_rounded,
                            title: "Mesaj Geçmişini Sil",
                            subtitle: "Tüm konuşmaları sil",
                            onTap: _clearChatHistory,
                            iconColor: Colors.orange,
                          ),
                        ]),

                        const SizedBox(height: 24),

                        // ─────────────────────────────────────────
                        // ─────────────────────────────────────────
                        _buildSectionTitle("Tehlikeli Bölge"),
                        const SizedBox(height: 8),
                        _buildSettingsCard([
                          _buildSettingsItem(
                            icon: Icons.delete_forever_rounded,
                            title: "Hesabı Sil",
                            subtitle: "Kalıcı olarak hesabını sil",
                            onTap: _deleteAccount,
                            iconColor: Colors.redAccent,
                          ),
                        ]),

                        const SizedBox(height: 28),

                        _buildLogoutButton(),

                        const SizedBox(height: 32),

                        _buildVersionInfo(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_loading)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(SyraColors.accent),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: SyraColors.background,
        border: Border(
          bottom: BorderSide(
            color: SyraColors.divider,
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
              color: SyraColors.textPrimary,
              size: 20,
            ),
          ),

          const Expanded(
            child: Center(
              child: Text(
                "Ayarlar",
                style: TextStyle(
                  color: SyraColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────
  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SyraColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SyraColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SyraColors.accent.withOpacity(0.2),
              border: Border.all(
                color: SyraColors.accent.withOpacity(0.4),
                width: 1,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.person_rounded,
                color: SyraColors.accent,
                size: 26,
              ),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _email.isEmpty ? "Kullanıcı" : _email,
                  style: const TextStyle(
                    color: SyraColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _isPremium
                        ? SyraColors.accent.withOpacity(0.2)
                        : SyraColors.glassBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _isPremium ? "Premium ✨" : "Ücretsiz Plan",
                    style: TextStyle(
                      color: _isPremium
                          ? SyraColors.accent
                          : SyraColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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

  // ─────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────
  Widget _buildPremiumSection() {
    return GestureDetector(
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
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SyraColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SyraColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFD54F).withOpacity(0.15),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: Color(0xFFFFD54F),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isPremium ? "Premium Aktif 🎉" : "Premium'a Geç",
                    style: const TextStyle(
                      color: SyraColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isPremium
                        ? "Sınırsız mesaj ve analiz aktif"
                        : "Sınırsız mesaj ve özel özellikler",
                    style: TextStyle(
                      color: SyraColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: SyraColors.textHint,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────
  Widget _buildUsageSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SyraColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SyraColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Günlük Mesaj Hakkı",
            style: TextStyle(
              color: SyraColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (_isPremium)
            Text(
              "Premium üyesin, mesajların sınırsız ✨",
              style: TextStyle(
                color: SyraColors.textSecondary,
                fontSize: 13,
              ),
            )
          else
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (_dailyLimit <= 0)
                              ? 0
                              : (_usedToday / _dailyLimit).clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: SyraColors.glassBg,
                          valueColor: const AlwaysStoppedAnimation(
                            SyraColors.accent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "$_usedToday / $_dailyLimit",
                      style: TextStyle(
                        color: SyraColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Günlük sıfırlanma: Gece yarısı",
                  style: TextStyle(
                    color: SyraColors.textHint,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: SyraColors.textHint,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────
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
                color: (iconColor ?? SyraColors.textSecondary).withOpacity(0.12),
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

  // ─────────────────────────────────────────────────────────────
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
          color: Colors.redAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.redAccent.withOpacity(0.3),
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
  // ─────────────────────────────────────────────────────────────
  Widget _buildVersionInfo() {
    return Column(
      children: [
        Text(
          "SYRA",
          style: TextStyle(
            color: SyraColors.textMuted,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Versiyon 2.0.0",
          style: TextStyle(
            color: SyraColors.textHint,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
