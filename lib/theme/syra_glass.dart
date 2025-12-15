// lib/theme/syra_glass.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'syra_theme.dart';

/// ═══════════════════════════════════════════════════════════════
/// SYRA GLASS COMPONENTS
/// Unified glass/frosted UI system for premium look
/// ═══════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════
// GLASS TOKENS
// ═══════════════════════════════════════════════════════════════
class SyraGlass {
  SyraGlass._();

  // ─── Colors ───
  static const Color base = Color(0xFF1A1D26);
  static const Color overlay = Color(0x331A1D26);

  // Figma-derived chat bar colors
  static const Color chatBarBlack = Color(0xFF000000);
  static const Color chatBarGray45 = Color(0x73333333);
  static const Color chatBarGray30 = Color(0x4D999999);

  // White opacity variants
  static const Color white100 = Color(0xFFFFFFFF);
  static const Color white40 = Color(0x66FFFFFF);
  static const Color white20 = Color(0x33FFFFFF);
  static const Color white12 = Color(0x1FFFFFFF);
  static const Color white8 = Color(0x14FFFFFF);
  static const Color white1 = Color(0x03FFFFFF);

  // ─── Blur Levels ───
  static const double blurSubtle = 8.0;
  static const double blurMedium = 16.0;
  static const double blurStrong = 24.0;

  // ─── Dimensions ───
  static const double buttonSize = 48.0;
  static const double barHeight = 48.0;
  static const double cardPadding = 16.0;

  // ─── Gradients ───
  static LinearGradient get glassGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          white20,
          base.withOpacity(0.6),
          base.withOpacity(0.8),
        ],
        stops: const [0.0, 0.4, 1.0],
      );

  static LinearGradient get liquidGlassGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          chatBarGray30,
          chatBarGray45,
          chatBarBlack.withOpacity(0.85),
        ],
        stops: const [0.0, 0.5, 1.0],
      );

  static LinearGradient get innerGlowGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          white1,
          Colors.transparent,
        ],
      );

  static LinearGradient get highlightGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          white12,
          white1,
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      );

  // ─── Shadows ───
  static List<BoxShadow> get glassShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.65),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ];

  static List<BoxShadow> get subtleShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get lightShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
}

// ═══════════════════════════════════════════════════════════════
// BASE GLASS CONTAINER
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
    this.enableHighlight = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? SyraRadius.md;
    final effectiveBorder = border ??
        Border.all(
          color: SyraGlass.white12,
          width: 0.5,
        );

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(effectiveRadius),
        boxShadow: boxShadow ?? SyraGlass.subtleShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(effectiveRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              gradient: gradient ?? SyraGlass.glassGradient,
              borderRadius: BorderRadius.circular(effectiveRadius),
              border: effectiveBorder,
            ),
            child: Stack(
              children: [
                // Optional highlight overlay
                if (enableHighlight)
                  Container(
                    decoration: BoxDecoration(
                      gradient: SyraGlass.highlightGradient,
                      borderRadius: BorderRadius.circular(effectiveRadius),
                    ),
                  ),
                // Content
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
    final card = SyraGlassContainer(
      borderRadius: borderRadius ?? SyraRadius.card,
      padding: padding ?? const EdgeInsets.all(SyraGlass.cardPadding),
      child: child,
    );

    if (onTap != null) {
      return Padding(
        padding: margin ?? EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius ?? SyraRadius.card),
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
    final effectiveHeight = height ?? SyraGlass.barHeight;
    final effectiveRadius = effectiveHeight / 2;

    return SyraGlassContainer(
      height: effectiveHeight,
      borderRadius: effectiveRadius,
      gradient: SyraGlass.liquidGlassGradient,
      blur: SyraGlass.blurStrong,
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: 14.0,
          ),
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// GLASS BUTTON (Circular)
// ═══════════════════════════════════════════════════════════════
// NOTE: SyraGlassButton moved to lib/widgets/syra_glass_button.dart
// This version is deprecated. Use: import '../../widgets/syra_glass_button.dart';
/*
class SyraGlassButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onPressed;
  final double? size;
  final Color? color;

  const SyraGlassButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSize = size ?? SyraGlass.buttonSize;

    return SyraGlassContainer(
      width: effectiveSize,
      height: effectiveSize,
      borderRadius: effectiveSize / 2,
      blur: SyraGlass.blurMedium,
      gradient: color != null
          ? LinearGradient(
              colors: [
                color!.withOpacity(0.3),
                color!.withOpacity(0.1),
              ],
            )
          : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(effectiveSize / 2),
          child: Center(child: icon),
        ),
      ),
    );
  }
}
*/

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
    return SyraGlassContainer(
      borderRadius: SyraRadius.full,
      padding: EdgeInsets.symmetric(
        horizontal: icon != null ? 10 : 12,
        vertical: 6,
      ),
      blur: SyraGlass.blurSubtle,
      gradient: color != null
          ? LinearGradient(
              colors: [
                color!.withOpacity(0.2),
                color!.withOpacity(0.05),
              ],
            )
          : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(SyraRadius.full),
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
