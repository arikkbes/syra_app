// lib/widgets/syra_glass_button.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/syra_glass_tokens.dart';

/// Circular glass button component (Bold variant)
/// 
/// Based on Figma "Liquid Glass button iOS 26 – Bold variant"
/// Adapted to SYRA's dark theme
/// 
/// Features:
/// - 48x48 circular shape
/// - Liquid glass effect with blur
/// - Subtle gradient and border
/// - Smooth scale animation on tap
class SyraGlassButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool enabled;

  const SyraGlassButton({
    super.key,
    required this.child,
    required this.onTap,
    this.enabled = true,
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
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.05,
      end: SyraGlassSpec.scaleDown,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: SyraGlassSpec.animationCurve,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.enabled) {
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.enabled) {
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.enabled) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.enabled ? widget.onTap : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: SyraGlassSpec.buttonSize,
          height: SyraGlassSpec.buttonSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [SyraGlassSpec.defaultShadow],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(SyraGlassSpec.buttonRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: SyraGlassSpec.blurSigma,
                sigmaY: SyraGlassSpec.blurSigma,
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: SyraGlassSpec.glassGradient,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: SyraGlassSpec.borderColor,
                    width: SyraGlassSpec.borderWidth,
                  ),
                ),
                child: Stack(
                  children: [
                    // Inner glow
                    Container(
                      decoration: BoxDecoration(
                        gradient: SyraGlassSpec.innerGlowGradient,
                        shape: BoxShape.circle,
                      ),
                    ),
                    // Content
                    Center(
                      child: IconTheme(
                        data: IconThemeData(
                          color: Colors.white.withValues(alpha: 0.90),
                          size: SyraGlassSpec.iconSize,
                        ),
                        child: widget.child,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
