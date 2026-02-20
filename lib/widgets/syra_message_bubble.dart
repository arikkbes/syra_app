// lib/widgets/syra_message_bubble.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/syra_theme.dart';
import '../theme/syra_glass.dart';
import 'syra_markdown.dart';

/// ═══════════════════════════════════════════════════════════════
/// PREMIUM MESSAGE BUBBLE v3.0
/// ═══════════════════════════════════════════════════════════════
/// Claude/ChatGPT-style message bubbles with:
/// - Soft glass effects
/// - Clean typography
/// - Image support
/// - Reply indicators
/// - Flag indicators (red/green)
/// ═══════════════════════════════════════════════════════════════

class SyraMessageBubble extends StatefulWidget {
  final String? text;
  final bool isUser;
  final DateTime? time;
  final String? replyToText;
  final bool hasRedFlag;
  final bool hasGreenFlag;
  final VoidCallback? onLongPress;
  final VoidCallback? onSwipeReply;
  final String? imageUrl;
  
  // Feedback params (assistant messages only)
  final String? feedback; // 'like' | 'dislike' | null
  final VoidCallback? onCopy;
  final ValueChanged<String?>? onFeedbackChanged;

  const SyraMessageBubble({
    super.key,
    this.text,
    required this.isUser,
    this.time,
    this.replyToText,
    this.hasRedFlag = false,
    this.hasGreenFlag = false,
    this.onLongPress,
    this.onSwipeReply,
    this.imageUrl,
    this.feedback,
    this.onCopy,
    this.onFeedbackChanged,
  });

  @override
  State<SyraMessageBubble> createState() => _SyraMessageBubbleState();
}

