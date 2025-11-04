import 'package:flutter/material.dart';

class KoraCornerColors {
  KoraCornerColors._();

  static const Color background = Color(0xFF0D0D0D);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color primaryGreen = Color(0xFF80C456);
  static const Color accentGold = Color(0xFFFFC700); // Bright Gold
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB3B3B3); // light gray
}

class KoraCornerDimens {
  KoraCornerDimens._();

  static const double radius = 16.0; // 16px rounded borders
  static const double fieldHeight = 56.0;
  static const double spacing = 16.0;
}

class KoraCornerTheme {
  KoraCornerTheme._();

  static ThemeData themeData = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: KoraCornerColors.background,
    primaryColor: KoraCornerColors.primaryGreen,
    colorScheme: const ColorScheme.dark(
      primary: KoraCornerColors.primaryGreen,
      secondary: KoraCornerColors.accentGold,
      background: KoraCornerColors.background,
      surface: KoraCornerColors.surface,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        color: KoraCornerColors.accentGold,
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
      labelLarge: TextStyle(
        color: KoraCornerColors.background,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      bodyMedium: TextStyle(
        color: KoraCornerColors.textSecondary,
        fontSize: 14,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: KoraCornerColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(KoraCornerDimens.radius),
        borderSide: const BorderSide(color: KoraCornerColors.primaryGreen, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(KoraCornerDimens.radius),
        borderSide: const BorderSide(color: KoraCornerColors.primaryGreen, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(KoraCornerDimens.radius),
        borderSide: const BorderSide(color: KoraCornerColors.primaryGreen, width: 2),
      ),
      hintStyle: const TextStyle(color: KoraCornerColors.textSecondary),
    ),
  );

  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: KoraCornerColors.primaryGreen,
    foregroundColor: KoraCornerColors.background,
    minimumSize: const Size.fromHeight(56),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(KoraCornerDimens.radius),
    ),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
    ),
  );
}
