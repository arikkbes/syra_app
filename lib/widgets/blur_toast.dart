import 'package:flutter/material.dart';
import '../theme/syra_theme.dart';
import '../theme/syra_glass.dart';

/// ═══════════════════════════════════════════════════════════════
/// BLUR TOAST - Premium glass toast notification
/// Updated to use unified glass system
/// ═══════════════════════════════════════════════════════════════

class BlurToast {
  static OverlayEntry? _entry;

  static void show(BuildContext context, String msg) {
    _entry?.remove();
    final overlay = Overlay.of(context);

    _entry = OverlayEntry(
      builder: (_) {
        return Positioned(
          bottom: 100,
          left: 24,
          right: 24,
          child: Center(
            child: SyraGlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              borderRadius: 14,
              blur: 24,
              opacity: 0.7,
              withShadow: true,
              child: Text(
                msg,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: SyraColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_entry!);
    Future.delayed(const Duration(seconds: 2), () {
      _entry?.remove();
      _entry = null;
    });
  }
}

