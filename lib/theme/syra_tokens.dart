// lib/theme/syra_tokens.dart

import 'package:flutter/material.dart';

/// Design tokens for SYRA app
/// Contains all the core design values used across the app
class SyraTokens {
  // Private constructor to prevent instantiation
  SyraTokens._();

  // ===== COLORS =====
  
  /// Main app background - dark navy
  static const Color bg = Color(0xFF11131A);
  
  /// Card/surface color - slightly lighter than bg
  static const Color card = Color(0xFF1A1D26);
  
  /// Secondary card/surface (for nested cards)
  static const Color cardElevated = Color(0xFF22252E);
  
  /// Accent/primary color - cool cyan
  static const Color accent = Color(0xFF66E0FF);
  
  /// Accent color with reduced opacity for hover states
  static const Color accentHover = Color(0xFF52B3CC);
  
  /// Primary text color - almost white
  static const Color textPrimary = Color(0xFFE8EBF0);
  
  /// Secondary text color - dimmed
  static const Color textSecondary = Color(0xFF8B92A6);
  
  /// Tertiary text color - very dimmed
  static const Color textTertiary = Color(0xFF5A5F73);
  
  /// Subtle border color
  static const Color borderSubtle = Color(0xFF2A2D36);
  
  /// More visible border color
  static const Color border = Color(0xFF3A3D46);
  
  /// Divider color
  static const Color divider = Color(0xFF252830);
  
  /// Error/danger color
  static const Color error = Color(0xFFFF4D6D);
  
  /// Success color
  static const Color success = Color(0xFF4ADE80);
  
  /// Warning color
  static const Color warning = Color(0xFFFBBF24);

  // ===== BORDER RADII =====
  
  /// Large radius for sheets and major cards
  static const double radiusLg = 24.0;
  
  /// Medium radius for buttons and smaller cards
  static const double radiusMd = 16.0;
  
  /// Small radius for compact elements
  static const double radiusSm = 10.0;
  
  /// Extra small radius
  static const double radiusXs = 6.0;

  // ===== SPACING/PADDING =====
  
  /// Standard page horizontal padding
  static const double pagePadding = 16.0;
  
  /// Large padding
  static const double paddingLg = 24.0;
  
  /// Medium padding
  static const double paddingMd = 16.0;
  
  /// Small padding
  static const double paddingSm = 12.0;
  
  /// Extra small padding
  static const double paddingXs = 8.0;
  
  /// Tiny padding
  static const double paddingXxs = 4.0;

  // ===== ANIMATION DURATIONS =====
  
  /// Fast animation (for quick feedback)
  static const Duration animFast = Duration(milliseconds: 160);
  
  /// Normal animation (standard transitions)
  static const Duration animNormal = Duration(milliseconds: 220);
  
  /// Slow animation (for emphasis)
  static const Duration animSlow = Duration(milliseconds: 320);

  // ===== ANIMATION CURVES =====
  
  /// Standard ease curve
  static const Curve curveStandard = Curves.easeInOut;
  
  /// Emphasize curve (for sheets coming in)
  static const Curve curveEmphasize = Curves.easeOutCubic;
  
  /// Decelerate curve (for popovers)
  static const Curve curveDecelerate = Curves.easeOut;

  // ===== SHADOWS =====
  
  /// Subtle shadow for cards
  static List<BoxShadow> get shadowSubtle => [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
  
  /// Medium shadow for elevated elements
  static List<BoxShadow> get shadowMedium => [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
  
  /// Large shadow for sheets and modals
  static List<BoxShadow> get shadowLarge => [
        BoxShadow(
          color: Colors.black.withOpacity(0.25),
          blurRadius: 32,
          offset: const Offset(0, 8),
        ),
      ];

  // ===== BLUR VALUES =====
  
  /// Subtle blur for light dimming
  static const double blurSubtle = 4.0;
  
  /// Medium blur for sheets
  static const double blurMedium = 8.0;
  
  /// Strong blur for modals
  static const double blurStrong = 12.0;

  // ===== OPACITY VALUES =====
  
  /// Very light dim (for popovers)
  static const double dimLight = 0.15;
  
  /// Medium dim (for sheets)
  static const double dimMedium = 0.35;
  
  /// Strong dim (for modals)
  static const double dimStrong = 0.55;

  // ===== TYPOGRAPHY =====
  
  /// Extra large title (32px)
  static const TextStyle titleXl = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: textPrimary,
    height: 1.2,
  );
  
  /// Large title (24px)
  static const TextStyle titleLg = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    color: textPrimary,
    height: 1.3,
  );
  
  /// Medium title (20px)
  static const TextStyle titleMd = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: textPrimary,
    height: 1.3,
  );
  
  /// Small title (16px)
  static const TextStyle titleSm = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.4,
  );
  
  /// Body large (16px)
  static const TextStyle bodyLg = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    height: 1.5,
  );
  
  /// Body medium (14px)
  static const TextStyle bodyMd = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    height: 1.5,
  );
  
  /// Body small (13px)
  static const TextStyle bodySm = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.5,
  );
  
  /// Caption (12px)
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.4,
  );
  
  /// Label (11px)
  static const TextStyle label = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: textTertiary,
    height: 1.4,
  );
}
