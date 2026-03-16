import 'package:flutter/material.dart';

class AppTheme {
  // Palette Navy & Or
  static const Color navyDark = Color(0xFF0A1628);
  static const Color navyMedium = Color(0xFF0D2045);
  static const Color navyLight = Color(0xFF1A3260);
  static const Color navyCard = Color(0xFF162848);

  static const Color gold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFFFD700);
  static const Color goldMuted = Color(0xFFC9A227);

  static const Color textPrimary = Color(0xFFF0F4FF);
  static const Color textSecondary = Color(0xFF8FA3C8);
  static const Color textMuted = Color(0xFF4A6080);

  static const Color success = Color(0xFF00C896);
  static const Color danger = Color(0xFFFF4B6E);
  static const Color error = Color(0xFFFF4B6E); // alias de danger
  static const Color warning = Color(0xFFFFAA33);
  static const Color info = Color(0xFF3B9EFF);

  // Couleurs des catégories d'actifs
  static const Color colorImmobilier = Color(0xFF3B9EFF);
  static const Color colorVehicule = Color(0xFF00C896);
  static const Color colorInvestissement = Color(0xFFD4AF37);
  static const Color colorCreance = Color(0xFFFF8C42);
  static const Color colorAutre = Color(0xFF9B72CF);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: navyDark,
      primaryColor: gold,
      fontFamily: 'Poppins',
      colorScheme: const ColorScheme.dark(
        primary: gold,
        secondary: goldLight,
        surface: navyCard,
        error: danger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: navyDark,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: navyCard,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: navyDark,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: navyMedium,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: navyLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: gold, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textMuted),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: navyMedium,
        selectedItemColor: gold,
        unselectedItemColor: textMuted,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      dividerColor: navyLight,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
            color: textPrimary, fontSize: 32, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(
            color: textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(
            color: textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
        bodyLarge:
            TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.normal),
        bodyMedium:
            TextStyle(color: textSecondary, fontSize: 14, fontWeight: FontWeight.normal),
        bodySmall:
            TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.normal),
        labelLarge: TextStyle(
            color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}
