// lib/widgets/skeleton_loader.dart

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/syra_theme.dart';

/// ═══════════════════════════════════════════════════════════════
/// SKELETON LOADERS - Claude/ChatGPT Style
/// ═══════════════════════════════════════════════════════════════
/// Premium loading placeholders with shimmer effect
/// ═══════════════════════════════════════════════════════════════

class SkeletonLoader {
  SkeletonLoader._();

  // ─── Base Shimmer Colors ───
  static Color get _baseColor => SyraColors.surface;
  static Color get _highlightColor => SyraColors.surfaceLight;

  // ═══════════════════════════════════════════════════════════════
  // MESSAGE BUBBLE SKELETON
  // ═══════════════════════════════════════════════════════════════

  static Widget messageBubble({
    bool isUser = false,
    double width = 200,
  }) {
    return Shimmer.fromColors(
      baseColor: _baseColor,
      highlightColor: _highlightColor,
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: SyraSpacing.md,
            vertical: SyraSpacing.xs,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: SyraSpacing.md,
            vertical: SyraSpacing.sm,
          ),
          width: width,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(SyraRadius.lg),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TYPING INDICATOR (3 dots)
  // ═══════════════════════════════════════════════════════════════

  static Widget typingIndicator() {
    return Padding(
      padding: EdgeInsets.all(SyraSpacing.md),
      child: Row(
        children: [
          _TypingDot(delay: 0),
          SizedBox(width: 8),
          _TypingDot(delay: 200),
          SizedBox(width: 8),
          _TypingDot(delay: 400),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CHAT LIST SKELETON
  // ═══════════════════════════════════════════════════════════════

  static Widget chatList({int count = 5}) {
    return ListView.builder(
      itemCount: count,
      padding: EdgeInsets.all(SyraSpacing.md),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: _baseColor,
          highlightColor: _highlightColor,
          child: Container(
            margin: EdgeInsets.only(bottom: SyraSpacing.sm),
            padding: EdgeInsets.all(SyraSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(SyraRadius.md),
            ),
            child: Row(
              children: [
                // Avatar skeleton
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: SyraSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title skeleton
                      Container(
                        width: double.infinity,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      SizedBox(height: 8),
                      // Subtitle skeleton
                      Container(
                        width: 150,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TEXT LINE SKELETON
  // ═══════════════════════════════════════════════════════════════

  static Widget textLine({
    double width = double.infinity,
    double height = 16,
  }) {
    return Shimmer.fromColors(
      baseColor: _baseColor,
      highlightColor: _highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CARD SKELETON
  // ═══════════════════════════════════════════════════════════════

  static Widget card({
    double height = 120,
    double? width,
  }) {
    return Shimmer.fromColors(
      baseColor: _baseColor,
      highlightColor: _highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(SyraRadius.md),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CIRCLE SKELETON (Avatar)
  // ═══════════════════════════════════════════════════════════════

  static Widget circle({
    double size = 48,
  }) {
    return Shimmer.fromColors(
      baseColor: _baseColor,
      highlightColor: _highlightColor,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TYPING DOT ANIMATION
// ═══════════════════════════════════════════════════════════════

class _TypingDot extends StatefulWidget {
  final int delay;

  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );

    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Start animation with delay
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: SyraColors.accent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
