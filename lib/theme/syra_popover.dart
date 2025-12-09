// lib/theme/syra_popover.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'syra_tokens.dart';

/// Small floating popover for compact selections
/// Similar to ChatGPT/Claude model pickers
/// 
/// Features:
/// - Compact size with max width
/// - Light background dim
/// - Optional subtle blur
/// - Smooth fade + scale animation
class SyraPopover extends StatelessWidget {
  /// Optional title displayed at the top
  final String? title;
  
  /// Main content of the popover
  final Widget child;
  
  /// Maximum width of the popover (default: 340)
  final double maxWidth;
  
  /// Alignment of the popover on screen
  final Alignment alignment;

  const SyraPopover({
    super.key,
    this.title,
    required this.child,
    this.maxWidth = 340,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        margin: EdgeInsets.only(
          top: alignment == Alignment.topCenter ? 64 : 16,
          left: 16,
          right: 16,
          bottom: 16,
        ),
        constraints: BoxConstraints(
          maxWidth: maxWidth,
        ),
        decoration: BoxDecoration(
          color: SyraTokens.card.withOpacity(0.98),
          borderRadius: BorderRadius.circular(SyraTokens.radiusLg),
          border: Border.all(
            color: SyraTokens.borderSubtle,
            width: 1,
          ),
          boxShadow: SyraTokens.shadowMedium,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(SyraTokens.radiusLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title section (optional)
              if (title != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SyraTokens.paddingMd,
                    vertical: SyraTokens.paddingSm,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: SyraTokens.divider,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Text(
                    title!,
                    style: SyraTokens.label.copyWith(
                      color: SyraTokens.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              // Content
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Show a small floating popover
/// 
/// Usage:
/// ```dart
/// await showSyraPopover(
///   context: context,
///   title: 'Select Mode',
///   alignment: Alignment.topCenter,
///   child: ModeSelector(),
/// );
/// ```
Future<T?> showSyraPopover<T>({
  required BuildContext context,
  Alignment alignment = Alignment.topCenter,
  String? title,
  required Widget child,
  double maxWidth = 340,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withOpacity(SyraTokens.dimLight),
    transitionDuration: SyraTokens.animFast,
    pageBuilder: (context, animation, secondaryAnimation) {
      return SyraPopover(
        title: title,
        maxWidth: maxWidth,
        alignment: alignment,
        child: child,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      // Optional subtle blur
      return BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: SyraTokens.blurSubtle * animation.value,
          sigmaY: SyraTokens.blurSubtle * animation.value,
        ),
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: SyraTokens.curveDecelerate,
          ),
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: SyraTokens.curveDecelerate,
            ).drive(Tween<double>(begin: 0.95, end: 1.0)),
            child: child,
          ),
        ),
      );
    },
  );
}

/// Single selectable item for popover lists
class SyraPopoverItem extends StatelessWidget {
  /// Icon to display
  final IconData? icon;
  
  /// Label text
  final String label;
  
  /// Optional description text
  final String? description;
  
  /// Whether this item is currently selected
  final bool isSelected;
  
  /// Callback when tapped
  final VoidCallback? onTap;

  const SyraPopoverItem({
    super.key,
    this.icon,
    required this.label,
    this.description,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: SyraTokens.paddingMd,
            vertical: SyraTokens.paddingSm,
          ),
          child: Row(
            children: [
              // Icon
              if (icon != null)
                Padding(
                  padding: const EdgeInsets.only(right: SyraTokens.paddingSm),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isSelected
                        ? SyraTokens.accent
                        : SyraTokens.textSecondary,
                  ),
                ),
              
              // Label and description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: SyraTokens.bodyMd.copyWith(
                        color: isSelected
                            ? SyraTokens.accent
                            : SyraTokens.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    if (description != null)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: SyraTokens.paddingXxs,
                        ),
                        child: Text(
                          description!,
                          style: SyraTokens.caption,
                        ),
                      ),
                  ],
                ),
              ),
              
              // Check icon for selected state
              if (isSelected)
                const Padding(
                  padding: EdgeInsets.only(left: SyraTokens.paddingSm),
                  child: Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: SyraTokens.accent,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Divider for popover lists
class SyraPopoverDivider extends StatelessWidget {
  const SyraPopoverDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(
        vertical: SyraTokens.paddingXs,
      ),
      color: SyraTokens.divider,
    );
  }
}
