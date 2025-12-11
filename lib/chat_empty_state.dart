// lib/widgets/chat_empty_state.dart

// LEGACY / UNUSED COPY – canonical version lives under lib/widgets/chat_empty_state.dart
// Kept only as backup. Do not import this file from production code.

import 'package:flutter/material.dart';
import '../theme/syra_theme.dart';
import '../theme/syra_glass.dart';
import '../theme/syra_animations.dart';

/// ═══════════════════════════════════════════════════════════════
/// PREMIUM CHAT EMPTY STATE
/// ═══════════════════════════════════════════════════════════════
/// Hero section when no messages exist:
/// - Logo/icon
/// - Welcome message
/// - Quick action chips
/// ═══════════════════════════════════════════════════════════════

class ChatEmptyState extends StatelessWidget {
  final bool isTarotMode;
  final Function(String) onSuggestionTap;

  const ChatEmptyState({
    super.key,
    required this.isTarotMode,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(SyraSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo/Icon
            _buildLogo().fadeInSlide(
              delay: Duration(milliseconds: 100),
            ),

            SizedBox(height: SyraSpacing.xl),

            // Title
            Text(
              isTarotMode ? "Kartlar hazır..." : "Bugün neyi çözüyoruz?",
              style: SyraTextStyles.displayMedium.copyWith(
                color: isTarotMode ? SyraColors.accent : SyraColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ).fadeInSlide(
              delay: Duration(milliseconds: 200),
            ),

            SizedBox(height: SyraSpacing.md),

            // Subtitle
            Text(
              isTarotMode
                  ? "İstersen önce birkaç cümleyle durumu anlat."
                  : "Mesajını, ilişkinizi ya da aklındaki soruyu anlat.",
              style: SyraTextStyles.bodyMedium.copyWith(
                color: SyraColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ).fadeInSlide(
              delay: Duration(milliseconds: 300),
            ),

            SizedBox(height: SyraSpacing.xl + SyraSpacing.sm),

            // Suggestion chips
            _buildSuggestions(),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // LOGO
  // ═══════════════════════════════════════════════════════════════

  Widget _buildLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            SyraColors.accent.withValues(alpha: 0.2),
            SyraColors.accent.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: SyraColors.accent.withValues(alpha: 0.15),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Center(
        child: Text(
          isTarotMode ? "🔮" : "S",
          style: TextStyle(
            fontSize: isTarotMode ? 48 : 42,
            fontWeight: FontWeight.w300,
            color: SyraColors.accent.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SUGGESTIONS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSuggestions() {
    final List<String> suggestions = isTarotMode
        ? [
            "Son konuşmamı kartlarla yorumla",
            "İlişkim için genel tarot açılımı yap",
            "Bugün için kart çek",
          ]
        : [
            "İlişki mesajımı analiz et",
            "İlk mesaj taktiği ver",
            "Konuşmamın enerjisini değerlendir",
          ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: SyraSpacing.sm,
      runSpacing: SyraSpacing.sm,
      children: suggestions.asMap().entries.map((entry) {
        final index = entry.key;
        final text = entry.value;
        return _buildSuggestionChip(
          text: text,
          index: index,
        );
      }).toList(),
    );
  }

  Widget _buildSuggestionChip({
    required String text,
    required int index,
  }) {
    return SyraGlassCard(
      padding: EdgeInsets.symmetric(
        horizontal: SyraSpacing.md,
        vertical: SyraSpacing.sm + 2,
      ),
      borderRadius: SyraRadius.full,
      onTap: () => onSuggestionTap(text),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 16,
            color: SyraColors.accent.withValues(alpha: 0.7),
          ),
          SizedBox(width: SyraSpacing.xs),
          Flexible(
            child: Text(
              text,
              style: SyraTextStyles.labelMedium.copyWith(
                color: SyraColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    ).fadeInSlide(
      delay: Duration(milliseconds: 400 + (index * 100)),
    );
  }
}
