// lib/theme/syra_glass_tokens.dart

import 'package:flutter/material.dart';

/// Liquid Glass design tokens for SYRA
/// Based on Figma "Liquid Glass button iOS 26 – Bold variant"
/// Adapted to SYRA's dark theme (#0B0D10 background)
class SyraGlassTokens {
  SyraGlassTokens._();

  // ===== BASE COLORS =====
  
  /// Base glass color - adapted from Figma #1D1D1D to fit SYRA's #0B0D10
  /// Slightly lighter than the background for the glass effect
  static const Color glassBase = Color(0xFF141A20);
  
  /// Glass overlay - 20% opacity layer
  static const Color glassOverlay = Color(0x33141A20);
  
  // ===== FIGMA CHAT BAR COLORS =====
  // Extracted from Figma Liquid Glass Chat Bar design
  
  /// Black base - 100% opacity
  static const Color chatBarBlack100 = Color(0xFF000000);
  
  /// Dark gray - 45% opacity (#333333)
  static const Color chatBarGray45 = Color(0x73333333);
  
  /// Light gray - 30% opacity (#999999)
  static const Color chatBarGray30 = Color(0x4D999999);
  
  // ===== WHITE OPACITY VARIANTS =====
  
  /// White at 100% - for brightest highlights
  static const Color white100 = Color(0xFFFFFFFF);
  
  /// White at 40% - for main glass gradient
  static const Color white40 = Color(0x66FFFFFF);
  
  /// White at 20% - for borders and subtle effects
  static const Color white20 = Color(0x33FFFFFF);
  
  /// White at 1-2% - for very subtle inner glow
  static const Color white1 = Color(0x05FFFFFF);
  
  // ===== GLASS GRADIENTS =====
  
  /// Main glass gradient for button surfaces
  /// Combines dark base with white highlights
  static LinearGradient get glassGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          white20, // Top-left highlight
          glassBase.withOpacity(0.6), // Center
          glassBase.withOpacity(0.8), // Bottom-right
        ],
        stops: const [0.0, 0.4, 1.0],
      );
  
  /// Chat bar gradient - Figma-derived layered fills
  /// Creates depth with black, dark gray, and light gray layers
  static LinearGradient get chatBarGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          chatBarGray30, // Top: Light gray highlight
          chatBarGray45, // Middle: Dark gray body
          chatBarBlack100.withOpacity(0.85), // Bottom: Black depth
        ],
        stops: const [0.0, 0.5, 1.0],
      );
  
  /// Subtle inner glow gradient
  static LinearGradient get innerGlowGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          white1,
          Colors.transparent,
        ],
      );
  
  // ===== BORDERS =====
  
  /// Glass border width
  static const double borderWidth = 1.2;
  
  /// Glass border color (white at 20%)
  static Color get borderColor => white20;
  
  // ===== SHADOWS =====
  
  /// Soft shadow for glass elements
  /// Positioned below the element for depth
  static List<BoxShadow> get glassShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.65),
          blurRadius: 22,
          offset: const Offset(0, 10),
          spreadRadius: 0,
        ),
      ];
  
  /// Inner shadows for chat bar - creates depth and bevel effect
  /// Stack of multiple shadows to simulate Figma's layered inner shadows
  static List<BoxShadow> get chatBarInnerShadows => [
        // Top highlight
        BoxShadow(
          color: Colors.white.withOpacity(0.12),
          blurRadius: 3,
          offset: const Offset(0, 1),
          spreadRadius: -1,
        ),
        // Bottom depth
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 6,
          offset: const Offset(0, -2),
          spreadRadius: -2,
        ),
        // Side depth left
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 4,
          offset: const Offset(1, 0),
          spreadRadius: -1,
        ),
        // Side depth right
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 4,
          offset: const Offset(-1, 0),
          spreadRadius: -1,
        ),
      ];
  
  /// Subtle inner shadow for depth (original)
  static List<BoxShadow> get innerShadow => [
        BoxShadow(
          color: Colors.white.withOpacity(0.08),
          blurRadius: 4,
          offset: const Offset(0, 1),
          spreadRadius: -2,
        ),
      ];
  
  // ===== BLUR VALUES =====
  
  /// Backdrop filter blur amount (default)
  static const double blurSigma = 16.0;
  
  /// Chat bar blur - Figma Gaussian blur (20-28 range)
  static const double chatBarBlur = 24.0;
  
  // ===== DIMENSIONS =====
  
  /// Circular button size (Bold variant)
  static const double buttonSize = 48.0;
  
  /// Circular button radius (perfect circle)
  static const double buttonRadius = 24.0;
  
  /// Icon size in circular button
  static const double iconSize = 20.0;
  
  /// Glass bar height (pill shape)
  static const double barHeight = 48.0;
  
  /// Glass bar radius (pill = height / 2)
  static const double barRadius = 24.0;
  
  /// Glass bar horizontal padding
  static const double barPaddingHorizontal = 14.0;
  
  // ===== CHAT BAR DIMENSIONS (Figma-derived) =====
  
  /// Chat bar corner radius - Figma value 54.99 (rounded to 55)
  static const double chatBarRadius = 55.0;
  
  /// Chat bar icon size - Material 3 standard (24×24)
  static const double chatBarIconSize = 24.0;
  
  /// Space between chat bar icons
  static const double chatBarIconSpacing = 12.0;
  
  /// Chat bar vertical padding
  static const double chatBarPaddingVertical = 10.0;
  
  /// Chat bar horizontal padding
  static const double chatBarPaddingHorizontal = 16.0;
  
  // ===== ANIMATION =====
  
  /// Scale animation duration
  static const Duration animationDuration = Duration(milliseconds: 200);
  
  /// Scale animation curve
  static const Curve animationCurve = Curves.easeOutCubic;
  
  /// Scale down value on press (elevated animation)
  static const double scaleDown = 0.92;
  
  /// Scale up value (normal)
  static const double scaleUp = 1.0;
}
