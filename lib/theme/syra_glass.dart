// lib/theme/syra_glass.dart

export 'syra_glass_tokens.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'syra_theme.dart';
import 'syra_glass_tokens.dart';

export 'syra_glass_tokens.dart';

/// ═══════════════════════════════════════════════════════════════
/// SYRA GLASS COMPONENTS
/// Unified glass/frosted UI system for premium look
/// ═══════════════════════════════════════════════════════════════
/// UPDATED: Now uses SyraGlassSpec from syra_glass_tokens.dart
/// All glass effects are Figma-matched with no conflicting gradients
/// ═══════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════
// LEGACY GLASS TOKENS (deprecated - use SyraGlassSpec instead)
// ═══════════════════════════════════════════════════════════════
class SyraGlass {
  SyraGlass._();

  // Colors
  static const Color base = Color(0xFF1A1D26);
  static const Color overlay = Color(0x331A1D26);

  // White opacity variants
  static const Color white100 = Color(0xFFFFFFFF);
  static const Color white40 = Color(0x66FFFFFF);
  static const Color white20 = Color(0x33FFFFFF);
  static const Color white12 = Color(0x1FFFFFFF);
  static const Color white8 = Color(0x14FFFFFF);
  static const Color white1 = Color(0x03FFFFFF);

  // Blur Levels
  static const double blurSubtle = 8.0;
  static const double blurMedium = 16.0;
  static const double blurStrong = 24.0;

  // Dimensions
  static const double buttonSize = 48.0;
  static const double barHeight = 48.0;
  static const double cardPadding = 16.0;

  // Shadows
  static List<BoxShadow> get glassShadow => [SyraGlassSpec.defaultShadow];
  static List<BoxShadow> get subtleShadow => [SyraGlassSpec.defaultShadow];
  static List<BoxShadow> get lightShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ];
}

// ═══════════════════════════════════════════════════════════════
// BASE GLASS CONTAINER (Refactored to use SyraLiquidGlass)
// ═══════════════════════════════════════════════════════════════
class SyraGlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final double blur;
  final Color? color;
  final Gradient? gradient;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final double? width;
  final double? height;
  final bool enableHighlight;

  const SyraGlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.blur = 16.0,
    this.color,
    this.gradient,
    this.border,
    this.boxShadow,
    this.width,
    this.height,
    this.enableHighlight = false, // Changed default to false
  });

  @override
  Widget build(BuildContext context) {
    // If custom parameters provided, build legacy way
    if (gradient != null || color != null || enableHighlight) {
      return _buildLegacyGlass(context);
    }
    
    // Otherwise use clean liquid glass
    return SyraLiquidGlass(
      borderRadius: borderRadius,
      blur: blur,
      width: width,
      height: height,
      padding: padding,
      child: child,
    );
  }

  Widget _buildLegacyGlass(BuildContext context) {
    final effectiveRadius = borderRadius ?? SyraRadius.md;
    final effectiveBorder = border ??
        Border.all(
          color: SyraGlassSpec.strokeColor,
          width: SyraGlassSpec.strokeWidth,
        );

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(effectiveRadius),
        boxShadow: boxShadow ?? [SyraGlassSpec.defaultShadow],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(effectiveRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              gradient: gradient,
              borderRadius: BorderRadius.circular(effectiveRadius),
              border: effectiveBorder,
            ),
            child: Stack(
              children: [
                if (enableHighlight)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(effectiveRadius),
                    ),
                  ),
                Padding(
                  padding: padding ?? EdgeInsets.zero,
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// GLASS CARD
// ═══════════════════════════════════════════════════════════════
class SyraGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final VoidCallback? onTap;

  const SyraGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = SyraLiquidGlass(
      borderRadius: borderRadius ?? SyraGlassSpec.radiusCard,
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );

    if (onTap != null) {
      return Padding(
        padding: margin ?? EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius ?? SyraGlassSpec.radiusCard),
          child: card,
        ),
      );
    }

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: card,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// GLASS BAR (Pill-shaped, for chat input, etc.)
// ═══════════════════════════════════════════════════════════════
class SyraGlassBar extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? height;

  const SyraGlassBar({
    super.key,
    required this.child,
    this.padding,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = height ?? 48.0;
    final effectiveRadius = effectiveHeight / 2;

    return SyraLiquidGlass(
      height: effectiveHeight,
      borderRadius: effectiveRadius,
      blur: SyraGlassSpec.blurSigma,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 14.0),
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// GLASS PILL (Compact tag/badge style)
// ═══════════════════════════════════════════════════════════════
class SyraGlassPill extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color? color;

  const SyraGlassPill({
    super.key,
    required this.text,
    this.icon,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SyraLiquidGlass(
      borderRadius: SyraGlassSpec.radiusPill,
      padding: EdgeInsets.symmetric(
        horizontal: icon != null ? 10 : 12,
        vertical: 6,
      ),
      blur: SyraGlassSpec.blurSubtle,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(SyraGlassSpec.radiusPill),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: color ?? SyraColors.textSecondary,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                text,
                style: SyraTextStyles.labelSmall.copyWith(
                  color: color ?? SyraColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
