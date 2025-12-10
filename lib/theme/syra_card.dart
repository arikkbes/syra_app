import 'package:flutter/material.dart';
import 'syra_tokens.dart';

/// ═══════════════════════════════════════════════════════════════
/// SYRA CARD - Premium Card Component
/// ═══════════════════════════════════════════════════════════════
/// 
/// A consistent, premium card component for dashboard/panel screens.
/// 
/// Features:
/// - Token-based styling (colors, padding, radius, shadows)
/// - Elevated and outlined variants
/// - Optional tap interaction with subtle feedback
/// - Consistent across all dashboard-style screens
/// 
/// Module 5: Created as shared building block for stats, analysis,
/// tips, and other panel-based content.
/// ═══════════════════════════════════════════════════════════════

/// Main card component with premium styling
class SyraCard extends StatefulWidget {
  /// Content of the card
  final Widget child;
  
  /// Custom padding (defaults to token-based padding)
  final EdgeInsetsGeometry? padding;
  
  /// Tap handler (if provided, card becomes tappable)
  final VoidCallback? onTap;
  
  /// Whether to use elevated style (with shadow)
  final bool elevated;
  
  /// Whether to use outlined style (with border, no shadow)
  final bool outlined;
  
  /// Custom background color (overrides default)
  final Color? backgroundColor;
  
  /// Custom border color (for outlined style)
  final Color? borderColor;

  const SyraCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.elevated = true,
    this.outlined = false,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  State<SyraCard> createState() => _SyraCardState();
}

class _SyraCardState extends State<SyraCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectivePadding = widget.padding ?? 
        EdgeInsets.all(SyraTokens.paddingLg);
    
    final bgColor = widget.backgroundColor ?? SyraTokens.surface;
    
    final decoration = BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(SyraTokens.radiusMd),
      border: widget.outlined
          ? Border.all(
              color: widget.borderColor ?? SyraTokens.border,
              width: 1,
            )
          : null,
      boxShadow: widget.elevated && !widget.outlined
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ]
          : null,
    );

    Widget cardContent = Container(
      padding: effectivePadding,
      decoration: decoration,
      child: widget.child,
    );

    // If tappable, add interaction feedback
    if (widget.onTap != null) {
      return GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap!();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: _isPressed ? 0.9 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: cardContent,
          ),
        ),
      );
    }

    return cardContent;
  }
}

/// Compact card variant for smaller content
class SyraCardCompact extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  const SyraCardCompact({
    super.key,
    required this.child,
    this.onTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SyraCard(
      padding: EdgeInsets.all(SyraTokens.paddingMd),
      onTap: onTap,
      backgroundColor: backgroundColor,
      child: child,
    );
  }
}

/// Outlined card variant (no shadow, just border)
class SyraCardOutlined extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  const SyraCardOutlined({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return SyraCard(
      elevated: false,
      outlined: true,
      padding: padding,
      onTap: onTap,
      child: child,
    );
  }
}

/// Info card with icon and title (common pattern in stats screens)
class SyraInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;

  const SyraInfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
    this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return SyraCard(
      onTap: onTap,
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (iconColor ?? SyraTokens.accent).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(SyraTokens.radiusMd),
            ),
            child: Icon(
              icon,
              color: iconColor ?? SyraTokens.accent,
              size: 24,
            ),
          ),
          SizedBox(width: SyraTokens.paddingMd),
          
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: SyraTokens.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    color: SyraTokens.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: SyraTokens.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Stat card for displaying percentage or metric (common in relationship stats)
class SyraStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;

  const SyraStatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? SyraTokens.accent;

    return SyraCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null)
            Container(
              width: 40,
              height: 40,
              margin: EdgeInsets.only(bottom: SyraTokens.paddingMd),
              decoration: BoxDecoration(
                color: effectiveColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(SyraTokens.radiusSm),
              ),
              child: Icon(
                icon,
                color: effectiveColor,
                size: 20,
              ),
            ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: SyraTokens.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              color: effectiveColor,
              fontWeight: FontWeight.w700,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
