import 'dart:math' as math;
import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════
/// SYRA NEON AURA RING  (orb.png tabanlı) - CRASH-PROOF v2.0
/// ═══════════════════════════════════════════════════════════════
/// - Ortada: syra_orb.png (1024x1024 logo)
/// - Idle: hafif nefes alma (scale 0.97 ↔ 1.03), yumuşak glow
/// - Active: glow kuvvetlenir, biraz daha canlı nefes
/// - ✅ CRASH-PROOF: Asset yüklenmezse fallback gradient gösterir
/// ═══════════════════════════════════════════════════════════════

class NeonAuraRing extends StatefulWidget {
  final double size;
  final bool isActive; // true = AI cevap veriyor
  final double idleGlowIntensity;
  final double activeGlowIntensity;

  const NeonAuraRing({
    super.key,
    this.size = 180,
    this.isActive = false,
    this.idleGlowIntensity = 0.4,
    this.activeGlowIntensity = 1.0,
  });

  @override
  State<NeonAuraRing> createState() => _NeonAuraRingState();
}

class _NeonAuraRingState extends State<NeonAuraRing>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  late AnimationController _intensityController;

  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();

    // Hafif nefes alma (scale animasyonu)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(
        parent: _floatController,
        curve: Curves.easeInOutSine,
      ),
    );

    // Idle ↔ Active glow geçişi
    _intensityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      value: widget.isActive ? 1.0 : 0.0,
    );

    // Çok yavaş dönen orb (enerji hissi)
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant NeonAuraRing oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _intensityController.forward();
      } else {
        _intensityController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _intensityController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _floatController,
          _intensityController,
          _rotationController,
        ]),
        builder: (context, child) {
          // 0 → idle, 1 → active
          final t = _intensityController.value;
          final glow = widget.idleGlowIntensity +
              (widget.activeGlowIntensity - widget.idleGlowIntensity) * t;

          final scale = _floatAnimation.value;
          final rotation = _rotationController.value * 2 * math.pi;

          return Stack(
            alignment: Alignment.center,
            children: [
              // ─────────────────────────────────────────────────────
              // OUTER GLOW (PNG'nin etrafındaki ekstra aura)
              // ─────────────────────────────────────────────────────
              Container(
                width: widget.size * (1.3 + 0.05 * glow),
                height: widget.size * (1.3 + 0.05 * glow),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B9D).withValues(alpha: 0.45 * glow),
                      blurRadius: 40 * glow,
                      spreadRadius: 3 * glow,
                    ),
                    BoxShadow(
                      color: const Color(0xFF00D4FF).withValues(alpha: 0.40 * glow),
                      blurRadius: 50 * glow,
                      spreadRadius: 4 * glow,
                    ),
                    BoxShadow(
                      color: const Color(0xFFB388FF).withValues(alpha: 0.25 * glow),
                      blurRadius: 60 * glow,
                      spreadRadius: 6 * glow,
                    ),
                  ],
                ),
              ),

              // ─────────────────────────────────────────────────────
              // ORB PNG (LOGO) - CRASH-PROOF VERSION
              // ─────────────────────────────────────────────────────
              Transform.rotate(
                angle: rotation,
                child: Transform.scale(
                  scale: scale,
                  child: child,
                ),
              ),
            ],
          );
        },
        // ✅ CRASH-PROOF: errorBuilder eklendi
        child: Image.asset(
          'assets/orb/syra_orb.png',
          width: widget.size,
          height: widget.size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          // 🛡️ CRASH FIX: Asset yüklenmezse fallback göster
          errorBuilder: (context, error, stackTrace) {
            debugPrint('⚠️ [NeonAuraRing] Asset load error: $error');
            // Fallback: Gradient circle (logo yokken)
            return Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const SweepGradient(
                  colors: [
                    Color(0xFFFF6B9D), // Pink
                    Color(0xFFB388FF), // Violet
                    Color(0xFF00D4FF), // Cyan
                    Color(0xFFFF6B9D), // Pink (loop)
                  ],
                ),
              ),
              child: Center(
                child: Text(
                  'SYRA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: widget.size * 0.2,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// COMPACT AURA RING (küçük alanlar – loading vs)
/// ═══════════════════════════════════════════════════════════════
/// Login loading overlay gibi yerler için mini versiyon.
/// Aynı orb, sadece daha küçük boy ve biraz daha sade glow.
/// ═══════════════════════════════════════════════════════════════
class CompactAuraRing extends StatelessWidget {
  final double size;
  final bool isActive;

  const CompactAuraRing({
    super.key,
    this.size = 40,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return NeonAuraRing(
      size: size,
      isActive: isActive,
      idleGlowIntensity: 0.3,
      activeGlowIntensity: 0.9,
    );
  }
}
