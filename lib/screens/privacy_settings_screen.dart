import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/firestore_user.dart';
import '../services/chat_session_service.dart';
import '../theme/syra_theme.dart';
import 'login_screen.dart';
import 'chat_screen.dart';

/// ═══════════════════════════════════════════════════════════════
/// PRIVACY SETTINGS SCREEN - FIXED
/// ═══════════════════════════════════════════════════════════════
/// ✅ Clear History - works
/// ✅ Privacy Policy - opens URL
/// ✅ Delete My Data - fully functional
/// ═══════════════════════════════════════════════════════════════

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SyraColors.background,
      appBar: AppBar(
        backgroundColor: SyraColors.background,
        elevation: 0,
        title: const Text(
          "Veri & Gizlilik",
          style: TextStyle(
            color: SyraColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: SyraColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: SyraColors.accent),
            )
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // INFO
                  Text(
                    "Verilerinizi yönetin ve gizliliğinizi koruyun.",
                    style: TextStyle(
                      fontSize: 13,
                      color: SyraColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // CLEAR HISTORY
                  _buildOptionTile(
                    icon: Icons.delete_sweep_rounded,
                    title: 'Geçmişi Temizle',
                    subtitle: 'Tüm sohbet geçmişini sil',
                    isDanger: true,
                    onTap: _showClearHistoryDialog,
                  ),

                  const SizedBox(height: 12),

                  // PRIVACY POLICY
                  _buildOptionTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Gizlilik Politikası',
                    subtitle: 'Verilerinizi nasıl koruduğumuzu öğrenin',
                    onTap: _openPrivacyPolicy,
                  ),

                  const SizedBox(height: 12),

                  // DELETE MY DATA
                  _buildOptionTile(
                    icon: Icons.warning_amber_rounded,
                    title: 'Verilerimi Sil',
                    subtitle: 'Hesap ve tüm verilerinizi kalıcı olarak silin',
                    isDanger: true,
                    onTap: _showDeleteAccountDialog,
                  ),

                  const SizedBox(height: 32),

                  // WARNING INFO
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: SyraColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.red.withOpacity(0.8),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Veri silme işlemleri geri alınamaz. Dikkatli olun.',
                            style: TextStyle(
                              color: SyraColors.textSecondary,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SyraColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: SyraColors.border,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDanger
                    ? Colors.red.withOpacity(0.1)
                    : SyraColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isDanger ? Colors.red : SyraColors.accent,
                size: 20,
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
                      color: isDanger ? Colors.red : SyraColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: SyraColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: SyraColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CLEAR HISTORY
  // ═══════════════════════════════════════════════════════════════
  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => _buildConfirmDialog(
        title: 'Geçmişi Temizle',
        message:
            'Tüm sohbet geçmişin silinecek. Bu işlem geri alınamaz.\n\nDevam etmek istiyor musun?',
        confirmText: 'Sil',
        isDanger: true,
        onConfirm: _clearHistory,
      ),
    );
  }

  Future<void> _clearHistory() async {
    Navigator.pop(context); // Close dialog
    setState(() => _loading = true);

    try {
      // Clear all chat sessions and messages
      final sessions = await ChatSessionService.getUserSessions();
      for (final session in sessions) {
        await ChatSessionService.deleteSession(session.id);
      }

      // Clear conversations from FirestoreUser
      await FirestoreUser.clearAllConversations();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tüm geçmiş silindi'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to fresh chat
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ChatScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('Error clearing history: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // PRIVACY POLICY
  // ═══════════════════════════════════════════════════════════════
  Future<void> _openPrivacyPolicy() async {
    final url = Uri.parse('https://ariksoftware.com.tr/privacy-policy.html');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'URL açılamadı';
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('URL açılamadı: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // DELETE ACCOUNT
  // ═══════════════════════════════════════════════════════════════
  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => _buildConfirmDialog(
        title: 'Hesabı Sil',
        message:
            'Hesabın ve TÜM VERİLERİN kalıcı olarak silinecek:\n\n• Tüm sohbet geçmişi\n• Profil bilgileri\n• Premium üyelik\n• Tüm ayarlar\n\nBu işlem GERİ ALINAMAZ!\n\nDevam etmek istediğine emin misin?',
        confirmText: 'Evet, Sil',
        isDanger: true,
        onConfirm: _deleteAccount,
      ),
    );
  }

  Future<void> _deleteAccount() async {
    Navigator.pop(context); // Close dialog
    setState(() => _loading = true);

    try {
      await FirestoreUser.deleteAccountCompletely();

      if (!mounted) return;

      // Navigate to login
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hesabın başarıyla silindi'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error deleting account: $e');
      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CONFIRM DIALOG BUILDER
  // ═══════════════════════════════════════════════════════════════
  Widget _buildConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required VoidCallback onConfirm,
    bool isDanger = false,
  }) {
    return Dialog(
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
                  message,
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
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'İptal',
                          style: TextStyle(
                            color: SyraColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onConfirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isDanger ? Colors.red : SyraColors.accent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          confirmText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
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
    );
  }
}
