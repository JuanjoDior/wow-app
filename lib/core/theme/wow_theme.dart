import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WowTheme {
  WowTheme._();

  // WoW-inspired color palette
  static const Color primaryGold = Color(0xFFFFD100);
  static const Color darkBackground = Color(0xFF1A1A2E);
  static const Color surfaceDark = Color(0xFF16213E);
  static const Color surfaceLight = Color(0xFF0F3460);
  static const Color accentBlue = Color(0xFF53A8E2);
  static const Color accentRed = Color(0xFFE94560);
  static const Color textPrimary = Color(0xFFE8E8E8);
  static const Color textSecondary = Color(0xFFA0A0B0);
  static const Color border = Color(0xFF2A2A4A);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: primaryGold,
        secondary: accentBlue,
        surface: surfaceDark,
        error: accentRed,
        onPrimary: darkBackground,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        outline: border,
      ),
      textTheme: GoogleFonts.notoSansTextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor: textPrimary, displayColor: textPrimary),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceDark,
        foregroundColor: primaryGold,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGold, width: 2),
        ),
        hintStyle: const TextStyle(color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: darkBackground,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
    );
  }

  /// Get color for WoW class
  static Color getClassColor(String className) {
    final colors = {
      'warrior': const Color(0xFFC79C6E),
      'paladin': const Color(0xFFF58CBA),
      'hunter': const Color(0xFFABD473),
      'rogue': const Color(0xFFFFF569),
      'priest': const Color(0xFFFFFFFF),
      'death knight': const Color(0xFFC41F3B),
      'shaman': const Color(0xFF0070DE),
      'mage': const Color(0xFF69CCF0),
      'warlock': const Color(0xFF9482C9),
      'monk': const Color(0xFF00FF96),
      'druid': const Color(0xFFFF7D0A),
      'demon hunter': const Color(0xFFA330C9),
      'evoker': const Color(0xFF33937F),
    };
    return colors[className.toLowerCase()] ?? Colors.white;
  }

  /// Get color for item quality
  static Color getQualityColor(String quality) {
    final colors = {
      'POOR': const Color(0xFF9D9D9D),
      'COMMON': const Color(0xFFFFFFFF),
      'UNCOMMON': const Color(0xFF1EFF00),
      'RARE': const Color(0xFF0070DD),
      'EPIC': const Color(0xFFA335EE),
      'LEGENDARY': const Color(0xFFFF8000),
    };
    return colors[quality.toUpperCase()] ?? Colors.white;
  }
}
