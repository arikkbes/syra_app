// lib/theme/syra_popover.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'syra_tokens.dart';

/// Small floating popover for compact selections
/// Similar to ChatGPT/Claude model pickers
/// 
/// Features:
/// - Compact size with max width
/// - Blur lives INSIDE the card (not the background)
/// - Very subtle background dim (no heavy blur)
/// - Smooth fade + scale + slight slide animation
/// - Optional anchored positioning (for app bar labels, etc.)
class SyraPopover extends StatelessWidget {
  /// Optional title displayed at the top
  final String? title;
  
  /// Main content of the popover
  final Widget child;
  
  /// Maximum width of the popover (default: 340)
  final double maxWidth;
  
  /// Alignment of the popover on screen (when not anchored)
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
        child: _PopoverCard(
          title: title,
          child: child,
        ),
      ),
    );
  }
}

/// Internal card widget with blur applied inside
class _PopoverCard extends StatelessWidget {
  final String? title;
  final Widget child;

  const _PopoverCard({
    this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(SyraTokens.radiusLg),
      child: BackdropFilter(
        // Blur lives INSIDE the card, creating the glass effect
        filter: ImageFilter.blur(
          sigmaX: SyraTokens.blurMedium,
          sigmaY: SyraTokens.blurMedium,
        ),
        child: Container(
          decoration: BoxDecoration(
            // Semi-transparent background for glass effect
            color: SyraTokens.card.withOpacity(0.9),
            borderRadius: BorderRadius.circular(SyraTokens.radiusLg),
            border: Border.all(
              color: SyraTokens.borderSubtle,
              width: 1,
            ),
            // Subtle shadow for premium depth
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
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
/// Supports two positioning modes:
/// 1. **Alignment-based** (default): Position using screen alignment (topCenter, center, etc.)
/// 2. **Anchored**: Attach to a specific widget using a LayerLink
/// 
/// Basic usage (alignment-based):
/// ```dart
/// await showSyraPopover(
///   context: context,
///   title: 'Select Mode',
///   alignment: Alignment.topCenter,
///   child: ModeSelector(),
/// );
/// ```
/// 
/// Anchored usage (attach to app bar label):
/// ```dart
/// // In your widget:
/// final LayerLink _anchorLink = LayerLink();
/// 
/// // Wrap the anchor widget (e.g., app bar label):
/// CompositedTransformTarget(
///   link: _anchorLink,
///   child: Text('GPT-4'),
/// )
/// 
/// // Show popover anchored to it:
/// await showSyraPopover(
///   context: context,
///   anchorLink: _anchorLink,
///   child: ModelSelector(),
/// );
/// ```
Future<T?> showSyraPopover<T>({
  required BuildContext context,
  Alignment alignment = Alignment.topCenter,
  String? title,
  required Widget child,
  double maxWidth = 340,
  bool barrierDismissible = true,
  
  /// Optional anchor link for positioning the popover relative to a widget
  /// When provided, the popover will appear below the anchored widget
  /// Overrides the `alignment` parameter
  LayerLink? anchorLink,
  
  /// Vertical offset from anchor (when anchored)
  double anchorOffset = 8.0,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    // Very subtle background dim (no heavy blur on background)
    barrierColor: Colors.black.withOpacity(SyraTokens.dimLight),
    transitionDuration: SyraTokens.animFast,
    pageBuilder: (context, animation, secondaryAnimation) {
      // If anchored, use CompositedTransformFollower
      if (anchorLink != null) {
        return _AnchoredPopover(
          anchorLink: anchorLink,
          anchorOffset: anchorOffset,
          maxWidth: maxWidth,
          title: title,
          child: child,
        );
      }
      
      // Otherwise, use standard alignment-based positioning
      return SyraPopover(
        title: title,
        maxWidth: maxWidth,
        alignment: alignment,
        child: child,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      // Modern, fast animation: scale + fade + slight slide from above
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: SyraTokens.curveDecelerate,
        ),
        child: SlideTransition(
          position: CurvedAnimation(
            parent: animation,
            curve: SyraTokens.curveDecelerate,
          ).drive(
            Tween<Offset>(
              begin: const Offset(0, -0.02), // Slight slide from above
              end: Offset.zero,
            ),
          ),
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: SyraTokens.curveDecelerate,
            ).drive(
              Tween<double>(begin: 0.95, end: 1.0),
            ),
            child: child,
          ),
        ),
      );
    },
  );
}

/// Internal widget for anchored popovers
class _AnchoredPopover extends StatelessWidget {
  final LayerLink anchorLink;
  final double anchorOffset;
  final double maxWidth;
  final String? title;
  final Widget child;

  const _AnchoredPopover({
    required this.anchorLink,
    required this.anchorOffset,
    required this.maxWidth,
    this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Positioned below the anchor
        Positioned.fill(
          child: CompositedTransformFollower(
            link: anchorLink,
            targetAnchor: Alignment.bottomCenter,
            followerAnchor: Alignment.topCenter,
            offset: Offset(0, anchorOffset),
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                ),
                child: _PopoverCard(
                  title: title,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
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
                  padding: EdgeInsets.only(right: SyraTokens.paddingSm),
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
                        padding: EdgeInsets.only(
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
