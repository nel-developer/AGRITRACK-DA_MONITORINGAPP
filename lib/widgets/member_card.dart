import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/da_colors.dart';

// ── Member model ──────────────────────────────────────────────────
class MemberModel {
  final String name;
  final String status; // not_monitored / in_progress / completed

  const MemberModel({required this.name, required this.status});
}

// ── Member card ───────────────────────────────────────────────────
class MemberCard extends StatelessWidget {
  const MemberCard({
    super.key,
    required this.member,
    required this.onAction,
  });

  final MemberModel  member;
  final VoidCallback onAction;

  Color get _statusColor {
    switch (member.status) {
      case 'completed':      return DAColors.greenMid;
      case 'in_progress':    return const Color(0xFFFFB300);
      case 'not_monitored':
      default:               return const Color(0xFF9E9E9E);
    }
  }

  String get _statusLabel {
    switch (member.status) {
      case 'completed':      return 'Completed';
      case 'in_progress':    return 'In Progress';
      case 'not_monitored':
      default:               return 'Not Monitored';
    }
  }

  String get _btnLabel {
    switch (member.status) {
      case 'completed':      return 'View Record';
      case 'in_progress':    return 'Continue Monitoring';
      case 'not_monitored':
      default:               return 'Start Monitoring';
    }
  }

  Color get _btnColor {
    switch (member.status) {
      case 'completed':   return DAColors.greenMid;
      case 'in_progress': return const Color(0xFFFFB300);
      default:            return const Color(0xFF9E9E9E);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // Colored left bar by status
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: _statusColor,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(14)),
              ),
            ),

            // Card content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                child: Row(
                  children: [

                    // Name + status badge
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment:  MainAxisAlignment.center,
                        children: [
                          Text(member.name,
                            style: GoogleFonts.poppins(
                              fontSize: 15, fontWeight: FontWeight.w700,
                              color: DAColors.textDark),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color:        _statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(color: _statusColor, width: 1.2),
                            ),
                            child: Text(_statusLabel,
                              style: GoogleFonts.poppins(
                                fontSize: 11, fontWeight: FontWeight.w600,
                                color: _statusColor),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Action button
                    GestureDetector(
                      onTap: onAction,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color:        _btnColor,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(_btnLabel,
                          style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w700,
                            color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}