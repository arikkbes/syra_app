// lib/theme/syra_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ═══════════════════════════════════════════════════════════════
///  SYRA DESIGN SYSTEM v4.0
///  Premium AI relationship coach aesthetic
///  Background: #0B0E14 (deep dark with blue undertone)
///  Accent: #66E0FF (premium cyan)
/// ═══════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════
// COLORS
// ═══════════════════════════════════════════════════════════════
class SyraColors {
  SyraColors._();

  // ─── Background ───
  static const Color background = Color(0xFF0B0E14);
  static const Color surface = Color(0xFF11131A);
  static const Color surfaceLight = Color(0xFF16181F);
  static const Color surfaceDark = Color(0xFF0C0F15);

  // ─── Borders & Dividers ───
  static const Color border = Color(0xFF1A1E24);
  static const Color divider = Color(0xFF1A1E24);

  // ─── Text ───
  static const Color textPrimary = Color(0xFFEDEDED);
  static const Color textSecondary = Color(0xFF9AA0A6);
  static const Color textMuted = Color(0xFF5A5F66);
  static const Color textHint = Color(0xFF5A5F66);

  // ─── Accent ───
  static const Color accent = Color(0xFF66E0FF);
  static const Color accentLight = Color(0xFF8AEAFF);
  static const Color accentMuted = Color(0x3366E0FF);

  // ─── Icons ───
  static const Color iconStroke = Color(0xFFCFCFCF);
  static const Color iconActive = textPrimary;
  static const Color iconMuted = textSecondary;

  // ─── Semantic ───
  static const Color success = Color(0xFF4ADE80);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFFF4D6D);

  // ─── Glass Effect ───
  static const Color glassBg = Color(0x3311131A);
  static const Color glassBorder = divider;
  static const Color glassHighlight = Color(0x1AEDEDED);

  // ─── Chat Bubbles ───
  static const Color syraBubbleBg = surface;
  static const Color userBubbleBg = Color(0xFF16181F);
  static const Color syraBubbleGlow = accent;

  // ─── Gradients ───
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [background, background, background],
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentLight],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient orbGradient = LinearGradient(
    colors: [accent, accentLight],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  // ─── Shadows ───
  static List<BoxShadow> orbIdleGlow() => [
        BoxShadow(
          color: accent.withValues(alpha: 0.2),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ];

  static List<BoxShadow> orbThinkingGlow() => [
        BoxShadow(
          color: accent.withValues(alpha: 0.4),
          blurRadius: 30,
          spreadRadius: 5,
        ),
      ];

  static List<BoxShadow> bubbleGlow({double intensity = 0.1}) => [
        BoxShadow(
          color: accent.withValues(alpha: intensity),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> cardGlow() => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> subtleShadow() => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
}

// ═══════════════════════════════════════════════════════════════
// SPACING & SIZING
// ═══════════════════════════════════════════════════════════════
class SyraSpacing {
  SyraSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Page-level padding
  static const double pagePadding = md;
  static const double horizontalPadding = md;
}

// ═══════════════════════════════════════════════════════════════
// BORDER RADIUS
// ═══════════════════════════════════════════════════════════════
class SyraRadius {
  SyraRadius._();

  static const double xs = 6.0;
  static const double sm = 10.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double full = 999.0;

  // Component-specific
  static const double card = md;
  static const double button = md;
  static const double sheet = lg;
  static const double pill = full;
}

// ═══════════════════════════════════════════════════════════════
// ANIMATIONS
// ═══════════════════════════════════════════════════════════════
class SyraAnimation {
  SyraAnimation._();

  // Durations
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration normal = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 320);

  // Curves
  static const Curve standard = Curves.easeInOut;
  static const Curve emphasize = Curves.easeOutCubic;
  static const Curve decelerate = Curves.easeOut;
  static const Curve spring = Curves.easeOutBack;
}

// ═══════════════════════════════════════════════════════════════
// TYPOGRAPHY
// ═══════════════════════════════════════════════════════════════
class SyraTextStyles {
  SyraTextStyles._();

  // Base font family using Google Fonts
  static String get _fontFamily => GoogleFonts.inter().fontFamily!;

  // ─── Display & Headings ───
  static TextStyle get displayLarge => GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: SyraColors.textPrimary,
        height: 1.2,
      );

  static TextStyle get displayMedium => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: SyraColors.textPrimary,
        height: 1.2,
      );

  static TextStyle get headingLarge => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: SyraColors.textPrimary,
        height: 1.3,
      );

  static TextStyle get headingMedium => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: SyraColors.textPrimary,
        height: 1.3,
      );

  static TextStyle get headingSmall => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: SyraColors.textPrimary,
        height: 1.4,
      );

  // ─── Body Text ───
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: SyraColors.textPrimary,
        height: 1.5,
        letterSpacing: 0.1,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: SyraColors.textPrimary,
        height: 1.5,
        letterSpacing: 0.1,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: SyraColors.textSecondary,
        height: 1.5,
      );

  // ─── Labels & Captions ───
  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: SyraColors.textPrimary,
        letterSpacing: 0.1,
      );

  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: SyraColors.textSecondary,
        letterSpacing: 0.1,
      );

  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: SyraColors.textMuted,
        letterSpacing: 0.5,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: SyraColors.textMuted,
        letterSpacing: 0.2,
        height: 1.4,
      );

  // ─── Special ───
  static TextStyle get button => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: SyraColors.textPrimary,
      );

  static TextStyle get overline => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
        color: SyraColors.textMuted,
      );

  // Logo uses SF Pro Display fallback for brand consistency
  static TextStyle logoStyle({double fontSize = 20}) => TextStyle(
        fontFamily: "SF Pro Display",
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: fontSize * 0.12,
        color: SyraColors.textPrimary,
      );
}

