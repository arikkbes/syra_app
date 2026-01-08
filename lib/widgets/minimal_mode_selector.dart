// lib/widgets/minimal_mode_selector.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart' as ib;

/// ═══════════════════════════════════════════════════════════════
/// MINIMAL MODE SELECTOR - ChatInputBar Glass Style
/// ═══════════════════════════════════════════════════════════════
/// Clean, minimal mode selector using the same glass effect as ChatInputBar
/// - Grows from SYRA title with smooth animation
/// - No icons, text-only design
/// - ChatInputBar glass morphism style
/// ═══════════════════════════════════════════════════════════════

class MinimalModeSelector extends StatefulWidget {
  final String selectedMode;
  final Function(String) onModeSelected;
  final VoidCallback onClose;
  final Offset anchorPosition;

  const MinimalModeSelector({
    super.key,
    required this.selectedMode,
    required this.onModeSelected,
    required this.onClose,
    required this.anchorPosition,
  });

  @override
  State<MinimalModeSelector> createState() => _MinimalModeSelectorState();
}

class _MinimalModeSelectorState extends State<MinimalModeSelector>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
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
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Transparent backdrop - tap to close
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeWithAnimation,
              behavior: HitTestBehavior.translucent,
            ),
          ),

          // Mode selector card - positioned at anchor
          Positioned(
            left: widget.anchorPosition.dx,
            top: widget.anchorPosition.dy,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return ScaleTransition(
                  scale: _scaleAnimation,
                  alignment: Alignment.topCenter,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: child,
                  ),
                );
              },
              child: GestureDetector(
                onTap: () {}, // Prevent close on card tap
                child: _buildModeCard(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(23),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 250,
          decoration: ib.BoxDecoration(
            color: Colors.white.withValues(alpha: 0.003),
            borderRadius: BorderRadius.circular(23),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
            boxShadow: [
              // CSS: 0 -2px 4px inset black 20%
              ib.BoxShadow(
                inset: true,
                offset: const Offset(0, -2),
                blurRadius: 4,
                color: Colors.black.withValues(alpha: 0.15),
              ),
              // CSS: 0 2px 4px inset white 40%
              ib.BoxShadow(
                inset: true,
                offset: const Offset(0, 2),
                blurRadius: 4,
                color: Colors.white.withValues(alpha: 0.20),
              ),
              // Drop shadow
              ib.BoxShadow(
                offset: const Offset(0, 8),
                blurRadius: 24,
                color: Colors.black.withValues(alpha: 0.2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Center(
                  child: Text(
                    'SYRA',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),

              // Mode items
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  children: [
                    _buildModeItem(
                      mode: 'standard',
                      label: 'Normal',
                      description: 'Dengeli, akıcı sohbet',
                    ),
                    const SizedBox(height: 8),
                    _buildModeItem(
                      mode: 'deep',
                      label: 'Derin Analiz',
                      description: 'Psikolojik analiz ve içgörü',
                    ),
                    const SizedBox(height: 8),
                    _buildModeItem(
                      mode: 'mentor',
                      label: 'Dost Acı Söyler',
                      description: 'Direkt ve samimi',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeItem({
    required String mode,
    required String label,
    required String description,
  }) {
    final isSelected = widget.selectedMode == mode;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onModeSelected(mode);
        _closeWithAnimation();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Checkmark on the left
            SizedBox(
              width: 24,
              child: isSelected
                  ? Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.9),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows the minimal mode selector
void showMinimalModeSelector({
  required BuildContext context,
  required String selectedMode,
  required Function(String) onModeSelected,
  Offset? anchorPosition,
  VoidCallback? onShow,
  VoidCallback? onHide,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry overlayEntry;

  // Call onShow when overlay is shown
  onShow?.call();

  overlayEntry = OverlayEntry(
    builder: (context) => MinimalModeSelector(
      selectedMode: selectedMode,
      onModeSelected: onModeSelected,
      onClose: () {
        overlayEntry.remove();
        // Call onHide when overlay is removed
        onHide?.call();
      },
      anchorPosition: anchorPosition ?? const Offset(20, 100),
    ),
  );

  overlay.insert(overlayEntry);
}
