// lib/widgets/syra_glass_sheet.dart

import 'dart:ui';
import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════
/// SYRA GLASS SHEET - Claude-style glass regions
/// ═══════════════════════════════════════════════════════════════
/// Reusable glass overlay for top/bottom regions with:
/// - BackdropFilter blur (no shaders)
/// - Soft edge fading (gradient mask on background ONLY)
/// - Subtle tint overlay
/// - Configurable parameters
/// ═══════════════════════════════════════════════════════════════

enum FadeDirection {
  top, // Fade from bottom edge upward
  bottom, // Fade from top edge downward
  both, // Fade both edges
  none, // No fade (sharp edges)
}

class SyraGlassSheet extends StatelessWidget {
  /// Blur intensity (sigma for BackdropFilter)
  final double blurSigma;

  /// Background tint color and opacity
  final Color tintColor;
  final double tintAlpha;

  /// Soft fade configuration - DUAL FADE support
  final double fadeTopHeight; // Height of fade at TOP edge (pixels)
  final double fadeBottomHeight; // Height of fade at BOTTOM edge (pixels)

  /// Legacy parameter for backward compatibility
  final double fadeHeight; // Used when only one fade is needed
  final FadeDirection fadeDirection;

  /// Optional matte scrim overlay (gradient) for Claude-style matte glass
  final bool enableMatteScrim;
  final double matteScrimAlphaTop; // Gradient alpha at top
  final double matteScrimAlphaBottom; // Gradient alpha at bottom

  /// Optional border
  final Border? border;

  /// Optional border radius for rounded edges
  final BorderRadius? borderRadius;

  /// Child widget (typically header or input bar)
  final Widget child;

  const SyraGlassSheet({
    super.key,
    this.blurSigma = 12.0,
    this.tintColor = Colors.black,
    this.tintAlpha = 0.15,
    this.fadeHeight = 40.0,
    this.fadeTopHeight = 0.0,
    this.fadeBottomHeight = 0.0,
    this.fadeDirection = FadeDirection.none,
    this.enableMatteScrim = false,
    this.matteScrimAlphaTop = 0.0,
    this.matteScrimAlphaBottom = 0.06,
    this.border,
    this.borderRadius,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    Widget blurContent = BackdropFilter(
      filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
      child: Stack(
        children: [
          // Background layer with fade mask + matte scrim
          _buildBackgroundWithFadeAndScrim(),

          // Content layer (NOT affected by fade mask)
          child,
        ],
      ),
    );

    // Apply border radius if provided
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: blurContent,
      );
    }

