// lib/screens/chat/chat_app_bar.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/syra_theme.dart';

/// ═══════════════════════════════════════════════════════════════
/// PREMIUM CHAT APP BAR - Claude Style
/// ═══════════════════════════════════════════════════════════════
/// Clean, minimal header with:
/// - Left: Hamburger menu icon button
/// - Center: Text-based selector (SYRA • Mode + chevron)
/// - Right: Single profile/ghost icon button
/// ═══════════════════════════════════════════════════════════════

class ChatAppBar extends StatelessWidget {
  final String selectedMode;
  final LayerLink modeAnchorLink;
  final VoidCallback onMenuTap;
  final VoidCallback onModeTap;
  final VoidCallback onDocumentUpload;
  final bool isModeSelectorOpen;

  const ChatAppBar({
    super.key,
    required this.selectedMode,
    required this.modeAnchorLink,
    required this.onMenuTap,
    required this.onModeTap,
    required this.onDocumentUpload,
    this.isModeSelectorOpen = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 56,
          padding: EdgeInsets.symmetric(
            horizontal: SyraSpacing.md,
          ),
          decoration: BoxDecoration(
            color: SyraColors.background.withValues(alpha: 0.85),
            // NOTE: Claude-style header has NO bottom divider line.
          ),
          child: Row(
            children: [
              // Left: Menu button
              _TapScale(
                onTap: onMenuTap,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(SyraRadius.sm),
                  ),
                  child: Icon(
                    Icons.menu_rounded,
                    color: SyraColors.iconStroke,
                    size: 22,
                  ),
                ),
              ),

              // Center: Text-based mode selector (NOT a pill)
              Expanded(
                child: Center(
                  child: _buildModeTrigger(),
                ),
              ),

              // Right: Profile/ghost button
              _TapScale(
                onTap: onDocumentUpload,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(SyraRadius.sm),
                  ),
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: SyraColors.iconStroke,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Mode selector - Clean text-based design without heavy glass pill
  Widget _buildModeTrigger() {
    String modeLabel;
    Color modeColor;

    switch (selectedMode) {
      case 'deep':
        modeLabel = 'Derin';
        modeColor = SyraColors.accent;
        break;
      case 'mentor':
        modeLabel = 'Mentor';
        modeColor = SyraColors.warning;
        break;
      default:
        modeLabel = 'Normal';
        modeColor = SyraColors.textSecondary;
    }

    return CompositedTransformTarget(
      link: modeAnchorLink,
      child: _TapScale(
        onTap: onModeTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: SyraSpacing.sm,
            vertical: SyraSpacing.xs,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeOut,
            child: isModeSelectorOpen
                ? SizedBox(
                    key: ValueKey('empty'),
                    height: 28,
                  )
                : Row(
                    key: ValueKey('content'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // SYRA logo text
                      Text(
                        'SYRA',
                        style: SyraTextStyles.logoStyle(fontSize: 17).copyWith(
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      SizedBox(width: 6),

                      // Dot separator
                      Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color: SyraColors.textMuted.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                      ),

                      SizedBox(width: 6),

                      // Mode label
                      Text(
                        modeLabel,
                        style: TextStyle(
                          color: modeColor.withValues(alpha: 0.85),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),

                      SizedBox(width: 4),

                      // Dropdown arrow (small)
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: SyraColors.iconMuted.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
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

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
