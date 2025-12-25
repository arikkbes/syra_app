// lib/widgets/syra_top_haze_with_holes.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'syra_top_haze.dart';

/// ═══════════════════════════════════════════════════════════════
/// SYRA TOP HAZE WITH HOLES - Icon Button Exclusion
/// ═══════════════════════════════════════════════════════════════
/// Same as SyraTopHaze, but with circular "holes" that exclude
/// the left/right icon button zones from the scrim overlay.
///
/// This prevents the BackdropFilter in glass icon buttons from
/// sampling the dark scrim, keeping their tone matching ChatInputBar.
///
/// Implementation:
/// - Full-width scrim (no vertical seams)
/// - ClipPath with evenOdd fill to create circular holes
/// - Holes positioned under icon buttons (left + right)
/// ═══════════════════════════════════════════════════════════════

class SyraTopHazeWithHoles extends StatelessWidget {
  /// Same parameters as SyraTopHaze
  final double height;
  final double blurSigma;
  final double featherHeight;
  final double scrimTopAlpha;
  final double scrimMidAlpha;
  final double scrimMidStop;
  final double whiteLiftAlpha;

  /// Left button position from left edge (padding + button center)
  final double leftButtonCenterX;

  /// Right button position from right edge (padding + button center)
  final double rightButtonCenterX;

  /// Vertical center of buttons (from top, typically topInset + ~28)
  final double buttonCenterY;

  /// Radius of the hole (button radius + margin, typically ~26)
  final double holeRadius;

  const SyraTopHazeWithHoles({
    super.key,
    this.height = 170.0,
    this.blurSigma = 5.5,
    this.featherHeight = 70.0,
    this.scrimTopAlpha = 0.75,
    this.scrimMidAlpha = 0.25,
    this.scrimMidStop = 0.60,
    this.whiteLiftAlpha = 0.03,
    this.leftButtonCenterX = 36.0, // 16 padding + 20 button radius
    this.rightButtonCenterX = 36.0, // same from right
    this.buttonCenterY = 28.0, // vertical center of 56px bar
    this.holeRadius = 26.0, // 20 button radius + 6 margin
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;

          return SizedBox(
            height: height,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: blurSigma,
                  sigmaY: blurSigma,
                  tileMode: TileMode.clamp,
                ),
                child: ClipPath(
                  clipper: _ButtonHolesClipper(
                    leftButtonCenterX: leftButtonCenterX,
                    rightButtonCenterX: maxWidth - rightButtonCenterX,
                    buttonCenterY: buttonCenterY,
                    holeRadius: holeRadius,
                  ),
                  child: SyraTopHaze(
                    height: height,
                    blurSigma: 0, // Blur already applied above
                    featherHeight: featherHeight,
                    scrimTopAlpha: scrimTopAlpha,
                    scrimMidAlpha: scrimMidAlpha,
                    scrimMidStop: scrimMidStop,
                    whiteLiftAlpha: whiteLiftAlpha,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// BUTTON HOLES CLIPPER - Creates circular exclusion zones
/// ═══════════════════════════════════════════════════════════════

class _ButtonHolesClipper extends CustomClipper<Path> {
  final double leftButtonCenterX;
  final double rightButtonCenterX;
  final double buttonCenterY;
  final double holeRadius;

  _ButtonHolesClipper({
    required this.leftButtonCenterX,
    required this.rightButtonCenterX,
    required this.buttonCenterY,
    required this.holeRadius,
  });

  @override
  Path getClip(Size size) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      // Full rect (entire scrim area)
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      // Left button hole
      ..addOval(Rect.fromCircle(
        center: Offset(leftButtonCenterX, buttonCenterY),
        radius: holeRadius,
      ))
      // Right button hole
      ..addOval(Rect.fromCircle(
        center: Offset(rightButtonCenterX, buttonCenterY),
        radius: holeRadius,
      ));

    return path;
  }

  @override
  bool shouldReclip(covariant _ButtonHolesClipper oldClipper) {
    return leftButtonCenterX != oldClipper.leftButtonCenterX ||
        rightButtonCenterX != oldClipper.rightButtonCenterX ||
        buttonCenterY != oldClipper.buttonCenterY ||
        holeRadius != oldClipper.holeRadius;
  }
}
