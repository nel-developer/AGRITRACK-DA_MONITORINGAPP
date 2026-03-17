import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/da_colors.dart';
import '../../widgets/record_card.dart';
import 'record_edit_modal.dart';
import 'approve_modal.dart';

class RecordViewModal extends StatelessWidget {
  const RecordViewModal({
    super.key,
    required this.record,
    this.memberName,
    this.isGroup       = false,
    this.showEdit      = false,
    this.showSync      = false,
    this.showApprove   = false,
    this.approveLocked = false,
  });

  final RecordModel record;
  final String?     memberName;   // null = collective view
  final bool        isGroup;      // true = group/FCA record view
  final bool        showEdit;
  final bool        showSync;
  final bool        showApprove;
  final bool        approveLocked;

  void _openEdit(BuildContext context) {
    Navigator.pop(context);
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => RecordEditModal(record: record),
    );
  }

  void _openApprove(BuildContext context, bool isApprove) {
    Navigator.pop(context);
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => ApproveModal(record: record, isApprove: isApprove),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final botPad  = MediaQuery.of(context).padding.bottom;
    final type    = record.productionType.toLowerCase();

    return Container(
      height: screenH * 0.88,
      decoration: const BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(children: [

        // Handle
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 40, height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2)),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
          child: Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isGroup
                      ? '${record.name} — Group Record'
                      : (memberName ?? record.name),
                  style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w800,
                    color: DAColors.textDark)),
                const SizedBox(height: 2),
                Row(children: [
                  _TypeChip(label: record.productionType),
                  const SizedBox(width: 6),
                  _TypeChip(label: record.implType),
                ]),
              ],
            )),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded, color: Colors.grey)),
          ]),
        ),

        Divider(color: Colors.grey[200], height: 16),

        // Scrollable body
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (type == 'crop')     _CropFields()
                else if (type == 'livestock') _LivestockFields()
                else                    _PoultryFields(),
              ],
            ),
          ),
        ),

        // Footer buttons
        _buildFooter(context, botPad),
      ]),
    );
  }

  Widget _buildFooter(BuildContext context, double botPad) {
    final deco = BoxDecoration(
      color:  Colors.white,
      border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
    );

    if (showEdit && !showSync && !showApprove && !approveLocked) {
      return Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + botPad),
        decoration: deco,
        child: Row(children: [
          Expanded(child: _ActionBtn(label: 'Edit',
            color: const Color(0xFF1565C0),
            onTap: () => _openEdit(context))),
        ]),
      );
    }

    if (showSync) {
      return Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + botPad),
        decoration: deco,
        child: Row(children: [
          Expanded(child: _ActionBtn(label: 'Edit',
            color: const Color(0xFF1565C0),
            onTap: () => _openEdit(context))),
          const SizedBox(width: 12),
          Expanded(child: _ActionBtn(label: 'Sync',
            color: DAColors.greenMid,
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Syncing record...',
                  style: GoogleFonts.poppins(fontSize: 12)),
                backgroundColor: DAColors.greenMid,
                behavior: SnackBarBehavior.floating,
              ));
            })),
        ]),
      );
    }

    if (showApprove || approveLocked) {
      return Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + botPad),
        decoration: deco,
        child: Row(children: [
          Expanded(child: _LockedBtn(label: 'Approve',
            color: DAColors.greenMid, locked: approveLocked,
            lockMsg: 'Moderators only',
            onTap: showApprove ? () => _openApprove(context, true) : null)),
          const SizedBox(width: 8),
          Expanded(child: _LockedBtn(label: 'Edit',
            color: const Color(0xFF1565C0), locked: approveLocked,
            lockMsg: 'Moderators only',
            onTap: showApprove ? () => _openEdit(context) : null)),
          const SizedBox(width: 8),
          Expanded(child: _LockedBtn(label: 'Decline',
            color: Colors.red, locked: approveLocked,
            lockMsg: 'Moderators only',
            onTap: showApprove ? () => _openApprove(context, false) : null)),
        ]),
      );
    }

    return SizedBox(height: botPad + 16);
  }
}

// ── Production-specific field views ──────────────────────────────

