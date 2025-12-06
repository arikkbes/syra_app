import 'package:flutter/material.dart';
import '../theme/syra_theme.dart';

/// ═══════════════════════════════════════════════════════════════
/// SYRA MESSAGE BUBBLE v2.0 — ChatGPT 2025 Style
/// ═══════════════════════════════════════════════════════════════
/// - Minimal, text-focused design
/// - No heavy bubbles or gradients
/// - Subtle visual distinction between user/bot
/// ═══════════════════════════════════════════════════════════════

class SyraMessageBubble extends StatefulWidget {
  final String? text; // Artık optional - image mesajlarında text olmayabilir
  final bool isUser;
  final DateTime? time;
  final String? replyToText;
  final bool hasRedFlag;
  final bool hasGreenFlag;
  final VoidCallback? onLongPress;
  final VoidCallback? onSwipeReply;
  final String? imageUrl; // Yeni: resim URL'i

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
      duration: const Duration(milliseconds: 350),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
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
            margin: const EdgeInsets.only(bottom: 16),
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
                    if (!widget.isUser) ...[
                      _buildAvatar(),
                      const SizedBox(width: 12),
                    ],

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

                    if (widget.isUser) const SizedBox(width: 4),
                  ],
                ),

                if (widget.time != null) _buildTimestamp(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: SyraColors.surface,
        border: Border.all(
          color: SyraColors.border,
          width: 0.5,
        ),
      ),
      child: Center(
        child: Text(
          "S",
          style: TextStyle(
            color: SyraColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageContent() {
    // Eğer resim VE text varsa, ikisini de göster (ChatGPT/Claude style)
    if (widget.imageUrl != null && widget.text != null && widget.text!.isNotEmpty) {
      return Column(
        crossAxisAlignment: widget.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Resim
          Container(
            constraints: const BoxConstraints(
              maxWidth: 280,
              maxHeight: 350,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.imageUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 280,
                    height: 200,
                    color: SyraColors.surface,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: SyraColors.accent,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 280,
                    height: 200,
                    color: SyraColors.surface,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image_rounded,
                        size: 48,
                        color: SyraColors.textMuted,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Text
          Container(
            constraints: const BoxConstraints(maxWidth: 280),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: widget.isUser ? SyraColors.userBubbleBg : SyraColors.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              widget.text!,
              style: SyraTypography.messageText.copyWith(
                color: widget.isUser 
                    ? SyraColors.textPrimary 
                    : SyraColors.textPrimary.withOpacity(0.95),
              ),
            ),
          ),
        ],
      );
    }
    
    // Sadece resim varsa
    if (widget.imageUrl != null) {
      return Container(
        constraints: const BoxConstraints(
          maxWidth: 280,
          maxHeight: 350,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            widget.imageUrl!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 280,
                height: 200,
                color: SyraColors.surface,
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    color: SyraColors.accent,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 280,
                height: 200,
                color: SyraColors.surface,
                child: const Center(
                  child: Icon(
                    Icons.broken_image_rounded,
                    size: 48,
                    color: SyraColors.textMuted,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    // Sadece text varsa (normal mesaj)
    if (widget.isUser) {
      return Container(
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: SyraColors.userBubbleBg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          widget.text ?? '',
          style: SyraTypography.messageText,
        ),
      );
    } else {
      return Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          widget.text ?? '',
          style: SyraTypography.messageText.copyWith(
            color: SyraColors.textPrimary.withOpacity(0.95),
          ),
        ),
      );
    }
  }

  Widget _buildReplyIndicator() {
    return Container(
      margin: EdgeInsets.only(
        bottom: 6,
        left: widget.isUser ? 0 : 40,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: SyraColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: SyraColors.border,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 2,
            height: 16,
            decoration: BoxDecoration(
              color: SyraColors.accent,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.replyToText!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: SyraColors.textMuted,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlagIndicator() {
    final isRed = widget.hasRedFlag;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isRed
            ? Colors.orange.withOpacity(0.15)
            : Colors.green.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(
          color: isRed
              ? Colors.orange.withOpacity(0.3)
              : Colors.green.withOpacity(0.3),
        ),
      ),
      child: Icon(
        isRed ? Icons.warning_rounded : Icons.check_circle_rounded,
        size: 12,
        color: isRed ? Colors.orangeAccent : Colors.greenAccent,
      ),
    );
  }

  Widget _buildTimestamp() {
    final timeStr =
        "${widget.time!.hour.toString().padLeft(2, '0')}:${widget.time!.minute.toString().padLeft(2, '0')}";

    return Padding(
      padding: EdgeInsets.only(
        top: 4,
        left: widget.isUser ? 0 : 40,
      ),
      child: Text(
        timeStr,
        style: SyraTypography.timeText,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ═══════════════════════════════════════════════════════════════
class TypingIndicatorBubble extends StatefulWidget {
  const TypingIndicatorBubble({super.key});

  @override
  State<TypingIndicatorBubble> createState() => _TypingIndicatorBubbleState();
}

class _TypingIndicatorBubbleState extends State<TypingIndicatorBubble>
    with TickerProviderStateMixin {
  late List<AnimationController> _dotControllers;
  late List<Animation<double>> _dotAnimations;

  @override
  void initState() {
    super.initState();

    _dotControllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );

    _dotAnimations = _dotControllers.map((c) {
      return Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut),
      );
    }).toList();

    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 180), () {
        if (mounted) _dotControllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (var c in _dotControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: SyraColors.surface,
            border: Border.all(
              color: SyraColors.border,
              width: 0.5,
            ),
          ),
          child: Center(
            child: Text(
              "S",
              style: TextStyle(
                color: SyraColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return AnimatedBuilder(
              animation: _dotAnimations[i],
              builder: (context, _) {
                return Container(
                  margin: EdgeInsets.only(left: i == 0 ? 0 : 4),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: SyraColors.textMuted
                        .withOpacity(_dotAnimations[i].value),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}
