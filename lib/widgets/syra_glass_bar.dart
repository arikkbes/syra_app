// lib/widgets/syra_glass_bar.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/syra_glass_tokens.dart';

/// Pill-shaped glass bar component
/// 
/// Based on Figma "Liquid Glass button iOS 26 – Bold variant" pill shape
/// Adapted to SYRA's dark theme
/// 
/// Features:
/// - 48px height with pill shape (borderRadius = height/2)
/// - Liquid glass effect with blur
/// - Subtle gradient and border
/// - Wraps child content (like input fields)
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
    final effectiveHeight = height ?? SyraGlassTokens.barHeight;
    final effectiveRadius = effectiveHeight / 2;

    return Container(
      height: effectiveHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(effectiveRadius),
        boxShadow: SyraGlassTokens.glassShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(effectiveRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: SyraGlassTokens.blurSigma,
            sigmaY: SyraGlassTokens.blurSigma,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: SyraGlassTokens.glassGradient,
              borderRadius: BorderRadius.circular(effectiveRadius),
              border: Border.all(
                color: SyraGlassTokens.borderColor,
                width: SyraGlassTokens.borderWidth,
              ),
            ),
            child: Stack(
              children: [
                // Inner glow
                Container(
                  decoration: BoxDecoration(
                    gradient: SyraGlassTokens.innerGlowGradient,
                    borderRadius: BorderRadius.circular(effectiveRadius),
                  ),
                ),
                // Content with padding
                Padding(
                  padding: padding ??
                      EdgeInsets.symmetric(
                        horizontal: SyraGlassTokens.barPaddingHorizontal,
                      ),
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
