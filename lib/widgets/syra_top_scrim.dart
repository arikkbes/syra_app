// lib/widgets/syra_top_scrim.dart

import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════
/// SYRA TOP SCRIM - Claude/Sonnet Style Header Dimming
/// ═══════════════════════════════════════════════════════════════
/// A clean gradient overlay that dims the content behind the header.
/// NO blur - just a soft darkening scrim that fades into the message list.
///
/// Features:
/// - IgnorePointer: doesn't block scroll/touches
/// - Gradient: strongest at top, fades to transparent
/// - Clean: no hard lines, no blur artifacts
/// ═══════════════════════════════════════════════════════════════

class SyraTopScrim extends StatelessWidget {
  /// Height of the scrim overlay (recommended: 120-200)
  final double height;

  /// Opacity at the very top (recommended: 0.70-0.85)
  final double topOpacity;

  /// Opacity at the middle point (recommended: 0.20-0.35)
  final double midOpacity;

  /// Where the middle stop occurs (0.0-1.0, recommended: 0.55)
  final double midStop;

  const SyraTopScrim({
    super.key,
    this.height = 160.0,
    this.topOpacity = 0.78,
    this.midOpacity = 0.28,
    this.midStop = 0.55,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(topOpacity), // Strong dim at top
              Colors.black.withOpacity(midOpacity), // Medium dim at mid
              Colors.transparent, // Fade to transparent
            ],
            stops: [
              0.0,
              midStop,
              1.0,
            ],
          ),
        ),
      ),
    );
  }
}
