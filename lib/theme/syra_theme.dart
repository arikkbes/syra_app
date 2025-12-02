import 'package:flutter/material.dart';

/// =============================================================
///  SYRA MODERN THEME v2.0 - ChatGPT 2025 Style
///  Deep blue background (#072233) + Clean white text (#FEFEFE)
///  Minimal, elegant, lots of negative space
/// =============================================================

class SyraColors {
  // ─────────────────────────────────────────────────────────────
  // BACKGROUND - Deep blue (main app background)
  // ─────────────────────────────────────────────────────────────
  static const Color background = Color(0xFF072233);
  static const Color bgTop = Color(0xFF072233);
  static const Color bgMiddle = Color(0xFF072233);
  static const Color bgBottom = Color(0xFF061A29);

  // Surface colors (slightly lighter/darker variants)
  static const Color surface = Color(0xFF0A2D42);
  static const Color surfaceLight = Color(0xFF0D3650);
  static const Color surfaceDark = Color(0xFF051B2A);

  // ─────────────────────────────────────────────────────────────
  // TEXT COLORS
  // ─────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFFEFEFE);
  static const Color textSecondary = Color(0xB3FEFEFE); // 70% opacity
  static const Color textMuted = Color(0x80FEFEFE); // 50% opacity
  static const Color textHint = Color(0x4DFEFEFE); // 30% opacity

  // ─────────────────────────────────────────────────────────────
  // ACCENT COLOR (subtle, cold neutral)
  // ─────────────────────────────────────────────────────────────
  static const Color accent = Color(0xFF5B9BD5); // Subtle blue accent
  static const Color accentLight = Color(0xFF7EB3E8);
  static const Color accentMuted = Color(0x4D5B9BD5); // 30% opacity

  // ─────────────────────────────────────────────────────────────
  // NEUTRAL GREYS for dividers, icons, status
  // ─────────────────────────────────────────────────────────────
  static const Color divider = Color(0xFF1A3A4F);
  static const Color border = Color(0xFF1E4460);
  static const Color iconMuted = Color(0xFF6B8A9E);
  static const Color iconActive = Color(0xFFFEFEFE);

  // ─────────────────────────────────────────────────────────────
  // CHAT BUBBLE COLORS (ChatGPT style - minimal)
  // ─────────────────────────────────────────────────────────────
  static const Color syraBubbleBg = Color(0xFF0A2D42);
  static const Color userBubbleBg = Color(0xFF1A4A65);
  static const Color syraBubbleGlow = Color(0xFF5B9BD5);
  static const Color userBubbleShadow = Color(0xFF051B2A);
  
  // ─────────────────────────────────────────────────────────────
  // GLASSMORPHISM (subtle, not heavy)
  // ─────────────────────────────────────────────────────────────
  static const Color glassBg = Color(0x0DFEFEFE); // ~5% white
  static const Color glassBorder = Color(0xFF1E4460);
  static const Color glassHighlight = Color(0x14FEFEFE); // ~8% white

  // ─────────────────────────────────────────────────────────────
  // LEGACY COLORS (kept for backward compatibility)
  // ─────────────────────────────────────────────────────────────
  static const Color neonPink = Color(0xFF5B9BD5); // Remapped to accent
  static const Color neonCyan = Color(0xFF5B9BD5); // Remapped to accent
  static const Color neonPinkLight = Color(0xFF7EB3E8);
  static const Color neonCyanLight = Color(0xFF7EB3E8);
  static const Color neonPinkDark = Color(0xFF4A8BC5);
  static const Color neonCyanDark = Color(0xFF4A8BC5);
  static const Color neonViolet = Color(0xFF7B9FB8);

  // Logo colors (now use white)
  static const Color logoGoldTop = Color(0xFFFEFEFE);
  static const Color logoGoldBottom = Color(0xFFD0D0D0);
  static const Color logoGlow = Color(0xFFFEFEFE);

  // ─────────────────────────────────────────────────────────────
  // GRADIENTS (minimal, subtle)
  // ─────────────────────────────────────────────────────────────
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgTop, bgMiddle, bgBottom],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient logoGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [logoGoldTop, logoGoldBottom],
  );

  /// Primary accent gradient (subtle)
  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentLight],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Legacy orb gradient (now subtle accent)
  static const LinearGradient orbGradient = LinearGradient(
    colors: [accent, accentLight],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  // ─────────────────────────────────────────────────────────────
  // SHADOWS (minimal)
  // ─────────────────────────────────────────────────────────────
  static List<BoxShadow> orbIdleGlow() => [];
  static List<BoxShadow> orbThinkingGlow() => [];
  static List<BoxShadow> bubbleGlow({double intensity = 0.025}) => [];
  static List<BoxShadow> cardGlow() => [];

  // Subtle shadows for cards
  static List<BoxShadow> subtleShadow() => [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}

// ═══════════════════════════════════════════════════════════════
// TYPOGRAPHY
// ═══════════════════════════════════════════════════════════════
class SyraTypography {
  static const String logoFont = "SF Pro Display";
  static const String mainFont = "SF Pro Display";
  static const String fallbackFont = ".SF UI Text";

  static TextStyle logoStyle({double fontSize = 22}) => TextStyle(
        fontFamily: logoFont,
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: fontSize * 0.15,
        color: SyraColors.textPrimary,
      );

  static const TextStyle messageText = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.1,
    color: SyraColors.textPrimary,
  );

  static const TextStyle timeText = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    color: SyraColors.textMuted,
  );

  static const TextStyle headingLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: SyraColors.textPrimary,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: SyraColors.textPrimary,
  );

  static const TextStyle bodyText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: SyraColors.textSecondary,
  );
}

// ═══════════════════════════════════════════════════════════════
// MAIN THEME
// ═══════════════════════════════════════════════════════════════
class SyraTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: SyraColors.background,
        fontFamily: SyraTypography.fallbackFont,
        colorScheme: const ColorScheme.dark(
          primary: SyraColors.accent,
          secondary: SyraColors.accentLight,
          surface: SyraColors.surface,
          onPrimary: SyraColors.textPrimary,
          onSecondary: SyraColors.textPrimary,
          onSurface: SyraColors.textPrimary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: SyraColors.textPrimary),
          titleTextStyle: TextStyle(
            color: SyraColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: CardThemeData(
          color: SyraColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: SyraColors.border),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: SyraColors.accent,
            foregroundColor: SyraColors.textPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: SyraColors.accent,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: SyraColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: SyraColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: SyraColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: SyraColors.accent),
          ),
          hintStyle: const TextStyle(color: SyraColors.textHint),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: SyraColors.surface,
          contentTextStyle: const TextStyle(color: SyraColors.textPrimary),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: SyraColors.accent,
        ),
        dividerTheme: const DividerThemeData(
          color: SyraColors.divider,
          thickness: 0.5,
        ),
      );
}
