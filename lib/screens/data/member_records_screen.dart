import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/da_colors.dart';
import '../../widgets/member_card.dart';
import '../../widgets/record_card.dart';
import '../../routes/app_routes.dart';
import '../crop/crop_step_wrapper.dart';
import '../livestock/livestock_step_wrapper.dart';
import '../poultry/poultry_step_wrapper.dart';
import 'record_view_modal.dart';

// ── Mock members ──────────────────────────────────────────────────
const _mockMembers = [
  MemberModel(name: 'Juan Dela Cruz',   status: 'completed'),
  MemberModel(name: 'Maria Santos',     status: 'in_progress'),
  MemberModel(name: 'Pedro Reyes',      status: 'not_monitored'),
  MemberModel(name: 'Ana Bautista',     status: 'not_monitored'),
  MemberModel(name: 'Jose Ramos',       status: 'completed'),
];

class MemberRecordsScreen extends StatefulWidget {
  const MemberRecordsScreen({super.key, required this.record});
  final RecordModel record;

  @override
  State<MemberRecordsScreen> createState() => _MemberRecordsScreenState();
}

class _MemberRecordsScreenState extends State<MemberRecordsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  bool get _isHybrid     => widget.record.implType == 'Hybrid';
  bool get _isIndividual => widget.record.implType == 'Individual';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<MemberModel> get _filteredMembers {
    final q = _query.toLowerCase();
    return _mockMembers
        .where((m) => q.isEmpty || m.name.toLowerCase().contains(q))
        .toList();
  }

  // ── Navigate to step 2 of the correct production type ────────
  void _addCommodityForMember(String farmerName) {
    final type = widget.record.productionType.toLowerCase();
    if (type == 'crop') {
      final w = CropStepWrapper()
        ..fcaName            = widget.record.name
        ..implementationType = widget.record.implType.toLowerCase()
        ..farmerName         = farmerName;
      Navigator.of(context).pushNamed(AppRoutes.cropStep2, arguments: w);
    } else if (type == 'livestock') {
      final w = LivestockStepWrapper()
        ..fcaName            = widget.record.name
        ..implementationType = widget.record.implType.toLowerCase()
        ..farmerName         = farmerName;
      Navigator.of(context).pushNamed(AppRoutes.livestockStep2, arguments: w);
    } else {
      final w = PoultryStepWrapper()
        ..fcaName            = widget.record.name
        ..implementationType = widget.record.implType.toLowerCase()
        ..farmerName         = farmerName;
      Navigator.of(context).pushNamed(AppRoutes.poultryStep2, arguments: w);
    }
  }

  void _addCommodityForGroup() {
    final type = widget.record.productionType.toLowerCase();
    if (type == 'crop') {
      final w = CropStepWrapper()
        ..fcaName            = widget.record.name
        ..implementationType = widget.record.implType.toLowerCase();
      Navigator.of(context).pushNamed(AppRoutes.cropStep2, arguments: w);
    } else if (type == 'livestock') {
      final w = LivestockStepWrapper()
        ..fcaName            = widget.record.name
        ..implementationType = widget.record.implType.toLowerCase();
      Navigator.of(context).pushNamed(AppRoutes.livestockStep2, arguments: w);
    } else {
      final w = PoultryStepWrapper()
        ..fcaName            = widget.record.name
        ..implementationType = widget.record.implType.toLowerCase();
      Navigator.of(context).pushNamed(AppRoutes.poultryStep2, arguments: w);
    }
  }

  void _addAnotherFarmer() {
    final type = widget.record.productionType.toLowerCase();
    if (type == 'crop') {
      final w = CropStepWrapper()
        ..implementationType = widget.record.implType.toLowerCase();
      Navigator.of(context).pushNamed(AppRoutes.cropStep1, arguments: w);
    } else if (type == 'livestock') {
      final w = LivestockStepWrapper()
        ..implementationType = widget.record.implType.toLowerCase();
      Navigator.of(context).pushNamed(AppRoutes.livestockStep1, arguments: w);
    } else {
      final w = PoultryStepWrapper()
        ..implementationType = widget.record.implType.toLowerCase();
      Navigator.of(context).pushNamed(AppRoutes.poultryStep1, arguments: w);
    }
  }

  void _viewMember(MemberModel member) {
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => RecordViewModal(
        record:      widget.record,
        memberName:  member.name,
        showEdit:    widget.record.status == 'draft' || widget.record.status == 'unsync',
        showApprove: widget.record.status == 'pending',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq      = MediaQuery.of(context);
    final topPad  = mq.padding.top;
    final botPad  = mq.padding.bottom;
    final screenW = mq.size.width;
    final hPad    = screenW * 0.048;

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: Column(children: [

        // ── Green header ────────────────────────────────────────
        Container(
          padding: EdgeInsets.fromLTRB(hPad, topPad + 12, hPad, 20),
          decoration: const BoxDecoration(
            color: DAColors.greenDark,
            image: DecorationImage(
              image:   AssetImage('assets/images/splash_bg.png'),
              fit:     BoxFit.cover,
              opacity: 0.18,
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.20),
                    shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 20))),
              const SizedBox(width: 12),
              Expanded(child: Text('Member Records',
                style: GoogleFonts.bebasNeue(
                  fontSize: 22, color: Colors.white, letterSpacing: 2))),
            ]),
            const SizedBox(height: 14),
            Text(widget.record.name,
              style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 6),
            Row(children: [
              _InfoChip(label: widget.record.productionType),
              const SizedBox(width: 8),
              _InfoChip(label: widget.record.implType),
            ]),
          ]),
        ),

        // ── Body ────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(hPad, 20, hPad, botPad + 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Search
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 8, offset: const Offset(0, 2))]),
                child: TextField(
                  controller: _searchCtrl,
                  style: GoogleFonts.poppins(fontSize: 13),
                  decoration: InputDecoration(
                    hintText:  'Search member name',
                    hintStyle: GoogleFonts.poppins(
                        fontSize: 13, color: DAColors.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: DAColors.textMuted, size: 22),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14)),
                ),
              ),
              const SizedBox(height: 20),

              // ── Add Another Farmer button (top) ───────────────
              GestureDetector(
                onTap: _addAnotherFarmer,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8, offset: const Offset(0, 2))]),
                  child: Row(children: [
                    Container(width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: DAColors.amber.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.person_add_rounded,
                          color: DAColors.amber, size: 22)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Add Another Farmer',
                          style: GoogleFonts.poppins(
                            fontSize: 14, fontWeight: FontWeight.w700,
                            color: DAColors.textDark)),
                        Text('Start monitoring a new farmer',
                          style: GoogleFonts.poppins(
                            fontSize: 12, color: DAColors.textMuted)),
                      ],
                    )),
                    const Icon(Icons.chevron_right_rounded,
                        color: DAColors.amber, size: 24),
                  ]),
                ),
              ),
              const SizedBox(height: 24),

              // ── FCA / Group card ──────────────────────────────
              const _SectionLabel(label: 'Group / FCA'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: DAColors.greenMid.withOpacity(0.25), width: 1.5),
                  boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6, offset: const Offset(0, 2))]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: DAColors.greenLight.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.groups_rounded,
                            color: DAColors.greenMid, size: 24)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.record.name,
                            style: GoogleFonts.poppins(
                              fontSize: 14, fontWeight: FontWeight.w700,
                              color: DAColors.textDark)),
                          Text(
                            '${widget.record.productionType} · ${widget.record.implType}',
                            style: GoogleFonts.poppins(
                              fontSize: 12, color: DAColors.textMuted)),
                        ],
                      )),
                      // View button — only for hybrid
                      if (_isHybrid)
                        GestureDetector(
                          onTap: () => showModalBottomSheet(
                            context:            context,
                            isScrollControlled: true,
                            backgroundColor:    Colors.transparent,
                            builder: (_) => RecordViewModal(
                              record:    widget.record,
                              isGroup:   true,
                              showEdit:  widget.record.status == 'draft' ||
                                         widget.record.status == 'unsync',
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: DAColors.greenMid.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(50)),
                            child: Text('View',
                              style: GoogleFonts.poppins(
                                fontSize: 12, fontWeight: FontWeight.w600,
                                color: DAColors.greenMid))),
                        ),
                    ]),

                    // Add Another Commodity — for hybrid only
                    if (_isHybrid) ...[
                      const SizedBox(height: 10),
                      const Divider(height: 1, color: Color(0xFFF0F0F0)),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: _addCommodityForGroup,
                        child: Row(children: [
                          Container(width: 26, height: 26,
                            decoration: BoxDecoration(
                              color: DAColors.greenMid.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.add_rounded,
                                color: DAColors.greenMid, size: 16)),
                          const SizedBox(width: 8),
                          Text('Add Another Commodity',
                            style: GoogleFonts.poppins(
                              fontSize: 12, fontWeight: FontWeight.w600,
                              color: DAColors.greenMid)),
                        ]),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Members ───────────────────────────────────────
              const _SectionLabel(label: 'Members Monitoring'),
              const SizedBox(height: 10),

              _filteredMembers.isEmpty
                  ? Center(child: Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Text('No members found',
                        style: GoogleFonts.poppins(
                          fontSize: 13, color: DAColors.textMuted)),
                    ))
                  : ListView.separated(
                      shrinkWrap: true,
                      physics:    const NeverScrollableScrollPhysics(),
                      itemCount:  _filteredMembers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) {
                        final member = _filteredMembers[i];
                        return _MemberCard(
                          member:           member,
                          onView:           () => _viewMember(member),
                          onAddCommodity:   () => _addCommodityForMember(member.name),
                        );
                      },
                    ),
            ]),
          ),
        ),

        // ── Bottom action bar (Unsync → Sync, Pending → Approve/Decline, Approved → Edit) ──
        if (widget.record.status == 'unsync' || widget.record.status == 'pending' || widget.record.status == 'approved')
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(hPad, 12, hPad, botPad + 16),
            child: Row(children: [

              if (widget.record.status == 'approved')
                Expanded(child: _actionBtn(
                  context: context,
                  label:   'Edit',
                  color:   const Color(0xFF1565C0),
                  icon:    Icons.edit_outlined,
                  onTap: () => showModalBottomSheet(
                    context:            context,
                    isScrollControlled: true,
                    backgroundColor:    Colors.transparent,
                    builder: (_) => RecordViewModal(
                      record:   widget.record,
                      showEdit: true,
                    ),
                  ),
                )),

              if (widget.record.status == 'unsync')
                Expanded(child: _actionBtn(
                  context: context,
                  label:   'Sync',
                  color:   DAColors.greenMid,
                  icon:    Icons.sync_rounded,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Syncing ${widget.record.name}...',
                        style: GoogleFonts.poppins(fontSize: 13)),
                    backgroundColor: DAColors.greenMid,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  )),
                )),

              if (widget.record.status == 'pending') ...[
                Expanded(child: _actionBtn(
                  context: context,
                  label:   'Approve',
                  color:   DAColors.greenMid,
                  icon:    Icons.check_circle_outline_rounded,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('${widget.record.name} approved!',
                        style: GoogleFonts.poppins(fontSize: 13)),
                    backgroundColor: DAColors.greenMid,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  )),
                )),
                const SizedBox(width: 12),
                Expanded(child: _actionBtn(
                  context: context,
                  label:   'Decline',
                  color:   Colors.red,
                  icon:    Icons.cancel_outlined,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('${widget.record.name} declined.',
                        style: GoogleFonts.poppins(fontSize: 13)),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  )),
                )),
              ],
            ]),
          ),

      ]),
    );
  }

  Widget _actionBtn({
    required BuildContext context,
    required String       label,
    required Color        color,
    required IconData     icon,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 50,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(50)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
      ]),
    ),
  );
}

