import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/syra_design_tokens.dart';

/// ═══════════════════════════════════════════════════════════════
/// SYRA ANIMATION HELPERS
/// Reusable micro-animations for premium feel
/// ═══════════════════════════════════════════════════════════════

/// Fade in animation
Widget fadeIn(
  Widget child, {
  Duration? delay,
  Duration? duration,
}) {
  return Animate(
    effects: [
      FadeEffect(
        delay: delay ?? Duration.zero,
        duration: duration ?? SyraAnimation.normal,
        curve: SyraAnimation.easeOut,
      ),
    ],
    child: child,
  );
}

/// Slide and fade in from bottom
Widget slideInFromBottom(
  Widget child, {
  Duration? delay,
  Duration? duration,
  double offset = 20.0,
}) {
  return Animate(
    effects: [
      SlideEffect(
        begin: Offset(0, offset / 100),
        end: Offset.zero,
        delay: delay ?? Duration.zero,
        duration: duration ?? SyraAnimation.normal,
        curve: SyraAnimation.spring,
      ),
      FadeEffect(
        delay: delay ?? Duration.zero,
        duration: duration ?? SyraAnimation.normal,
        curve: SyraAnimation.easeOut,
      ),
    ],
    child: child,
  );
}

/// Slide and fade in from top
Widget slideInFromTop(
  Widget child, {
  Duration? delay,
  Duration? duration,
  double offset = 20.0,
}) {
  return Animate(
    effects: [
      SlideEffect(
        begin: Offset(0, -offset / 100),
        end: Offset.zero,
        delay: delay ?? Duration.zero,
        duration: duration ?? SyraAnimation.normal,
        curve: SyraAnimation.spring,
      ),
      FadeEffect(
        delay: delay ?? Duration.zero,
        duration: duration ?? SyraAnimation.normal,
        curve: SyraAnimation.easeOut,
      ),
    ],
    child: child,
  );
}

/// Slide and fade in from left
Widget slideInFromLeft(
  Widget child, {
  Duration? delay,
  Duration? duration,
  double offset = 20.0,
}) {
  return Animate(
    effects: [
      SlideEffect(
        begin: Offset(-offset / 100, 0),
        end: Offset.zero,
        delay: delay ?? Duration.zero,
        duration: duration ?? SyraAnimation.normal,
        curve: SyraAnimation.spring,
      ),
      FadeEffect(
        delay: delay ?? Duration.zero,
        duration: duration ?? SyraAnimation.normal,
        curve: SyraAnimation.easeOut,
      ),
    ],
    child: child,
  );
}

/// Scale and fade in
Widget scaleIn(
  Widget child, {
  Duration? delay,
  Duration? duration,
  double begin = 0.9,
}) {
  return Animate(
    effects: [
      ScaleEffect(
        begin: Offset(begin, begin),
        end: const Offset(1, 1),
        delay: delay ?? Duration.zero,
        duration: duration ?? SyraAnimation.normal,
        curve: SyraAnimation.spring,
      ),
      FadeEffect(
        delay: delay ?? Duration.zero,
        duration: duration ?? SyraAnimation.normal,
        curve: SyraAnimation.easeOut,
      ),
    ],
    child: child,
  );
}

/// Shimmer effect (for loading states)
Widget shimmer(Widget child) {
  return Animate(
    onPlay: (controller) => controller.repeat(),
    effects: [
      ShimmerEffect(
        duration: const Duration(milliseconds: 1500),
        color: Colors.white.withOpacity(0.1),
      ),
    ],
    child: child,
  );
}

/// ═══════════════════════════════════════════════════════════════
/// ANIMATED PRESS BUTTON
/// Button with scale animation on press
/// ═══════════════════════════════════════════════════════════════

class AnimatedPressButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final Duration duration;

  const AnimatedPressButton({
    super.key,
    required this.child,
    this.onTap,
    this.scale = SyraAnimation.scalePressed,
    this.duration = SyraAnimation.fast,
  });

  @override
  State<AnimatedPressButton> createState() => _AnimatedPressButtonState();
}

class _AnimatedPressButtonState extends State<AnimatedPressButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scale,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: SyraAnimation.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => _controller.forward() : null,
      onTapUp: widget.onTap != null ? (_) => _controller.reverse() : null,
      onTapCancel: widget.onTap != null ? () => _controller.reverse() : null,
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// STAGGERED LIST
/// Animate list items with staggered delays
/// ═══════════════════════════════════════════════════════════════

class StaggeredList extends StatelessWidget {
  final List<Widget> children;
  final Duration staggerDelay;
  final Duration itemDuration;
  final Axis direction;

  const StaggeredList({
    super.key,
    required this.children,
    this.staggerDelay = SyraAnimation.staggerDelay,
    this.itemDuration = SyraAnimation.normal,
    this.direction = Axis.vertical,
  });

  @override
  Widget build(BuildContext context) {
    return direction == Axis.vertical
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: _buildStaggeredChildren(),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: _buildStaggeredChildren(),
          );
  }

  List<Widget> _buildStaggeredChildren() {
    return List.generate(
      children.length,
      (index) => slideInFromBottom(
        children[index],
        delay: staggerDelay * index,
        duration: itemDuration,
        offset: 10,
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// SYRA ANIMATED CONTAINER WRAPPER
/// Container with entrance animation
/// ═══════════════════════════════════════════════════════════════

class SyraAnimatedContainer extends StatelessWidget {
  final Widget child;
  final Duration? delay;
  final AnimationType type;

  const SyraAnimatedContainer({
    super.key,
    required this.child,
    this.delay,
    this.type = AnimationType.fadeSlide,
  });

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case AnimationType.fade:
        return fadeIn(child, delay: delay);
      case AnimationType.fadeSlide:
        return slideInFromBottom(child, delay: delay);
      case AnimationType.scale:
        return scaleIn(child, delay: delay);
      case AnimationType.slideLeft:
        return slideInFromLeft(child, delay: delay);
      case AnimationType.slideTop:
        return slideInFromTop(child, delay: delay);
    }
  }
}

enum AnimationType {
  fade,
  fadeSlide,
  scale,
  slideLeft,
  slideTop,
}

/// ═══════════════════════════════════════════════════════════════
/// MESSAGE BUBBLE ANIMATION
/// Subtle animation for chat messages
/// ═══════════════════════════════════════════════════════════════

Widget animateMessage(Widget child, {int index = 0}) {
  return Animate(
    effects: [
      FadeEffect(
        delay: Duration(milliseconds: 30 * index),
        duration: SyraAnimation.fast,
        curve: SyraAnimation.easeOut,
      ),
      SlideEffect(
        begin: const Offset(0, 0.05),
        end: Offset.zero,
        delay: Duration(milliseconds: 30 * index),
        duration: SyraAnimation.fast,
        curve: SyraAnimation.spring,
      ),
    ],
    child: child,
  );
}

/// ═══════════════════════════════════════════════════════════════
/// SHEET SLIDE UP ANIMATION
/// For bottom sheets and modals
/// ═══════════════════════════════════════════════════════════════

Widget animateSheet(Widget child) {
  return Animate(
    effects: [
      SlideEffect(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
        duration: SyraAnimation.normal,
        curve: SyraAnimation.spring,
      ),
      FadeEffect(
        duration: SyraAnimation.fast,
        curve: SyraAnimation.easeOut,
      ),
    ],
    child: child,
  );
}
