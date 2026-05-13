import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/da_colors.dart';

// ── Data model ────────────────────────────────────────────────────
class RecordModel {
  final String? id;
  final String name;
  final String productionType;
  final String implType; // Collective / Individual / Hybrid
  final String enumerator;
  final String date;
  final String status; // unsync / pending / approved
  final String? documentPath;
  final Map<String, dynamic>? data;
  final bool isLocal;

  const RecordModel({
    this.id,
    required this.name,
    required this.productionType,
    required this.implType,
    required this.enumerator,
    required this.date,
    required this.status,
    this.documentPath,
    this.data,
    this.isLocal = false,
  });
}

// ── Status color helper ───────────────────────────────────────────
Color statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'unsync':
      return const Color(0xFF9E9E9E);
    case 'pending':
      return const Color(0xFFFFB300);
    case 'approved':
      return DAColors.greenMid;
    default:
      return DAColors.greenMid;
  }
}

// ── Record card ───────────────────────────────────────────────────
class RecordCard extends StatelessWidget {
  const RecordCard({
    super.key,
    required this.record,
    required this.tabColor,
    this.showEdit = false,
    this.showSync = false,
    this.showApprove = false,
    this.approveLocked = false,
    required this.onTap,
    this.onDelete,
  });

  final RecordModel record;
  final Color tabColor;
  final bool showEdit;
  final bool showSync;
  final bool showApprove;
  final bool approveLocked;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Colored left status bar
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: tabColor,
                  borderRadius:
                      const BorderRadius.horizontal(left: Radius.circular(14)),
                ),
              ),

              // Card body
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + View button
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              record.name,
                              style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: DAColors.textDark),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: onTap,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 8),
                              decoration: BoxDecoration(
                                color: DAColors.greenMid,
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Text(
                                'View',
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Production | Impl type
                      Row(
                        children: [
                          Text(record.productionType,
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: DAColors.textMuted)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text('|',
                                style: GoogleFonts.poppins(
                                    fontSize: 13, color: DAColors.textMuted)),
                          ),
                          Text(record.implType,
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: DAColors.textDark)),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Date chip + Enumerator / Sync user + Delete button
                      Row(
                        children: [
                          if (record.status.toLowerCase() == 'unsync')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEEEEE),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_month_outlined,
                                      size: 13, color: Color(0xFF666666)),
                                  const SizedBox(width: 4),
                                  Text(record.date,
                                      style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: const Color(0xFF666666))),
                                ],
                              ),
                            ),
                          if (record.status.toLowerCase() == 'unsync')
                            const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              record.status.toLowerCase() == 'unsync'
                                  ? 'Enumerator: ${record.enumerator}'
                                  : 'Synced by: ${record.enumerator}',
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: DAColors.textDark),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (record.status.toLowerCase() == 'unsync' &&
                              onDelete != null)
                            GestureDetector(
                              onTap: onDelete,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.delete_outline,
                                    size: 18, color: Colors.red),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
