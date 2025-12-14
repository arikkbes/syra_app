// lib/theme/syra_animations.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'syra_theme.dart';

/// ═══════════════════════════════════════════════════════════════
/// SYRA ANIMATION HELPERS
/// Consistent micro-animations using flutter_animate
/// ═══════════════════════════════════════════════════════════════

extension SyraAnimateExtensions on Widget {
  /// Fade in with slide from bottom (for cards, sheets)
  Widget fadeInSlide({
    Duration? delay,
    Duration? duration,
  }) {
    return animate(delay: delay ?? Duration.zero)
        .fadeIn(
          duration: duration ?? SyraAnimation.normal,
          curve: SyraAnimation.emphasize,
        )
        .slideY(
          begin: 0.1,
          end: 0,
          duration: duration ?? SyraAnimation.normal,
          curve: SyraAnimation.emphasize,
        );
  }

  /// Fade in only (for text, icons)
  Widget fadeInOnly({
    Duration? delay,
    Duration? duration,
  }) {
    return animate(delay: delay ?? Duration.zero).fadeIn(
      duration: duration ?? SyraAnimation.normal,
      curve: SyraAnimation.standard,
    );
  }

  /// Scale in (for buttons, chips)
  Widget scaleIn({
    Duration? delay,
    Duration? duration,
  }) {
    return animate(delay: delay ?? Duration.zero)
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1.0, 1.0),
          duration: duration ?? SyraAnimation.fast,
          curve: SyraAnimation.spring,
        )
        .fadeIn(
          duration: duration ?? SyraAnimation.fast,
          curve: SyraAnimation.standard,
        );
  }

  /// Shimmer effect (for loading states)
  Widget shimmer({
    Duration? duration,
    Color? color,
  }) {
    return animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: duration ?? const Duration(milliseconds: 1200),
          color: color ?? SyraColors.accent.withValues(alpha: 0.3),
        );
  }

  /// Slide from right (for drawer, panels)
  Widget slideFromRight({
    Duration? delay,
    Duration? duration,
  }) {
    return animate(delay: delay ?? Duration.zero).slideX(
      begin: 0.3,
      end: 0,
      duration: duration ?? SyraAnimation.normal,
      curve: SyraAnimation.emphasize,
    );
  }

  /// Slide from left
  Widget slideFromLeft({
    Duration? delay,
    Duration? duration,
  }) {
    return animate(delay: delay ?? Duration.zero).slideX(
      begin: -0.3,
      end: 0,
      duration: duration ?? SyraAnimation.normal,
      curve: SyraAnimation.emphasize,
    );
  }
}

/// Staggered list animation helper
class SyraStaggeredList extends StatelessWidget {
  final List<Widget> children;
  final Duration staggerDelay;
  final Duration itemDuration;
  final Axis scrollDirection;
  final EdgeInsetsGeometry? padding;

  const SyraStaggeredList({
    super.key,
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 50),
    this.itemDuration = const Duration(milliseconds: 220),
    this.scrollDirection = Axis.vertical,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: scrollDirection,
      padding: padding,
      itemCount: children.length,
      itemBuilder: (context, index) {
        return children[index].fadeInSlide(
          delay: staggerDelay * index,
          duration: itemDuration,
        );
      },
    );
  }
}
