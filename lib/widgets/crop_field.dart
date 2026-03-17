import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/da_colors.dart';

/// Reusable text field for crop monitoring forms

class CropField extends StatelessWidget {
  const CropField({
    super.key,
    required this.label,
    required this.hint,
    this.initialValue,
    this.onChanged,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.enabled = true,
    this.inputFormatters,
  });

  final String              label;
  final String              hint;
  final String?             initialValue;
  final ValueChanged<String>? onChanged;
  final TextInputType       keyboardType;
  final int                 maxLines;
  final bool                enabled;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
          style: GoogleFonts.poppins(
            fontSize:   14,
            fontWeight: FontWeight.w700,
            color:      DAColors.textDark,
          )),
        const SizedBox(height: 8),
        TextFormField(
          initialValue:    initialValue,
          onChanged:       onChanged,
          keyboardType:    keyboardType,
          maxLines:        maxLines,
          enabled:         enabled,
          inputFormatters: inputFormatters,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color:    DAColors.textDark,
          ),
          decoration: InputDecoration(
            hintText:  hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 14,
              color:    DAColors.textMuted,
            ),
            filled:      true,
            fillColor:   enabled ? Colors.white : const Color(0xFFF5F5F5),
            isDense:     true,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                  color: Color(0xFFDDDDDD), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                  color: Color(0xFFDDDDDD), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                  color: DAColors.greenMid, width: 2.0),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                  color: Color(0xFFEEEEEE), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}