class _CropFields extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _SectionHeader(title: 'Project Background'),
      _Row2('Reporting Period', '2026', 'FCA Name', 'Maharlika FCA'),
      _Row2('Region', 'Region IV-A', 'Province', 'Batangas'),
      _Row2('Municipality', 'Cuenca', 'Barangay', 'Bungahan'),
      _Row1('Project Title', 'SAAD 2026 Crop Production'),
      _Row2('Primary Intervention', 'Any Fruit', 'Support Intervention', 'Fertilizers'),

      _SectionHeader(title: 'Commodity Information'),
      _Row2('Name of Farmer', 'Juan Dela Cruz', 'Type of Crop', 'Banana'),
      _Row2('Variety', 'Lakatan', 'Farmgate Price', '₱25/kg'),

      _SectionHeader(title: 'Planting Stage'),
      _Row2('Total Land Area', '1.5 ha', 'Land Ownership', 'Owned'),
      _Row2('Planting Date', '2026-01-10', 'Source of Water', 'Rainfall'),
      _Row2('Seed Amount', '50 kg', 'Germination Rate', '85%'),

      _SectionHeader(title: 'Fertilization'),
      _Row2('Fertilizer Type', 'Organic', 'Organic Source', 'Commercial'),
      _Row2('Bags from SAAD', '10 bags', 'Total Cost', '₱2,500'),

      _SectionHeader(title: 'Harvesting Stage'),
      _Row2('Total Harvested', '500 kg', 'Avg Harvest/ha', '333 kg/ha'),
      _Row2('Food Consumption', '10%', 'Harvest Cost', '₱1,000'),

      _SectionHeader(title: 'Crop Damage'),
      _Row1('Damage Type', 'Pest Occurrence'),
      _Row2('Date Observed', '2026-02-01', 'Damage Area', '0.5 ha'),
      _Row1('Treatment', 'Applied pesticide'),

      _SectionHeader(title: 'Trainings Attended'),
      _Row1('Training', 'Crop Production Seminar — Jan 2026, 25 farmers'),
    ],
  );
}

class _LivestockFields extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _SectionHeader(title: 'Project Background'),
      _Row2('FCA Name', 'Maharlika FCA', 'Region', 'Region IV-A'),
      _Row2('Municipality', 'Cuenca', 'Barangay', 'Bungahan'),
      _Row1('Project Title', 'SAAD 2026 Livestock Production'),
      _Row2('Primary Intervention', 'Goat', 'Purpose', 'Breeding, Meat'),

      _SectionHeader(title: 'Livestock Information'),
      _Row2('Name of Farmer', 'Juan Dela Cruz', 'Breed', 'Anglo-Nubian'),
      _Row1('Farmgate Price', '₱3,500/head'),

      _SectionHeader(title: 'Production Information'),
      _Row2('Stocks Received', '10 heads', 'Date Received', '2026-01-05'),
      _Row2('Male Stocks', '3', 'Female Stocks', '7'),
      _Row2('M:F Ratio', '3:7', 'Age Upon Receipt', '6 months'),
      _Row2('Avg Weight', '15 kg', 'Housing Type', 'Semi-confinement'),
      _Row2('Land Ownership', 'Owned', 'Usufruct', 'N/A'),

      _SectionHeader(title: 'Water and Feeding'),
      _Row2('Grazing Area', '0.5 ha/head', 'Water Source', 'Well water'),

      _SectionHeader(title: 'Harvesting Information'),
      _Row2('Avg Marketable Weight', '25 kg', 'Sold as Liveweight', 'Yes'),

      _SectionHeader(title: 'Mortality Information'),
      _Row2('Pest Mortality', '0', 'Disease Mortality', '1'),
      _Row2('Total Mortalities', '1', 'Remaining Stocks', '9'),

      _SectionHeader(title: 'Trainings Attended'),
      _Row1('Training', 'Livestock Production Seminar — Feb 2026, 20 farmers'),
    ],
  );
}

