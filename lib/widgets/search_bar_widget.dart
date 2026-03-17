import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/da_colors.dart';

class DASearchBar extends StatelessWidget {
  const DASearchBar({
    super.key,
    required this.controller,
    this.hint = 'Search FCA Name',
  });

  final TextEditingController controller;
  final String                hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.07),
          blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: TextField(
        controller: controller,
        style:      GoogleFonts.poppins(fontSize: 13),
        decoration: InputDecoration(
          hintText:       hint,
          hintStyle:      GoogleFonts.poppins(
            fontSize: 13, color: DAColors.textMuted),
          prefixIcon:     const Icon(Icons.search_rounded,
            color: DAColors.textMuted, size: 22),
          border:         InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}