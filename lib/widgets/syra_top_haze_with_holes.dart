// lib/widgets/syra_top_haze_with_holes.dart

import 'dart:io' show Platform;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';

/// ═══════════════════════════════════════════════════════════════
/// SYRA TOP HAZE WITH HOLES
/// ═══════════════════════════════════════════════════════════════
/// 
/// iOS: Pure native UIVisualEffectView - all blur/fade handled in Swift
/// Android: Flutter BackdropFilter fallback
/// 
/// ═══════════════════════════════════════════════════════════════

class SyraTopHazeWithHoles extends StatelessWidget {
  final double height;
  
  // Android-only parameters (ignored on iOS)
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
    this.blurSigma = 12.0,
    this.featherHeight = 70.0,
    this.scrimTopAlpha = 0.08,
    this.scrimMidAlpha = 0.02,
    this.scrimMidStop = 0.60,
    this.whiteLiftAlpha = 0.0,
    this.leftButtonCenterX = 36.0,
    this.rightButtonCenterX = 36.0,
    this.buttonCenterY = 28.0,
    this.holeRadius = 26.0,
  });

  @override
  Widget build(BuildContext context) {
    // ═══════════════════════════════════════════════════════════
    // iOS: 100% NATIVE - No Dart blur/scrim/fade layers
    // Everything handled by UIVisualEffectView + CAGradientLayer in Swift
    // ═══════════════════════════════════════════════════════════
    if (Platform.isIOS) {
      return IgnorePointer(
        child: SizedBox(
          height: height,
          child: const UiKitView(
            viewType: 'syra_native_blur_view',
            creationParams: null,
            creationParamsCodec: StandardMessageCodec(),
            hitTestBehavior: PlatformViewHitTestBehavior.transparent,
          ),
        ),
      );
    }

    // ═══════════════════════════════════════════════════════════
    // Android: Flutter BackdropFilter fallback
    // ═══════════════════════════════════════════════════════════
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final featherStart = ((height - featherHeight) / height).clamp(0.0, 1.0);
          final rightButtonX = maxWidth - rightButtonCenterX;

          return SizedBox(
            height: height,
            child: Stack(
              children: [
                // Blur layer with fade
                if (blurSigma > 0)
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
                            color: Colors.white.withOpacity(0.001),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Scrim layer with holes
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
                        stops: [0.0, featherStart, 1.0],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstIn,
                    child: ClipPath(
                      clipper: _ButtonHolesClipper(
                        leftButtonCenterX: leftButtonCenterX,
                        rightButtonCenterX: rightButtonX,
                        buttonCenterY: buttonCenterY,
                        holeRadius: holeRadius,
                      ),
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
                            stops: [0.0, scrimMidStop, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

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
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(
        Rect.fromCircle(
          center: Offset(leftButtonCenterX, buttonCenterY),
          radius: holeRadius,
        ),
      )
      ..addOval(
        Rect.fromCircle(
          center: Offset(rightButtonCenterX, buttonCenterY),
          radius: holeRadius,
        ),
      );
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
