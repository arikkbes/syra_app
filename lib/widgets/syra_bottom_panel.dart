import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/syra_theme.dart';

class SyraBottomPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? maxHeight;

  const SyraBottomPanel({
    super.key,
    required this.child,
    this.padding,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final screenHeight = MediaQuery.of(context).size.height;
    final safeBottomPadding = MediaQuery.of(context).padding.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: maxHeight ?? screenHeight * 0.85,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: SyraColors.surface.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: SyraColors.border.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, -8),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: SyraColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Flexible(
                    child: Padding(
                      padding: padding ?? const EdgeInsets.all(16),
                      child: child,
                    ),
                  ),
                  SizedBox(height: safeBottomPadding > 0 ? safeBottomPadding : 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    EdgeInsets? padding,
    double? maxHeight,
    bool isDismissible = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => SyraBottomPanel(
        padding: padding,
        maxHeight: maxHeight,
        child: child,
      ),
    );
  }
}
