
import 'package:flutter/material.dart';

class AppColors {
  // Light Mode
  static const Color primaryLight = Color(0xFF7B61FF); // Vivid Violet (profile gradient)
  static const Color secondaryLight = Color(0xFFB388FF); // Soft Lavender
  static const Color accentLight = Color(0xFFFF6B6B); // Warm Alert/Action
  static const Color backgroundLight = Color(0xFFF5F4FF); // Tinted white
  static const Color surfaceLight = Colors.white;
  static const Color textPrimaryLight = Color(0xFF2D2436);
  static const Color textSecondaryLight = Color(0xFF636E72);

  // Dark Mode
  static const Color primaryDark = Color(0xFFC2B4FF); // Softer, more readable violet
  static const Color secondaryDark = Color(0xFFE0D4FF); // Very pale lavender
  static const Color accentDark = Color(0xFFFF9E9E); // Softer Red
  static const Color backgroundDark = Color(0xFF0F0E17); // Deeper purple-black
  static const Color surfaceDark = Color(0xFF161622); // Card surface
  static const Color surfaceVariantDark = Color(0xFF232232); // For inputs/chips
  static const Color textPrimaryDark = Color(0xFFF9F9FB); // Off-white for less eye strain
  static const Color textSecondaryDark = Color(0xFFA7A9BE); 

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFC2B4FF), Color(0xFF9D85FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primaryLight,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      fontFamily: 'Poppins',
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryLight,
        secondary: AppColors.secondaryLight,
        surface: AppColors.surfaceLight,
        error: AppColors.accentLight,
      ),
      textTheme: const TextTheme().apply(
        bodyColor: AppColors.textPrimaryLight,
        displayColor: AppColors.textPrimaryLight,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: AppColors.primaryLight.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primaryDark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      cardColor: AppColors.surfaceDark,
      fontFamily: 'Poppins',
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryDark,
        secondary: AppColors.secondaryDark,
        surface: AppColors.surfaceDark,
        surfaceContainer: AppColors.surfaceVariantDark,
        error: AppColors.accentDark,
        onSurface: AppColors.textPrimaryDark,
        onSurfaceVariant: AppColors.textSecondaryDark,
      ),
      textTheme: const TextTheme().apply(
        bodyColor: AppColors.textPrimaryDark,
        displayColor: AppColors.textPrimaryDark,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: AppColors.backgroundDark,
          elevation: 4,
          shadowColor: AppColors.primaryDark.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariantDark,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryDark, width: 2),
        ),
      ),
    );
  }
}
