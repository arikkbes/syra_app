import 'package:flutter/material.dart';

class FlortIQTheme {
  // 🎨 Premium ana renkler
  static const Color darkBg = Color(0xFF0D0D0D);
  static const Color darkBg2 = Color(0xFF121212);
  static const Color glass = Color(0x15FFFFFF);
  static const Color white = Colors.white;
  static const Color white70 = Colors.white70;

  // 💎 Premium vurgu renkleri
  static const Color pink = Color(0xFFFF7AB8);
  static const Color cyan = Color(0xFF66E0FF);

  // 🌈 Ana gradient (premium kutu)
  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x33FF7AB8),
      Color(0x3366E0FF),
    ],
  );

  // 🧊 Glassmorphism gradient
  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x22FFFFFF),
      Color(0x0FFFFFFF),
    ],
  );

  // 💡 Glow
  static const List<BoxShadow> premiumGlow = [
    BoxShadow(
      color: Color(0x33FF7AB8),
      blurRadius: 20,
      spreadRadius: 1,
      offset: Offset(0, 0),
    ),
    BoxShadow(
      color: Color(0x2266E0FF),
      blurRadius: 20,
      spreadRadius: 1,
      offset: Offset(0, 0),
    ),
  ];

  // 🌫 Soft shadow
  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x66000000),
      blurRadius: 25,
      offset: Offset(0, 8),
    ),
  ];

  // 🎨 Global Theme
  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      fontFamily: "Poppins",

      // 📌 AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // 📌 Butonlar
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: pink,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 6,
          shadowColor: pink.withValues(alpha: 0.4),
        ),
      ),

      // 📌 TextField (Input)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkBg2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: white70.withValues(alpha: 0.15),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: pink, width: 1.3),
        ),
        hintStyle: const TextStyle(
          color: white70,
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          color: white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      // 📌 Text Theme
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: white,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: white,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: TextStyle(
          color: white70,
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          color: white70,
          fontSize: 12,
        ),
      ),

      // 📌 Icon Theme
      iconTheme: const IconThemeData(
        color: white,
        size: 22,
      ),

      // 📌 Card (Yeni API: CardThemeData)
      cardTheme: CardThemeData(
        color: darkBg2,
        elevation: 0,
        margin: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}
