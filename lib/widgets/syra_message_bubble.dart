// lib/widgets/syra_message_bubble.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/syra_theme.dart';
import '../theme/syra_glass.dart';
import 'syra_markdown.dart';
import 'message_action_row.dart';

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
  final VoidCallback? onSwipeReply;
  final String? imageUrl;

  const SyraMessageBubble({
    super.key,
    this.text,
    required this.isUser,
    this.time,
    this.replyToText,
    this.hasRedFlag = false,
    this.hasGreenFlag = false,
    this.onSwipeReply,
    this.imageUrl,
  });

  @override
  State<SyraMessageBubble> createState() => _SyraMessageBubbleState();
}

class _SyraMessageBubbleState extends State<SyraMessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Action row state
  bool _isHovered = false;
  bool _isLiked = false;
  bool _isDisliked = false;

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
    // Check if mobile/tablet based on screen width
    final isMobile = MediaQuery.of(context).size.width < 768;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: MouseRegion(
          onEnter: (_) {
            if (!isMobile) {
              setState(() => _isHovered = true);
            }
          },
          onExit: (_) {
            if (!isMobile) {
              setState(() => _isHovered = false);
            }
          },
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

                    if (widget.isUser) SizedBox(width: SyraSpacing.xs),
                  ],
                ),

                // Action row for assistant messages only
                if (!widget.isUser && widget.text != null)
                  _buildActionRow(isMobile),

                // Timestamp: hidden (ChatGPT style - no timestamps shown)
              ],
            ),
          ),
        ),
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
    // User: Keep bubble style
    if (widget.isUser) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(SyraRadius.lg),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: SyraGlass.blurSubtle,
            sigmaY: SyraGlass.blurSubtle,
          ),
          child: Container(
            constraints: BoxConstraints(maxWidth: 280),
            padding: EdgeInsets.symmetric(
              horizontal: SyraSpacing.md,
              vertical: SyraSpacing.sm + 2,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  SyraColors.accent.withValues(alpha: 0.15),
                  SyraColors.accent.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(SyraRadius.lg),
              border: Border.all(
                color: SyraColors.accent.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Text(
              widget.text ?? "",
              style: SyraTextStyles.bodyMedium.copyWith(
                color: SyraColors.textPrimary,
                height: 1.5,
              ),
            ),
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
            horizontal: 20, // Reading column: 20px both sides
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
  // TIMESTAMP
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTimestamp() {
    final timeStr = _formatTime(widget.time!);
    return Padding(
      padding: EdgeInsets.only(
        top: SyraSpacing.xs,
        left: widget.isUser ? 0 : 40,
        right: widget.isUser ? SyraSpacing.xs : 0,
      ),
      child: Text(
        timeStr,
        style: SyraTextStyles.caption.copyWith(
          fontSize: 11,
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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

  // ═══════════════════════════════════════════════════════════════
  // ACTION ROW (ChatGPT/Claude style inline actions)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildActionRow(bool isMobile) {
    return Padding(
      padding: const EdgeInsets.only(left: 20), // Match message padding
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isMobile ? 1.0 : (_isHovered ? 1.0 : 0.0), // Always visible on mobile
        child: MessageActionRow(
          messageText: widget.text ?? "",
          isLiked: _isLiked,
          isDisliked: _isDisliked,
          onLikeChanged: (value) {
            setState(() => _isLiked = value);
            _sendFeedbackEvent(value ? 'like' : 'unlike');
          },
          onDislikeChanged: (value) {
            setState(() => _isDisliked = value);
            _sendFeedbackEvent(value ? 'dislike' : 'undislike');
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // FEEDBACK EVENT (Fire-and-forget)
  // ═══════════════════════════════════════════════════════════════

  void _sendFeedbackEvent(String eventType) {
    // Fire-and-forget feedback event
    // TODO: Implement Firestore integration when available

    final feedbackData = {
      'eventType': eventType,
      'messageText': widget.text ?? '',
      'messageSnippet': (widget.text ?? '').length > 100
          ? '${widget.text!.substring(0, 100)}...'
          : widget.text ?? '',
      'createdAt': DateTime.now().toIso8601String(),
      'platform': 'flutter',
      // TODO: Add userId from FirebaseAuth when available
      // TODO: Add sessionId/chatId/messageId when available
    };

    debugPrint('📊 Feedback Event: $feedbackData');
    // TODO: Replace with Firestore call:
    // FirebaseFirestore.instance.collection('message_feedback').add(feedbackData);
  }
}
