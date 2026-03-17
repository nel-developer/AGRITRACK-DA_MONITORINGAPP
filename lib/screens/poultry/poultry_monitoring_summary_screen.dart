import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/da_colors.dart';
import '../../routes/app_routes.dart';
import 'poultry_step_wrapper.dart';

// ── Record model ──────────────────────────────────────────────────
class PoultryMonitoringRecord {
  final String   farmerName;
  final String   breed;
  final DateTime completedAt;

  const PoultryMonitoringRecord({
    required this.farmerName,
    required this.breed,
    required this.completedAt,
  });
}

// ── Member model ──────────────────────────────────────────────────
class PoultryMember {
  final String name;
  bool monitored;
  PoultryMember({required this.name, this.monitored = false});
}

class PoultryMonitoringSummaryScreen extends StatefulWidget {
  const PoultryMonitoringSummaryScreen({
    super.key,
    required this.wrapper,
    required this.completedRecords,
    this.members,
  });

  final PoultryStepWrapper            wrapper;
  final List<PoultryMonitoringRecord> completedRecords;
  final List<PoultryMember>?          members;

  @override
  State<PoultryMonitoringSummaryScreen> createState() =>
      _PoultryMonitoringSummaryScreenState();
}

class _PoultryMonitoringSummaryScreenState
    extends State<PoultryMonitoringSummaryScreen> {

  late final List<PoultryMember> _members = widget.members ?? [
    PoultryMember(name: 'Juan Dela Cruz'),
    PoultryMember(name: 'Maria Santos'),
    PoultryMember(name: 'Pedro Reyes'),
    PoultryMember(name: 'Ana Bautista'),
    PoultryMember(name: 'Jose Ramos'),
  ];

  void _addAnotherFarmer() {
    final next = PoultryStepWrapper()
      ..reportingPeriod      = widget.wrapper.reportingPeriod
      ..fcaName              = ''
      ..region               = widget.wrapper.region
      ..province             = widget.wrapper.province
      ..municipality         = widget.wrapper.municipality
      ..barangay             = widget.wrapper.barangay
      ..projectTitle         = widget.wrapper.projectTitle
      ..primaryIntervention  = widget.wrapper.primaryIntervention
      ..supportInterventions = List.from(widget.wrapper.supportInterventions)
      ..purposeBreeding      = widget.wrapper.purposeBreeding
      ..purposeMeat          = widget.wrapper.purposeMeat
      ..purposeEgg           = widget.wrapper.purposeEgg
      ..implementationType   = widget.wrapper.implementationType;
    Navigator.of(context).pushNamed(AppRoutes.poultryStep1, arguments: next);
  }

  void _monitorMember(PoultryMember member) {
    final next = PoultryStepWrapper()
      ..reportingPeriod      = widget.wrapper.reportingPeriod
      ..fcaName              = widget.wrapper.fcaName
      ..region               = widget.wrapper.region
      ..province             = widget.wrapper.province
      ..municipality         = widget.wrapper.municipality
      ..barangay             = widget.wrapper.barangay
      ..projectTitle         = widget.wrapper.projectTitle
      ..primaryIntervention  = widget.wrapper.primaryIntervention
      ..supportInterventions = List.from(widget.wrapper.supportInterventions)
      ..purposeBreeding      = widget.wrapper.purposeBreeding
      ..purposeMeat          = widget.wrapper.purposeMeat
      ..purposeEgg           = widget.wrapper.purposeEgg
      ..implementationType   = 'individual'
      ..farmerName           = member.name;
    Navigator.of(context)
        .pushNamed(AppRoutes.poultryStep2, arguments: next)
        .then((_) => setState(() => member.monitored = true));
  }

  void _addBatchForMember(PoultryMember member) {
    final next = PoultryStepWrapper()
      ..reportingPeriod      = widget.wrapper.reportingPeriod
      ..fcaName              = widget.wrapper.fcaName
      ..region               = widget.wrapper.region
      ..province             = widget.wrapper.province
      ..municipality         = widget.wrapper.municipality
      ..barangay             = widget.wrapper.barangay
      ..projectTitle         = widget.wrapper.projectTitle
      ..primaryIntervention  = widget.wrapper.primaryIntervention
      ..supportInterventions = List.from(widget.wrapper.supportInterventions)
      ..purposeBreeding      = widget.wrapper.purposeBreeding
      ..purposeMeat          = widget.wrapper.purposeMeat
      ..purposeEgg           = widget.wrapper.purposeEgg
      ..implementationType   = 'individual'
      ..farmerName           = member.name;
    Navigator.of(context).pushNamed(AppRoutes.poultryStep2, arguments: next);
  }

  void _addBatchForGroup() {
    final next = PoultryStepWrapper()
      ..reportingPeriod      = widget.wrapper.reportingPeriod
      ..fcaName              = widget.wrapper.fcaName
      ..region               = widget.wrapper.region
      ..province             = widget.wrapper.province
      ..municipality         = widget.wrapper.municipality
      ..barangay             = widget.wrapper.barangay
      ..projectTitle         = widget.wrapper.projectTitle
      ..primaryIntervention  = widget.wrapper.primaryIntervention
      ..supportInterventions = List.from(widget.wrapper.supportInterventions)
      ..purposeBreeding      = widget.wrapper.purposeBreeding
      ..purposeMeat          = widget.wrapper.purposeMeat
      ..purposeEgg           = widget.wrapper.purposeEgg
      ..implementationType   = widget.wrapper.implementationType;
    Navigator.of(context).pushNamed(AppRoutes.poultryStep2, arguments: next);
  }

  void _done() =>
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);

  @override
  Widget build(BuildContext context) {
    final mq      = MediaQuery.of(context);
    final topPad  = mq.padding.top;
    final botPad  = mq.padding.bottom;
    final screenW = mq.size.width;
    final hPad    = screenW * 0.05;
    final w       = widget.wrapper;

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
                onTap: _done,
                child: Container(width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.20),
                    shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 20))),
              const SizedBox(width: 12),
              Expanded(child: Text('Monitoring Summary',
                style: GoogleFonts.bebasNeue(
                  fontSize: 22, color: Colors.white, letterSpacing: 2))),
            ]),
            const SizedBox(height: 14),
            Text(w.fcaName,
              style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: Colors.white)),
            const SizedBox(height: 6),
            Row(children: [
              _InfoChip(label: w.municipality ?? ''),
              const SizedBox(width: 8),
              _InfoChip(label: _implLabel(w.implementationType)),
            ]),
          ]),
        ),

        // ── Body ────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(hPad, 20, hPad, botPad + 100),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // ── Add Another Farmer ────────────────────────────
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
                    Container(width: 46, height: 46,
                      decoration: BoxDecoration(
                        color: DAColors.amber.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.person_add_rounded,
                          color: DAColors.amber, size: 24)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Add Another Farmer',
                          style: GoogleFonts.poppins(
                            fontSize: 14, fontWeight: FontWeight.w700,
                            color: DAColors.textDark)),
                        const SizedBox(height: 2),
                        Text('Monitor a new farmer',
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

              // ── Group / FCA card ──────────────────────────────
              Text('Group / FCA',
                style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: DAColors.textDark)),
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
                          Text(w.fcaName.isEmpty ? '—' : w.fcaName,
                            style: GoogleFonts.poppins(
                              fontSize: 14, fontWeight: FontWeight.w700,
                              color: DAColors.textDark)),
                          const SizedBox(height: 2),
                          Text(
                            [
                              if (w.primaryIntervention != null)
                                w.primaryIntervention!,
                              if (w.municipality != null) w.municipality!,
                            ].join(' · '),
                            style: GoogleFonts.poppins(
                              fontSize: 12, color: DAColors.textMuted)),
                        ],
                      )),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: DAColors.greenLight.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(50)),
                        child: Text('Completed',
                          style: GoogleFonts.poppins(
                            fontSize: 11, fontWeight: FontWeight.w600,
                            color: DAColors.greenMid))),
                    ]),
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: Color(0xFFF0F0F0)),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _addBatchForGroup,
                      child: Row(children: [
                        Container(width: 26, height: 26,
                          decoration: BoxDecoration(
                            color: DAColors.greenMid.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.add_rounded,
                              color: DAColors.greenMid, size: 16)),
                        const SizedBox(width: 8),
                        Text('Add Another Batch',
                          style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: DAColors.greenMid)),
                      ]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Members ───────────────────────────────────────
              Text('Members',
                style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: DAColors.textDark)),
              const SizedBox(height: 10),

              ..._members.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _MemberCard(
                  member:     m,
                  onMonitor:  () => _monitorMember(m),
                  onAddBatch: () => _addBatchForMember(m),
                ),
              )),
            ]),
          ),
        ),

        // ── Buttons ─────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(hPad, 12, hPad, botPad + 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              width: double.infinity, height: 54,
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Saved as draft!',
                        style: GoogleFonts.poppins(fontSize: 13)),
                    backgroundColor: DAColors.greenMid,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ));
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/home', (r) => false);
                },
                icon: const Icon(Icons.save_outlined,
                    color: DAColors.greenMid, size: 20),
                label: Text('Save as Draft',
                  style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: DAColors.greenMid)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                      color: DAColors.greenMid, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: _done,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DAColors.amberLight,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50))),
                child: Text('Done',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 22, color: Colors.white, letterSpacing: 2)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  String _implLabel(String? type) {
    switch (type) {
      case 'individual': return 'Individually Managed';
      case 'collective': return 'Collectively Managed';
      case 'hybrid':     return 'Hybrid';
      default:           return '';
    }
  }
}

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

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.onMonitor,
    required this.onAddBatch,
  });
  final PoultryMember member;
  final VoidCallback  onMonitor;
  final VoidCallback  onAddBatch;

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
            color: member.monitored
                ? DAColors.greenLight.withOpacity(0.25)
                : const Color(0xFFF0F0F0),
            shape: BoxShape.circle),
          child: Icon(
            member.monitored
                ? Icons.check_circle_rounded
                : Icons.person_rounded,
            color: member.monitored ? DAColors.greenMid : DAColors.textMuted,
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
                  color: member.monitored
                      ? DAColors.greenMid
                      : const Color(0xFFBBBBBB),
                  shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text(member.monitored ? 'Monitored' : 'Not yet monitored',
                style: GoogleFonts.poppins(fontSize: 11,
                  color: member.monitored
                      ? DAColors.greenMid
                      : DAColors.textMuted)),
            ]),
          ],
        )),
        if (!member.monitored)
          GestureDetector(
            onTap: onMonitor,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: DAColors.greenMid,
                borderRadius: BorderRadius.circular(50)),
              child: Text('Monitor', style: GoogleFonts.poppins(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: Colors.white)))),
      ]),
      const SizedBox(height: 10),
      const Divider(height: 1, color: Color(0xFFF0F0F0)),
      const SizedBox(height: 10),
      GestureDetector(
        onTap: onAddBatch,
        child: Row(children: [
          Container(width: 26, height: 26,
            decoration: BoxDecoration(
              color: DAColors.greenMid.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.add_rounded,
                color: DAColors.greenMid, size: 16)),
          const SizedBox(width: 8),
          Text('Add Another Batch',
            style: GoogleFonts.poppins(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: DAColors.greenMid)),
        ]),
      ),
    ]),
  );
}