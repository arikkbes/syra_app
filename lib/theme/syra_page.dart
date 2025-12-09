// lib/theme/syra_page.dart

import 'package:flutter/material.dart';
import 'syra_tokens.dart';

/// Base page widget for full-screen pages like Settings, Premium, etc.
/// 
/// Provides consistent layout with:
/// - Dark background
/// - Top bar with back button, title, and optional trailing widget
/// - Subtle divider
/// - SafeArea wrapping
class SyraPage extends StatelessWidget {
  /// Page title displayed in the top bar
  final String title;
  
  /// Main content of the page
  final Widget body;
  
  /// Optional widget to display on the right side of the top bar
  /// (e.g., action icons, info buttons)
  final Widget? trailing;
  
  /// Whether to show the back button (default: true)
  final bool showBackButton;
  
  /// Custom back button callback (if null, uses Navigator.pop)
  final VoidCallback? onBack;
  
  /// Whether to use a scrollable body (default: true)
  final bool scrollable;
  
  /// Bottom widget (e.g., for action buttons)
  final Widget? bottom;

  const SyraPage({
    super.key,
    required this.title,
    required this.body,
    this.trailing,
    this.showBackButton = true,
    this.onBack,
    this.scrollable = true,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SyraTokens.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            _buildTopBar(context),
            
            // Divider
            Container(
              height: 1,
              color: SyraTokens.divider,
            ),
            
            // Body
            Expanded(
              child: scrollable
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SyraTokens.pagePadding,
                        vertical: SyraTokens.paddingLg,
                      ),
                      child: body,
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SyraTokens.pagePadding,
                      ),
                      child: body,
                    ),
            ),
            
            // Bottom widget if provided
            if (bottom != null) ...[
              Container(
                height: 1,
                color: SyraTokens.divider,
              ),
              bottom!,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(
        horizontal: SyraTokens.paddingSm,
      ),
      child: Row(
        children: [
          // Back button
          if (showBackButton)
            _BackButton(onPressed: onBack),
          
          if (!showBackButton)
            const SizedBox(width: 8),
          
          // Title
          Expanded(
            child: Text(
              title,
              style: SyraTokens.titleSm,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Trailing widget
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ] else
            const SizedBox(width: 8),
        ],
      ),
    );
  }
}

/// Custom back button with proper styling
class _BackButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _BackButton({this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed ?? () => Navigator.of(context).maybePop(),
        borderRadius: BorderRadius.circular(SyraTokens.radiusSm),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: SyraTokens.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// Simple action button for top bar trailing
class SyraTopBarAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  const SyraTopBarAction({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SyraTokens.radiusSm),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 20,
            color: SyraTokens.textPrimary,
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}
