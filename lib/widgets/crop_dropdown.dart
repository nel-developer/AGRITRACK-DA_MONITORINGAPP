import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/da_colors.dart';

/// Reusable dropdown for crop monitoring forms

class CropDropdown extends StatelessWidget {
  const CropDropdown({
    super.key,
    required this.label,
    required this.hint,
    required this.items,
    this.value,
    this.onChanged,
    this.enabled = true,
    this.showLabel = true,
  });

  final String        label;
  final String        hint;
  final List<String>  items;
  final String?       value;
  final ValueChanged<String?>? onChanged;
  final bool          enabled;
  final bool          showLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel && label.isNotEmpty) ...[
          Text(label,
            style: GoogleFonts.poppins(
              fontSize:   14,
              fontWeight: FontWeight.w700,
              color:      DAColors.textDark,
            )),
          const SizedBox(height: 8),
        ],
        IgnorePointer(
          ignoring: !enabled || items.isEmpty,
          child: Opacity(
            opacity: enabled && items.isNotEmpty ? 1.0 : 0.45,
            child: DropdownButtonFormField<String>(
              initialValue:       items.contains(value) ? value : null,
              isExpanded:  true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: DAColors.textDark, size: 22),
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
                fillColor:   Colors.white,
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
              ),
              items: items.map((item) => DropdownMenuItem(
                value: item,
                child: Text(item,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color:    DAColors.textDark,
                  )),
              )).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}