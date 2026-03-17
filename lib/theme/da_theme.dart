import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'da_colors.dart';

/// Main ThemeData configuration for AgriTrack.
/// Applied in app.dart via MaterialApp(theme: DATheme.light).
class DATheme {
  DATheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,

      // ── Color scheme ──────────────────────────────────────────────
      colorScheme: ColorScheme.fromSeed(
        seedColor:  DAColors.greenMid,
        primary:    DAColors.greenMid,
        secondary:  DAColors.amber,
        surface:    DAColors.white,
      ),

      // ── Base font ─────────────────────────────────────────────────
      textTheme: GoogleFonts.poppinsTextTheme(),
      scaffoldBackgroundColor: DAColors.offWhite,

      // ── AppBar ────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor:  DAColors.greenDark,
        foregroundColor:  DAColors.white,
        elevation:        0,
        centerTitle:      false,
        titleTextStyle:   GoogleFonts.poppins(
          fontSize:     16,
          fontWeight:   FontWeight.w600,
          color:        DAColors.white,
        ),
        iconTheme: const IconThemeData(color: DAColors.white),
      ),

      // ── ElevatedButton ────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DAColors.greenMid,
          foregroundColor: DAColors.white,
          minimumSize:     const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          textStyle: GoogleFonts.poppins(
            fontSize:      13,
            fontWeight:    FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      ),

      // ── OutlinedButton ────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DAColors.greenMid,
          side: const BorderSide(color: DAColors.greenMid, width: 1.5),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize:   13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── TextButton ────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: DAColors.greenMid,
          textStyle: GoogleFonts.poppins(
            fontSize:   13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── InputDecoration ───────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled:          true,
        fillColor:       DAColors.offWhite,
        contentPadding:  const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: DAColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: DAColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: DAColors.greenMid, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: Colors.red, width: 1.5),
        ),
        labelStyle: GoogleFonts.poppins(
          fontSize: 12, color: DAColors.textMuted,
        ),
        hintStyle: GoogleFonts.poppins(
          fontSize: 13, color: DAColors.textMuted,
        ),
        errorStyle: GoogleFonts.poppins(
          fontSize: 11, color: Colors.red,
        ),
      ),

      // ── BottomNavigationBar ───────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor:       DAColors.white,
        selectedItemColor:     DAColors.greenMid,
        unselectedItemColor:   DAColors.textMuted,
        elevation:             8,
        type:                  BottomNavigationBarType.fixed,
        selectedLabelStyle:    GoogleFonts.poppins(
          fontSize: 10, fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle:  GoogleFonts.poppins(fontSize: 10),
      ),

      // ── Card ──────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color:       DAColors.white,
        elevation:   2,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Divider ───────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color:     DAColors.border,
        thickness: 1,
        space:     1,
      ),

      // ── Chip ──────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor:  DAColors.greenPale,
        labelStyle:       GoogleFonts.poppins(
          fontSize: 11, fontWeight: FontWeight.w500, color: DAColors.greenMid,
        ),
        side:       BorderSide.none,
        shape:      RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
    );
  }
}