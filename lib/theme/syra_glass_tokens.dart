// lib/theme/syra_glass_tokens.dart
// ═══════════════════════════════════════════════════════════════
// SYRA GLASS SYSTEM - UNIFIED FIGMA-MATCHED PRESET
// ═══════════════════════════════════════════════════════════════
// Single source of truth for all glass effects
// Figma values: radius=24, blur=24, 
// white=7.000000000000001%, black=8.0%
// ═══════════════════════════════════════════════════════════════

import 'dart:ui';
import 'package:flutter/material.dart';

/// Unified glass specification matching Figma design
class SyraGlassSpec {
  SyraGlassSpec._();


  // ─── LEGACY COLOR CONSTANTS (for backward compatibility) ───
  static final Color white20 = Colors.white.withValues(alpha: 0.20);
  static final Color white12 = Colors.white.withValues(alpha: 0.12);
  static final Color white8 = Colors.white.withValues(alpha: 0.08);
  static final Color white1 = Colors.white.withValues(alpha: 0.01);

  // ─── FIGMA-MATCHED VALUES ───
  static const double radius = 24;
  static const double blurSigma = 24;
  
  // Overlay colors (white + black tint)
  static final Color whiteOverlay = Colors.white.withValues(alpha: 0.07);
  static final Color blackOverlay = Colors.black.withValues(alpha: 0.08);
  
  // Stroke
  static final Color strokeColor = Colors.white.withValues(alpha: 0.1);
  static const double strokeWidth = 1.0;
  
  // Shadow
  static final BoxShadow defaultShadow = BoxShadow(
    color: Colors.black.withValues(alpha: 0.12),
    blurRadius: 20,
    offset: const Offset(0, 8),
    spreadRadius: 0,
  );

  // ─── VARIANT RADII (for different components) ───
  static const double radiusCard = 16.0;
  static const double radiusPill = 999.0;
  static const double radiusButton = 999.0;
  
  // ─── BLUR VARIANTS ───
  static const double blurSubtle = 16.0;
  static const double blurStrong = 28.0;
  
  // ─── DIMENSIONS ───
  static const double barHeight = 48.0;
  static const double buttonSize = 48.0;
  
  // ─── PADDING ───
  static const double barPaddingHorizontal = 14.0;
  static const double barPaddingVertical = 12.0;
  
  // ─── BORDERS ───
  static final Color borderColor = strokeColor; // Alias for compatibility
  static const double borderWidth = strokeWidth; // Alias for compatibility
  
  // ─── CHAT BAR SPECIFIC (legacy compatibility) ───
  static const double chatBarPaddingHorizontal = 14.0;
  static const double chatBarPaddingVertical = 12.0;
  static const double chatBarRadius = radius; // Same as default
  static const double chatBarBlur = blurSigma; // Same as default
  static const double chatBarIconSpacing = 8.0;
  
  // ─── ANIMATION ───
  static const Duration animationDuration = Duration(milliseconds: 200);
  static const double scaleUp = 1.05;
  
  // ─── GRADIENTS (for legacy components) ───
  static final LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [whiteOverlay, blackOverlay],
  );
  
  static final LinearGradient chatBarGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [whiteOverlay, blackOverlay],
  );
  
  static final LinearGradient innerGlowGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.white.withValues(alpha: 0.02),
      Colors.transparent,
    ],
  );
  
  // ─── SHADOWS (legacy) ───
  static final List<BoxShadow> glassShadow = [defaultShadow];
  static const List<BoxShadow> chatBarInnerShadows = [];


  // ─── ANIMATION & INTERACTION ───
  static const double scaleDown = 0.92;
  static const Curve animationCurve = Curves.easeOut;

  // ─── ICON SIZES ───
  static const double iconSize = 24.0;
  static const double chatBarIconSize = 24.0;
  // TODO: Define animationCurve
  // TODO: Define iconSize
  // TODO: Define chatBarIconSize
  // TODO: Define scaleDown
  static const double buttonRadius = 24.0;

}

/// Clean liquid glass container - NO gradients, NO highlights
/// Uses only: blur + white/black overlays + stroke + shadow
class SyraLiquidGlass extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final double? blur;
  final double? height;
  final double? width;

  const SyraLiquidGlass({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.blur,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? SyraGlassSpec.radius;
    final effectiveBlur = blur ?? SyraGlassSpec.blurSigma;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(effectiveRadius),
        boxShadow: [SyraGlassSpec.defaultShadow],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(effectiveRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: effectiveBlur,
            sigmaY: effectiveBlur,
          ),
          child: Container(
            decoration: BoxDecoration(
              // Simple color blend: white + black overlays only
              color: Color.alphaBlend(
                SyraGlassSpec.whiteOverlay,
                SyraGlassSpec.blackOverlay,
              ),
              borderRadius: BorderRadius.circular(effectiveRadius),
              border: Border.all(
                color: SyraGlassSpec.strokeColor,
                width: SyraGlassSpec.strokeWidth,
              ),
            ),
            padding: padding ?? EdgeInsets.zero,
            child: child,
          ),
        ),
      ),
    );
  }
}
