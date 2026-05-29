import 'package:flutter/material.dart';

// Application color constants matching the Tailwind configuration of the WebApp
class AppColors {
  static const Color primary = Color(0xFFB3E600); // Neon Lime
  static const Color primaryHover = Color(0xFFA2D000); // Darker Lime
  static const Color background = Color(0xFF121212); // Default background
  static const Color backgroundDarker = Color(0xFF0A0A0A); // Sub-sections background
  static const Color surface = Color(0xFF1E1E1E); // Dark surface/card
  static const Color surfaceInner = Color(0xFF111714); // Dark-green/black inner container
  static const Color surfaceInput = Color(0xFF2A2A2A); // Active input background
  static const Color textLight = Color(0xFF111714); // Dark text on light background
  static const Color textDark = Color(0xFFFFFFFF); // White text on dark background
  static const Color textMuted = Color(0xFF9CA3AF); // Muted grey
  static const Color textMutedGreenish = Color(0xFF9EB7A8); // Muted slate green/grey
  
  static const Color border = Color(0x1AFFFFFF); // white with 10% opacity (border-white/10)
  static const Color borderSubtle = Color(0x0DFFFFFF); // white with 5% opacity (border-white/5)
  static const Color shadowGlow = Color(0x4DB3E600); // Neon Lime shadow glow
}

class AppTheme {
  // Configures the global dark ThemeData with visual settings mirroring the WebApp
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'SplineSans',
      scaffoldBackgroundColor: AppColors.background,
      
      // Configure default color scheme mapping standard properties
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.textLight,
        primaryContainer: AppColors.primaryHover,
        surface: AppColors.background,
        onSurface: AppColors.textDark,
        onSurfaceVariant: AppColors.textMuted,
        outline: AppColors.border,
      ),

      // Custom card styling matching "bg-surface-dark border border-white/5 rounded-2xl"
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.borderSubtle, width: 1.0),
          borderRadius: BorderRadius.circular(16.0), // 1rem
        ),
      ),

      // AppBar styling resembling the headers/navs
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'SplineSans',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
        iconTheme: IconThemeData(color: AppColors.textDark),
      ),

      // Custom buttons matching the WebApp pill style buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textLight,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.3),
          disabledForegroundColor: AppColors.textLight.withOpacity(0.5),
          shadowColor: AppColors.primary.withOpacity(0.4),
          elevation: 8,
          textStyle: const TextStyle(
            fontFamily: 'SplineSans',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9999), // rounded-full
          ),
        ),
      ),

      // TextButton configuration for secondary interactions
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textDark,
          textStyle: const TextStyle(
            fontFamily: 'SplineSans',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Styled text field borders/colors matching the form input themes
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceInput,
        hintStyle: TextStyle(
          color: AppColors.textMuted.withOpacity(0.5),
          fontFamily: 'SplineSans',
          fontSize: 15,
        ),
        prefixIconColor: AppColors.textMuted,
        suffixIconColor: AppColors.textMuted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: AppColors.border, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: AppColors.border, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: AppColors.primary, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2.0),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 13),
      ),
    );
  }
}
