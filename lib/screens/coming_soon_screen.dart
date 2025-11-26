import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/syra_theme.dart';
import '../widgets/glass_background.dart';

/// ═══════════════════════════════════════════════════════════════
/// COMING SOON SCREEN
/// ═══════════════════════════════════════════════════════════════
/// Henüz tamamlanmamış özelliklere yönlendirme ekranı
/// ═══════════════════════════════════════════════════════════════

class ComingSoonScreen extends StatelessWidget {
  final String? featureName;

  const ComingSoonScreen({
    super.key,
    this.featureName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const SyraBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Icon
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF00D4FF).withValues(alpha: 0.15),
                            ),
                            child: Icon(
                              Icons.schedule_rounded,
                              color: const Color(0xFF00D4FF),
                              size: 40,
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Title
                          Text(
                            featureName ?? "Yakında",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 16),

                          // Description
                          Text(
                            "Bu özellik gelecek bir güncellemede eklenecektir.",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 15,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 32),

                          // Back Button
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00D4FF).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF00D4FF).withValues(alpha: 0.5),
                                ),
                              ),
                              child: const Text(
                                "Geri Dön",
                                style: TextStyle(
                                  color: Color(0xFF00D4FF),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.25),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.06),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
      ),
    );
  }
}
