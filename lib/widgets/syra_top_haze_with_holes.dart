// lib/widgets/syra_top_haze_with_holes.dart

import 'dart:ui';
import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════
/// SYRA TOP HAZE - Simple subtle blur, no scrim, no mud
/// ═══════════════════════════════════════════════════════════════

class SyraTopHazeWithHoles extends StatelessWidget {
  final double height;
  final double blurSigma;
  final double featherHeight;
  final double scrimTopAlpha;
  final double scrimMidAlpha;
  final double scrimMidStop;
  final double whiteLiftAlpha;
  final double leftButtonCenterX;
  final double rightButtonCenterX;
  final double buttonCenterY;
  final double holeRadius;

  const SyraTopHazeWithHoles({
    super.key,
    this.height = 170.0,
    this.blurSigma = 8.0,
    this.featherHeight = 40.0,
    this.scrimTopAlpha = 0.0,
    this.scrimMidAlpha = 0.0,
    this.scrimMidStop = 0.60,
    this.whiteLiftAlpha = 0.0,
    this.leftButtonCenterX = 36.0,
    this.rightButtonCenterX = 36.0,
    this.buttonCenterY = 28.0,
    this.holeRadius = 26.0,
  });

  @override
  Widget build(BuildContext context) {
    final featherStart = ((height - featherHeight) / height).clamp(0.0, 1.0);

    return IgnorePointer(
      child: SizedBox(
        height: height,
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
              stops: [0.0, featherStart, 1.0],
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
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
