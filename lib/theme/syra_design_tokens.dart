import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'syra_theme.dart';

/// ═══════════════════════════════════════════════════════════════
/// SYRA TYPOGRAPHY SYSTEM
/// Premium typography hierarchy using Google Fonts
/// ═══════════════════════════════════════════════════════════════

class SyraTypography {
  SyraTypography._();

  // Base font family
  static String get fontFamily => GoogleFonts.inter().fontFamily!;

  // ═══════════════════════════════════════════════════════════════
  // DISPLAY STYLES (Large, attention-grabbing)
  // ═══════════════════════════════════════════════════════════════

  static TextStyle displayLarge = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
    color: SyraColors.textPrimary,
  );

  static TextStyle displayMedium = GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.25,
    color: SyraColors.textPrimary,
  );

  // ═══════════════════════════════════════════════════════════════
  // TITLE STYLES (Section headers, screen titles)
  // ═══════════════════════════════════════════════════════════════

  static TextStyle titleLarge = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.3,
    color: SyraColors.textPrimary,
  );

  static TextStyle titleMedium = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.35,
    color: SyraColors.textPrimary,
  );

  static TextStyle titleSmall = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.4,
    color: SyraColors.textPrimary,
  );

  // ═══════════════════════════════════════════════════════════════
  // BODY STYLES (Main content text)
  // ═══════════════════════════════════════════════════════════════

  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
    color: SyraColors.textPrimary,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
    color: SyraColors.textPrimary,
  );

  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.45,
    color: SyraColors.textSecondary,
  );

  // ═══════════════════════════════════════════════════════════════
  // LABEL STYLES (Buttons, tabs, small UI elements)
  // ═══════════════════════════════════════════════════════════════

  static TextStyle labelLarge = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.3,
    color: SyraColors.textPrimary,
  );

  static TextStyle labelMedium = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.3,
    color: SyraColors.textSecondary,
  );

  static TextStyle labelSmall = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    height: 1.3,
    color: SyraColors.textMuted,
  );

  // ═══════════════════════════════════════════════════════════════
  // CAPTION STYLES (Hints, timestamps, metadata)
  // ═══════════════════════════════════════════════════════════════

  static TextStyle caption = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.4,
    color: SyraColors.textMuted,
  );

  static TextStyle captionBold = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.4,
    color: SyraColors.textSecondary,
  );

  // ═══════════════════════════════════════════════════════════════
  // SPECIAL STYLES
  // ═══════════════════════════════════════════════════════════════

  /// App logo text
  static TextStyle logo = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.8,
    height: 1.2,
    color: SyraColors.textPrimary,
  );

  /// Accent text (highlighted, important)
  static TextStyle accent = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.4,
    color: SyraColors.accent,
  );

  /// Monospace (for code, numbers)
  static TextStyle mono = GoogleFonts.jetBrainsMono(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
    color: SyraColors.textPrimary,
  );
}

/// ═══════════════════════════════════════════════════════════════
/// SYRA SPACING SYSTEM
/// Consistent spacing scale for layouts
/// ═══════════════════════════════════════════════════════════════

class SyraSpacing {
  SyraSpacing._();

  // Base unit: 4px
  static const double unit = 4.0;

  // Spacing scale
  static const double xs = unit; // 4px
  static const double sm = unit * 2; // 8px
  static const double md = unit * 3; // 12px
  static const double lg = unit * 4; // 16px
  static const double xl = unit * 5; // 20px
  static const double xxl = unit * 6; // 24px
  static const double xxxl = unit * 8; // 32px
  static const double huge = unit * 10; // 40px

  // Screen edges (safe area)
  static const double screenEdge = lg; // 16px
  static const double screenEdgeLarge = xxl; // 24px

  // Section spacing
  static const double sectionGap = xxxl; // 32px
  static const double componentGap = lg; // 16px
  static const double itemGap = md; // 12px
  static const double tightGap = sm; // 8px

  // Card/Container padding
  static const double cardPadding = lg; // 16px
  static const double cardPaddingLarge = xl; // 20px
  static const double cardPaddingSmall = md; // 12px
}

/// ═══════════════════════════════════════════════════════════════
/// SYRA ANIMATION CONSTANTS
/// Standard animation durations and curves
/// ═══════════════════════════════════════════════════════════════

class SyraAnimation {
  SyraAnimation._();

  // Durations
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration verySlow = Duration(milliseconds: 600);

  // Curves
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve spring = Curves.easeOutCubic;
  static const Curve bounce = Curves.elasticOut;

  // Fade delays
  static const Duration fadeDelay = Duration(milliseconds: 50);
  static const Duration staggerDelay = Duration(milliseconds: 80);

  // Scale values
  static const double scalePressed = 0.95;
  static const double scalePressedSmall = 0.92;
  static const double scaleNormal = 1.0;
}

/// ═══════════════════════════════════════════════════════════════
/// SYRA ELEVATION SYSTEM
/// Consistent elevation/depth scale
/// ═══════════════════════════════════════════════════════════════

class SyraElevation {
  SyraElevation._();

  static const double none = 0;
  static const double low = 2;
  static const double medium = 4;
  static const double high = 8;
  static const double veryHigh = 16;
}

/// ═══════════════════════════════════════════════════════════════
/// SYRA BORDER RADIUS SYSTEM
/// Consistent corner radius scale
/// ═══════════════════════════════════════════════════════════════

class SyraRadius {
  SyraRadius._();

  static const double none = 0;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double pill = 999; // Fully rounded

  // Border radius objects
  static BorderRadius get radiusXS => BorderRadius.circular(xs);
  static BorderRadius get radiusSM => BorderRadius.circular(sm);
  static BorderRadius get radiusMD => BorderRadius.circular(md);
  static BorderRadius get radiusLG => BorderRadius.circular(lg);
  static BorderRadius get radiusXL => BorderRadius.circular(xl);
  static BorderRadius get radiusXXL => BorderRadius.circular(xxl);
  static BorderRadius get radiusXXXL => BorderRadius.circular(xxxl);
  static BorderRadius get radiusPill => BorderRadius.circular(pill);
}
