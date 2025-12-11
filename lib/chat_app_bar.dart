// lib/screens/chat/chat_app_bar.dart

import 'dart:ui';
// LEGACY / UNUSED COPY – canonical version lives under lib/screens/chat/chat_app_bar.dart
// Kept only as backup. Do not import this file from production code.

import 'package:flutter/material.dart';
import '../../theme/syra_theme.dart';
import '../../theme/syra_glass.dart';
import '../../widgets/syra_glass_button.dart';

/// ═══════════════════════════════════════════════════════════════
/// PREMIUM CHAT APP BAR
/// ═══════════════════════════════════════════════════════════════
/// Glass header for ChatScreen with:
/// - Left: Menu button
/// - Center: Mode selector (SYRA • Mode) with glass pill
/// - Right: Document upload button
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
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: SyraSpacing.md,
            vertical: SyraSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            color: SyraColors.background.withValues(alpha: 0.85),
            border: Border(
              bottom: BorderSide(
                color: SyraColors.divider.withValues(alpha: 0.5),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              // Menu button
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

              // Mode selector (center)
              Expanded(
                child: Center(
                  child: _buildModeTrigger(),
                ),
              ),

              // Upload button
              SyraGlassButton(
                onTap: onDocumentUpload,
                child: Icon(
                  Icons.upload_file_outlined,
                  size: 18,
                  color: SyraColors.iconStroke,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Mode selector with premium glass pill design
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
        child: SyraGlassContainer(
          padding: EdgeInsets.symmetric(
            horizontal: SyraSpacing.md,
            vertical: SyraSpacing.xs + 2,
          ),
          borderRadius: SyraRadius.full,
          blur: SyraGlass.blurSubtle,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // SYRA logo text
              Text(
                'SYRA',
                style: SyraTextStyles.logoStyle(fontSize: 16).copyWith(
                  letterSpacing: 1.2,
                ),
              ),
              
              SizedBox(width: SyraSpacing.xs),
              
              // Dot separator
              Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  color: SyraColors.textMuted.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
              ),
              
              SizedBox(width: SyraSpacing.xs),
              
              // Mode label
              Text(
                modeLabel,
                style: SyraTextStyles.labelMedium.copyWith(
                  color: modeColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              SizedBox(width: 4),
              
              // Dropdown arrow
              Icon(
                Icons.expand_more_rounded,
                size: 16,
                color: SyraColors.iconMuted,
              ),
            ],
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
