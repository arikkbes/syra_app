import 'package:flutter/material.dart';
import '../theme/syra_theme.dart';
import '../theme/syra_glass.dart';

/// ═══════════════════════════════════════════════════════════════
/// SYRA BACKGROUND v2.0 — ChatGPT 2025 Style
/// ═══════════════════════════════════════════════════════════════
/// - Solid deep blue background (#072233)
/// - No gradients, no particles, no orb reflections
/// - Clean, minimal, modern
/// ═══════════════════════════════════════════════════════════════

class SyraBackground extends StatelessWidget {
  final bool enableParticles;
  final bool enableGrain;
  final double particleOpacity;

  const SyraBackground({
    super.key,
    this.enableParticles = false, // Disabled by default
    this.enableGrain = false,
    this.particleOpacity = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: SyraColors.background,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ═══════════════════════════════════════════════════════════════
class SyraLogo extends StatelessWidget {
  final double fontSize;
  final bool withGlow;
  final bool showModLabel;
  final String? selectedMode;

  const SyraLogo({
    super.key,
    this.fontSize = 22,
    this.withGlow = false, // No glow by default
    this.showModLabel = false,
    this.selectedMode,
  });

  String _getModeDisplayName(String mode) {
    switch (mode) {
      case 'standard':
        return 'Normal';
      case 'deep':
        return 'Derin Analiz';
      case 'mentor':
        return 'Dost Acı Söyler';
      default:
        return 'Normal';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "SYRA",
          style: SyraTextStyles.logoStyle(fontSize: fontSize),
        ),
        if (showModLabel && selectedMode != null) ...[
          SizedBox(width: SyraSpacing.sm),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: SyraSpacing.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: SyraColors.glassBg,
              borderRadius: BorderRadius.circular(SyraRadius.xs),
              border: Border.all(color: SyraColors.border, width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getModeDisplayName(selectedMode!),
                  style: SyraTextStyles.labelSmall.copyWith(
                    fontSize: fontSize * 0.45,
                  ),
                ),
                SizedBox(width: SyraSpacing.xs),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: fontSize * 0.55,
                  color: SyraColors.textMuted,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// BACKWARD COMPATIBILITY: GlassCard → SyraGlassCard
// ═══════════════════════════════════════════════════════════════
@Deprecated('Use SyraGlassCard instead')
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurAmount;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.blurAmount = 10,
  });

  @override
  Widget build(BuildContext context) {
    return SyraGlassCard(
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      child: child,
    );
  }
}
