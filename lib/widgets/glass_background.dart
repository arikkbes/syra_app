import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/syra_theme.dart';

/// ═══════════════════════════════════════════════════════════════
/// SYRA BACKGROUND v1.0 — Classic Dark
/// ═══════════════════════════════════════════════════════════════
/// - Deep dark gradient with subtle blue undertone
/// - Minimal particles for elegance
/// - Subtle vignette for depth
/// - Logo-aligned accent colors
/// ═══════════════════════════════════════════════════════════════

class SyraBackground extends StatefulWidget {
  final bool enableParticles;
  final bool enableGrain;
  final double particleOpacity;

  const SyraBackground({
    super.key,
    this.enableParticles = true,
    this.enableGrain = false, // Disabled by default for cleaner look
    this.particleOpacity = 0.02,
  });

  @override
  State<SyraBackground> createState() => _SyraBackgroundState();
}

class _SyraBackgroundState extends State<SyraBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    // Generate subtle particles
    for (int i = 0; i < 20; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 1.2 + 0.4,
        speed: _random.nextDouble() * 0.0002 + 0.0001,
        opacity: _random.nextDouble() * 0.015 + 0.005,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ─────────────────────────────────────────────────────────
        // BASE GRADIENT (SYRA Classic Dark)
        // ─────────────────────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                SyraColors.bgTop,
                SyraColors.bgMiddle,
                SyraColors.bgBottom,
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),

        // ─────────────────────────────────────────────────────────
        // AMBIENT LIGHT (Subtle orb reflection)
        // ─────────────────────────────────────────────────────────
        Positioned(
          top: 60,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    SyraColors.neonPink.withValues(alpha: 0.03),
                    SyraColors.neonCyan.withValues(alpha: 0.02),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
        ),

        // ─────────────────────────────────────────────────────────
        // MICRO PARTICLES
        // ─────────────────────────────────────────────────────────
        if (widget.enableParticles)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                size: Size.infinite,
                painter: _ParticlePainter(
                  particles: _particles,
                  animationValue: _controller.value,
                  opacity: widget.particleOpacity,
                ),
              );
            },
          ),

        // ─────────────────────────────────────────────────────────
        // FILM GRAIN (Optional, very subtle)
        // ─────────────────────────────────────────────────────────
        if (widget.enableGrain)
          Positioned.fill(
            child: CustomPaint(
              painter: _FilmGrainPainter(opacity: 0.02),
            ),
          ),

        // ─────────────────────────────────────────────────────────
        // VIGNETTE (Subtle edge darkening)
        // ─────────────────────────────────────────────────────────
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.3,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.25),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PARTICLE DATA
// ═══════════════════════════════════════════════════════════════
class _Particle {
  double x;
  double y;
  final double size;
  final double speed;
  final double opacity;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

// ═══════════════════════════════════════════════════════════════
// PARTICLE PAINTER
// ═══════════════════════════════════════════════════════════════
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double animationValue;
  final double opacity;

  _ParticlePainter({
    required this.particles,
    required this.animationValue,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      // Slow upward drift
      final y = (particle.y - animationValue * particle.speed * 100) % 1.0;

      final paint = Paint()
        ..color = SyraColors.textPrimary.withValues(alpha: particle.opacity * opacity * 10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

      canvas.drawCircle(
        Offset(particle.x * size.width, y * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════════════
// FILM GRAIN PAINTER
// ═══════════════════════════════════════════════════════════════
class _FilmGrainPainter extends CustomPainter {
  final double opacity;
  final math.Random _random = math.Random();

  _FilmGrainPainter({this.opacity = 0.02});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    const step = 5;

    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        if (_random.nextDouble() > 0.75) {
          final grainOpacity = _random.nextDouble() * opacity;
          paint.color = SyraColors.textPrimary.withValues(alpha: grainOpacity);
          canvas.drawRect(
            Rect.fromLTWH(x, y, 1, 1),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_FilmGrainPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════
// SYRA LOGO WIDGET (Premium Gold Gradient)
// ═══════════════════════════════════════════════════════════════
class SyraLogo extends StatelessWidget {
  final double fontSize;
  final bool withGlow;

  const SyraLogo({
    super.key,
    this.fontSize = 22,
    this.withGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: withGlow
          ? BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: SyraColors.logoGlow.withValues(alpha: 0.12),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            )
          : null,
      child: ShaderMask(
        shaderCallback: (bounds) => SyraColors.logoGradient.createShader(bounds),
        child: Text(
          "SYRA",
          style: TextStyle(
            fontFamily: "Georgia",
            fontSize: fontSize,
            fontWeight: FontWeight.w400,
            letterSpacing: fontSize * 0.45,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// GLASS CARD
// ═══════════════════════════════════════════════════════════════
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurAmount;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.blurAmount = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SyraColors.glassBg,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: SyraColors.glassBorder,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