class _SyraMessageBubbleState extends State<SyraMessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: SyraAnimation.normal,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: SyraAnimation.decelerate,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: SyraAnimation.emphasize,
    ));

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: GestureDetector(
          onLongPress: widget.onLongPress,
          child: Container(
            // No margin here - spacing handled in ListView (sender-aware)
            child: Column(
              crossAxisAlignment: widget.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (widget.replyToText != null) _buildReplyIndicator(),

                Row(
                  mainAxisAlignment: widget.isUser
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // NO avatar for assistant (ChatGPT style)

                    Flexible(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _buildMessageContent(),
                          if (widget.hasRedFlag || widget.hasGreenFlag)
                            Positioned(
                              top: -6,
                              right: widget.isUser ? null : -6,
                              left: widget.isUser ? -6 : null,
                              child: _buildFlagIndicator(),
                            ),
                        ],
                      ),
                    ),

                  ],
                ),

                // Action row for assistant messages
                if (!widget.isUser) _buildActionRow(),

                // Timestamp: hidden (ChatGPT style - no timestamps shown)
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ACTION ROW (Copy / Like / Dislike)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildActionRow() {
    final likeIsSelected = widget.feedback == 'like';
    final dislikeIsSelected = widget.feedback == 'dislike';
    
    return Padding(
      padding: const EdgeInsets.only(
        left: 12, // Aligned with assistant text left edge
        top: 4,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ActionButton(
            icon: Icons.copy_rounded,
            isSelected: false,
            isCopyButton: true, // Enable checkmark animation
            onTap: () {
              if (widget.onCopy != null) {
                widget.onCopy!();
              } else {
                // Fallback: copy text directly (NO TOAST)
                final text = widget.text ?? '';
                Clipboard.setData(ClipboardData(text: text));
              }
            },
          ),
          const SizedBox(width: 4),
          _ActionButton(
            icon: Icons.thumb_up_rounded, // Filled icon (selected state)
            outlineIcon: Icons.thumb_up_outlined, // Outline icon (unselected state)
            isSelected: likeIsSelected,
            isLikeButton: true, // Enable slide animation
            dislikeIsSelected: dislikeIsSelected, // Pass dislike state for slide
            onTap: () {
              final newFeedback = likeIsSelected ? null : 'like';
              widget.onFeedbackChanged?.call(newFeedback);
            },
          ),
          const SizedBox(width: 4),
          _ActionButton(
            icon: Icons.thumb_down_rounded, // Filled icon (selected state)
            outlineIcon: Icons.thumb_down_outlined, // Outline icon (unselected state)
            isSelected: dislikeIsSelected,
            isDislikeButton: true, // Enable slide animation
            likeIsSelected: likeIsSelected, // Pass like state for slide
            onTap: () {
              final newFeedback = dislikeIsSelected ? null : 'dislike';
              widget.onFeedbackChanged?.call(newFeedback);
            },
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // MESSAGE CONTENT (NO AVATAR - ChatGPT style)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildMessageContent() {
    // Image + Text
    if (widget.imageUrl != null && widget.text != null && widget.text!.isNotEmpty) {
      return Column(
        crossAxisAlignment: widget.isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          _buildImage(),
          SizedBox(height: SyraSpacing.xs),
          _buildTextBubble(),
        ],
      );
    }

    // Only image
    if (widget.imageUrl != null) {
      return _buildImage();
    }

    // Only text
    return _buildTextBubble();
  }

  Widget _buildTextBubble() {
    // User: Claude-style subtle bubble (dark fill + thin border, NOT accent color)
    if (widget.isUser) {
      return Container(
        constraints: BoxConstraints(maxWidth: 280),
        padding: EdgeInsets.symmetric(
          horizontal: SyraSpacing.md,
          vertical: SyraSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          // Subtle dark fill - close to background
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(SyraRadius.lg),
          // Thin border for definition
          border: Border.all(
            color: Colors.white.withOpacity(0.12),
            width: 1,
          ),
        ),
        child: Text(
          widget.text ?? "",
          style: SyraTextStyles.bodyMedium.copyWith(
            color: SyraColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.45,
            letterSpacing: 0,
          ),
        ),
      );
    }

    // Assistant: NO bubble, ChatGPT style (reading column) with Premium Markdown
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 720), // Desktop max width
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 12, // Aligned with ChatInputBar left edge (12px)
            vertical: 4, // Minimal vertical padding
          ),
          child: SyraMarkdown(
            data: widget.text ?? "",
            selectable: true,
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    return GestureDetector(
      onTap: () => _showImagePreview(widget.imageUrl!),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 280,
          maxHeight: 350,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(SyraRadius.md),
          boxShadow: SyraGlass.subtleShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(SyraRadius.md),
          child: Image.network(
            widget.imageUrl!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 280,
                height: 200,
                decoration: BoxDecoration(
                  color: SyraColors.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(SyraRadius.md),
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    valueColor: AlwaysStoppedAnimation(SyraColors.accent),
                    strokeWidth: 2,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 280,
                height: 200,
                decoration: BoxDecoration(
                  color: SyraColors.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(SyraRadius.md),
                ),
                child: Center(
                  child: Icon(
                    Icons.broken_image_rounded,
                    size: 48,
                    color: SyraColors.iconMuted,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // REPLY INDICATOR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildReplyIndicator() {
    return Container(
      margin: EdgeInsets.only(
        bottom: SyraSpacing.xs,
        left: widget.isUser ? 40 : 40,
        right: widget.isUser ? 0 : 40,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: SyraSpacing.sm,
        vertical: SyraSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: SyraColors.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(SyraRadius.sm),
        border: Border.all(
          color: SyraColors.accent.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.reply,
            size: 12,
            color: SyraColors.accent,
          ),
          SizedBox(width: SyraSpacing.xs),
          Flexible(
            child: Text(
              widget.replyToText!,
              style: SyraTextStyles.caption.copyWith(
                color: SyraColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // FLAG INDICATOR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildFlagIndicator() {
    final color = widget.hasRedFlag ? SyraColors.error : SyraColors.success;
    final icon = widget.hasRedFlag ? Icons.flag : Icons.verified;

    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Icon(
        icon,
        size: 12,
        color: color,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // IMAGE PREVIEW
  // ═══════════════════════════════════════════════════════════════

  void _showImagePreview(String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(SyraSpacing.lg),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(SyraRadius.lg),
              child: Image.network(
                url,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ACTION BUTTON (for Copy/Like/Dislike)
// ═══════════════════════════════════════════════════════════════

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final IconData? outlineIcon; // Outline version of icon (unselected)
  final bool isSelected;
  final VoidCallback onTap;
  final bool isCopyButton;
  final bool isDislikeButton; // Is this the dislike button?
  final bool isLikeButton; // Is this the like button?
  final bool likeIsSelected; // Is the like button selected? (for slide animation)
  final bool dislikeIsSelected; // Is the dislike button selected? (for slide animation)

  const _ActionButton({
    required this.icon,
    this.outlineIcon,
    required this.isSelected,
    required this.onTap,
    this.isCopyButton = false,
    this.isDislikeButton = false,
    this.isLikeButton = false,
    this.likeIsSelected = false,
    this.dislikeIsSelected = false,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> with TickerProviderStateMixin {
  bool _isPressed = false;
  bool _showCheckmark = false;
  late AnimationController _checkmarkController;
  late Animation<double> _checkmarkAnimation;
  late AnimationController _fillController;
  late Animation<double> _fillAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Checkmark animation (for copy button)
    _checkmarkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _checkmarkAnimation = CurvedAnimation(
      parent: _checkmarkController,
      curve: Curves.easeOut,
    );

    // Fill animation (for like/dislike)
    _fillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fillAnimation = CurvedAnimation(
      parent: _fillController,
      curve: Curves.easeInOut,
    );

    // Slide animation (bidirectional)
    // - Dislike slides left when like is selected
    // - Like slides right when dislike is selected
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    
    // Dislike slides left (-1.2), Like slides right (+1.2)
    final slideDirection = widget.isDislikeButton ? -1.2 : (widget.isLikeButton ? 1.2 : 0.0);
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(slideDirection, 0),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));

    // Set initial state
    if (widget.isSelected && !widget.isCopyButton) {
      _fillController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_ActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Animate fill when selection changes (like/dislike only)
    if (!widget.isCopyButton && widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _fillController.forward();
      } else {
        _fillController.reverse();
      }
    }

    // Slide animation for Dislike: when like is selected, dislike slides left
    if (widget.isDislikeButton && widget.likeIsSelected != oldWidget.likeIsSelected) {
      if (widget.likeIsSelected) {
        _slideController.forward();
      } else {
        _slideController.reverse();
      }
    }

    // Slide animation for Like: when dislike is selected, like slides right
    if (widget.isLikeButton && widget.dislikeIsSelected != oldWidget.dislikeIsSelected) {
      if (widget.dislikeIsSelected) {
        _slideController.forward();
      } else {
        _slideController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _checkmarkController.dispose();
    _fillController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _handleTap() {
    widget.onTap();
    
    // Copy button: show checkmark animation
    if (widget.isCopyButton) {
      setState(() => _showCheckmark = true);
      _checkmarkController.forward();
      
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          _checkmarkController.reverse().then((_) {
            if (mounted) {
              setState(() => _showCheckmark = false);
            }
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Claude-style colors
    final tileColor = Colors.white.withOpacity(0.10); // Neutral gray tile
    final iconColor = Colors.white.withOpacity(0.85); // Icon color
    final subtleIconColor = Colors.white.withOpacity(0.55); // Unselected

    final displayIcon = _showCheckmark ? Icons.check_rounded : widget.icon;

    Widget buttonContent = GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _handleTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            // Claude-style tile: only show when selected (like/dislike only)
            color: widget.isSelected && !widget.isCopyButton ? tileColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: widget.isCopyButton
                ? (_showCheckmark
                    ? ScaleTransition(
                        scale: _checkmarkAnimation,
                        child: Icon(
                          displayIcon,
                          size: 20,
                          color: iconColor,
                        ),
                      )
                    : Icon(
                        displayIcon,
                        size: 20,
                        color: subtleIconColor,
                      ))
                : AnimatedBuilder(
                    animation: _fillAnimation,
                    builder: (context, child) {
                      // For like/dislike: use outline when unselected, filled when selected
                      final currentIcon = widget.isSelected 
                          ? widget.icon  // Filled icon
                          : (widget.outlineIcon ?? widget.icon); // Outline icon
                      
                      return Icon(
                        currentIcon,
                        size: 20,
                        color: widget.isSelected ? iconColor : subtleIconColor,
                      );
                    },
                  ),
          ),
        ),
      ),
    );

    // Wrap dislike button with slide + fade animation (slides left when like is selected)
    if (widget.isDislikeButton) {
      return AnimatedBuilder(
        animation: _slideController,
        builder: (context, child) {
          // Calculate opacity: 1.0 at start, 0.0 at end
          final opacity = 1.0 - _slideController.value;
          
          return Opacity(
            opacity: opacity,
            child: SlideTransition(
              position: _slideAnimation,
              child: buttonContent,
            ),
          );
        },
      );
    }

    // Wrap like button with slide + fade animation (slides right when dislike is selected)
    if (widget.isLikeButton) {
      return AnimatedBuilder(
        animation: _slideController,
        builder: (context, child) {
          // Calculate opacity: 1.0 at start, 0.0 at end
          final opacity = 1.0 - _slideController.value;
          
          return Opacity(
            opacity: opacity,
            child: SlideTransition(
              position: _slideAnimation,
              child: buttonContent,
            ),
          );
        },
      );
    }

    return buttonContent;
  }
}
