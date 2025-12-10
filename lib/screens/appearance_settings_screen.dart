import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/syra_theme.dart';
import '../widgets/glass_background.dart';

/// ═══════════════════════════════════════════════════════════════
/// APPEARANCE SETTINGS SCREEN
/// ═══════════════════════════════════════════════════════════════
/// Görünüm ayarları - Tema, parlaklık, desen, animasyon.
/// ═══════════════════════════════════════════════════════════════

class AppearanceSettingsScreen extends StatefulWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  State<AppearanceSettingsScreen> createState() => _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState extends State<AppearanceSettingsScreen> {
  String _themeMode = "dark"; // system, dark, light

  String _orbBrightness = "medium"; // low, medium, high

  int _backgroundPattern = 0; // 0, 1, 2

  String _animationSpeed = "normal"; // slow, normal, fast

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
                        _buildSectionTitle("Tema Modu"),
                        const SizedBox(height: 12),
                        _buildThemeModeSection(),
                        const SizedBox(height: 28),
                        _buildSectionTitle("SYRA Orb Parlaklığı"),
                        const SizedBox(height: 12),
                        _buildOrbBrightnessSection(),
                        const SizedBox(height: 28),
                        _buildSectionTitle("Arka Plan Deseni"),
                        const SizedBox(height: 12),
                        _buildBackgroundPatternSection(),
                        const SizedBox(height: 28),
                        _buildSectionTitle("Animasyon Hızı"),
                        const SizedBox(height: 12),
                        _buildAnimationSpeedSection(),
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
                        Icons.palette_rounded,
                        color: Color(0xFFB388FF),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Görünüm",
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 4),
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

  Widget _buildThemeModeSection() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _buildRadioOption(
            title: "Sistem",
            subtitle: "Cihaz ayarlarını takip et",
            icon: Icons.settings_suggest_rounded,
            value: "system",
            groupValue: _themeMode,
            onChanged: (v) => setState(() => _themeMode = v!),
          ),
          _buildDivider(),
          _buildRadioOption(
            title: "Koyu",
            subtitle: "Her zaman koyu tema",
            icon: Icons.dark_mode_rounded,
            value: "dark",
            groupValue: _themeMode,
            onChanged: (v) => setState(() => _themeMode = v!),
          ),
          _buildDivider(),
          _buildRadioOption(
            title: "Açık",
            subtitle: "Her zaman açık tema",
            icon: Icons.light_mode_rounded,
            value: "light",
            groupValue: _themeMode,
            onChanged: (v) => setState(() => _themeMode = v!),
          ),
        ],
      ),
    );
  }

  Widget _buildOrbBrightnessSection() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _buildRadioOption(
            title: "Düşük",
            subtitle: "Hafif parlama efekti",
            icon: Icons.brightness_low_rounded,
            value: "low",
            groupValue: _orbBrightness,
            onChanged: (v) => setState(() => _orbBrightness = v!),
          ),
          _buildDivider(),
          _buildRadioOption(
            title: "Orta",
            subtitle: "Dengeli parlama",
            icon: Icons.brightness_medium_rounded,
            value: "medium",
            groupValue: _orbBrightness,
            onChanged: (v) => setState(() => _orbBrightness = v!),
          ),
          _buildDivider(),
          _buildRadioOption(
            title: "Yüksek",
            subtitle: "Maksimum parlama",
            icon: Icons.brightness_high_rounded,
            value: "high",
            groupValue: _orbBrightness,
            onChanged: (v) => setState(() => _orbBrightness = v!),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundPatternSection() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildPatternOption(
            index: 0,
            label: "Klasik",
            gradient: const [Color(0xFF0A0A0F), Color(0xFF12121A)],
          ),
          _buildPatternOption(
            index: 1,
            label: "Nebula",
            gradient: const [Color(0xFF0F0A1A), Color(0xFF1A0F20)],
          ),
          _buildPatternOption(
            index: 2,
            label: "Ocean",
            gradient: const [Color(0xFF0A1015), Color(0xFF0F1A20)],
          ),
        ],
      ),
    );
  }

  Widget _buildPatternOption({
    required int index,
    required String label,
    required List<Color> gradient,
  }) {
    final isSelected = _backgroundPattern == index;

    return GestureDetector(
      onTap: () => setState(() => _backgroundPattern = index),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF00D4FF)
                    : Colors.white.withValues(alpha: 0.1),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: isSelected
                ? const Icon(
                    Icons.check_rounded,
                    color: Color(0xFF00D4FF),
                    size: 24,
                  )
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimationSpeedSection() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _buildRadioOption(
            title: "Yavaş",
            subtitle: "Rahatlatıcı animasyonlar",
            icon: Icons.slow_motion_video_rounded,
            value: "slow",
            groupValue: _animationSpeed,
            onChanged: (v) => setState(() => _animationSpeed = v!),
          ),
          _buildDivider(),
          _buildRadioOption(
            title: "Normal",
            subtitle: "Varsayılan hız",
            icon: Icons.play_arrow_rounded,
            value: "normal",
            groupValue: _animationSpeed,
            onChanged: (v) => setState(() => _animationSpeed = v!),
          ),
          _buildDivider(),
          _buildRadioOption(
            title: "Hızlı",
            subtitle: "Daha hızlı geçişler",
            icon: Icons.fast_forward_rounded,
            value: "fast",
            groupValue: _animationSpeed,
            onChanged: (v) => setState(() => _animationSpeed = v!),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    final isSelected = value == groupValue;

    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? const Color(0xFF00D4FF).withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.05),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? const Color(0xFF00D4FF)
                    : Colors.white.withValues(alpha: 0.5),
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: isSelected ? 1 : 0.8),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: const Color(0xFF00D4FF),
              fillColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFF00D4FF);
                }
                return Colors.white.withValues(alpha: 0.3);
              }),
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
              "Ayarlar şimdilik sadece bu oturumda geçerli. Kalıcı kayıt SYRA 1.1'de eklenecek.",
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
