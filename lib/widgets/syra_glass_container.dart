import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/syra_theme.dart';

/// iOS 26 Style Liquid Glass Container
///
/// Reusable glass effect container based on Figma specs:
/// - Frosted glass blur (BackdropFilter)
/// - Layered gradient (#000, #333, #999)
/// - Subtle top highlight streak
/// - Thin neon-like border
/// - Soft shadows for depth
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
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        // Outer shadow for depth
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.7),
            blurRadius: 24,
            offset: const Offset(0, 12),
            spreadRadius: 0,
          ),
          // Soft upper glow for volume
          BoxShadow(
            color: Colors.white.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
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
              // Layered gradient base: dark to darker
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  // Top: Light gray (~30% opacity #999999)
                  const Color(0xFF999999).withOpacity(0.30),
                  // Middle: Dark gray (~45% opacity #333333)
                  const Color(0xFF333333).withOpacity(0.45),
                  // Bottom: Black (100% opacity)
                  const Color(0xFF000000).withOpacity(1.0),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(borderRadius),
              // Thin neon-like border
              border: Border.all(
                // Mix of white opacities from Figma: 100%, 33%, 8%, 6%
                color: Colors.white.withOpacity(0.12),
                width: 0.5,
              ),
            ),
            child: Stack(
              children: [
                // Subtle top-left to bottom-right highlight streak
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(borderRadius),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.12), // Top highlight
                        Colors.white.withOpacity(0.03), // Middle fade
                        Colors.transparent, // Bottom clear
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
                // Optional overlay tint
                if (overlayColor != null)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(borderRadius),
                      color: overlayColor!.withOpacity(0.05),
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
