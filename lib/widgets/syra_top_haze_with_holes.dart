// lib/widgets/syra_top_haze_with_holes.dart

import 'dart:io' show Platform;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'syra_top_haze.dart';

/// Flag to enable/disable native iOS blur. Set to false to fallback to BackdropFilter on iOS.
const bool kUseNativeIOSBlur = true;

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

          // iOS: Native UIVisualEffectView (premium blur in screen recordings)
          if (kUseNativeIOSBlur && Platform.isIOS) {
            return SizedBox(
              height: height,
              child: Stack(
                children: [
                  // 1) Native blur base layer
                  const Positioned.fill(
                    child: UiKitView(
                      viewType: 'syra_native_blur_view',
                      creationParams: null,
                      creationParamsCodec: StandardMessageCodec(),
                    ),
                  ),

                  // 2) Minimal scrim (NO BackdropFilter, NO white lift) with holes
                  Positioned.fill(
                    child: ClipPath(
                      clipper: _ButtonHolesClipper(
                        leftButtonCenterX: leftButtonCenterX,
                        rightButtonCenterX: maxWidth - rightButtonCenterX,
                        buttonCenterY: buttonCenterY,
                        holeRadius: holeRadius,
                      ),
                      child: _IOSMinimalTopScrim(
                        height: height,
                        featherHeight: featherHeight,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // Android (and fallback): Use BackdropFilter + SyraTopHaze as before
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

/// iOS-only: minimal scrim with a feathered fade (no blur, no white lift)
class _IOSMinimalTopScrim extends StatelessWidget {
  final double height;
  final double featherHeight;

  const _IOSMinimalTopScrim({
    required this.height,
    required this.featherHeight,
  });

  @override
  Widget build(BuildContext context) {
    // Feather fade starts near bottom
    final featherStart = ((height - featherHeight) / height).clamp(0.0, 1.0);

    // Keep these iOS values low to avoid muddy look.
    const top = 0.22; // 0.18–0.26 sweet spot
    const mid = 0.10; // 0.08–0.14 sweet spot

    final scrim = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(top),
            Colors.black.withOpacity(mid),
            Colors.transparent,
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
    );

    // Feather mask to avoid a hard line at the bottom
    return ShaderMask(
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
      child: scrim,
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
