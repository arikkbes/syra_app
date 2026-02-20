// ═══════════════════════════════════════════════════════════════
// ═══════════════════════════════════════════════════════════════
// ═══════════════════════════════════════════════════════════════
import 'dart:ui';
import 'package:flutter/material.dart';

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
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Close button (X)
                        GestureDetector(
                          onTap: () {
                            _entry?.remove();
                            _entry = null;
                          },
                          child: Container(
                            width: 20,
                            height: 20,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                        // Message
                        Flexible(
                          child: DefaultTextStyle(
                            style: const TextStyle(
                              decoration: TextDecoration.none,
                            ),
                            child: Text(
                              msg,
                              textAlign: TextAlign.left,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ),
                      ],
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

  // ═══════════════════════════════════════════════════════════════
  // Top toast variant (ChatGPT-style feedback toast)
  // ═══════════════════════════════════════════════════════════════
  static void showTop(BuildContext context, String msg,
      {Duration duration = const Duration(seconds: 3)}) {
    _entry?.remove();
    final overlay = Overlay.of(context);
    final topPadding = MediaQuery.of(context).padding.top;

    _entry = OverlayEntry(
      builder: (_) {
        return Positioned(
          top: topPadding + 12,
          left: 24,
          right: 24,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Close button (X)
                        GestureDetector(
                          onTap: () {
                            _entry?.remove();
                            _entry = null;
                          },
                          child: Container(
                            width: 20,
                            height: 20,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                        // Message
                        Flexible(
                          child: DefaultTextStyle(
                            style: const TextStyle(
                              decoration: TextDecoration.none,
                            ),
                            child: Text(
                              msg,
                              textAlign: TextAlign.left,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ),
                      ],
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
    Future.delayed(duration, () {
      _entry?.remove();
      _entry = null;
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // Compact status chip (for "Yanıtlanıyor..." typing indicator)
  // ═══════════════════════════════════════════════════════════════
  static void showStatus(BuildContext context, String status) {
    _entry?.remove();
    final overlay = Overlay.of(context);
    final topPadding = MediaQuery.of(context).padding.top;

    _entry = OverlayEntry(
      builder: (_) {
        return Positioned(
          top: topPadding + 12,
          left: 0,
          right: 0,
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: DefaultTextStyle(
                    style: const TextStyle(
                      decoration: TextDecoration.none,
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.none,
                      ),
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
  }

  // Hide status chip (when assistant starts responding)
  static void hideStatus() {
    _entry?.remove();
    _entry = null;
  }
}
