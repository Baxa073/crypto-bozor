import 'package:flutter/material.dart';

class AppTheme {
  // Main Colors
  static const Color primaryColor = Color(0xFF0A84FF); // Blue
  static const Color secondaryColor = Color(0xFF1C1C1E); // Dark
  static const Color accentColor = Color(0xFFFF9500); // Orange Accent

  // Gradient for background
  static const Color backgroundColorStart = Color(0xFF191B20); // Dark gradient start
  static const Color backgroundColorEnd = Color(0xFF0A84FF); // Blue gradient end

  static const Color cardColor = Color(0xFF191B20); // Card background
  static const Color errorColor = Color(0xFFFF3B30); // Red for errors

  // Text Colors
  static const Color textPrimaryColor = Color(0xFFFFFFFF); // White text
  static const Color textSecondaryColor = Color(0xFF8E8E93); // Secondary gray text

  // General App Style
  static ThemeData get themeData {
    return ThemeData(
      primaryColor: primaryColor,
      colorScheme: ColorScheme(
        primary: primaryColor,
        secondary: accentColor,
        surface: cardColor,
        background: backgroundColorStart,
        error: errorColor,
        onPrimary: textPrimaryColor,
        onSecondary: textPrimaryColor,
        onSurface: textPrimaryColor,
        onBackground: textPrimaryColor,
        onError: textPrimaryColor,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: Colors.transparent, // Transparent for gradient background
      cardColor: cardColor,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textPrimaryColor,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(color: textPrimaryColor, fontSize: 32, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: textPrimaryColor, fontSize: 24, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: textPrimaryColor, fontSize: 16),
        bodyMedium: TextStyle(color: textSecondaryColor, fontSize: 14),
        titleMedium: TextStyle(color: textPrimaryColor, fontSize: 18),
        titleSmall: TextStyle(color: textSecondaryColor, fontSize: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: textPrimaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 5,
        ),
      ),
    );
  }
}
