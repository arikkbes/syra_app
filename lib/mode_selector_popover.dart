// LEGACY / UNUSED COPY – canonical version lives under lib/widgets/mode_selector_popover.dart
// Kept only as backup. Do not import this file from production code.

// lib/widgets/mode_selector_popover.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/syra_theme.dart';
import '../theme/syra_glass.dart';
import '../theme/syra_animations.dart';

/// ═══════════════════════════════════════════════════════════════
/// PREMIUM MODE SELECTOR POPOVER
/// ═══════════════════════════════════════════════════════════════
/// Claude/ChatGPT-style floating mode selector:
/// - Glass blur effect
/// - Staggered animations
/// - Clear mode descriptions
/// - Active selection highlight
/// ═══════════════════════════════════════════════════════════════

class ModeSelectorPopover extends StatelessWidget {
  final String selectedMode;
  final Function(String) onModeSelected;

  const ModeSelectorPopover({
    super.key,
    required this.selectedMode,
    required this.onModeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(SyraRadius.lg),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: SyraGlass.blurMedium,
            sigmaY: SyraGlass.blurMedium,
          ),
          child: Container(
            width: 320,
            decoration: BoxDecoration(
              gradient: SyraGlass.liquidGlassGradient,
              borderRadius: BorderRadius.circular(SyraRadius.lg),
              border: Border.all(
                color: SyraGlass.white12,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 24,
                  spreadRadius: 0,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.all(SyraSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Konuşma Modu',
                        style: SyraTextStyles.headingSmall,
                      ),
                      SizedBox(height: SyraSpacing.xs - 2),
                      Text(
                        'SYRA\'nın konuşma tarzını seç',
                        style: SyraTextStyles.caption.copyWith(
                          color: SyraColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ).fadeInSlide(delay: Duration(milliseconds: 50)),

                Divider(
                  height: 1,
                  color: SyraColors.divider.withValues(alpha: 0.3),
                ),

                // Mode options
                Padding(
                  padding: EdgeInsets.all(SyraSpacing.sm),
                  child: Column(
                    children: [
                      _buildModeOption(
                        context: context,
                        mode: 'standard',
                        icon: Icons.chat_bubble_outline,
                        title: 'Normal',
                        description: 'Dengeli ve yapıcı yaklaşım',
                        index: 0,
                      ),
                      SizedBox(height: SyraSpacing.xs),
                      _buildModeOption(
                        context: context,
                        mode: 'deep',
                        icon: Icons.psychology_outlined,
                        title: 'Derin Analiz',
                        description: 'Detaylı psikolojik yorumlar',
                        index: 1,
                      ),
                      SizedBox(height: SyraSpacing.xs),
                      _buildModeOption(
                        context: context,
                        mode: 'mentor',
                        icon: Icons.emoji_people_outlined,
                        title: 'Dost Acı Söyler',
                        description: 'Direkt ve samimi tavsiyer',
                        index: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeOption({
    required BuildContext context,
    required String mode,
    required IconData icon,
    required String title,
    required String description,
    required int index,
  }) {
    final isSelected = selectedMode == mode;

    return _TapScale(
      onTap: () {
        onModeSelected(mode);
        Navigator.pop(context);
      },
      child: Container(
        padding: EdgeInsets.all(SyraSpacing.sm + 2),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    SyraColors.accent.withValues(alpha: 0.15),
                    SyraColors.accent.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(SyraRadius.md),
          border: Border.all(
            color: isSelected
                ? SyraColors.accent.withValues(alpha: 0.4)
                : SyraColors.border.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? SyraColors.accent.withValues(alpha: 0.15)
                    : SyraColors.surface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(SyraRadius.sm),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isSelected ? SyraColors.accent : SyraColors.iconMuted,
              ),
            ),

            SizedBox(width: SyraSpacing.sm),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: SyraTextStyles.labelLarge.copyWith(
                      color: isSelected
                          ? SyraColors.textPrimary
                          : SyraColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    description,
                    style: SyraTextStyles.caption.copyWith(
                      color: SyraColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            // Check icon
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: SyraColors.accent,
                size: 20,
              ),
          ],
        ),
      ),
    ).fadeInSlide(delay: Duration(milliseconds: 100 + (index * 50)));
  }
}

/// ═══════════════════════════════════════════════════════════════
/// TAP SCALE ANIMATION
/// ═══════════════════════════════════════════════════════════════

class _TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _TapScale({
    required this.child,
    this.onTap,
  });

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: SyraAnimation.fast,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(
        parent: _controller,
        curve: SyraAnimation.emphasize,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
