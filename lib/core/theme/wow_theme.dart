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

  static const Map<String, Color> _classColors = {
    'warrior': Color(0xFFC79C6E),
    'paladin': Color(0xFFF58CBA),
    'hunter': Color(0xFFABD473),
    'rogue': Color(0xFFFFF569),
    'priest': Color(0xFFFFFFFF),
    'death knight': Color(0xFFC41F3B),
    'shaman': Color(0xFF0070DE),
    'mage': Color(0xFF69CCF0),
    'warlock': Color(0xFF9482C9),
    'monk': Color(0xFF00FF96),
    'druid': Color(0xFFFF7D0A),
    'demon hunter': Color(0xFFA330C9),
    'evoker': Color(0xFF33937F),
  };

  static const Map<String, String> _classAliases = {
    // EN
    'warrior': 'warrior',
    'paladin': 'paladin',
    'hunter': 'hunter',
    'rogue': 'rogue',
    'priest': 'priest',
    'death knight': 'death knight',
    'shaman': 'shaman',
    'mage': 'mage',
    'warlock': 'warlock',
    'monk': 'monk',
    'druid': 'druid',
    'demon hunter': 'demon hunter',
    'evoker': 'evoker',
    // ES
    'guerrero': 'warrior',
    'cazador': 'hunter',
    'picaro': 'rogue',
    'sacerdote': 'priest',
    'caballero de la muerte': 'death knight',
    'chaman': 'shaman',
    'mago': 'mage',
    'brujo': 'warlock',
    'monje': 'monk',
    'druida': 'druid',
    'cazador de demonios': 'demon hunter',
    'evocador': 'evoker',
    // Alias cortos habituales
    'dk': 'death knight',
    'dh': 'demon hunter',
  };

  /// Get color for WoW class.
  /// Soporta nombres canónicos y localizados (ES/EN).
  static Color getClassColor(String className) {
    final normalized = _normalizeClassName(className);
    final canonical = _classAliases[normalized] ?? normalized;
    return _classColors[canonical] ?? Colors.white;
  }

  static String _normalizeClassName(String value) {
    var normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return normalized;

    const replacements = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
    };
    replacements.forEach((from, to) {
      normalized = normalized.replaceAll(from, to);
    });

    normalized = normalized.replaceAll(RegExp(r'[_-]+'), ' ');
    normalized = normalized.replaceAll("'", '');
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');
    return normalized;
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
