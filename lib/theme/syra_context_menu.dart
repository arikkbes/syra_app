// lib/theme/syra_context_menu.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'syra_tokens.dart';

/// Action item for context menu
class SyraContextAction {
  /// Icon to display
  final IconData icon;
  
  /// Label text
  final String label;
  
  /// Callback when tapped
  final VoidCallback onTap;
  
  /// Whether this action is destructive (e.g., delete)
  final bool isDestructive;

  const SyraContextAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });
}

/// Compact context menu for actions like Share, Rename, Archive, Delete
/// Similar to ChatGPT's bottom action panel
/// 
/// Features:
/// - Aligned near bottom center
/// - Very light background dim
/// - Compact card with proper spacing
/// - Smooth slide-up animation
class SyraContextMenu extends StatelessWidget {
  /// List of actions to display
  final List<SyraContextAction> actions;

  const SyraContextMenu({
    super.key,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.only(
          left: SyraTokens.paddingMd,
          right: SyraTokens.paddingMd,
          bottom: SyraTokens.paddingLg,
        ),
        constraints: const BoxConstraints(
          maxWidth: 400,
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
            children: actions
                .asMap()
                .entries
                .map((entry) {
                  final index = entry.key;
                  final action = entry.value;
                  
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ContextMenuItem(action: action),
                      
                      // Divider between items (but not after the last one)
                      if (index < actions.length - 1)
                        Container(
                          height: 1,
                          color: SyraTokens.divider,
                        ),
                    ],
                  );
                })
                .toList(),
          ),
        ),
      ),
    );
  }
}

/// Single action row in context menu
class _ContextMenuItem extends StatelessWidget {
  final SyraContextAction action;

  const _ContextMenuItem({required this.action});

  @override
  Widget build(BuildContext context) {
    final textColor = action.isDestructive
        ? SyraTokens.error
        : SyraTokens.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Close the menu first
          Navigator.of(context).pop();
          // Then execute the action
          action.onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: SyraTokens.paddingLg,
            vertical: SyraTokens.paddingMd,
          ),
          child: Row(
            children: [
              // Icon
              Icon(
                action.icon,
                size: 20,
                color: textColor,
              ),
              
              const SizedBox(width: SyraTokens.paddingMd),
              
              // Label
              Expanded(
                child: Text(
                  action.label,
                  style: SyraTokens.bodyMd.copyWith(
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Show a context menu with actions
/// 
/// Usage:
/// ```dart
/// await showSyraContextMenu(
///   context: context,
///   actions: [
///     SyraContextAction(
///       icon: Icons.share_rounded,
///       label: 'Share Chat',
///       onTap: () => shareChat(),
///     ),
///     SyraContextAction(
///       icon: Icons.delete_rounded,
///       label: 'Delete Chat',
///       isDestructive: true,
///       onTap: () => deleteChat(),
///     ),
///   ],
/// );
/// ```
Future<T?> showSyraContextMenu<T>({
  required BuildContext context,
  required List<SyraContextAction> actions,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withOpacity(0.1), // Very light dim
    transitionDuration: SyraTokens.animFast,
    pageBuilder: (context, animation, secondaryAnimation) {
      return SyraContextMenu(actions: actions);
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      // Subtle blur
      return BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: SyraTokens.blurSubtle * animation.value * 0.5,
          sigmaY: SyraTokens.blurSubtle * animation.value * 0.5,
        ),
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: SyraTokens.curveDecelerate,
          ),
          child: SlideTransition(
            position: CurvedAnimation(
              parent: animation,
              curve: SyraTokens.curveEmphasize,
            ).drive(
              Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ),
            ),
            child: child,
          ),
        ),
      );
    },
  );
}

/// Convenience function to show a simple confirmation context menu
/// 
/// Returns true if confirmed, false if cancelled
Future<bool> showSyraConfirmation({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool isDestructive = false,
}) async {
  final result = await showSyraContextMenu<bool>(
    context: context,
    actions: [
      SyraContextAction(
        icon: Icons.close_rounded,
        label: cancelLabel,
        onTap: () {
          // Will be popped by _ContextMenuItem
        },
      ),
      SyraContextAction(
        icon: isDestructive ? Icons.delete_rounded : Icons.check_rounded,
        label: confirmLabel,
        isDestructive: isDestructive,
        onTap: () {
          Navigator.of(context).pop(true);
        },
      ),
    ],
  );

  return result ?? false;
}
