import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/da_colors.dart';
import '../../widgets/record_card.dart';

class ApproveModal extends StatelessWidget {
  const ApproveModal({
    super.key,
    required this.record,
    required this.isApprove,
    this.onConfirm,
  });

  final RecordModel record;
  final bool isApprove;
  final VoidCallback? onConfirm;

  List<Map<String, dynamic>> _extractCommodities() {
    final data = record.data ?? {};
    final commodities = (data['completedCommodities'] as List?) ??
        (data['completedBatches'] as List?) ??
        const [];
    return commodities
        .whereType<Map<String, dynamic>>()
        .map((c) => Map<String, dynamic>.from(c))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final botPad = MediaQuery.of(context).padding.bottom;
    final color = isApprove ? DAColors.greenMid : Colors.red;
    final label = isApprove ? 'Approve' : 'Decline';
    final icon =
        isApprove ? Icons.check_circle_outline_rounded : Icons.cancel_outlined;
    final msg = isApprove
        ? 'Mark "${record.name}" as approved. This action cannot be undone.'
        : 'Decline "${record.name}". The profiler will be notified to make corrections.';

    final commodities = _extractCommodities();
    final type = record.productionType.toLowerCase();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon + Title
                  Center(
                    child: Column(
                      children: [
                        Icon(icon, color: color, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          isApprove
                              ? 'Approve this record?'
                              : 'Decline this record?',
                          style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: DAColors.textDark),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          msg,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: DAColors.textMuted),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Record Details
                  Text(
                    'Record Details',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: DAColors.textDark),
                  ),

                  const SizedBox(height: 12),

                  // Summary Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DetailRow('FCA Name', record.name),
                        const SizedBox(height: 8),
                        _DetailRow('Type', record.productionType),
                        const SizedBox(height: 8),
                        _DetailRow(
                            'Implementation',
                            (record.data?['implementationType'] as String?) ??
                                'N/A'),
                      ],
                    ),
                  ),

                  // Commodities Section
                  if (commodities.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      type == 'crop' ? 'Commodities' : 'Batches',
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: DAColors.textDark),
                    ),
                    const SizedBox(height: 8),
                    ...commodities.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final commodity = entry.value;
                      final commodityId =
                          commodity['commodityId']?.toString() ?? '';
                      final isBatch = type == 'livestock' || type == 'poultry';

                      String subtitle = '';
                      if (type == 'crop') {
                        final cropType =
                            (commodity['typeOfCrop'] as String? ?? '').trim();
                        final variety =
                            (commodity['variety'] as String? ?? '').trim();
                        subtitle = [
                          if (cropType.isNotEmpty) cropType,
                          if (variety.isNotEmpty) variety,
                        ].join(' · ');
                      } else {
                        final breed =
                            (commodity['breed'] as String? ?? '').trim();
                        subtitle = breed.isNotEmpty ? breed : 'Batch details';
                      }

                      final title = commodityId.isNotEmpty
                          ? '$commodityId ${isBatch ? '(Batch)' : '(Commodity)'}'
                          : (isBatch
                              ? 'Batch ${idx + 1}'
                              : 'Commodity ${idx + 1}');

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: DAColors.textDark),
                            ),
                            if (subtitle.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: GoogleFonts.poppins(
                                    fontSize: 12, color: DAColors.textMuted),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),

          // Action Buttons
          Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + botPad),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                // Cancel
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50)),
                    ),
                    child: Text('Cancel',
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: DAColors.textMuted)),
                  ),
                ),
                const SizedBox(width: 12),
                // Confirm
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onConfirm?.call();
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
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.poppins(fontSize: 12, color: DAColors.textMuted)),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: DAColors.textDark)),
      ],
    );
  }
}
