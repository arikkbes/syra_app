// lib/widgets/syra_glass_container.dart
// ═══════════════════════════════════════════════════════════════
// DEPRECATED: Use lib/theme/syra_glass_tokens.dart instead
// ═══════════════════════================================================================════════
// This file is kept for backward compatibility only.
// All new code should use SyraLiquidGlass from syra_glass_tokens.dart
// ═══════════════════════════════════════════════════════════════

import 'dart:ui';
import 'package:flutter/material.dart';

@Deprecated('Use SyraLiquidGlass from theme/syra_glass_tokens.dart instead')
class SyraGlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double blur;
  final Color? overlayColor;
  final double? height;

  const SyraGlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 999,
    this.blur = 20,
    this.overlayColor,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    // Simplified version - removed conflicting gradients
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blur,
            sigmaY: blur,
          ),
          child: Container(
            decoration: BoxDecoration(
              // Clean overlay - no gradients
              color: Color.alphaBlend(
                Colors.white.withValues(alpha: 0.07),
                Colors.black.withValues(alpha: 0.08),
              ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.10),
                width: 1.0,
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
