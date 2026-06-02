import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary:          AppColors.primary,
      onPrimary:        Colors.white,
      surface:          AppColors.surfaceLight,
      onSurface:        AppColors.textPrimaryLight,
      surfaceContainer: AppColors.cardLight,
    ),
    scaffoldBackgroundColor: AppColors.backgroundLight,
    textTheme: AppTypography.textTheme,

    // Botón principal pill (Continue, Skip)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor:  AppColors.primary,
        foregroundColor:  Colors.white,
        minimumSize:      const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w600,
        ),
        elevation: 0,
      ),
    ),

    // Cards (playlist cards, service cards)
    cardTheme: CardThemeData(
      color:        AppColors.cardLight,
      elevation:    0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    // Bottom nav
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor:      AppColors.surfaceLight,
      selectedItemColor:    AppColors.primary,
      unselectedItemColor:  AppColors.textSecondary,
      type:                 BottomNavigationBarType.fixed,
      elevation:            8,
    ),
  );

  // ─── DARK ─────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary:          AppColors.primary,
      onPrimary:        Colors.white,
      surface:          AppColors.surfaceDark,
      onSurface:        AppColors.textPrimaryDark,
      surfaceContainer: AppColors.cardDark,
    ),
    scaffoldBackgroundColor: AppColors.backgroundDark,
    textTheme: AppTypography.textTheme.apply(
      bodyColor:        AppColors.textPrimaryDark,
      displayColor:     AppColors.textPrimaryDark,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize:     const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
        ),
        elevation: 0,
      ),
    ),

    cardTheme: CardThemeData(
      color:     AppColors.cardDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor:     AppColors.navBarDark,
      selectedItemColor:   AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      type:                BottomNavigationBarType.fixed,
      elevation:           0,
    ),
  );
}