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
/// - Premium card with glassmorphism
/// - Smooth slide-up + fade animation
/// - Calm, comfortable spacing
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
        margin: EdgeInsets.only(
          left: SyraTokens.paddingMd,
          right: SyraTokens.paddingMd,
          bottom: SyraTokens.paddingLg,
        ),
        constraints: const BoxConstraints(
          maxWidth: 400,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(SyraTokens.radiusLg),
          child: BackdropFilter(
            // Subtle blur inside the sheet for glass effect
            filter: ImageFilter.blur(
              sigmaX: SyraTokens.blurMedium,
              sigmaY: SyraTokens.blurMedium,
            ),
            child: Container(
              decoration: BoxDecoration(
                // Premium semi-transparent background
                color: SyraTokens.card.withOpacity(0.96),
                borderRadius: BorderRadius.circular(SyraTokens.radiusLg),
                border: Border.all(
                  color: SyraTokens.borderSubtle,
                  width: 1,
                ),
                // Very subtle shadow for depth
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                ],
              ),
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
                              margin: const EdgeInsets.symmetric(
                                horizontal: SyraTokens.paddingMd,
                              ),
                              color: SyraTokens.divider,
                            ),
                        ],
                      );
                    })
                    .toList(),
              ),
            ),
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
    // Destructive actions use error color with slightly bolder text
    final textColor = action.isDestructive
        ? SyraTokens.error
        : SyraTokens.textPrimary;
    
    final fontWeight = action.isDestructive
        ? FontWeight.w500  // Slightly bolder for destructive actions
        : FontWeight.w400;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Close the menu first
          Navigator.of(context).pop();
          // Then execute the action
          action.onTap();
        },
        // Subtle hover/press feedback
        splashColor: action.isDestructive
            ? SyraTokens.error.withOpacity(0.1)
            : SyraTokens.accent.withOpacity(0.05),
        highlightColor: action.isDestructive
            ? SyraTokens.error.withOpacity(0.05)
            : SyraTokens.accent.withOpacity(0.03),
        child: Container(
          // Comfortable vertical padding for easy tapping
          padding: const EdgeInsets.symmetric(
            horizontal: SyraTokens.paddingMd,
            vertical: SyraTokens.paddingSm + 2, // 14px for comfortable touch
          ),
          child: Row(
            children: [
              // Icon - size 20 for consistency
              Icon(
                action.icon,
                size: 20,
                color: textColor,
              ),
              
              SizedBox(width: SyraTokens.paddingSm),
              
              // Label
              Expanded(
                child: Text(
                  action.label,
                  style: SyraTokens.bodyMd.copyWith(
                    color: textColor,
                    fontWeight: fontWeight,
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
    // Very subtle background dim - calm, not aggressive
    barrierColor: Colors.black.withOpacity(SyraTokens.dimLight),
    transitionDuration: SyraTokens.animFast,
    pageBuilder: (context, animation, secondaryAnimation) {
      return SyraContextMenu(actions: actions);
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      // Smooth slide up from slightly below + fade
      // Duration: ~160ms with ease-out curve for snappy feel
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: SyraTokens.curveDecelerate,
        ),
        child: SlideTransition(
          position: CurvedAnimation(
            parent: animation,
            curve: SyraTokens.curveEmphasize, // Smooth ease-out cubic
          ).drive(
            Tween<Offset>(
              begin: const Offset(0, 0.03), // Slight slide from below (12px at typical height)
              end: Offset.zero,
            ),
          ),
          child: child,
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
