import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/syra_theme.dart';
import '../widgets/glass_background.dart';
import '../widgets/blur_toast.dart';

/// ═══════════════════════════════════════════════════════════════
/// PRIVACY SETTINGS SCREEN
/// ═══════════════════════════════════════════════════════════════
/// Gizlilik ve veri ayarları.
/// ═══════════════════════════════════════════════════════════════

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _sendAnalytics = true;
  bool _sendErrorReports = true;

  void _clearChatHistory() {
    BlurToast.show(context, "Konuşma geçmişi temizleme SYRA 1.1 ile gelecek.");
  }

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
                        _buildPrivacyInfoCard(),
                        const SizedBox(height: 24),
                        _buildSectionTitle("Veri Paylaşımı"),
                        const SizedBox(height: 12),
                        _buildDataSharingCard(),
                        const SizedBox(height: 24),
                        _buildSectionTitle("Veri Yönetimi"),
                        const SizedBox(height: 12),
                        _buildDataManagementCard(),
                        const SizedBox(height: 24),
                        _buildSectionTitle("Gizlilik Politikası"),
                        const SizedBox(height: 12),
                        _buildPrivacyPolicyCard(),
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
                        Icons.shield_rounded,
                        color: Color(0xFF4DB6AC),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Gizlilik ve Veri",
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

  Widget _buildPrivacyInfoCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF4DB6AC).withValues(alpha: 0.15),
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: Color(0xFF4DB6AC),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  "Gizliliğin Bizim İçin Önemli",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "SYRA, konuşmalarını güvenli bir şekilde saklar ve üçüncü taraflarla paylaşmaz. "
            "Verilerinin nasıl kullanıldığını aşağıdan kontrol edebilirsin.",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
              height: 1.5,
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

  Widget _buildDataSharingCard() {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildSwitchItem(
            icon: Icons.analytics_rounded,
            iconColor: const Color(0xFF64B5F6),
            title: "Kullanım Analitiği Gönder",
            subtitle: "Uygulamayı geliştirmemize yardımcı ol",
            value: _sendAnalytics,
            onChanged: (v) => setState(() => _sendAnalytics = v),
          ),
          _buildDivider(),
          _buildSwitchItem(
            icon: Icons.bug_report_rounded,
            iconColor: const Color(0xFFFF6B9D),
            title: "Hata Raporu Gönder",
            subtitle: "Hataları otomatik olarak bildir",
            value: _sendErrorReports,
            onChanged: (v) => setState(() => _sendErrorReports = v),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
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
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
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

  Widget _buildDataManagementCard() {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildActionItem(
            icon: Icons.delete_sweep_rounded,
            iconColor: Colors.orangeAccent,
            title: "Konuşma Geçmişini Temizle",
            subtitle: "Tüm sohbetleri sil",
            onTap: _clearChatHistory,
          ),
          _buildDivider(),
          _buildActionItem(
            icon: Icons.download_rounded,
            iconColor: const Color(0xFFB388FF),
            title: "Verilerimi İndir",
            subtitle: "Tüm verilerinin bir kopyasını al",
            onTap: () {
              BlurToast.show(context, "Veri indirme SYRA 1.1 ile gelecek.");
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
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

  Widget _buildPrivacyPolicyCard() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Veri Saklama",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "• Konuşma geçmişin şifreli olarak saklanır\n"
            "• Kişisel verilerin üçüncü taraflarla paylaşılmaz\n"
            "• İstediğin zaman verilerini silebilirsin\n"
            "• AI modeli eğitimi için veriler kullanılmaz",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 0.5,
      color: Colors.white.withValues(alpha: 0.06),
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
              "Gizlilik ayarları şimdilik sadece bu oturumda geçerli. Kalıcı kayıt SYRA 1.1'de eklenecek.",
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
