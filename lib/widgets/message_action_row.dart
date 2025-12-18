import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/syra_theme.dart';

/// ChatGPT/Claude style inline action row for assistant messages
/// Shows Copy, Like, Dislike actions with subtle hover behavior
class MessageActionRow extends StatefulWidget {
  final String messageText;
  final String? messageId;
  final bool isLiked;
  final bool isDisliked;
  final ValueChanged<bool>? onLikeChanged;
  final ValueChanged<bool>? onDislikeChanged;

  const MessageActionRow({
    super.key,
    required this.messageText,
    this.messageId,
    this.isLiked = false,
    this.isDisliked = false,
    this.onLikeChanged,
    this.onDislikeChanged,
  });

  @override
  State<MessageActionRow> createState() => _MessageActionRowState();
}

class _MessageActionRowState extends State<MessageActionRow> {
  bool _copied = false;

  void _handleCopy() async {
    await Clipboard.setData(ClipboardData(text: widget.messageText));
    HapticFeedback.lightImpact();
    setState(() => _copied = true);

    // Reset copied state after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _copied = false);
      }
    });
  }

  void _handleLike() {
    HapticFeedback.lightImpact();
    final newValue = !widget.isLiked;
    widget.onLikeChanged?.call(newValue);

    // Auto-clear dislike if liking
    if (newValue && widget.isDisliked) {
      widget.onDislikeChanged?.call(false);
    }
  }

  void _handleDislike() {
    HapticFeedback.lightImpact();
    final newValue = !widget.isDisliked;
    widget.onDislikeChanged?.call(newValue);

    // Auto-clear like if disliking
    if (newValue && widget.isLiked) {
      widget.onLikeChanged?.call(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ActionButton(
            icon: _copied ? Icons.check_rounded : Icons.content_copy_rounded,
            tooltip: _copied ? 'Kopyalandı' : 'Kopyala',
            onTap: _handleCopy,
            isActive: _copied,
          ),
          const SizedBox(width: 4),
          _ActionButton(
            icon: Icons.thumb_up_rounded,
            tooltip: 'Beğen',
            onTap: _handleLike,
            isActive: widget.isLiked,
          ),
          const SizedBox(width: 4),
          _ActionButton(
            icon: Icons.thumb_down_rounded,
            tooltip: 'Beğenme',
            onTap: _handleDislike,
            isActive: widget.isDisliked,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isActive;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.isActive = false,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isActive
        ? SyraColors.accent
        : SyraColors.textSecondary;

    final opacity = _isHovered ? 1.0 : 0.75;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Tooltip(
          message: widget.tooltip,
          waitDuration: const Duration(milliseconds: 500),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: opacity,
            child: Icon(
              widget.icon,
              size: 18,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
