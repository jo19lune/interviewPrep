import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Tailwind Colors Extracted from Mockup
  static const Color primaryContainer = Color(0xFF001A5E);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryFixedVariant = Color(0xFF2F4285);
  
  static const Color secondaryColor = Color(0xFF4A90E2); // Original secondary
  static const Color secondaryContainer = Color(0xFF68ABFF);
  static const Color onSecondaryContainer = Color(0xFF003E73);
  
  static const Color background = Color(0xFFF7F9FF);
  static const Color surface = Color(0xFFF7F9FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFEDF4FF);
  static const Color onSurface = Color(0xFF091D2E);
  static const Color onSurfaceVariant = Color(0xFF454650);
  
  static const Color outline = Color(0xFF757681);
  static const Color outlineVariant = Color(0xFFC5C5D2);
  
  static const Color error = Color(0xFFBA1A1A);
  
  static const Color tertiaryFixed = Color(0xFF94F990); // Green accent
  static const Color onTertiaryFixedVariant = Color(0xFF005313);

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryContainer,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primaryContainer,
        secondary: secondaryColor,
        surface: surface,
        onPrimary: onPrimary,
        onSecondary: onPrimary,
        onSurface: onSurface,
        error: error,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.manrope(
          color: onSurface, fontWeight: FontWeight.w700, fontSize: 40, letterSpacing: -0.8, height: 1.2,
        ),
        displayMedium: GoogleFonts.manrope(
          color: onSurface, fontWeight: FontWeight.w600, fontSize: 32, letterSpacing: -0.32, height: 1.25,
        ),
        displaySmall: GoogleFonts.manrope(
          color: onSurface, fontWeight: FontWeight.w600, fontSize: 24, height: 1.3,
        ),
        bodyLarge: GoogleFonts.inter(
          color: onSurface, fontWeight: FontWeight.w400, fontSize: 18, height: 1.6,
        ),
        bodyMedium: GoogleFonts.inter(
          color: onSurface, fontWeight: FontWeight.w400, fontSize: 16, height: 1.5,
        ),
        labelLarge: GoogleFonts.inter(
          color: onSurface, fontWeight: FontWeight.w600, fontSize: 14, height: 1.4,
        ),
        bodySmall: GoogleFonts.inter(
          color: onSurfaceVariant, fontWeight: FontWeight.w400, fontSize: 12, height: 1.4,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryContainer,
          foregroundColor: onPrimary,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 2,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          side: const BorderSide(color: outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: outlineVariant, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: secondaryContainer, width: 2.0),
        ),
        labelStyle: GoogleFonts.inter(color: onSurfaceVariant, fontWeight: FontWeight.w600, fontSize: 14),
        hintStyle: GoogleFonts.inter(color: outline, fontSize: 16),
        prefixIconColor: outline,
      ),
    );
  }
}
