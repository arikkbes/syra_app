import 'package:flutter/material.dart';
import '../theme/syra_theme.dart';

/// ═══════════════════════════════════════════════════════════════
/// COMPACT AURA RING — Legacy Compatibility
/// ═══════════════════════════════════════════════════════════════
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
    return SizedBox(
      width: size,
      height: size,
      child: isActive
          ? CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: const AlwaysStoppedAnimation<Color>(
                SyraColors.accent,
              ),
            )
          : Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: SyraColors.border,
                  width: 2,
                ),
              ),
            ),
    );
  }
}