// ── Member card with View + Add Commodity ─────────────────────────
class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.onView,
    required this.onAddCommodity,
  });
  final MemberModel  member;
  final VoidCallback onView;
  final VoidCallback onAddCommodity;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color:        Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 6, offset: const Offset(0, 2))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      Row(children: [
        Container(width: 42, height: 42,
          decoration: BoxDecoration(
            color: member.status == 'completed'
                ? DAColors.greenLight.withOpacity(0.25)
                : const Color(0xFFF0F0F0),
            shape: BoxShape.circle),
          child: Icon(
            member.status == 'completed'
                ? Icons.check_circle_rounded
                : Icons.person_rounded,
            color: member.status == 'completed'
                ? DAColors.greenMid
                : DAColors.textMuted,
            size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(member.name, style: GoogleFonts.poppins(
              fontSize: 14, fontWeight: FontWeight.w700,
              color: DAColors.textDark)),
            const SizedBox(height: 2),
            Row(children: [
              Container(width: 7, height: 7,
                decoration: BoxDecoration(
                  color: _statusColor(member.status),
                  shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text(_statusLabel(member.status),
                style: GoogleFonts.poppins(fontSize: 11,
                  color: _statusColor(member.status))),
            ]),
          ],
        )),
        // View button
        GestureDetector(
          onTap: onView,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.10),
              borderRadius: BorderRadius.circular(50)),
            child: Text('View', style: GoogleFonts.poppins(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: const Color(0xFF1565C0))))),
      ]),

      const SizedBox(height: 10),
      const Divider(height: 1, color: Color(0xFFF0F0F0)),
      const SizedBox(height: 10),

      GestureDetector(
        onTap: onAddCommodity,
        child: Row(children: [
          Container(width: 26, height: 26,
            decoration: BoxDecoration(
              color: DAColors.greenMid.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.add_rounded,
                color: DAColors.greenMid, size: 16)),
          const SizedBox(width: 8),
          Text('Add Another Commodity',
            style: GoogleFonts.poppins(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: DAColors.greenMid)),
        ]),
      ),
    ]),
  );

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':    return DAColors.greenMid;
      case 'in_progress':  return DAColors.amber;
      default:             return const Color(0xFFBBBBBB);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'completed':    return 'Completed';
      case 'in_progress':  return 'In Progress';
      default:             return 'Not yet monitored';
    }
  }
}

// ── Widgets ───────────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
      color:        Colors.white.withOpacity(0.18),
      borderRadius: BorderRadius.circular(50),
      border:       Border.all(color: Colors.white.withOpacity(0.40))),
    child: Text(label, style: GoogleFonts.poppins(
      fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)));
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Text(label,
    style: GoogleFonts.poppins(
      fontSize: 14, fontWeight: FontWeight.w700, color: DAColors.textDark));
}