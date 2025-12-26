// lib/widgets/chat_empty_state.dart

import 'package:flutter/material.dart';
import '../theme/syra_theme.dart';
import '../theme/syra_glass.dart';
import '../theme/syra_animations.dart';

/// ═══════════════════════════════════════════════════════════════
/// PREMIUM CHAT EMPTY STATE
/// ═══════════════════════════════════════════════════════════════
/// Hero section when no messages exist:
/// - Logo
/// - Welcome title
/// - Subtitle
/// (Suggestion chips removed for clean Claude-style empty state)
/// ═══════════════════════════════════════════════════════════════

class ChatEmptyState extends StatelessWidget {
  final bool isTarotMode;

  /// Kept for compatibility with existing calls (even though suggestions are hidden)
  final Function(String) onSuggestionTap;

  const ChatEmptyState({
    super.key,
    required this.isTarotMode,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w >= 900;

    final titleText =
        isTarotMode ? "Kartlar hazır..." : "Bugün neyi çözüyoruz?";
    final subtitleText = isTarotMode
        ? "İstersen önce birkaç cümleyle durumu anlat."
        : "Mesajını, ilişkini ya da aklındaki soruyu anlat.";

    final titleStyle = TextStyle(
      fontFamily: 'Literata',
      fontSize: isDesktop ? 34 : 30,
      fontWeight: FontWeight.w400,
      height: isDesktop ? (42 / 34) : (38 / 30),
      color: (isTarotMode ? SyraColors.accent : SyraColors.textPrimary)
          .withValues(alpha: 0.92),
    );

    final subtitleStyle = TextStyle(
      fontFamily: 'Geist',
      fontSize: isDesktop ? 15 : 14,
      fontWeight: FontWeight.w500,
      height: 22 / (isDesktop ? 15 : 14),
      color: SyraColors.textSecondary.withValues(alpha: 0.72),
    );

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(SyraSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              _buildLogo().fadeInSlide(
                delay: const Duration(milliseconds: 100),
              ),

              SizedBox(height: SyraSpacing.xl),

              // Title
              Text(
                titleText,
                style: titleStyle,
                textAlign: TextAlign.center,
              ).fadeInSlide(
                delay: const Duration(milliseconds: 200),
              ),

              const SizedBox(height: 12),

              // Subtitle
              Text(
                subtitleText,
                style: subtitleStyle,
                textAlign: TextAlign.center,
              ).fadeInSlide(
                delay: const Duration(milliseconds: 300),
              ),

              // Suggestions removed (as requested)
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // LOGO
  // ═══════════════════════════════════════════════════════════════

  Widget _buildLogo() {
    return Container(
      width: 108,
      height: 108,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            SyraColors.accent.withValues(alpha: 0.18),
            SyraColors.accent.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: SyraColors.accent.withValues(alpha: 0.14),
            blurRadius: 34,
            spreadRadius: 6,
          ),
        ],
      ),
      child: Center(
        child: Image.asset(
          'assets/images/syra_logo.png',
          width: 56,
          height: 56,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
