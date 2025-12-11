import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../theme/syra_theme.dart';

/// ═══════════════════════════════════════════════════════════════
/// SYRA GLASS SYSTEM v3.0 - Unified Glassmorphism
/// Using the glassmorphism package for consistent, premium glass effects
/// ═══════════════════════════════════════════════════════════════

class SyraGlass {
  SyraGlass._();

  // ═══════════════════════════════════════════════════════════════
  // GLASS CONSTANTS
  // ═══════════════════════════════════════════════════════════════

  /// Standard blur amount for glass effects
  static const double blurStrength = 20.0;

  /// Light blur for subtle effects
  static const double blurLight = 10.0;

  /// Strong blur for prominent glass surfaces
  static const double blurStrong = 30.0;

  /// Standard border thickness
  static const double borderThickness = 1.0;

  /// Subtle border thickness
  static const double borderThin = 0.5;

  /// Glass opacity - main surface
  static const double opacityMain = 0.15;

  /// Glass opacity - lighter variant
  static const double opacityLight = 0.08;

  /// Glass opacity - stronger variant
  static const double opacityStrong = 0.25;

  // ═══════════════════════════════════════════════════════════════
  // GLASS COLORS
  // ═══════════════════════════════════════════════════════════════

  /// Main glass fill color (dark with low opacity)
  static Color get fillColor => SyraColors.surface.withOpacity(opacityMain);

  /// Light glass fill
  static Color get fillLight => SyraColors.surface.withOpacity(opacityLight);

  /// Strong glass fill
  static Color get fillStrong => SyraColors.surface.withOpacity(opacityStrong);

  /// Glass border color
  static Color get borderColor => Colors.white.withOpacity(0.12);

  /// Subtle border
  static Color get borderSubtle => Colors.white.withOpacity(0.06);

  // ═══════════════════════════════════════════════════════════════
  // GLASS SHADOWS
  // ═══════════════════════════════════════════════════════════════

  /// Standard glass shadow
  static List<BoxShadow> get shadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  /// Elevated glass shadow (for floating elements)
  static List<BoxShadow> get shadowElevated => [
        BoxShadow(
          color: Colors.black.withOpacity(0.4),
          blurRadius: 32,
          offset: const Offset(0, 12),
        ),
      ];

  /// Subtle shadow
  static List<BoxShadow> get shadowSubtle => [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}

/// ═══════════════════════════════════════════════════════════════
/// SYRA GLASS CONTAINER
/// Main reusable glass container component
/// ═══════════════════════════════════════════════════════════════
class SyraGlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double? width;
  final double? height;
  final double? blur;
  final double? opacity;
  final Color? fillColor;
  final Color? borderColor;
  final bool withShadow;
  final AlignmentGeometry? alignment;

  const SyraGlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.width,
    this.height,
    this.blur,
    this.opacity,
    this.fillColor,
    this.borderColor,
    this.withShadow = true,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBlur = blur ?? SyraGlass.blurStrength;
    final effectiveFillColor = fillColor ?? SyraGlass.fillColor;
    final effectiveBorderColor = borderColor ?? SyraGlass.borderColor;

    return Container(
      margin: margin,
      width: width,
      height: height,
      decoration: withShadow
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: SyraGlass.shadow,
            )
          : null,
      child: GlassmorphicContainer(
        width: width ?? double.infinity,
        height: height ?? double.infinity,
        borderRadius: borderRadius,
        blur: effectiveBlur,
        alignment: alignment ?? Alignment.center,
        border: SyraGlass.borderThickness,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            effectiveFillColor.withOpacity(opacity ?? 0.15),
            effectiveFillColor.withOpacity((opacity ?? 0.15) * 0.5),
          ],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            effectiveBorderColor,
            effectiveBorderColor.withOpacity(0.5),
          ],
        ),
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// SYRA GLASS BUTTON
/// Circular glass button with tap animation
/// ═══════════════════════════════════════════════════════════════
class SyraGlassButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool enabled;
  final double size;

  const SyraGlassButton({
    super.key,
    required this.child,
    required this.onTap,
    this.enabled = true,
    this.size = 48.0,
  });

  @override
  State<SyraGlassButton> createState() => _SyraGlassButtonState();
}

class _SyraGlassButtonState extends State<SyraGlassButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => _controller.forward() : null,
      onTapUp: widget.enabled ? (_) => _controller.reverse() : null,
      onTapCancel: widget.enabled ? () => _controller.reverse() : null,
      onTap: widget.enabled ? widget.onTap : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: SyraGlass.shadow,
          ),
          child: GlassmorphicContainer(
            width: widget.size,
            height: widget.size,
            borderRadius: widget.size / 2,
            blur: SyraGlass.blurStrength,
            alignment: Alignment.center,
            border: SyraGlass.borderThickness,
            linearGradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                SyraGlass.fillColor,
                SyraGlass.fillColor.withOpacity(0.5),
              ],
            ),
            borderGradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                SyraGlass.borderColor,
                SyraGlass.borderColor.withOpacity(0.5),
              ],
            ),
            child: IconTheme(
              data: IconThemeData(
                color: SyraColors.textPrimary.withOpacity(0.9),
                size: 20,
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// SYRA GLASS BAR
/// Pill-shaped glass bar for input fields and action bars
/// ═══════════════════════════════════════════════════════════════
class SyraGlassBar extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final double? blur;

  const SyraGlassBar({
    super.key,
    required this.child,
    this.padding,
    this.height,
    this.blur,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = height ?? 56.0;
    final effectiveRadius = effectiveHeight / 2;
    final effectiveBlur = blur ?? SyraGlass.blurStrength;

    return Container(
      height: effectiveHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(effectiveRadius),
        boxShadow: SyraGlass.shadow,
      ),
      child: GlassmorphicContainer(
        width: double.infinity,
        height: effectiveHeight,
        borderRadius: effectiveRadius,
        blur: effectiveBlur,
        alignment: Alignment.center,
        border: SyraGlass.borderThickness,
        linearGradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            SyraGlass.fillColor,
            SyraGlass.fillColor.withOpacity(0.5),
          ],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SyraGlass.borderColor,
            SyraGlass.borderColor.withOpacity(0.5),
          ],
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
          child: child,
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// SYRA GLASS CARD
/// Card-style glass container (from glass_background.dart GlassCard)
/// ═══════════════════════════════════════════════════════════════
class SyraGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;

  const SyraGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return SyraGlassContainer(
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin,
      borderRadius: borderRadius,
      blur: SyraGlass.blurLight,
      opacity: 0.8,
      child: child,
    );
  }
}
