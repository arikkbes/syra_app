import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/syra_theme.dart';

/// ═══════════════════════════════════════════════════════════════
/// SYRA ORB v1.0 — Static Premium Halo
/// ═══════════════════════════════════════════════════════════════
/// - Logo-aligned gradient (Pink → Cyan)
/// - Subtle glow, no harsh effects
/// - Minimal animation for v1.0 (breathing only)
/// - Thinking state with gentle pulse
/// ═══════════════════════════════════════════════════════════════

enum OrbState { idle, thinking }

class SyraOrb extends StatefulWidget {
  final OrbState state;
  final double size;

  const SyraOrb({
    super.key,
    this.state = OrbState.idle,
    this.size = 150,
  });

  @override
  State<SyraOrb> createState() => _SyraOrbState();
}

class _SyraOrbState extends State<SyraOrb> with SingleTickerProviderStateMixin {
  late AnimationController _breathController;

  @override
  void initState() {
    super.initState();

    // Single, gentle breathing animation
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant SyraOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _updateAnimationSpeed();
    }
  }

  void _updateAnimationSpeed() {
    final isThinking = widget.state == OrbState.thinking;
    _breathController.duration = Duration(
      milliseconds: isThinking ? 1500 : 3000,
    );
    _breathController
      ..stop()
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _breathController,
      builder: (context, _) {
        final breathT = _breathController.value;
        final isThinking = widget.state == OrbState.thinking;

        // Subtle scale change with breathing
        final scale = lerpDouble(
          isThinking ? 0.97 : 0.99,
          isThinking ? 1.03 : 1.01,
          breathT,
        )!;

        // Glow intensity based on state
        final baseGlow = isThinking ? 0.35 : 0.22;
        final glowIntensity = baseGlow + (breathT * (isThinking ? 0.15 : 0.05));

        // Ring stroke width
        final strokeWidth = isThinking ? 2.5 : 2.0;
        final size = widget.size * scale;

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // ───────────────────────────────────────────────────
                // AMBIENT GLOW - Soft background aura
                // ───────────────────────────────────────────────────
                Container(
                  width: size * 1.3,
                  height: size * 1.3,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        SyraColors.neonPink.withValues(alpha: glowIntensity * 0.35),
                        SyraColors.neonCyan.withValues(alpha: glowIntensity * 0.2),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),

                // ───────────────────────────────────────────────────
                // OUTER HALO - Soft shadow
                // ───────────────────────────────────────────────────
                Container(
                  width: size * 1.05,
                  height: size * 1.05,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: SyraColors.neonPink
                            .withValues(alpha: glowIntensity * 0.4),
                        blurRadius: 16 + (breathT * 6),
                        spreadRadius: 1 + (breathT * 2),
                      ),
                      BoxShadow(
                        color: SyraColors.neonCyan
                            .withValues(alpha: glowIntensity * 0.25),
                        blurRadius: 20 + (breathT * 4),
                        spreadRadius: 2 + (breathT * 1.5),
                      ),
                    ],
                  ),
                ),

                // ───────────────────────────────────────────────────
                // NEON RING - Logo-aligned gradient
                // ───────────────────────────────────────────────────
                SizedBox(
                  width: size,
                  height: size,
                  child: CustomPaint(
                    painter: _StaticNeonRingPainter(
                      glowIntensity: glowIntensity,
                      strokeWidth: strokeWidth,
                      isThinking: isThinking,
                    ),
                  ),
                ),

                // ───────────────────────────────────────────────────
                // INNER CORE - Deep dark center
                // ───────────────────────────────────────────────────
                Container(
                  width: size * 0.78,
                  height: size * 0.78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: SyraColors.bgTop,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.8),
                        blurRadius: 20,
                        spreadRadius: -3,
                      ),
                    ],
                  ),
                ),

                // ───────────────────────────────────────────────────
                // INNER HIGHLIGHT - Subtle reflection
                // ───────────────────────────────────────────────────
                Container(
                  width: size * 0.78,
                  height: size * 0.78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.3, -0.35),
                      colors: [
                        SyraColors.neonCyan.withValues(alpha: 0.04),
                        Colors.transparent,
                      ],
                      radius: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// STATIC NEON RING PAINTER - No rotation, just gradient ring
/// ═══════════════════════════════════════════════════════════════
class _StaticNeonRingPainter extends CustomPainter {
  final double glowIntensity;
  final double strokeWidth;
  final bool isThinking;

  _StaticNeonRingPainter({
    required this.glowIntensity,
    required this.strokeWidth,
    required this.isThinking,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth - 2;

    // ─────────────────────────────────────────────────────────────
    // GLOW LAYER - Single soft halo
    // ─────────────────────────────────────────────────────────────
    if (isThinking) {
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 4
        ..shader = const SweepGradient(
          colors: [
            SyraColors.neonPink,
            SyraColors.neonViolet,
            SyraColors.neonCyan,
            SyraColors.neonPink,
          ],
          stops: [0.0, 0.35, 0.65, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawCircle(center, radius, glowPaint);
    }

    // ─────────────────────────────────────────────────────────────
    // MAIN RING - Logo-aligned Pink → Cyan
    // ─────────────────────────────────────────────────────────────
    final mainPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        colors: [
          SyraColors.neonPink,
          SyraColors.neonPinkLight,
          SyraColors.neonViolet,
          SyraColors.neonCyan,
          SyraColors.neonCyanLight,
          SyraColors.neonPink,
        ],
        stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, mainPaint);
  }

  @override
  bool shouldRepaint(_StaticNeonRingPainter oldDelegate) {
    return oldDelegate.glowIntensity != glowIntensity ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.isThinking != isThinking;
  }
}

/// ═══════════════════════════════════════════════════════════════
/// COMPACT ORB - For small icons / app bar
/// ═══════════════════════════════════════════════════════════════
class SyraOrbCompact extends StatefulWidget {
  final double size;
  final bool isActive;

  const SyraOrbCompact({
    super.key,
    this.size = 32,
    this.isActive = false,
  });

  @override
  State<SyraOrbCompact> createState() => _SyraOrbCompactState();
}

class _SyraOrbCompactState extends State<SyraOrbCompact>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final glow = widget.isActive ? 0.4 + (t * 0.2) : 0.15 + (t * 0.08);

        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const SweepGradient(
              colors: [
                SyraColors.neonPink,
                SyraColors.neonCyan,
                SyraColors.neonPink,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: SyraColors.neonPink.withValues(alpha: glow),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: widget.size * 0.7,
              height: widget.size * 0.7,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: SyraColors.bgTop,
              ),
            ),
          ),
        );
      },
    );
  }
}
