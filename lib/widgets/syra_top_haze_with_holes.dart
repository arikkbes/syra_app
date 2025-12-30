// lib/widgets/syra_top_haze_with_holes.dart

import 'dart:io' show Platform;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';

/// ═══════════════════════════════════════════════════════════════
/// SYRA TOP HAZE WITH HOLES - Header Overlay with Button Exclusions
/// ═══════════════════════════════════════════════════════════════
/// 
/// ARCHITECTURE (v2 - Fixed hard edge, clean compositing):
///
/// The key insight: separate blur from scrim, apply holes only to scrim.
///
/// LAYER A: Full-width blur + dstIn fade (NO holes)
///   - BackdropFilter covers entire haze area
///   - ShaderMask(dstIn) fades blur at bottom edge → soft fadeout
///   - No holes here because blur is continuous and subtle
///
/// LAYER B: Scrim/tint layer WITH holes (NO blur)
///   - ClipPath cuts circular holes around icon buttons
///   - Icons stay crisp because scrim doesn't overlay them
///   - ShaderMask(dstIn) fades scrim at same rate as blur
///
/// This prevents:
/// - Hard horizontal line at haze bottom (blur is faded)
/// - Seams/banding from clip paths cutting blur
/// - Muddy gray plate look (minimal whiteLift)
/// - Icons getting dirtied by scrim overlay
///
/// FLAG: kUseNativeIOSBlur = false (disabled by default)
/// Native UIVisualEffectView doesn't support Flutter-side fade masks,
/// so we use BackdropFilter for consistent cross-platform appearance.
/// ═══════════════════════════════════════════════════════════════

/// Set to false to use Flutter BackdropFilter on iOS (recommended).
/// Native iOS blur cannot be faded with ShaderMask, causing hard edges.
const bool kUseNativeIOSBlur = false;

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

          // ─────────────────────────────────────────────────────────
          // iOS Native Path (DISABLED by default - see kUseNativeIOSBlur)
          // UIVisualEffectView cannot be faded from Flutter side,
          // which causes hard edge. Keep code for future reference.
          // ─────────────────────────────────────────────────────────
          if (kUseNativeIOSBlur && Platform.isIOS) {
            return SizedBox(
              height: height,
              child: const UiKitView(
                viewType: 'syra_native_blur_view',
                creationParams: null,
                creationParamsCodec: StandardMessageCodec(),
                hitTestBehavior: PlatformViewHitTestBehavior.transparent,
              ),
            );
          }

          // ─────────────────────────────────────────────────────────
          // Flutter Path (iOS + Android) - Proper fade compositing
          // ─────────────────────────────────────────────────────────
          
          // Calculate feather fade start position
          final featherStart = ((height - featherHeight) / height).clamp(0.0, 1.0);

          // Right button position from screen width
          final rightButtonX = maxWidth - rightButtonCenterX;

          return SizedBox(
            height: height,
            child: Stack(
              children: [
                // ─────────────────────────────────────────────────────
                // LAYER A: Full-width blur with feather fade (NO holes)
                // The blur covers everything but fades out smoothly.
                // No ClipPath here - blur is subtle enough to not
                // significantly affect icon clarity.
                // ─────────────────────────────────────────────────────
                if (blurSigma > 0)
                  Positioned.fill(
                    child: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: const [
                            Colors.white, // Full blur at top
                            Colors.white, // Full blur until feather
                            Colors.transparent, // Fade to zero
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
                          // Tiny-alpha child to make blur paint
                          child: Container(
                            color: Colors.white.withOpacity(0.001),
                          ),
                        ),
                      ),
                    ),
                  ),

                // ─────────────────────────────────────────────────────
                // LAYER B: Scrim with holes + feather fade
                // ClipPath cuts holes so icons remain crisp.
                // ShaderMask fades the scrim to match blur fade.
                // ─────────────────────────────────────────────────────
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
                ),

                // ─────────────────────────────────────────────────────
                // LAYER C: Subtle white lift with holes (optional)
                // Keep very low opacity to avoid muddy gray look.
                // ─────────────────────────────────────────────────────
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
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Custom clipper that creates circular holes for button areas.
/// Uses evenOdd fill to subtract circles from full rect.
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
      // Full rectangle
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      // Left button hole
      ..addOval(
        Rect.fromCircle(
          center: Offset(leftButtonCenterX, buttonCenterY),
          radius: holeRadius,
        ),
      )
      // Right button hole
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
