// lib/widgets/syra_suggestion_chip.dart

import 'package:flutter/material.dart';
import '../theme/syra_theme.dart';

/// ═══════════════════════════════════════════════════════════════
/// SYRA SUGGESTION CHIP - Dark Mode 2.0
/// ═══════════════════════════════════════════════════════════════
/// Clean suggestion buttons without borders
/// Soft fill with elevated surface color
/// ═══════════════════════════════════════════════════════════════

class SyraSuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const SyraSuggestionChip({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SyraRadius.full),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            // Yumuşak, silik dolgu - border yok
            color: SyraColors.surfaceElevated.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(SyraRadius.full),
          ),
          child: Text(
            label,
            style: SyraTextStyles.bodySmall.copyWith(
              color: SyraColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
