import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const primary        = Color(0xFF7C4DFF);
  static const primaryLight   = Color(0xFF9C6FFF);
  static const primaryDark    = Color(0xFF5B2FE0);

  // Gradient (logo, avatar)
  static const gradientStart  = Color(0xFF7C4DFF);
  static const gradientEnd    = Color(0xFFE040FB);

  // Sync status
  static const synced         = Color(0xFF00BCD4);
  static const syncing        = Color(0xFF9E9E9E);

  // Light theme
  static const backgroundLight = Color(0xFFF8F7FF);
  static const surfaceLight     = Color(0xFFFFFFFF);
  static const cardLight        = Color(0xFFFFFFFF);
  static const textPrimaryLight = Color(0xFF1A1A2E);
  static const textSecondary    = Color(0xFF9E9E9E);
  static const borderLight      = Color(0xFFE8E4FF);

  // Dark theme
  static const backgroundDark   = Color(0xFF0D1117);
  static const surfaceDark      = Color(0xFF161B27);
  static const cardDark         = Color(0xFF1E2535);
  static const navBarDark       = Color(0xFF1A2033);
  static const textPrimaryDark  = Color(0xFFFFFFFF);

  // Gradients helper
  static const brandGradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}