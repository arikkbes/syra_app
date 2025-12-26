// lib/widgets/syra_top_haze.dart

import 'dart:ui';
import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════
/// SYRA TOP HAZE - Claude/Sonnet Style Header Overlay
/// ═══════════════════════════════════════════════════════════════
/// A subtle "foggy/haze" effect that combines:
/// - Micro-blur (BackdropFilter with small sigma)
/// - Soft dimming scrim (vertical gradient)
/// - Feather fade at bottom edge (no hard line)
/// - Tiny white lift for fog appearance
///
/// This creates the characteristic Claude/Sonnet "slightly foggy"
/// header that fades smoothly into content.
/// ═══════════════════════════════════════════════════════════════

class SyraTopHaze extends StatelessWidget {
  /// Total height of the haze overlay (recommended: 150-200)
  final double height;

  /// Blur intensity for the haze effect (recommended: 4-6)
  /// iOS: 5-6, Android: 4-5
  final double blurSigma;

  /// Height of the feather fade at bottom (recommended: 60-90)
  final double featherHeight;

  /// Scrim gradient opacity at top (recommended: 0.70-0.85)
  final double scrimTopAlpha;

  /// Scrim gradient opacity at mid (recommended: 0.20-0.35)
  final double scrimMidAlpha;

  /// Where the mid scrim transition happens (0.0-1.0, recommended: 0.55-0.65)
  final double scrimMidStop;

  /// Subtle white lift for fog appearance (recommended: 0.02-0.04)
  final double whiteLiftAlpha;

  const SyraTopHaze({
    super.key,
    this.height = 170.0,
    this.blurSigma = 5.5,
    this.featherHeight = 70.0,
    this.scrimTopAlpha = 0.75,
    this.scrimMidAlpha = 0.25,
    this.scrimMidStop = 0.60,
    this.whiteLiftAlpha = 0.03,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        height: height,
        child: blurSigma > 0
            ? ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: blurSigma,
                    sigmaY: blurSigma,
                    tileMode: TileMode.clamp,
                  ),
                  child: _buildScrimWithFeather(),
                ),
              )
            : _buildScrimWithFeather(), // No blur wrapper when sigma is 0
      ),
    );
  }

  /// Build scrim gradient with feather fade at bottom
  Widget _buildScrimWithFeather() {
    // Calculate feather fade stops
    final featherStart = ((height - featherHeight) / height).clamp(0.0, 1.0);

    // Create the scrim + white lift stack
    Widget scrimStack = Stack(
      children: [
        // Base scrim gradient (darkening)
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(scrimTopAlpha), // Strong at top
                Colors.black.withOpacity(scrimMidAlpha), // Medium at mid
                Colors.transparent, // Fade to clear
              ],
              stops: [
                0.0,
                scrimMidStop,
                1.0,
              ],
            ),
          ),
        ),

        // Subtle white lift for fog/haze appearance
        // Using cool blue-white instead of Colors.white to prevent yellow tint
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFE8F0F8).withOpacity(whiteLiftAlpha), // Cool blue-white
                const Color(0xFFE8F0F8).withOpacity(whiteLiftAlpha * 0.5),
                Colors.transparent, // Fade to clear
              ],
              stops: [
                0.0,
                scrimMidStop,
                1.0,
              ],
            ),
          ),
        ),
      ],
    );

    // Apply feather fade mask to bottom edge
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Colors.white, // Full opacity at top
            Colors.white, // Full opacity until feather starts
            Colors.transparent, // Fade to transparent at bottom
          ],
          stops: [
            0.0,
            featherStart,
            1.0,
          ],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn, // Masks the scrim, creating feather fade
      child: scrimStack,
    );
  }
}
