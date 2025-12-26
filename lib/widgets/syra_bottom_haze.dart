// lib/widgets/syra_bottom_haze.dart

import 'dart:ui';
import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════
/// SYRA BOTTOM HAZE - Claude/Sonnet Style Footer Overlay
/// ═══════════════════════════════════════════════════════════════
/// A subtle "foggy/haze" effect for the bottom area that combines:
/// - Micro-blur (BackdropFilter with very small sigma)
/// - Soft dimming scrim (vertical gradient, strongest at bottom)
/// - Feather fade at TOP edge (no hard line)
/// - Tiny white lift for fog appearance
///
/// This creates the characteristic Claude/Sonnet "slightly foggy"
/// footer that fades smoothly into content.
/// ═══════════════════════════════════════════════════════════════

class SyraBottomHaze extends StatelessWidget {
  /// Total height of the haze overlay (recommended: 80-120)
  final double height;

  /// Blur intensity for the haze effect (recommended: 0.7-1.2)
  /// Should be minimal for a subtle micro-blur effect
  final double blurSigma;

  /// Height of the feather fade at top (recommended: 20-30)
  final double featherHeight;

  /// Scrim gradient opacity at bottom (recommended: 0.50-0.65)
  final double scrimBottomAlpha;

  /// Scrim gradient opacity at mid (recommended: 0.15-0.25)
  final double scrimMidAlpha;

  /// Where the mid scrim transition happens (0.0-1.0, recommended: 0.55-0.65)
  final double scrimMidStop;

  /// Subtle white lift for fog appearance (recommended: 0.02-0.04)
  final double whiteLiftAlpha;

  const SyraBottomHaze({
    super.key,
    this.height = 100.0,
    this.blurSigma = 0.9,
    this.featherHeight = 22.0,
    this.scrimBottomAlpha = 0.55,
    this.scrimMidAlpha = 0.18,
    this.scrimMidStop = 0.60,
    this.whiteLiftAlpha = 0.03,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        height: height,
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: blurSigma,
              sigmaY: blurSigma,
              tileMode: TileMode.clamp,
            ),
            child: _buildScrimWithFeather(),
          ),
        ),
      ),
    );
  }

  /// Build scrim gradient with feather fade at top
  Widget _buildScrimWithFeather() {
    // Calculate feather fade stops (fade at TOP for bottom haze)
    final featherStop = (featherHeight / height).clamp(0.0, 1.0);

    // Create the scrim + white lift stack
    Widget scrimStack = Stack(
      children: [
        // Base scrim gradient (darkening, strongest at bottom)
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent, // Fade from clear at top
                Colors.black.withOpacity(scrimMidAlpha), // Medium at mid
                Colors.black.withOpacity(scrimBottomAlpha), // Strong at bottom
              ],
              stops: [
                0.0,
                1.0 - scrimMidStop,
                1.0,
              ],
            ),
          ),
        ),

        // Subtle white lift for fog/haze appearance
        // Using cool blue-white to prevent yellow tint
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent, // Fade from clear at top
                const Color(0xFFE8F0F8).withOpacity(whiteLiftAlpha * 0.5),
                const Color(0xFFE8F0F8).withOpacity(whiteLiftAlpha),
              ],
              stops: [
                0.0,
                1.0 - scrimMidStop,
                1.0,
              ],
            ),
          ),
        ),
      ],
    );

    // Apply feather fade mask to top edge
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Colors.transparent, // Fade from transparent at top
            Colors.white, // Full opacity after feather
            Colors.white, // Full opacity at bottom
          ],
          stops: [
            0.0,
            featherStop,
            1.0,
          ],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn, // Masks the scrim, creating feather fade
      child: scrimStack,
    );
  }
}
