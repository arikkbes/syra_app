// lib/theme/syra_sheet.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'syra_tokens.dart';

/// Large glassy sheet for major flows (premium, relationship upload, etc.)
/// 
/// Features:
/// - Centered modal dialog
/// - Backdrop blur and dim
/// - Smooth fade + scale animation
/// - Consistent styling with design tokens
class SyraSheet extends StatelessWidget {
  /// Optional title displayed at the top of the sheet
  final String? title;
  
  /// Main content of the sheet
  final Widget child;
  
  /// Maximum width of the sheet (default: 500)
  final double maxWidth;
  
  /// Maximum height of the sheet (default: 90% of screen)
  final double? maxHeight;

  const SyraSheet({
    super.key,
    this.title,
    required this.child,
    this.maxWidth = 500,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final effectiveMaxHeight = maxHeight ?? screenHeight * 0.9;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: effectiveMaxHeight,
        ),
        child: Container(
          margin: EdgeInsets.all(SyraTokens.paddingLg),
          decoration: BoxDecoration(
            color: SyraTokens.card.withOpacity(0.95),
            borderRadius: BorderRadius.circular(SyraTokens.radiusLg),
            border: Border.all(
              color: SyraTokens.borderSubtle,
              width: 1,
            ),
            boxShadow: SyraTokens.shadowLarge,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(SyraTokens.radiusLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title section
                if (title != null)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(SyraTokens.paddingLg),
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
                      style: SyraTokens.titleSm,
                      textAlign: TextAlign.center,
                    ),
                  ),
                
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(SyraTokens.paddingLg),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Show a large glassy sheet modal
/// 
/// Usage:
/// ```dart
/// await showSyraSheet(
///   context: context,
///   title: 'Premium Features',
///   child: PremiumContent(),
/// );
/// ```
Future<T?> showSyraSheet<T>({
  required BuildContext context,
  String? title,
  required Widget child,
  double maxWidth = 500,
  double? maxHeight,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withOpacity(SyraTokens.dimMedium),
    transitionDuration: SyraTokens.animNormal,
    pageBuilder: (context, animation, secondaryAnimation) {
      return SyraSheet(
        title: title,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        child: child,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      // Backdrop blur
      return BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: SyraTokens.blurMedium * animation.value,
          sigmaY: SyraTokens.blurMedium * animation.value,
        ),
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: SyraTokens.curveStandard,
          ),
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: SyraTokens.curveEmphasize,
            ).drive(Tween<double>(begin: 0.92, end: 1.0)),
            child: child,
          ),
        ),
      );
    },
  );
}

/// Convenience widget for sheet actions (buttons at the bottom)
class SyraSheetActions extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment alignment;

  const SyraSheetActions({
    super.key,
    required this.children,
    this.alignment = MainAxisAlignment.end,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: SyraTokens.paddingLg),
      child: Row(
        mainAxisAlignment: alignment,
        children: children
            .map((child) => Padding(
                  padding: EdgeInsets.only(left: SyraTokens.paddingSm),
                  child: child,
                ))
            .toList(),
      ),
    );
  }
}

/// Primary button for sheets
class SyraSheetButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isDestructive;

  const SyraSheetButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isPrimary = false,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    if (isDestructive) {
      backgroundColor = SyraTokens.error;
      textColor = Colors.white;
    } else if (isPrimary) {
      backgroundColor = SyraTokens.accent;
      textColor = SyraTokens.bg;
    } else {
      backgroundColor = SyraTokens.cardElevated;
      textColor = SyraTokens.textPrimary;
    }

    return Material(
      color: onPressed == null
          ? backgroundColor.withOpacity(0.5)
          : backgroundColor,
      borderRadius: BorderRadius.circular(SyraTokens.radiusMd),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(SyraTokens.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: SyraTokens.paddingLg,
            vertical: SyraTokens.paddingMd,
          ),
          child: Text(
            label,
            style: SyraTokens.bodyMd.copyWith(
              color: onPressed == null
                  ? textColor.withOpacity(0.5)
                  : textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
