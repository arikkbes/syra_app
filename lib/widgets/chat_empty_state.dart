import 'package:flutter/material.dart';
import '../../theme/syra_theme.dart';
import '../../theme/syra_design_tokens.dart';
import '../../utils/animation_helpers.dart';

/// ═══════════════════════════════════════════════════════════════
/// CHAT EMPTY STATE
/// Premium empty state with animations
/// ═══════════════════════════════════════════════════════════════

class ChatEmptyState extends StatelessWidget {
  final VoidCallback onSuggestionTap;
  final bool isTarotMode;

  const ChatEmptyState({
    super.key,
    required this.onSuggestionTap,
    this.isTarotMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(SyraSpacing.screenEdgeLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with scale animation
            scaleIn(
              _buildLogo(),
              delay: Duration.zero,
            ),

            SizedBox(height: SyraSpacing.xxxl),

            // Welcome text with fade
            fadeIn(
              _buildWelcomeText(),
              delay: SyraAnimation.fadeDelay,
            ),

            SizedBox(height: SyraSpacing.xl),

            // Description with fade
            fadeIn(
              _buildDescription(),
              delay: SyraAnimation.fadeDelay * 2,
            ),

            SizedBox(height: SyraSpacing.huge),

            // Suggestions with stagger
            StaggeredList(
              staggerDelay: SyraAnimation.staggerDelay,
              children: _buildSuggestions(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SyraColors.accent.withOpacity(0.2),
            SyraColors.accent.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: SyraColors.accent.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.psychology_outlined,
          size: 48,
          color: SyraColors.accent.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildWelcomeText() {
    return Text(
      isTarotMode ? 'Tarot Modu' : 'Merhaba! Ben SYRA',
      style: SyraTypography.displayMedium,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDescription() {
    return Text(
      isTarotMode
          ? 'Kartlar senin için hazır. Ne öğrenmek istersin?'
          : 'İlişki danışmanın burada. Sana nasıl yardımcı olabilirim?',
      style: SyraTypography.bodyMedium.copyWith(
        color: SyraColors.textSecondary,
      ),
      textAlign: TextAlign.center,
    );
  }

  List<Widget> _buildSuggestions() {
    final suggestions = isTarotMode
        ? [
            'Aşk hayatım nasıl gidecek?',
            'Kariyerimde ne gibi değişiklikler olacak?',
            'Beni bekleyen fırsatlar neler?',
          ]
        : [
            'İlişkimde bir sorun var, yardım eder misin?',
            'Flört ettiğim kişi hakkında analiz yapar mısın?',
            'Eski sevgilim geri dönmek istiyor, ne yapmalıyım?',
          ];

    return suggestions
        .map((text) => _buildSuggestionChip(text))
        .toList();
  }

  Widget _buildSuggestionChip(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: SyraSpacing.md),
      child: AnimatedPressButton(
        onTap: onSuggestionTap,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: SyraSpacing.lg,
            vertical: SyraSpacing.md,
          ),
          decoration: BoxDecoration(
            color: SyraColors.surface.withOpacity(0.5),
            borderRadius: SyraRadius.radiusLG,
            border: Border.all(
              color: SyraColors.border,
              width: 1,
            ),
          ),
          child: Text(
            text,
            style: SyraTypography.bodyMedium.copyWith(
              color: SyraColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
