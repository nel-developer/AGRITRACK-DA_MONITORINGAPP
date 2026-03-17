import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/da_colors.dart';
import '../../widgets/record_card.dart';

class ApproveModal extends StatelessWidget {
  const ApproveModal({
    super.key,
    required this.record,
    required this.isApprove,
  });

  final RecordModel record;
  final bool        isApprove;

  @override
  Widget build(BuildContext context) {
    final botPad = MediaQuery.of(context).padding.bottom;
    final color  = isApprove ? DAColors.greenMid : Colors.red;
    final label  = isApprove ? 'Approve' : 'Decline';
    final icon   = isApprove
        ? Icons.check_circle_outline_rounded
        : Icons.cancel_outlined;
    final msg = isApprove
        ? 'This will mark "${record.name}" as approved. This action cannot be undone.'
        : 'This will decline "${record.name}". The profiler will be notified to make corrections.';

    return Container(
      decoration: const BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, 20 + botPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          // Handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2)),
          ),

          const SizedBox(height: 24),

          Icon(icon, color: color, size: 56),

          const SizedBox(height: 16),

          Text(
            isApprove ? 'Approve this record?' : 'Decline this record?',
            style: GoogleFonts.poppins(
              fontSize: 18, fontWeight: FontWeight.w800,
              color: DAColors.textDark),
          ),

          const SizedBox(height: 10),

          Text(msg,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13, color: DAColors.textMuted),
          ),

          const SizedBox(height: 28),

          Row(
            children: [
              // Cancel
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side:    BorderSide(color: Colors.grey[300]!),
                    shape:   RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50)),
                  ),
                  child: Text('Cancel',
                    style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: DAColors.textMuted)),
                ),
              ),

              const SizedBox(width: 12),

              // Confirm
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                        isApprove ? 'Record approved!' : 'Record declined.',
                        style: GoogleFonts.poppins(fontSize: 12)),
                      backgroundColor: color,
                      behavior: SnackBarBehavior.floating,
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50)),
                  ),
                  child: Text(label,
                    style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}