    return ClipRect(child: blurContent);
  }

  /// Build background tint with optional soft edge fading + matte scrim overlay
  Widget _buildBackgroundWithFadeAndScrim() {
    // Base tinted background
    Widget background = Container(
      decoration: BoxDecoration(
        color: tintColor.withValues(alpha: tintAlpha),
        border: border,
        borderRadius: borderRadius,
      ),
    );

    // Add matte scrim overlay if enabled (for Claude-style matte glass)
    // Combine background + scrim BEFORE applying fade mask so both fade together
    if (enableMatteScrim) {
      background = Stack(
        children: [
          background,
          // Matte scrim gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: matteScrimAlphaTop),
                  Colors.black.withValues(alpha: matteScrimAlphaBottom),
                ],
              ),
              borderRadius: borderRadius,
            ),
          ),
        ],
      );
    }

    // Apply fade mask to the combined background+scrim stack
    if (fadeDirection != FadeDirection.none ||
        fadeTopHeight > 0 ||
        fadeBottomHeight > 0) {
      background = ShaderMask(
        shaderCallback: (Rect bounds) {
          return _buildFadeGradient(bounds).createShader(bounds);
        },
        blendMode: BlendMode.dstIn, // Masks the background+scrim, not the content
        child: background,
      );
    }

    return background;
  }

  /// Create fade gradient based on direction and dual fade heights
  LinearGradient _buildFadeGradient(Rect bounds) {
    // DUAL FADE: Both top and bottom fade specified
    if (fadeTopHeight > 0 && fadeBottomHeight > 0) {
      final topStop = fadeTopHeight / bounds.height;
      final bottomStop = 1.0 - (fadeBottomHeight / bounds.height);

      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [
          Colors.transparent, // Fade at top
          Colors.white, // Full opacity in middle
          Colors.white, // Full opacity in middle
          Colors.transparent, // Fade at bottom
        ],
        stops: [
          0.0,
          topStop.clamp(0.0, 1.0),
          bottomStop.clamp(0.0, 1.0),
          1.0,
        ],
      );
    }

    // Legacy fadeDirection handling
    switch (fadeDirection) {
      case FadeDirection.top:
        // Fade from bottom edge upward (for bottom glass sheet)
        // Fade from transparent at top to full opacity
        final fadeEnd = (fadeHeight / bounds.height).clamp(0.0, 1.0);
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Colors.transparent, // Fade at top
            Colors.white, // Full opacity by fadeEnd
            Colors.white, // Full opacity at bottom
          ],
          stops: [
            0.0,
            fadeEnd,
            1.0,
          ],
        );

      case FadeDirection.bottom:
        // Fade from top edge downward - keep full opacity until near bottom, then fade
        final fadeStart = (1.0 - fadeHeight / bounds.height).clamp(0.0, 1.0);
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Colors.white, // Full opacity at top
            Colors.white, // Full opacity until fade starts
            Colors.transparent, // Fade to transparent at bottom
          ],
          stops: [
            0.0,
            fadeStart,
            1.0,
          ],
        );

      case FadeDirection.both:
        // Fade both top and bottom edges
        final fadeStop = (fadeHeight / bounds.height).clamp(0.0, 1.0);
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Colors.transparent, // Fade at top
            Colors.white, // Full opacity in middle
            Colors.white, // Full opacity in middle
            Colors.transparent, // Fade at bottom
          ],
          stops: [
            0.0,
            fadeStop,
            1.0 - fadeStop,
            1.0, // Explicit stop at 1.0 to avoid abrupt edge
          ],
        );

      case FadeDirection.none:
        // Should not reach here, but for completeness
        return const LinearGradient(
          colors: [Colors.white, Colors.white],
        );
    }
  }
}

/// ═══════════════════════════════════════════════════════════════
/// PRE-CONFIGURED VARIANTS FOR COMMON USE CASES
/// ═══════════════════════════════════════════════════════════════

/// Top header glass sheet with bottom fade
class SyraGlassSheetTop extends StatelessWidget {
  final Widget child;
  final double blurSigma;
  final double fadeHeight;

  const SyraGlassSheetTop({
    super.key,
    required this.child,
    this.blurSigma = 12.0,
    this.fadeHeight = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    return SyraGlassSheet(
      blurSigma: blurSigma,
      tintColor: Colors.black,
      tintAlpha: 0.05, // Reduced from 0.08 for lighter dimming
      fadeHeight: fadeHeight,
      fadeDirection: FadeDirection.bottom, // Fade from top into content
      enableMatteScrim: true, // Enable subtle matte scrim
      matteScrimAlphaTop: 0.03, // Subtle dim at top
      matteScrimAlphaBottom: 0.08, // Slightly more dim at bottom
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          child, // ChatAppBar
          IgnorePointer(
            child: SizedBox(height: fadeHeight), // Extend glass area downward
          ),
        ],
      ),
    );
  }
}

/// Bottom input bar glass sheet with dual feather fade + matte scrim
/// Claude-style: matte frosted glass that dissipates softly
class SyraGlassSheetBottom extends StatelessWidget {
  final Widget child;
  final double blurSigma;
  final double fadeTopHeight; // Fade into chat content
  final double fadeBottomHeight; // Fade toward home indicator
  final BorderRadius? borderRadius; // Optional rounded corners

  const SyraGlassSheetBottom({
    super.key,
    required this.child,
    this.blurSigma = 6.5,
    this.fadeTopHeight = 96.0,
    this.fadeBottomHeight = 28.0,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return SyraGlassSheet(
      blurSigma: blurSigma,
      tintColor: Colors.black,
      tintAlpha: 0.04,
      fadeTopHeight: fadeTopHeight,
      fadeBottomHeight: fadeBottomHeight,
      fadeDirection: FadeDirection.none, // Using dual fade instead
      enableMatteScrim: true, // Enable matte scrim overlay
      matteScrimAlphaTop: 0.0,
      matteScrimAlphaBottom: 0.075, // Subtle darkening at bottom
      borderRadius: borderRadius, // Pass through border radius
      child: child,
    );
  }
}
