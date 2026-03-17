import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'da_colors.dart';

/// All text styles for AgriTrack.
///
/// Brand display  → Bebas Neue  (GoogleFonts.bebasNeue)
/// UI copy        → Poppins     (GoogleFonts.poppins)
///
/// Every method accepts optional [fontSize] and [color] overrides
/// so screens can pass in responsive values from [ResponsiveHelper].
///
/// Usage:
///   Text('AGRI-TRACK', style: DATextStyles.brandDisplay())
///   Text('AGRI-TRACK', style: DATextStyles.brandDisplay(fontSize: r.splashBrandFontSize))
class DATextStyles {
  DATextStyles._();

  // ── Brand display (Bebas Neue) ───────────────────────────────────
  static TextStyle brandDisplay({
    double fontSize      = 34,
    Color  color         = DAColors.white,
    double letterSpacing = 6,
  }) =>
      GoogleFonts.bebasNeue(
        fontSize:      fontSize,
        color:         color,
        letterSpacing: letterSpacing,
      );

  static TextStyle brandSm({
    double fontSize      = 22,
    Color  color         = DAColors.white,
    double letterSpacing = 4,
  }) =>
      GoogleFonts.bebasNeue(
        fontSize:      fontSize,
        color:         color,
        letterSpacing: letterSpacing,
      );

  // ── Poppins headings ─────────────────────────────────────────────
  static TextStyle h1({
    double fontSize = 22,
    Color  color    = DAColors.textDark,
  }) =>
      GoogleFonts.poppins(
        fontSize: fontSize, fontWeight: FontWeight.w700, color: color,
      );

  static TextStyle h2({
    double fontSize = 18,
    Color  color    = DAColors.textDark,
  }) =>
      GoogleFonts.poppins(
        fontSize: fontSize, fontWeight: FontWeight.w600, color: color,
      );

  static TextStyle h3({
    double fontSize = 15,
    Color  color    = DAColors.textDark,
  }) =>
      GoogleFonts.poppins(
        fontSize: fontSize, fontWeight: FontWeight.w600, color: color,
      );

  // ── Poppins body ──────────────────────────────────────────────────
  static TextStyle bodyMd({
    double fontSize = 13,
    Color  color    = DAColors.textDark,
  }) =>
      GoogleFonts.poppins(
        fontSize: fontSize, fontWeight: FontWeight.w400, color: color,
      );

  static TextStyle bodySm({
    double fontSize = 11,
    Color  color    = DAColors.textMuted,
  }) =>
      GoogleFonts.poppins(
        fontSize: fontSize, fontWeight: FontWeight.w400, color: color,
      );

  // ── Labels / captions ────────────────────────────────────────────
  static TextStyle labelMd({
    double fontSize      = 11,
    Color  color         = DAColors.textMid,
    double letterSpacing = 1.2,
  }) =>
      GoogleFonts.poppins(
        fontSize:      fontSize,
        fontWeight:    FontWeight.w600,
        color:         color,
        letterSpacing: letterSpacing,
      );

  static TextStyle labelSm({
    double fontSize      = 9,
    Color  color         = DAColors.textMuted,
    double letterSpacing = 1.5,
  }) =>
      GoogleFonts.poppins(
        fontSize:      fontSize,
        fontWeight:    FontWeight.w600,
        color:         color,
        letterSpacing: letterSpacing,
      );

  // ── Buttons ───────────────────────────────────────────────────────
  static TextStyle buttonPrimary({double fontSize = 13}) =>
      GoogleFonts.poppins(
        fontSize:      fontSize,
        fontWeight:    FontWeight.w700,
        color:         DAColors.white,
        letterSpacing: 2,
      );

  // ── Status badges ─────────────────────────────────────────────────
  static TextStyle badge({double fontSize = 9}) =>
      GoogleFonts.poppins(
        fontSize:      fontSize,
        fontWeight:    FontWeight.w700,
        color:         DAColors.white,
        letterSpacing: 1,
      );

  // ── Form fields ───────────────────────────────────────────────────
  static TextStyle fieldLabel({
    double fontSize = 11,
    Color  color    = DAColors.textMid,
  }) =>
      GoogleFonts.poppins(
        fontSize:      fontSize,
        fontWeight:    FontWeight.w600,
        color:         color,
        letterSpacing: 0.8,
      );

  static TextStyle fieldHint({double fontSize = 13}) =>
      GoogleFonts.poppins(
        fontSize:   fontSize,
        fontWeight: FontWeight.w400,
        color:      DAColors.textMuted,
      );

  static TextStyle fieldValue({double fontSize = 13}) =>
      GoogleFonts.poppins(
        fontSize:   fontSize,
        fontWeight: FontWeight.w400,
        color:      DAColors.textDark,
      );

  // ── Step / form header ────────────────────────────────────────────
  static TextStyle stepTitle({double fontSize = 14}) =>
      GoogleFonts.poppins(
        fontSize:   fontSize,
        fontWeight: FontWeight.w600,
        color:      DAColors.white,
      );

  static TextStyle stepSubtitle({double fontSize = 10}) =>
      GoogleFonts.poppins(
        fontSize:      fontSize,
        fontWeight:    FontWeight.w400,
        color:         DAColors.white.withOpacity(0.7),
        letterSpacing: 0.5,
      );
}