// lib/widgets/syra_top_haze_with_holes.dart

import 'dart:io' show Platform;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'syra_top_haze.dart';

/// Flag to enable/disable native iOS blur. Set to false to fallback to BackdropFilter on iOS.
const bool kUseNativeIOSBlur = true;

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
    this.blurSigma = 5.5,
    this.featherHeight = 70.0,
    this.scrimTopAlpha = 0.75,
    this.scrimMidAlpha = 0.25,
    this.scrimMidStop = 0.60,
    this.whiteLiftAlpha = 0.03,
    this.leftButtonCenterX = 36.0,
    this.rightButtonCenterX = 36.0,
    this.buttonCenterY = 28.0,
    this.holeRadius = 26.0,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;

          // iOS: ONLY native UIVisualEffectView - no Flutter overlay
          // This gives clean Claude iOS-like blur in screen recordings
          if (kUseNativeIOSBlur && Platform.isIOS) {
            return SizedBox(
              height: height,
              child: const UiKitView(
                viewType: 'syra_native_blur_view',
                creationParams: null,
                creationParamsCodec: StandardMessageCodec(),
              ),
            );
          }

          // Android (and fallback): Use BackdropFilter + SyraTopHaze
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
                    blurSigma: 0,
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
