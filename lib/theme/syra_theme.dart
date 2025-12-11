import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════
///  SYRA THEME v3.0 - 2025 AI App Dark Theme
///  Shadow mentor aesthetic: Dark, cool, masculine
///  Background: #0B0E14 (almost black with blue undertone)
///  Accent: #66E0FF (cool premium blue)
/// ═══════════════════════════════════════════════════════════════

class SyraColors {
  // ─────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────
  /// Main scaffold background - SYRA's signature dark
  static const Color background = Color(0xFF0B0E14);
  
  static const Color surface = Color(0xFF11131A);
  
  /// Dividers and hairlines
  static const Color divider = Color(0xFF1A1E24);
  
  static const Color border = Color(0xFF1A1E24);

  static const Color bgTop = background;
  static const Color bgMiddle = background;
  static const Color bgBottom = background;
  static const Color surfaceLight = Color(0xFF16181F);
  static const Color surfaceDark = Color(0xFF0C0F15);

  // ─────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────
  /// Primary text - crisp white
  static const Color textPrimary = Color(0xFFEDEDED);
  
  /// Secondary text - medium grey
  static const Color textSecondary = Color(0xFF9AA0A6);
  
  /// Muted/disabled/hint text
  static const Color textMuted = Color(0xFF5A5F66);
  
  /// Hint text (lightest muted)
  static const Color textHint = Color(0xFF5A5F66);

  // ─────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────
  static const Color accent = Color(0xFF66E0FF);
  
  /// Lighter accent variant
  static const Color accentLight = Color(0xFF8AEAFF);
  
  static const Color accentMuted = Color(0x3366E0FF);

  // ─────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────
  /// Icon stroke/outline color
  static const Color iconStroke = Color(0xFFCFCFCF);
  
  /// Active icon color
  static const Color iconActive = textPrimary;
  
  /// Muted icon color
  static const Color iconMuted = textSecondary;

  // ─────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────
  static const Color syraBubbleBg = surface;
  static const Color userBubbleBg = Color(0xFF16181F);
  static const Color syraBubbleGlow = accent;
  static const Color userBubbleShadow = Color(0xFF000000);

  // ─────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────
  static const Color glassBg = Color(0x3311131A); // 20% opacity surface
  
  /// Glass border
  static const Color glassBorder = divider;
  
  /// Glass highlight
  static const Color glassHighlight = Color(0x1AEDEDED);

  // ─────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────
  static const Color neonPink = accent;
  static const Color neonCyan = accent;
  static const Color neonPinkLight = accentLight;
  static const Color neonCyanLight = accentLight;
  static const Color neonPinkDark = Color(0xFF4DC4E0);
  static const Color neonCyanDark = Color(0xFF4DC4E0);
  static const Color neonViolet = Color(0xFF7AC7E0);

  static const Color logoGoldTop = textPrimary;
  static const Color logoGoldBottom = Color(0xFFCFCFCF);
  static const Color logoGlow = accent;

  // ─────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [background, background, background],
  );

  static const LinearGradient logoGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [logoGoldTop, logoGoldBottom],
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

  // ─────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────
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
// ═══════════════════════════════════════════════════════════════
// ═══════════════════════════════════════════════════════════════
// NOTE: SyraTypography moved to syra_design_tokens.dart
// Use: import '../theme/syra_design_tokens.dart';
// ═══════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════
// ═══════════════════════════════════════════════════════════════
class SyraTheme {
  /// Spacing constants (16-20px as per spec)
  static const double horizontalPadding = 16.0;
  static const double cardRadius = 12.0;
  static const double sheetRadius = 12.0;

  /// Glass blur constants
  static const double glassBlurRadius = 28.0;
  static const double glassOpacity = 0.22;

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: SyraColors.background,
        fontFamily: 'Inter',

        // ─────────────────────────────────────────────────────────────
        // ─────────────────────────────────────────────────────────────
        colorScheme: const ColorScheme.dark(
          primary: SyraColors.accent,
          secondary: SyraColors.accentLight,
          surface: SyraColors.surface,
          surfaceContainer: SyraColors.surface,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: SyraColors.textPrimary,
          outline: SyraColors.border,
        ),

        // ─────────────────────────────────────────────────────────────
        // ─────────────────────────────────────────────────────────────
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(
            color: SyraColors.iconStroke,
            size: 24,
          ),
          titleTextStyle: TextStyle(
            color: SyraColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),

        // ─────────────────────────────────────────────────────────────
        // ─────────────────────────────────────────────────────────────
        cardTheme: CardThemeData(
          color: SyraColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardRadius),
            side: const BorderSide(
              color: SyraColors.border,
              width: 1,
            ),
          ),
        ),

        // ─────────────────────────────────────────────────────────────
        // ─────────────────────────────────────────────────────────────
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: SyraColors.accent,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(cardRadius),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: SyraColors.accent,
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
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
              horizontal: 24,
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(cardRadius),
            ),
          ),
        ),

        // ─────────────────────────────────────────────────────────────
        // ─────────────────────────────────────────────────────────────
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: SyraColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(cardRadius),
            borderSide: const BorderSide(
              color: SyraColors.border,
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(cardRadius),
            borderSide: const BorderSide(
              color: SyraColors.border,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(cardRadius),
            borderSide: const BorderSide(
              color: SyraColors.accent,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(cardRadius),
            borderSide: const BorderSide(
              color: Colors.redAccent,
              width: 1,
            ),
          ),
          hintStyle: const TextStyle(
            color: SyraColors.textMuted,
            fontSize: 15,
          ),
          labelStyle: const TextStyle(
            color: SyraColors.textSecondary,
            fontSize: 14,
          ),
        ),

        // ─────────────────────────────────────────────────────────────
        // ─────────────────────────────────────────────────────────────
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 8,
          ),
          iconColor: SyraColors.iconStroke,
          textColor: SyraColors.textPrimary,
          titleTextStyle: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: SyraColors.textPrimary,
          ),
          subtitleTextStyle: TextStyle(
            fontSize: 13,
            color: SyraColors.textSecondary,
          ),
        ),

        // ─────────────────────────────────────────────────────────────
        // ─────────────────────────────────────────────────────────────
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: SyraColors.surface,
          modalBackgroundColor: SyraColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(sheetRadius),
            ),
          ),
        ),

        // ─────────────────────────────────────────────────────────────
        // ─────────────────────────────────────────────────────────────
        snackBarTheme: SnackBarThemeData(
          backgroundColor: SyraColors.surface,
          contentTextStyle: const TextStyle(
            color: SyraColors.textPrimary,
            fontSize: 14,
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardRadius),
          ),
        ),

        // ─────────────────────────────────────────────────────────────
        // ─────────────────────────────────────────────────────────────
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: SyraColors.accent,
          circularTrackColor: SyraColors.divider,
        ),

        // ─────────────────────────────────────────────────────────────
        // ─────────────────────────────────────────────────────────────
        dividerTheme: const DividerThemeData(
          color: SyraColors.divider,
          thickness: 1,
          space: 1,
        ),

        // ─────────────────────────────────────────────────────────────
        // ─────────────────────────────────────────────────────────────
        iconTheme: const IconThemeData(
          color: SyraColors.iconStroke,
          size: 24,
        ),

        // ─────────────────────────────────────────────────────────────
        // ─────────────────────────────────────────────────────────────
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

        // ─────────────────────────────────────────────────────────────
        // ─────────────────────────────────────────────────────────────
        drawerTheme: const DrawerThemeData(
          backgroundColor: SyraColors.background,
          elevation: 0,
        ),
      );
}
