import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static TextTheme get textTheme => GoogleFonts.interTextTheme().copyWith(
    // "Tunely" / "Profile" — títulos grandes
    displayLarge: GoogleFonts.inter(
      fontSize: 28, fontWeight: FontWeight.w700,
    ),
    // "Shared Playlists", "Recent Activity"
    titleLarge: GoogleFonts.inter(
      fontSize: 18, fontWeight: FontWeight.w700,
    ),
    // Nombre de playlist
    titleMedium: GoogleFonts.inter(
      fontSize: 16, fontWeight: FontWeight.w600,
    ),
    // "42 tracks", timestamps
    bodyMedium: GoogleFonts.inter(
      fontSize: 13, fontWeight: FontWeight.w400,
    ),
    // Captions, hints
    bodySmall: GoogleFonts.inter(
      fontSize: 12, fontWeight: FontWeight.w400,
    ),
    // Botón "Continue"
    labelLarge: GoogleFonts.inter(
      fontSize: 16, fontWeight: FontWeight.w600,
    ),
  );
}