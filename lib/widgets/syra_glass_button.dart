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
      duration: SyraGlassTokens.animationDuration,
    );
    _scaleAnimation = Tween<double>(
      begin: SyraGlassTokens.scaleUp,
      end: SyraGlassTokens.scaleDown,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: SyraGlassTokens.animationCurve,
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
          width: SyraGlassTokens.buttonSize,
          height: SyraGlassTokens.buttonSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: SyraGlassTokens.glassShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(SyraGlassTokens.buttonRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: SyraGlassTokens.blurSigma,
                sigmaY: SyraGlassTokens.blurSigma,
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: SyraGlassTokens.glassGradient,
                  shape: BoxShape.circle,
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
                        shape: BoxShape.circle,
                      ),
                    ),
                    // Content
                    Center(
                      child: IconTheme(
                        data: IconThemeData(
                          color: SyraGlassTokens.white100.withOpacity(0.9),
                          size: SyraGlassTokens.iconSize,
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
