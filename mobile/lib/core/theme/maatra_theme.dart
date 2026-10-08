import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// MAATRA Design System: Swiss Medical Precision with Subtle Warmth
///
/// Inspired by One Medical & Apple Health:
/// - Warm ivory and porcelain canvas
/// - Deep forest emerald brand trust color
/// - Hairline borders and restrained 14-18px corner radii
/// - Human-centered Plus Jakarta Sans typography
/// - Zero cheap neon gradients, zero fuzzy AI glows
class MaatraTheme {
  // ==========================================
  // 1. SWISS PORCELAIN & WARM IVORY FOUNDATION
  // ==========================================
  static const Color bgIvory = Color(0xFFFAF8F5); // Warm, soothing ivory canvas
  static const Color surfacePorcelain = Color(0xFFFFFFFF); // Pure crisp porcelain card surface
  static const Color surfaceSubtle = Color(0xFFF3EFEA); // Soft warm inset / pill background
  static const Color borderHairline = Color(0xFFE8E2D8); // Ultra-delicate 1px hairline divider
  static const Color borderFocused = Color(0xFF0D483A); // Active brand emerald focus border

  // ==========================================
  // 2. BRAND & CLINICAL TRUST ACCENTS
  // ==========================================
  static const Color brandEmerald = Color(0xFF0D483A); // Deep medical forest emerald
  static const Color brandEmeraldDark = Color(0xFF09362B); // Rich deep obsidian emerald
  static const Color brandEmeraldLight = Color(0xFF165B4A); // Slightly lighter emerald for hover
  static const Color brandSage = Color(0xFF2E6555); // Calm clinical sage
  static const Color brandSageWash = Color(0xFFEBF3F0); // Very soft tint for pills & badges

  // ==========================================
  // 3. HUMAN-CENTERED TYPOGRAPHY (CHARCOAL INK)
  // ==========================================
  static const Color textCharcoal = Color(0xFF1B2421); // Authoritative deep charcoal ink
  static const Color textMuted = Color(0xFF56635F); // Refined slate sage for secondary copy
  static const Color textQuiet = Color(0xFF8A9793); // Soft hint, timestamp, label

  // ==========================================
  // 4. CLINICAL STATUS PALETTE (RESTFUL & PRECISE)
  // ==========================================
  static const Color statusSafe = Color(0xFF1B7A58); // Healthy vitals green
  static const Color statusSafeWash = Color(0xFFE8F5EF);
  static const Color statusWarning = Color(0xFFB46A10); // Warm amber attention
  static const Color statusWarningWash = Color(0xFFFEF5E7);
  static const Color statusAlert = Color(0xFFC53030); // Soft medical terracotta alert
  static const Color statusAlertWash = Color(0xFFFDE8E8);

  // ==========================================
  // 5. BACKWARD-COMPATIBLE ALIASES
  // ==========================================
  static const Color bgDark = bgIvory;
  static const Color surfaceDark = surfacePorcelain;
  static const Color cardDark = surfacePorcelain;
  static const Color inputDark = surfaceSubtle;
  static const Color borderMuted = borderHairline;
  static const Color borderActive = brandEmerald;
  static const Color borderDark = borderHairline;

  static const Color primaryAmethyst = brandEmerald;
  static const Color accentLilac = brandSage;
  static const Color accentLightAmethyst = brandSageWash;
  static const Color deepAmethyst = brandEmeraldDark;
  static const Color amethystGlow = Color(0x1A0D483A);

  static const Color emeraldSuccess = statusSafe;
  static const Color emeraldSafe = statusSafe;
  static const Color amberWarning = statusWarning;
  static const Color crimsonAlert = statusAlert;

  static const Color textPrimary = textCharcoal;
  static const Color textSecondary = textMuted;
  static const Color textTertiary = textQuiet;

  // ==========================================
  // 6. SWISS THEMEDATA DEFINITION
  // ==========================================
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgIvory,
      primaryColor: brandEmerald,
      canvasColor: surfacePorcelain,
      cardColor: surfacePorcelain,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      colorScheme: const ColorScheme.light(
        primary: brandEmerald,
        secondary: brandSage,
        surface: surfacePorcelain,
        error: statusAlert,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textCharcoal,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgIvory,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: textCharcoal),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: textCharcoal,
          fontSize: 19,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceSubtle,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: textQuiet,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: textMuted,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderHairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderHairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: brandEmerald, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: statusAlert),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandEmerald,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfacePorcelain,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderHairline, width: 1.0),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfacePorcelain,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderHairline),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfacePorcelain,
        modalBackgroundColor: surfacePorcelain,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderHairline,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // DarkTheme alias for cohesive rendering
  static ThemeData get darkTheme => lightTheme;
}
