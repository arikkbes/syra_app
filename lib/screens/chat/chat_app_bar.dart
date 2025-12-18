// lib/screens/chat/chat_app_bar.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  const ChatAppBar({
    super.key,
    required this.selectedMode,
    required this.modeAnchorLink,
    required this.onMenuTap,
    required this.onModeTap,
    required this.onDocumentUpload,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: 56,
          padding: EdgeInsets.symmetric(
            horizontal: SyraSpacing.md,
          ),
          decoration: BoxDecoration(
            // Claude-like translucent scrim with subtle gradient
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                SyraColors.background.withValues(alpha: 0.68),
                SyraColors.background.withValues(alpha: 0.58),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: SyraColors.border.withValues(alpha: 0.08),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              // Left: Menu button (Claude-style glass bubble)
              _TapScale(
                onTap: onMenuTap,
                child: _GlassBubble(
                  child: Icon(
                    Icons.menu_rounded,
                    color: SyraColors.iconStroke,
                    size: 22,
                  ),
                ),
              ),

              // Center: Text-based mode selector
              Expanded(
                child: Center(
                  child: _buildModeTrigger(),
                ),
              ),

              // Right: Profile button (Claude-style glass bubble)
              _TapScale(
                onTap: onDocumentUpload,
                child: _GlassBubble(
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
          child: Row(
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
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// GLASS BUBBLE - Claude-style circular button background
/// ═══════════════════════════════════════════════════════════════

class _GlassBubble extends StatelessWidget {
  final Widget child;

  const _GlassBubble({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            // Subtle translucent fill
            color: SyraColors.surface.withValues(alpha: 0.26),
            shape: BoxShape.circle,
            // Hairline border
            border: Border.all(
              color: SyraColors.border.withValues(alpha: 0.18),
              width: 0.5,
            ),
            // Top-left inner highlight (subtle gradient overlay)
            gradient: RadialGradient(
              center: Alignment.topLeft,
              radius: 1.5,
              colors: [
                SyraColors.accent.withValues(alpha: 0.08),
                SyraColors.surface.withValues(alpha: 0.0), // Token-based transparent
              ],
            ),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// TAP SCALE ANIMATION - Premium iOS-like press feel
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

class _TapScaleState extends State<_TapScale> {
  double _scale = 1.0;
  bool _isLongPressing = false;

  void _handleTapDown(TapDownDetails details) {
    if (!_isLongPressing) {
      HapticFeedback.lightImpact();
      setState(() => _scale = 0.96);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!_isLongPressing) {
      setState(() => _scale = 1.0);
    }
  }

  void _handleTapCancel() {
    if (!_isLongPressing) {
      setState(() => _scale = 1.0);
    }
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    _isLongPressing = true;
    HapticFeedback.mediumImpact();
    // Long press: grow (no shrink first)
    setState(() => _scale = 1.06);
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    _isLongPressing = false;
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      onLongPressStart: _handleLongPressStart,
      onLongPressEnd: _handleLongPressEnd,
      child: AnimatedScale(
        scale: _scale,
        duration: _scale == 1.0
            ? const Duration(milliseconds: 250) // Spring back
            : const Duration(milliseconds: 120), // Quick press
        curve: _scale == 1.0 ? Curves.easeOutBack : Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
