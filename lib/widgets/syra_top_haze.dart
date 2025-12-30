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
///
/// ARCHITECTURE (v2 - Fixed hard edge):
/// The blur itself is faded out using ShaderMask(dstIn) on the
/// BackdropFilter result. This eliminates the hard cutoff line
/// that occurred when only the scrim was faded.
///
/// Layer stack:
/// 1. ClipRect + BackdropFilter with tiny-alpha child (makes blur paint)
/// 2. ShaderMask(dstIn) wrapping the blur → fades blur intensity
/// 3. Scrim gradient layer (separate, also faded)
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
  /// NOTE: Set to 0 or very low to avoid "muddy" gray plate look
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
    // Calculate feather fade start position (0.0 = top, 1.0 = bottom)
    final featherStart = ((height - featherHeight) / height).clamp(0.0, 1.0);

    return IgnorePointer(
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            // ─────────────────────────────────────────────────────────
            // LAYER 1: Blur layer with feather fade
            // The blur itself is faded via ShaderMask(dstIn) so there's
            // no hard edge where the BackdropFilter clip ends.
            // ─────────────────────────────────────────────────────────
            if (blurSigma > 0)
              Positioned.fill(
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: const [
                        Colors.white, // Full blur at top
                        Colors.white, // Full blur until feather starts
                        Colors.transparent, // Fade blur to zero at bottom
                      ],
                      stops: [
                        0.0,
                        featherStart,
                        1.0,
                      ],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: blurSigma,
                        sigmaY: blurSigma,
                        tileMode: TileMode.clamp,
                      ),
                      // Tiny-alpha container to make BackdropFilter paint
                      // Without this, the blur may not render on some devices
                      child: Container(
                        color: Colors.white.withOpacity(0.001),
                      ),
                    ),
                  ),
                ),
              ),

            // ─────────────────────────────────────────────────────────
            // LAYER 2: Scrim gradient (dimming) with feather fade
            // Separate from blur so we can control tint independently.
            // Also faded with ShaderMask to match blur fade.
            // ─────────────────────────────────────────────────────────
            Positioned.fill(
              child: ShaderMask(
                shaderCallback: (Rect bounds) {
                  return LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: const [
                      Colors.white,
                      Colors.white,
                      Colors.transparent,
                    ],
                    stops: [
                      0.0,
                      featherStart,
                      1.0,
                    ],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(scrimTopAlpha),
                        Colors.black.withOpacity(scrimMidAlpha),
                        Colors.black.withOpacity(scrimMidAlpha * 0.5),
                      ],
                      stops: [
                        0.0,
                        scrimMidStop,
                        1.0,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ─────────────────────────────────────────────────────────
            // LAYER 3: Subtle white lift (optional fog appearance)
            // Keep very low (0.01-0.02) to avoid muddy gray look.
            // Also faded with the same feather gradient.
            // ─────────────────────────────────────────────────────────
            if (whiteLiftAlpha > 0)
              Positioned.fill(
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: const [
                        Colors.white,
                        Colors.white,
                        Colors.transparent,
                      ],
                      stops: [
                        0.0,
                        featherStart,
                        1.0,
                      ],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(whiteLiftAlpha),
                          Colors.white.withOpacity(whiteLiftAlpha * 0.3),
                          Colors.transparent,
                        ],
                        stops: [
                          0.0,
                          scrimMidStop,
                          1.0,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
