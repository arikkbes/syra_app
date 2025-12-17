// lib/theme/syra_theme.dart
// ═══════════════════════════════════════════════════════════════
// ⛔ SYRA DESIGN CORE — DO NOT EDIT
// ═══════════════════════════════════════════════════════════════
// LOCKED: Obsidian (#11131A) + Champagne Gold (#D6B35A)
// NO hardcoded Color(0xFF...) in UI code — use SyraColors.* only
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════
///  SYRA DESIGN SYSTEM — Obsidian + Champagne Gold
///  - Background: #11131A (Obsidian)
///  - Accent: #D6B35A (Champagne Gold - premium)
/// ═══════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════
// COLORS - Dark Mode 2.0: Rich Tech
// ═══════════════════════════════════════════════════════════════
class SyraColors {
  SyraColors._();

  // ─── Background (Marka Rengi Korundu) ───
  static const Color background = Color(0xFF11131A); // Ana BG - RGB(17, 19, 26)
  static const Color surface = Color(0xFF11131A); // Ana BG ile aynı
  static const Color surfaceElevated =
      Color(0xFF1B202C); // Yükseltilmiş yüzey - RGB(27, 32, 44)
  static const Color surfaceLight =
      Color(0xFF1B202C); // Input bar, kartlar için
  static const Color surfaceDark = Color(0xFF0C0F15); // Eski değer korundu

  // ─── Borders & Dividers (Subtle - white alpha) ───
  static const Color border = Color(0x14FFFFFF); // ~8% white
  static const Color divider = Color(0x0FFFFFFF); // ~6% white

  // ─── Text (Kırık Beyaz - premium) ───
  static const Color textPrimary = Color(0xFFE7E9EE);
  static const Color textSecondary = Color(0xFF9AA3B2);
  static const Color textMuted = Color(0xFF778090);
  static const Color textHint = textMuted;

  // ─── Accent (Champagne Gold) ───
  static const Color accent = Color(0xFFD6B35A);
  static const Color accentLight = Color(0xFFEAD7A5);
  static const Color accentMuted = Color(0x33D6B35A);

  // ─── Icons ───
  static const Color iconStroke = Color(0xFFE0E6ED);
  static const Color iconActive = textPrimary;
  static const Color iconMuted = textSecondary;

  // ─── Semantic ───
  static const Color success = Color(0xFF4ADE80);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFFF4D6D);

  // ─── Glass Effect ───
  static const Color glassBg = Color(0x3311131A);
  static const Color glassBorder = divider;
  static const Color glassHighlight = Color(0x1AE7E9EE);

  // ─── Chat Bubbles ───
  static const Color syraBubbleBg = surfaceElevated;
  static const Color userBubbleBg = Color(0xFF1B202C);
  static const Color syraBubbleGlow = accent;

  // ─── Backward Compatibility ───
  static const Color neonPink = accent;
  static const Color neonCyan = accent;
  static const Color neonPinkLight = accentLight;
  static const Color neonCyanLight = accentLight;
  static const Color neonPinkDark = Color(0xFF2A9DC5);
  static const Color neonCyanDark = Color(0xFF2A9DC5);
  static const Color neonViolet = Color(0xFF5AC8F5);

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
  static const double full = 999.0; // Pill shape

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
// TYPOGRAPHY - Dark Mode 2.0: Literary & Sophisticated
// ═══════════════════════════════════════════════════════════════
class SyraTextStyles {
  SyraTextStyles._();

  // Asset-backed font families (pubspec.yaml)
  static const String _uiFamily = 'Inter';
  static const String _displayFamily = 'DMSerifDisplay';

  // ─── Display & Headings (SERIF - Entelektüel Hava) ───
  static TextStyle get displayLarge => const TextStyle(
        fontFamily: _displayFamily,
        fontSize: 32,
        height: 1.2,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.4,
        color: SyraColors.textPrimary,
      );

  static TextStyle get displayMedium => const TextStyle(
        fontFamily: _displayFamily,
        fontSize: 28,
        height: 1.2,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.4,
        color: SyraColors.textPrimary,
      );

  static TextStyle get headingLarge => const TextStyle(
        fontFamily: _uiFamily,
        fontSize: 24,
        height: 1.3,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: SyraColors.textPrimary,
      );

  static TextStyle get headingMedium => const TextStyle(
        fontFamily: _uiFamily,
        fontSize: 20,
        height: 1.3,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: SyraColors.textPrimary,
      );

  static TextStyle get headingSmall => const TextStyle(
        fontFamily: _uiFamily,
        fontSize: 16,
        height: 1.4,
        fontWeight: FontWeight.w600,
        color: SyraColors.textPrimary,
      );

  // ─── Body Text (SANS-SERIF - Okunabilirlik) ───
  static TextStyle get bodyLarge => const TextStyle(
        fontFamily: _uiFamily,
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        color: SyraColors.textPrimary,
      );

  static TextStyle get bodyMedium => const TextStyle(
        fontFamily: _uiFamily,
        fontSize: 15,
        height: 1.5,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        color: SyraColors.textPrimary,
      );

  static TextStyle get bodySmall => const TextStyle(
        fontFamily: _uiFamily,
        fontSize: 14,
        height: 1.5,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        color: SyraColors.textSecondary,
      );

  // ─── Labels & Captions ───
  static TextStyle get labelLarge => const TextStyle(
        fontFamily: _uiFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: SyraColors.textPrimary,
        letterSpacing: 0.1,
      );

  static TextStyle get labelMedium => const TextStyle(
        fontFamily: _uiFamily,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: SyraColors.textPrimary,
        letterSpacing: 0.15,
      );

  static TextStyle get labelSmall => const TextStyle(
        fontFamily: _uiFamily,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: SyraColors.textSecondary,
        letterSpacing: 0.2,
      );

  static TextStyle get caption => const TextStyle(
        fontFamily: _uiFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: SyraColors.textMuted,
        letterSpacing: 0.2,
      );

  static TextStyle get button => const TextStyle(
        fontFamily: _uiFamily,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: SyraColors.textPrimary,
      );

  static TextStyle get overline => const TextStyle(
        fontFamily: _uiFamily,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
        color: SyraColors.textMuted,
      );

  // Logo uses Inter with tight tracking (premium)
  static TextStyle logoStyle({double fontSize = 20}) => TextStyle(
        fontFamily: _uiFamily,
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
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
        fontFamily: 'Inter',

        // ─── Color Scheme ───
        colorScheme: const ColorScheme.dark(
          primary: SyraColors.accent,
          secondary: SyraColors.accentLight,
          surface: SyraColors.surface,
          surfaceContainer: SyraColors.surfaceElevated,
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
          color: SyraColors.surfaceElevated,
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
          fillColor: SyraColors.surfaceElevated,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: SyraSpacing.md,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(SyraRadius.md),
            borderSide: BorderSide.none, // Border kaldırıldı
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(SyraRadius.md),
            borderSide: BorderSide.none,
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
          backgroundColor: SyraColors.surfaceElevated,
          modalBackgroundColor: SyraColors.surfaceElevated,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(SyraRadius.sheet),
            ),
          ),
        ),

        // ─── SnackBar ───
        snackBarTheme: SnackBarThemeData(
          backgroundColor: SyraColors.surfaceElevated,
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
