// lib/screens/chat/chat_app_bar.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart' as ib;
import '../../theme/syra_theme.dart';

/// ═══════════════════════════════════════════════════════════════
/// PREMIUM CHAT APP BAR - Claude Style
/// ═════════════════════════════════════════════════════════════ ///
/// Clean, minimal header with:
/// - Left: Hamburger menu icon button
/// - Center: Text-based selector (SYRA • Mode + chevron)
/// - Right: Single profile/ghost icon button
///
/// NOTE: BackdropFilter blur removed - now handled by SyraGlassSheetTop
/// Glass icon buttons now use SAME recipe as ChatInputBar for consistency
/// ═══════════════════════════════════════════════════════════════

class ChatAppBar extends StatelessWidget {
  static const double baseHeight = 56.0;

  final String selectedMode;
  final LayerLink modeAnchorLink;
  final VoidCallback onMenuTap;
  final VoidCallback onModeTap;
  final VoidCallback onPrivateChatTap;
  final bool isPrivateMode;
  final bool isModeSelectorOpen;
  final double topPadding;

  const ChatAppBar({
    super.key,
    required this.selectedMode,
    required this.modeAnchorLink,
    required this.onMenuTap,
    required this.onModeTap,
    required this.onPrivateChatTap,
    this.isPrivateMode = false,
    this.isModeSelectorOpen = false,
    this.topPadding = 0,
  });

  @override
  Widget build(BuildContext context) {
    // NOTE: Blur is now handled by SyraGlassSheetTop in ChatScreen
    // This widget only contains the content (no BackdropFilter)
    return Container(
      height: baseHeight + topPadding,
      padding: EdgeInsets.only(
        top: topPadding,
        left: SyraSpacing.md,
        right: SyraSpacing.md,
      ),
      // Transparent background - glass sheet provides blur/tint
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Row(
        children: [
          // Left: Menu button - using ChatInputBar glass recipe
          _GlassIconButton(
            icon: Icons.menu_rounded,
            onTap: onMenuTap,
          ),

          // Center: Text-based mode selector (NOT a pill)
          Expanded(
            child: Center(
              child: _buildModeTrigger(),
            ),
          ),

          // Right: Private chat button (toggles lock icon)
          _GlassIconButton(
            icon: isPrivateMode ? Icons.lock_rounded : Icons.lock_open_rounded,
            onTap: onPrivateChatTap,
          ),
        ],
      ),
    );
  }

  /// Mode selector - Clean text-based design without heavy glass pill
  Widget _buildModeTrigger() {
    String modeLabel;
    Color modeColor;

    switch (selectedMode) {
      case 'dost_aci':
        modeLabel = 'Dost';
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
                      // SYRA logo text - clean and minimal
                      Text(
                        'SYRA',
                        style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 17,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                          color: SyraColors.textPrimary,
                        ),
                      ),
                      SizedBox(width: 4),
                      // Chevron down icon to indicate mode selector
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: SyraColors.textSecondary.withOpacity(0.6),
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
/// GLASS ICON BUTTON - ChatInputBar glass recipe
/// ═══════════════════════════════════════════════════════════════
/// EXACT same glass settings as ChatInputBar for visual consistency:
/// - blur: sigmaX=9 sigmaY=9
/// - tint: Colors.white alpha 0.004
/// - border: Colors.white alpha 0.10, width 1
/// - shadows: outer shadow (0,10 blur 24 black alpha 0.30) + subtle inset shadows
///
class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // iOS: Skip BackdropFilter since native blur handles it
    // Android: Use BackdropFilter as before
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    
    Widget buttonContent = Container(
      width: 40,
      height: 40,
      decoration: ib.BoxDecoration(
        color: Colors.white.withValues(alpha: 0.004),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 1,
        ),
        boxShadow: [
          // Outer shadow for separation (same as ChatInputBar)
          ib.BoxShadow(
            inset: false,
            offset: const Offset(0, 10),
            blurRadius: 24,
            color: Colors.black.withValues(alpha: 0.30),
          ),
          // Inset shadow top
          ib.BoxShadow(
            inset: true,
            offset: const Offset(0, -2),
            blurRadius: 4,
            color: Colors.black.withValues(alpha: 0.18),
          ),
          // Inset shadow bottom
          ib.BoxShadow(
            inset: true,
            offset: const Offset(0, 2),
            blurRadius: 4,
            color: Colors.white.withValues(alpha: 0.30),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: SyraColors.iconStroke,
        size: 20,
      ),
    );

    return _TapScale(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: isIOS
            ? buttonContent // iOS: no BackdropFilter
            : BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
                child: buttonContent,
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
