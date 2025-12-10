import 'package:flutter/material.dart';
import '../../theme/syra_theme.dart';
import '../../theme/syra_tokens.dart';

/// ChatGPT-style App Bar for ChatScreen
/// 
/// Contains:
/// - Left: Menu button
/// - Center: Mode selector (SYRA • Mode)
/// - Right: Document upload button
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: SyraColors.background,
        border: Border(
          bottom: BorderSide(
            color: SyraColors.divider,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          _TapScale(
            onTap: onMenuTap,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.menu_rounded,
                color: SyraColors.textSecondary,
                size: 24,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: _buildModeTrigger(),
            ),
          ),
          _TapScale(
            onTap: onDocumentUpload,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.upload_file_outlined,
                color: SyraColors.textSecondary,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Mode selector trigger in the top bar
  /// Wrapped with CompositedTransformTarget to anchor the mode popover
  Widget _buildModeTrigger() {
    String modeLabel;
    switch (selectedMode) {
      case 'deep':
        modeLabel = 'Derin';
        break;
      case 'mentor':
        modeLabel = 'Mentor';
        break;
      default:
        modeLabel = 'Normal';
    }

    return CompositedTransformTarget(
      link: modeAnchorLink,
      child: GestureDetector(
        onTap: onModeTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: SyraTokens.paddingSm,
            vertical: SyraTokens.paddingXs - 2,
          ),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(SyraTokens.radiusSm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SYRA',
                style: SyraTokens.titleSm.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  color: SyraTokens.textSecondary.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                modeLabel,
                style: SyraTokens.bodyMd.copyWith(
                  fontWeight: FontWeight.w500,
                  color: SyraTokens.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.expand_more_rounded,
                size: 18,
                color: SyraTokens.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple tap scale animation widget
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
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
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
