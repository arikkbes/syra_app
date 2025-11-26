import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/syra_theme.dart';

/// ═══════════════════════════════════════════════════════════════
/// SYRA MESSAGE BUBBLE — Premium Apple-Grade Design
/// ═══════════════════════════════════════════════════════════════
/// SYRA messages:
/// - Soft teal glass effect
/// - 2-3% bloom glow behind
/// - Rounded corners, no harsh edges
///
/// User messages:
/// - Charcoal gray (#2A2A2C)
/// - Faint inner shadow for realism
/// ═══════════════════════════════════════════════════════════════

class SyraMessageBubble extends StatefulWidget {
  final String text;
  final bool isUser;
  final DateTime? time;
  final String? replyToText;
  final bool hasRedFlag;
  final bool hasGreenFlag;
  final VoidCallback? onLongPress;
  final VoidCallback? onSwipeReply;

  const SyraMessageBubble({
    super.key,
    required this.text,
    required this.isUser,
    this.time,
    this.replyToText,
    this.hasRedFlag = false,
    this.hasGreenFlag = false,
    this.onLongPress,
    this.onSwipeReply,
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
      duration: const Duration(milliseconds: 450),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(widget.isUser ? 0.15 : -0.15, 0.02),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
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
          child: Align(
            alignment:
                widget.isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: EdgeInsets.only(
                left: widget.isUser ? 55 : 0,
                right: widget.isUser ? 0 : 55,
                top: 3,
                bottom: 3,
              ),
              child: Column(
                crossAxisAlignment: widget.isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (widget.replyToText != null) _buildReplyIndicator(),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _buildBubble(),
                      if (widget.hasRedFlag || widget.hasGreenFlag)
                        Positioned(
                          top: -5,
                          right: widget.isUser ? null : -5,
                          left: widget.isUser ? -5 : null,
                          child: _buildFlagIndicator(),
                        ),
                    ],
                  ),
                  if (widget.time != null) _buildTimestamp(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBubble() {
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(widget.isUser ? 18 : 4),
      bottomRight: Radius.circular(widget.isUser ? 4 : 18),
    );

    if (widget.isUser) {
      // ─────────────────────────────────────────────────────────
      // USER BUBBLE: Hafif açılmış koyu gri + okunaklı metin
      // ─────────────────────────────────────────────────────────
      return Container(
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: SyraColors.userBubbleBg,
          borderRadius: borderRadius,
          boxShadow: [
            // Outer shadow
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          widget.text,
          style: SyraTypography.messageText.copyWith(
            color: Colors.white.withValues(alpha: 0.95),
          ),
        ),
      );
    } else {
      // ─────────────────────────────────────────────────────────
      // SYRA BUBBLE: Neon teal glass + güçlü glow
      // ─────────────────────────────────────────────────────────
      return Container(
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          // 3–4% bloom arka glow
          boxShadow: [
            BoxShadow(
              color: SyraColors.neonCyan.withValues(alpha: 0.04),
              blurRadius: 24,
              spreadRadius: 3,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    SyraColors.syraBubbleBg.withValues(alpha: 0.95),
                    SyraColors.neonCyanLight.withValues(alpha: 0.35),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: borderRadius,
                border: Border.all(
                  color: SyraColors.neonCyan.withValues(alpha: 0.16),
                  width: 0.6,
                ),
              ),
              child: Text(
                widget.text,
                style: SyraTypography.messageText.copyWith(
                  color: Colors.white.withValues(alpha: 0.94),
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildReplyIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 2,
            height: 20,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [SyraColors.neonCyan, SyraColors.neonPink],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
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
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
                fontStyle: FontStyle.italic,
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
            ? Colors.orange.withValues(alpha: 0.15)
            : Colors.green.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(
          color: isRed
              ? Colors.orange.withValues(alpha: 0.3)
              : Colors.green.withValues(alpha: 0.3),
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
      padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
      child: Text(
        timeStr,
        style: SyraTypography.timeText.copyWith(
          color: Colors.white.withValues(alpha: 0.25),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TYPING INDICATOR
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

    // Staggered start
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
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: SyraColors.neonCyan.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return AnimatedBuilder(
              animation: _dotAnimations[i],
              builder: (context, _) {
                final colors = [
                  SyraColors.neonCyan,
                  SyraColors.neonViolet,
                  SyraColors.neonPink,
                ];
                return Container(
                  margin: EdgeInsets.only(left: i == 0 ? 0 : 5),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors[i].withValues(alpha: _dotAnimations[i].value),
                    boxShadow: [
                      BoxShadow(
                        color: colors[i]
                            .withValues(alpha: _dotAnimations[i].value * 0.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}
