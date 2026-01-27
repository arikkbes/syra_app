// lib/widgets/chatgpt_mode_selector.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/syra_theme.dart';

/// ═══════════════════════════════════════════════════════════════
/// CHATGPT STYLE MODE SELECTOR - COMPACT VERSION
/// ═══════════════════════════════════════════════════════════════

class ChatGPTModeSelector extends StatefulWidget {
  final String selectedMode;
  final Function(String) onModeSelected;
  final VoidCallback onClose;
  final Offset anchorPosition;

  const ChatGPTModeSelector({
    super.key,
    required this.selectedMode,
    required this.onModeSelected,
    required this.onClose,
    required this.anchorPosition,
  });

  @override
  State<ChatGPTModeSelector> createState() => _ChatGPTModeSelectorState();
}

class _ChatGPTModeSelectorState extends State<ChatGPTModeSelector>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _closeWithAnimation() async {
    await _controller.reverse();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth > 400) ? 320.0 : screenWidth - 40;

    return GestureDetector(
      onTap: _closeWithAnimation,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Dark overlay with blur
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 3 * _fadeAnimation.value,
                    sigmaY: 3 * _fadeAnimation.value,
                  ),
                  child: Container(
                    color: Colors.black.withOpacity(0.4 * _fadeAnimation.value),
                  ),
                );
              },
            ),

            // Mode selector card - centered horizontally, positioned from bottom
            Positioned(
              left: (screenWidth - cardWidth) / 2,
              bottom: widget.anchorPosition.dy,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return SlideTransition(
                    position: _slideAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      alignment: Alignment.bottomCenter,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: child,
                      ),
                    ),
                  );
                },
                child: GestureDetector(
                  onTap: () {},
                  child: _buildModeCard(cardWidth),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard(double width) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          width: width,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.08),
                const Color(0xFF66E0FF).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 25,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: const Color(0xFF66E0FF).withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: -5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header - compact
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
                child: Row(
                  children: [
                    Text(
                      'Konuşma Modu',
                      style: SyraTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _closeWithAnimation,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Divider
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: Colors.white.withOpacity(0.1),
              ),

              // Mode items - compact
              Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  children: [
                    _buildModeItem(
                      mode: 'standard',
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Normal',
                      description: 'Dengeli, akıcı sohbet',
                      gradient: [
                        const Color(0xFF66E0FF),
                        const Color(0xFF4FC3DC),
                      ],
                    ),
                    _buildModeItem(
                      mode: 'dost_aci',
                      icon: Icons.psychology_alt_rounded,
                      label: 'Dost Acı Söyler',
                      description: 'Direkt ve samimi',
                      gradient: [
                        const Color(0xFFFF7E7E),
                        const Color(0xFFE05555),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeItem({
    required String mode,
    required IconData icon,
    required String label,
    required String description,
    required List<Color> gradient,
  }) {
    final isSelected = widget.selectedMode == mode;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onModeSelected(mode);
        _closeWithAnimation();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color:
              isSelected ? Colors.white.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? gradient[0].withOpacity(0.4) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Icon - smaller
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSelected
                      ? gradient
                      : [
                          Colors.white.withOpacity(0.1),
                          Colors.white.withOpacity(0.05),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color:
                    isSelected ? Colors.white : Colors.white.withOpacity(0.5),
              ),
            ),
            const SizedBox(width: 12),

            // Text - compact
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: SyraTextStyles.bodySmall.copyWith(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    description,
                    style: SyraTextStyles.caption.copyWith(
                      color: Colors.white.withOpacity(0.45),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // Checkmark - smaller
            if (isSelected)
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Shows the ChatGPT-style mode selector
void showChatGPTModeSelector({
  required BuildContext context,
  required String selectedMode,
  required Function(String) onModeSelected,
  Offset? anchorPosition,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => ChatGPTModeSelector(
      selectedMode: selectedMode,
      onModeSelected: onModeSelected,
      onClose: () => overlayEntry.remove(),
      anchorPosition: anchorPosition ?? const Offset(0, 140),
    ),
  );

  overlay.insert(overlayEntry);
}