// ═══════════════════════════════════════════════════════════════
// THEME DATA
// ═══════════════════════════════════════════════════════════════
class SyraTheme {
  SyraTheme._();

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: SyraColors.background,
        fontFamily: GoogleFonts.inter().fontFamily,

        // ─── Color Scheme ───
        colorScheme: const ColorScheme.dark(
          primary: SyraColors.accent,
          secondary: SyraColors.accentLight,
          surface: SyraColors.surface,
          surfaceContainer: SyraColors.surface,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: SyraColors.textPrimary,
          outline: SyraColors.border,
          error: SyraColors.error,
        ),

        // ─── AppBar ───
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(
            color: SyraColors.iconStroke,
            size: 24,
          ),
          titleTextStyle: SyraTextStyles.headingSmall,
        ),

        // ─── Card ───
        cardTheme: CardThemeData(
          color: SyraColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SyraRadius.card),
            side: const BorderSide(
              color: SyraColors.border,
              width: 1,
            ),
          ),
        ),

        // ─── Buttons ───
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: SyraColors.accent,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: SyraSpacing.lg,
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SyraRadius.button),
            ),
            textStyle: SyraTextStyles.button,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: SyraColors.accent,
            textStyle: SyraTextStyles.button,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: SyraColors.textPrimary,
            side: const BorderSide(
              color: SyraColors.border,
              width: 1,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: SyraSpacing.lg,
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SyraRadius.button),
            ),
          ),
        ),

        // ─── Input ───
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: SyraColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: SyraSpacing.md,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(SyraRadius.md),
            borderSide: const BorderSide(
              color: SyraColors.border,
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(SyraRadius.md),
            borderSide: const BorderSide(
              color: SyraColors.border,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(SyraRadius.md),
            borderSide: const BorderSide(
              color: SyraColors.accent,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(SyraRadius.md),
            borderSide: const BorderSide(
              color: SyraColors.error,
              width: 1,
            ),
          ),
          hintStyle: SyraTextStyles.bodyMedium.copyWith(
            color: SyraColors.textMuted,
          ),
          labelStyle: SyraTextStyles.bodySmall,
        ),

        // ─── ListTile ───
        listTileTheme: ListTileThemeData(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: SyraSpacing.md,
            vertical: SyraSpacing.sm,
          ),
          iconColor: SyraColors.iconStroke,
          textColor: SyraColors.textPrimary,
          titleTextStyle: SyraTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
          ),
          subtitleTextStyle: SyraTextStyles.bodySmall,
        ),

        // ─── Bottom Sheet ───
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: SyraColors.surface,
          modalBackgroundColor: SyraColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(SyraRadius.sheet),
            ),
          ),
        ),

        // ─── SnackBar ───
        snackBarTheme: SnackBarThemeData(
          backgroundColor: SyraColors.surface,
          contentTextStyle: SyraTextStyles.bodySmall.copyWith(
            color: SyraColors.textPrimary,
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SyraRadius.md),
          ),
        ),

        // ─── Progress Indicator ───
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: SyraColors.accent,
          circularTrackColor: SyraColors.divider,
        ),

        // ─── Divider ───
        dividerTheme: const DividerThemeData(
          color: SyraColors.divider,
          thickness: 1,
          space: 1,
        ),

        // ─── Icon ───
        iconTheme: const IconThemeData(
          color: SyraColors.iconStroke,
          size: 24,
        ),

        // ─── Switch ───
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return SyraColors.textMuted;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return SyraColors.accent;
            }
            return SyraColors.divider;
          }),
        ),

        // ─── Drawer ───
        drawerTheme: const DrawerThemeData(
          backgroundColor: SyraColors.background,
          elevation: 0,
        ),
      );
}
