import 'dart:ui';
import 'package:flutter/material.dart';

/// SYRA Glass Surface - Claude-style soft-edge blur
///
/// Features:
/// - Controlled blur (not overwhelming)
/// - Gradient overlay for glass effect
/// - Soft fade at edges (no hard lines)
/// - Subtle border
class SyraGlassSurface extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blurSigma;
  final bool fadeTop;
  final bool fadeBottom;
  final double fadeTopHeight;
  final double fadeBottomHeight;

  const SyraGlassSurface({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.blurSigma = 12,
    this.fadeTop = false,
    this.fadeBottom = false,
    this.fadeTopHeight = 16,
    this.fadeBottomHeight = 20,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            // Gradient overlay for glass effect
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.12),
                Colors.white.withValues(alpha: 0.08),
                Colors.white.withValues(alpha: 0.04),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            // Subtle border
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: child,
        ),
      ),
    );

    // Apply soft fade at edges
    if (fadeTop || fadeBottom) {
      content = ShaderMask(
        shaderCallback: (Rect bounds) {
          return LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _buildFadeColors(),
            stops: _buildFadeStops(bounds.height),
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: content,
      );
    }

    return content;
  }

  List<Color> _buildFadeColors() {
    if (fadeTop && fadeBottom) {
      return [
        Colors.transparent,
        Colors.white,
        Colors.white,
        Colors.transparent,
      ];
    } else if (fadeTop) {
      return [
        Colors.transparent,
        Colors.white,
        Colors.white,
      ];
    } else if (fadeBottom) {
      return [
        Colors.white,
        Colors.white,
        Colors.transparent,
      ];
    }
    return [Colors.white];
  }

  List<double> _buildFadeStops(double height) {
    if (fadeTop && fadeBottom) {
      final topStop = fadeTopHeight / height;
      final bottomStop = 1.0 - (fadeBottomHeight / height);
      return [0.0, topStop, bottomStop, 1.0];
    } else if (fadeTop) {
      final topStop = fadeTopHeight / height;
      return [0.0, topStop, 1.0];
    } else if (fadeBottom) {
      final bottomStop = 1.0 - (fadeBottomHeight / height);
      return [0.0, bottomStop, 1.0];
    }
    return [0.0, 1.0];
  }
}

/// Glass Surface Parameters - Single source of truth
class SyraGlassParams {
  // Blur settings
  static const double blurSigma = 12.0; // Reduced from ~16-20

  // Fade heights
  static const double fadeTopHeight = 16.0;
  static const double fadeBottomHeight = 20.0;

  // Border radius
  static const double inputBarRadius = 23.0;
  static const double headerRadius = 0.0; // Header is full width

  // Overlay alphas
  static const double overlayTopAlpha = 0.12;
  static const double overlayMidAlpha = 0.08;
  static const double overlayBottomAlpha = 0.04;

  // Border alpha
  static const double borderAlpha = 0.08;
}
