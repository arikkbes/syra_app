// ═══════════════════════════════════════════════════════════════
// ═══════════════════════════════════════════════════════════════
// ═══════════════════════════════════════════════════════════════
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/syra_theme.dart';

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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: SyraColors.neonCyan.withValues(alpha: 0.08),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Text(
                    msg,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
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
