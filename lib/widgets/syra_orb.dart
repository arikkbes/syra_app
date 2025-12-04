import 'package:flutter/material.dart';
import '../theme/syra_theme.dart';

/// ═══════════════════════════════════════════════════════════════
/// SYRA ORB — Legacy Compatibility (Minimal)
/// ═══════════════════════════════════════════════════════════════
/// The new theme doesn't use orb visuals, but some screens
/// may still reference these widgets.
/// ═══════════════════════════════════════════════════════════════

enum OrbState { idle, thinking }

class SyraOrb extends StatelessWidget {
  final OrbState state;
  final double size;

  const SyraOrb({
    super.key,
    this.state = OrbState.idle,
    this.size = 150,
  });

  @override
  Widget build(BuildContext context) {
    final isThinking = state == OrbState.thinking;
    
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Container(
          width: size * 0.5,
          height: size * 0.5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: SyraColors.surface,
            border: Border.all(
              color: SyraColors.border,
              width: 1,
            ),
          ),
          child: isThinking
              ? Padding(
                  padding: EdgeInsets.all(size * 0.12),
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      SyraColors.accent,
                    ),
                  ),
                )
              : Center(
                  child: Text(
                    "S",
                    style: TextStyle(
                      color: SyraColors.textPrimary,
                      fontSize: size * 0.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class SyraOrbCompact extends StatelessWidget {
  final double size;
  final bool isActive;

  const SyraOrbCompact({
    super.key,
    this.size = 32,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: SyraColors.surface,
        border: Border.all(
          color: isActive ? SyraColors.accent : SyraColors.border,
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          "S",
          style: TextStyle(
            color: SyraColors.textPrimary,
            fontSize: size * 0.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
