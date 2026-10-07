import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// MAATRA Theme System: Option 2 - "Midnight Slate & Royal Amethyst"
/// Ultra-premium luxury aesthetic with Plus Jakarta Sans typography.
class MaatraTheme {
  // Midnight Slate & Royal Amethyst Palette
  static const Color bgDark = Color(0xFF0B0F19); // Void Midnight Slate
  static const Color surfaceDark = Color(0xFF111827); // Obsidian Card
  static const Color cardDark = Color(0xFF161F30); // Elevated Card
  static const Color inputDark = Color(0xFF1F293D); // Pill / Input Fill
  static const Color borderMuted = Color(0xFF2A344A); // Elegant border
  static const Color borderActive = Color(0xFF8B5CF6); // Focus amethyst

  // Amethyst Accents
  static const Color primaryAmethyst = Color(0xFF8B5CF6); // Vivid Royal Amethyst
  static const Color accentLilac = Color(0xFFA78BFA); // Electric Lilac
  static const Color accentLightAmethyst = Color(0xFFC4B5FD); // Light Pastel Amethyst
  static const Color deepAmethyst = Color(0xFF6D28D9); // Deep Velvet Violet
  static const Color amethystGlow = Color(0x338B5CF6); // Soft glow overlay
  static const Color borderDark = Color(0xFF1F2937); // Dark Slate border

  // Status & Utility Accents
  static const Color emeraldSuccess = Color(0xFF10B981);
  static const Color emeraldSafe = Color(0xFF10B981);
  static const Color amberWarning = Color(0xFFF59E0B);
  static const Color crimsonAlert = Color(0xFFEF4444);

  // Typography Palette
  static const Color textPrimary = Color(0xFFF9FAFB); // Crisp Ivory
  static const Color textSecondary = Color(0xFF9CA3AF); // Cool Slate Lavender
  static const Color textTertiary = Color(0xFF64748B); // Muted Timestamp/Hint

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      primaryColor: primaryAmethyst,
      canvasColor: surfaceDark,
      cardColor: surfaceDark,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: primaryAmethyst,
        secondary: accentLilac,
        surface: surfaceDark,
        error: crimsonAlert,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: textTertiary,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: textSecondary,
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderMuted),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderMuted),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryAmethyst, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: crimsonAlert),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryAmethyst,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderMuted),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderMuted),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceDark,
        modalBackgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}
