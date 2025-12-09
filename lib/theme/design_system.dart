// lib/theme/design_system.dart

/// SYRA Design System Export
/// 
/// This file exports all the new design system components.
/// Use alongside the existing syra_theme.dart for backward compatibility.
/// 
/// New design system includes:
/// - SyraTokens: Design tokens (colors, spacing, animations)
/// - SyraPage: Base page widget for full-screen pages
/// - SyraSheet: Large modal overlays for major flows
/// - SyraPopover: Small floating panels for quick selections
/// - SyraContextMenu: Bottom action menus
/// 
/// Usage:
/// ```dart
/// import 'package:syra/theme/design_system.dart';
/// 
/// // Use in your widgets
/// showSyraSheet(
///   context: context,
///   title: 'Premium',
///   child: PremiumContent(),
/// );
/// ```

export 'syra_tokens.dart';
export 'syra_page.dart';
export 'syra_sheet.dart';
export 'syra_popover.dart';
export 'syra_context_menu.dart';