class _PoultryFields extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _SectionHeader(title: 'Project Background'),
      _Row2('FCA Name', 'Maharlika FCA', 'Region', 'Region IV-A'),
      _Row2('Municipality', 'Cuenca', 'Barangay', 'Bungahan'),
      _Row1('Project Title', 'SAAD 2026 Poultry Production'),
      _Row2('Primary Intervention', 'Chicken', 'Purpose', 'Meat / Broiler'),

      _SectionHeader(title: 'Poultry Information'),
      _Row2('Name of Farmer', 'Juan Dela Cruz', 'Breed', 'Native Chicken'),
      _Row1('Farmgate Price', '₱180/kg'),

      _SectionHeader(title: 'Production Information'),
      _Row2('Stocks Received', '100 heads', 'Date Received', '2026-01-10'),
      _Row2('Age Upon Receipt', '1 day old', 'Avg Weight', '40 g'),
      _Row2('Housing Type', 'Confinement', 'Land Ownership', 'Owned'),
      _Row2('Harvested Birds', '90', 'Total Weight', '180 kg'),
      _Row2('ADG', '22 g/day', 'Harvest Recovery', '90%'),
      _Row2('Avg Live Weight', '2 kg', 'FCR', '2.5 kg'),
      _Row2('Avg Age Harvested', '56 days', 'BPI', '312'),

      _SectionHeader(title: 'Mortality Information'),
      _Row2('Pest Mortality', '0', 'Disease Mortality', '2'),
      _Row2('Total Mortalities', '2', 'Remaining Stocks', '98'),

      _SectionHeader(title: 'Feeding and Water'),
      _Row2('Feed Type', 'Broiler Finisher', 'Total Feed', '250 kg'),
      _Row2('Feed per Day', '45 g/hd', 'Water Source', 'Tap water'),

      _SectionHeader(title: 'Waste Management'),
      _Row2('Manure Produced', '20 sacks', 'Manure Sold', '15 sacks'),
      _Row2('Manure Used', '5 sacks', 'Price/Sack', '₱80'),

      _SectionHeader(title: 'Trainings Attended'),
      _Row1('Training', 'Poultry Production Seminar — Jan 2026, 18 farmers'),
    ],
  );
}

// ── Shared field widgets ──────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 10),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(8)),
      alignment: Alignment.center,
      child: Text(title,
        style: GoogleFonts.poppins(
          fontSize: 13, fontWeight: FontWeight.w700,
          color: DAColors.textDark)),
    ),
  );
}

class _Row2 extends StatelessWidget {
  const _Row2(this.l1, this.v1, this.l2, this.v2);
  final String l1, v1, l2, v2;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _FieldItem(label: l1, value: v1)),
        Expanded(child: _FieldItem(label: l2, value: v2)),
      ],
    ),
  );
}

class _Row1 extends StatelessWidget {
  const _Row1(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: _FieldItem(label: label, value: value),
  );
}

class _FieldItem extends StatelessWidget {
  const _FieldItem({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: GoogleFonts.poppins(
        fontSize: 12, fontWeight: FontWeight.w600, color: DAColors.textDark)),
      Text(value, style: GoogleFonts.poppins(
        fontSize: 12, color: DAColors.textMuted)),
    ],
  );
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: DAColors.greenLight.withOpacity(0.2),
      borderRadius: BorderRadius.circular(50)),
    child: Text(label, style: GoogleFonts.poppins(
      fontSize: 11, fontWeight: FontWeight.w600, color: DAColors.greenMid)));
}

// ── Action buttons ────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.label, required this.color, this.onTap});
  final String label; final Color color; final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(height: 48,
      decoration: BoxDecoration(color: color,
          borderRadius: BorderRadius.circular(50)),
      alignment: Alignment.center,
      child: Text(label, style: GoogleFonts.poppins(
        fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white))));
}

class _LockedBtn extends StatelessWidget {
  const _LockedBtn({required this.label, required this.color,
    required this.locked, required this.lockMsg, this.onTap});
  final String label; final Color color;
  final bool locked; final String lockMsg; final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Stack(children: [
    _ActionBtn(label: label, color: color, onTap: onTap),
    if (locked)
      Positioned.fill(child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: Container(
          color: Colors.black.withOpacity(0.60),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.lock_rounded, color: Colors.white, size: 14),
            const SizedBox(height: 2),
            Text(lockMsg, style: GoogleFonts.poppins(
              fontSize: 8, color: Colors.white), textAlign: TextAlign.center),
          ]),
        ),
      )),
  ]);
}