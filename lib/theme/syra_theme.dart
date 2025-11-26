import 'package:flutter/material.dart';

/// =============================================================
///  SYRA CLASSIC DARK THEME v1.0
///  Stable, elegant, App Store ready
///  Logo-aligned neon gradient (Pink → Cyan)
/// =============================================================

class SyraColors {
  // ─────────────────────────────────────────────────────────────
  // BACKGROUND (Deep dark with subtle blue undertone)
  // ─────────────────────────────────────────────────────────────
  static const Color bgTop = Color(0xFF05050A);
  static const Color bgMiddle = Color(0xFF070A10);
  static const Color bgBottom = Color(0xFF0B0F16);

  /// Global background color shortcut
  static const Color background = bgMiddle;

  // Surface colors
  static const Color surface = Color(0xFF0D1117);
  static const Color surfaceLight = Color(0xFF131920);
  static const Color surfaceGlass = Color(0xFF101418);

  // ─────────────────────────────────────────────────────────────
  // ACCENT COLORS (Logo-aligned: Pink → Cyan)
  // ─────────────────────────────────────────────────────────────
  // Primary Pink (from logo)
  static const Color neonPink = Color(0xFFFF3B8F);
  static const Color neonPinkLight = Color(0xFFFF4FA3);
  static const Color neonPinkDark = Color(0xFFE6357F);

  // Primary Cyan (from logo)
  static const Color neonCyan = Color(0xFF00E5FF);
  static const Color neonCyanLight = Color(0xFF42E4FF);
  static const Color neonCyanDark = Color(0xFF00B8CC);

  // Transition violet
  static const Color neonViolet = Color(0xFFB388FF);

  // ─────────────────────────────────────────────────────────────
  // LOGO GRADIENT (Premium Gold for "SYRA" text)
  // ─────────────────────────────────────────────────────────────
  static const Color logoGoldTop = Color(0xFFF8EBC7);
  static const Color logoGoldBottom = Color(0xFFC1A873);
  static const Color logoGlow = Color(0xFFE8D4A0);

  // ─────────────────────────────────────────────────────────────
  // CHAT BUBBLE COLORS
  // ─────────────────────────────────────────────────────────────
  static const Color syraBubbleBg = Color(0xFF141B22);
  static const Color syraBubbleGlow = Color(0xFF42E4FF);
  static const Color userBubbleBg = Color(0xFF1E2530);
  static const Color userBubbleShadow = Color(0xFF0D1117);

  // ─────────────────────────────────────────────────────────────
  // TEXT COLORS
  // ─────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF5F7FA);
  static const Color textSecondary = Color(0xFFA0A8B5);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF4B5563);

  // ─────────────────────────────────────────────────────────────
  // GLASSMORPHISM
  // ─────────────────────────────────────────────────────────────
  static const Color glassBg = Color(0x0DFFFFFF); // ~5% white
  static const Color glassBorder = Color(0xFF1F2937);
  static const Color glassHighlight = Color(0x14FFFFFF); // ~8% white

  // ─────────────────────────────────────────────────────────────
  // GRADIENTS
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

  /// Primary accent gradient (Pink → Cyan, logo-aligned)
  static const LinearGradient accentGradient = LinearGradient(
    colors: [neonPink, neonCyan],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Orb gradient (matches logo ring)
  static const LinearGradient orbGradient = LinearGradient(
    colors: [neonPink, neonCyan],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  // ─────────────────────────────────────────────────────────────
  // GLOW EFFECTS (Subtle, not harsh)
  // ─────────────────────────────────────────────────────────────
  static List<BoxShadow> orbIdleGlow() => [
        BoxShadow(
          color: neonPink.withValues(alpha: 0.18),
          blurRadius: 25,
          spreadRadius: 4,
        ),
        BoxShadow(
          color: neonCyan.withValues(alpha: 0.12),
          blurRadius: 35,
          spreadRadius: 6,
        ),
      ];

  static List<BoxShadow> orbThinkingGlow() => [
        BoxShadow(
          color: neonPink.withValues(alpha: 0.35),
          blurRadius: 40,
          spreadRadius: 8,
        ),
        BoxShadow(
          color: neonCyan.withValues(alpha: 0.25),
          blurRadius: 50,
          spreadRadius: 12,
        ),
        BoxShadow(
          color: neonPink.withValues(alpha: 0.15),
          blurRadius: 70,
          spreadRadius: 20,
        ),
      ];

  static List<BoxShadow> bubbleGlow({double intensity = 0.025}) => [
        BoxShadow(
          color: neonCyanLight.withValues(alpha: intensity),
          blurRadius: 16,
          spreadRadius: 1,
        ),
      ];

  static List<BoxShadow> cardGlow() => [
        BoxShadow(
          color: neonPink.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: neonCyan.withValues(alpha: 0.06),
          blurRadius: 25,
          offset: const Offset(0, 6),
        ),
      ];
}

// ═══════════════════════════════════════════════════════════════
// TYPOGRAPHY
// ═══════════════════════════════════════════════════════════════
class SyraTypography {
  static const String logoFont = "Georgia";
  static const String mainFont = "SF Pro Display";
  static const String fallbackFont = ".SF UI Text";

  static TextStyle logoStyle({double fontSize = 22}) => TextStyle(
        fontFamily: logoFont,
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        letterSpacing: fontSize * 0.45,
        color: SyraColors.textPrimary,
      );

  static const TextStyle messageText = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.45,
    letterSpacing: 0.1,
    color: SyraColors.textPrimary,
  );

  static const TextStyle timeText = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    color: SyraColors.textMuted,
  );

  static const TextStyle headingLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
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
          primary: SyraColors.neonCyan,
          secondary: SyraColors.neonPink,
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
            side: const BorderSide(color: SyraColors.glassBorder),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: SyraColors.neonCyan,
            foregroundColor: SyraColors.background,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: SyraColors.neonCyan,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: SyraColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: SyraColors.glassBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: SyraColors.glassBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: SyraColors.neonCyan),
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
          color: SyraColors.neonCyan,
        ),
        dividerTheme: DividerThemeData(
          color: SyraColors.glassBorder.withValues(alpha: 0.5),
          thickness: 0.5,
        ),
      );
}
