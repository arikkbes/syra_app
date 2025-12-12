// lib/widgets/dynamic_greeting.dart

import 'package:flutter/material.dart';
import '../theme/syra_theme.dart';

/// ═══════════════════════════════════════════════════════════════
/// DYNAMIC GREETING - Dark Mode 2.0
/// ═══════════════════════════════════════════════════════════════
/// Shows time-appropriate greeting + main question
/// Uses Lora serif font for literary, sophisticated feel
/// ═══════════════════════════════════════════════════════════════

class DynamicGreeting extends StatelessWidget {
  const DynamicGreeting({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return 'Günaydın';
    } else if (hour >= 12 && hour < 17) {
      return 'İyi günler';
    } else if (hour >= 17 && hour < 22) {
      return 'İyi akşamlar';
    } else {
      return 'İyi geceler';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Time-based greeting (smaller, secondary)
        Text(
          _getGreeting(),
          style: SyraTextStyles.bodyMedium.copyWith(
            color: SyraColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        // Main question (larger, serif, primary)
        Text(
          'Bugün neyi çözüyoruz?',
          style: SyraTextStyles.displayMedium.copyWith(
            fontSize: 26,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
