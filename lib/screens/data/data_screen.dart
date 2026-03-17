import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/da_colors.dart';
import '../../widgets/record_card.dart';
import '../../widgets/search_bar_widget.dart';
import '../auth/login_screen.dart' show mockUserRole;
import 'record_view_modal.dart';
import 'member_records_screen.dart';

const _mockRecords = [
  RecordModel(name: 'Maharlika FCA',         productionType: 'Crop',      implType: 'Individual', enumerator: 'Arnel Parlonga', date: '2026-01-10', status: 'draft'),
  RecordModel(name: 'Samahang Magsasaka',    productionType: 'Livestock',  implType: 'Collective', enumerator: 'Arnel Parlonga', date: '2026-01-12', status: 'draft'),
  RecordModel(name: 'Bagong Pag-asa FCA',    productionType: 'Crop',      implType: 'Individual', enumerator: 'Arnel Parlonga', date: '2026-01-28', status: 'unsync'),
  RecordModel(name: 'Kalikasan Farmers Assoc.', productionType: 'Livestock', implType: 'Hybrid',   enumerator: 'Arnel Parlonga', date: '2026-01-28', status: 'unsync'),
  RecordModel(name: 'Tagumpay FCA',          productionType: 'Poultry',   implType: 'Hybrid',    enumerator: 'Arnel Parlonga', date: '2026-01-28', status: 'unsync'),
  RecordModel(name: 'Maharlika FCA',         productionType: 'Poultry',   implType: 'Collective', enumerator: 'Arnel Parlonga', date: '2026-01-28', status: 'pending'),
  RecordModel(name: 'Samahang Magsasaka',    productionType: 'Poultry',   implType: 'Hybrid',    enumerator: 'Arnel Parlonga', date: '2026-01-28', status: 'pending'),
  RecordModel(name: 'Bagong Pag-asa FCA',    productionType: 'Crop',      implType: 'Individual', enumerator: 'Arnel Parlonga', date: '2026-01-20', status: 'approved'),
  RecordModel(name: 'Kalikasan Farmers Assoc.', productionType: 'Livestock', implType: 'Collective', enumerator: 'Arnel Parlonga', date: '2026-01-15', status: 'approved'),
];

class DataScreen extends StatefulWidget {
  const DataScreen({super.key});
  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  String _query = '';

  static const _tabs = ['Draft', 'Unsync', 'Pending', 'Approved'];

  bool get _isProfiler  => mockUserRole == 'profiler';
  bool get _isModerator => mockUserRole == 'moderator' || mockUserRole == 'admin';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<RecordModel> _filtered(String status) {
    final q = _query.toLowerCase();
    return _mockRecords
        .where((r) => r.status == status)
        .where((r) => q.isEmpty ||
            r.name.toLowerCase().contains(q) ||
            r.productionType.toLowerCase().contains(q))
        .toList();
  }

  void _handleView(BuildContext context, RecordModel record, {
    bool showEdit = false, bool showSync = false,
    bool showApprove = false, bool approveLocked = false,
  }) {
    if (record.implType == 'Collective') {
      showModalBottomSheet(
        context:            context,
        isScrollControlled: true,
        backgroundColor:    Colors.transparent,
        builder: (_) => RecordViewModal(
          record:        record,
          showEdit:      showEdit,
          showSync:      showSync,
          showApprove:   showApprove,
          approveLocked: approveLocked,
        ),
      );
    } else {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => MemberRecordsScreen(record: record),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq          = MediaQuery.of(context);
    final screenH     = mq.size.height;
    final screenW     = mq.size.width;
    final topPad      = mq.padding.top;
    final botPad      = mq.padding.bottom;
    final navH        = kBottomNavigationBarHeight + botPad;
    final totalH      = screenH - topPad - navH;
    final imageH      = totalH * 0.22;
    final titleFSz    = (imageH * 0.26).clamp(22.0, 36.0);
    final subtitleFSz = (imageH * 0.07).clamp(9.0, 12.0);
    final hPad        = screenW * 0.048;

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor:          const Color(0xFFF2F2F2),
      resizeToAvoidBottomInset: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          SizedBox(height: topPad),

          // ── Image block ──────────────────────────────────────────
          SizedBox(
            height: imageH,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset('assets/images/splash_bg.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: DAColors.greenDark)),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end:   Alignment.bottomCenter,
                      colors: [
                        DAColors.greenDark.withOpacity(0.88),
                        DAColors.greenMid.withOpacity(0.80),
                        DAColors.greenLight.withOpacity(0.30),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.35, 0.70, 1.0],
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('DATA',
                      style: GoogleFonts.bebasNeue(
                        fontSize:      titleFSz,
                        color:         Colors.white,
                        letterSpacing: 4)),
                    SizedBox(height: imageH * 0.04),
                    Text('All of those numbers are available here',
                      style: GoogleFonts.poppins(
                        fontSize:  subtitleFSz,
                        fontStyle: FontStyle.italic,
                        color:     Colors.white.withOpacity(0.85))),
                  ],
                ),
              ],
            ),
          ),

          // ── White card ───────────────────────────────────────────
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(
                        (screenW * 0.07).clamp(20.0, 32.0))),
                ),
                child: Column(children: [

                  // Search
                  Padding(
                    padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 10),
                    child: DASearchBar(controller: _searchCtrl),
                  ),

                  // Tabs
                  TabBar(
                    controller:     _tabController,
                    isScrollable:   false,
                    tabAlignment:   TabAlignment.fill,
                    indicatorColor: Colors.transparent,
                    dividerColor:   Colors.transparent,
                    labelPadding:   EdgeInsets.zero,
                    padding:        EdgeInsets.symmetric(horizontal: hPad),
                    tabs: _tabs.map((t) => _TabChip(
                      label: t,
                      color: statusColor(t.toLowerCase()),
                    )).toList(),
                  ),

                  const SizedBox(height: 8),

                  // Tab views
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [

                        // Draft — Profiler only
                        _TabContent(
                          records:  _filtered('draft'),
                          tabColor: statusColor('draft'),
                          hPad:     hPad,
                          locked:   !_isProfiler,
                          lockMsg:  'Draft records are only\naccessible to Profilers.',
                          onView: (ctx, r) => _handleView(ctx, r,
                            showEdit: true),
                        ),

                        // Unsync — Profiler only
                        _TabContent(
                          records:  _filtered('unsync'),
                          tabColor: statusColor('unsync'),
                          hPad:     hPad,
                          locked:   !_isProfiler,
                          lockMsg:  'Unsync records are only\naccessible to Profilers.',
                          onView: (ctx, r) => _handleView(ctx, r,
                            showSync: true),
                        ),

                        // Pending — all view, approve for Mod/Admin
                        _TabContent(
                          records:  _filtered('pending'),
                          tabColor: statusColor('pending'),
                          hPad:     hPad,
                          onView: (ctx, r) => _handleView(ctx, r,
                            showApprove:   _isModerator,
                            approveLocked: _isProfiler),
                        ),

                        // Approved — view only
                        _TabContent(
                          records:  _filtered('approved'),
                          tabColor: statusColor('approved'),
                          hPad:     hPad,
                          onView: (ctx, r) => _handleView(ctx, r),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ),

          SizedBox(height: navH),
        ],
      ),
    );
  }
}

// ── Tab chip ──────────────────────────────────────────────────────
class _TabChip extends StatelessWidget {
  const _TabChip({required this.label, required this.color});
  final String label;
  final Color  color;

  @override
  Widget build(BuildContext context) => Tab(
    child: Container(
      margin:    const EdgeInsets.symmetric(horizontal: 4),
      padding:   const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(50),
        border:       Border(bottom: BorderSide(color: color, width: 3)),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 6, offset: const Offset(0, 2))],
      ),
      alignment: Alignment.center,
      child: Text(label,
        style: GoogleFonts.poppins(
          fontSize: 12, fontWeight: FontWeight.w700,
          color: DAColors.textDark)),
    ),
  );
}

// ── Tab content ───────────────────────────────────────────────────
typedef _OnView = void Function(BuildContext, RecordModel);

class _TabContent extends StatelessWidget {
  const _TabContent({
    required this.records,
    required this.tabColor,
    required this.hPad,
    required this.onView,
    this.locked      = false,
    this.lockMsg     = '',
    this.showSync    = false,
    this.showApprove = false,
  });

  final List<RecordModel> records;
  final Color             tabColor;
  final double            hPad;
  final _OnView           onView;
  final bool              locked;
  final String            lockMsg;
  final bool              showSync;
  final bool              showApprove;

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      records.isEmpty
          ? Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_rounded, size: 48,
                  color: DAColors.textMuted.withOpacity(0.4)),
                const SizedBox(height: 12),
                Text('No records found',
                  style: GoogleFonts.poppins(
                    fontSize: 13, color: DAColors.textMuted)),
              ],
            ))
          : ListView.separated(
              padding:          EdgeInsets.fromLTRB(hPad, 8, hPad, 24),
              itemCount:        records.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final r = records[i];
                return Column(children: [
                  RecordCard(
                    record:   r,
                    tabColor: tabColor,
                    onTap:    () => onView(ctx, r),
                  ),
                  if (showSync || showApprove)
                    _ActionRow(
                      record:      r,
                      showSync:    showSync,
                      showApprove: showApprove,
                      context:     ctx,
                    ),
                ]);
              },
            ),

      if (locked)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.62),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(hPad)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_rounded,
                    color: Colors.white, size: 44),
                const SizedBox(height: 14),
                Text(lockMsg,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14, color: Colors.white,
                    fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
    ]);
  }
}

// ── Inline action row below each card ─────────────────────────────
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.record,
    required this.showSync,
    required this.showApprove,
    required this.context,
  });
  final RecordModel record;
  final bool        showSync;
  final bool        showApprove;
  final BuildContext context;

  @override
  Widget build(BuildContext ctx) => Container(
    margin: const EdgeInsets.only(top: 1),
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(14)),
      boxShadow: [BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 4, offset: const Offset(0, 2))]),
    child: Row(children: [
      if (showSync)
        Expanded(child: _btn('Sync', DAColors.greenMid, Icons.sync_rounded,
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Syncing ${record.name}...',
                style: GoogleFonts.poppins(fontSize: 12)),
            backgroundColor: DAColors.greenMid,
            behavior: SnackBarBehavior.floating,
          )))),
      if (showApprove) ...[
        Expanded(child: _btn('Approve', DAColors.greenMid, Icons.check_circle_outline_rounded,
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${record.name} approved!',
                style: GoogleFonts.poppins(fontSize: 12)),
            backgroundColor: DAColors.greenMid,
            behavior: SnackBarBehavior.floating,
          )))),
        const SizedBox(width: 8),
        Expanded(child: _btn('Decline', Colors.red, Icons.cancel_outlined,
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${record.name} declined.',
                style: GoogleFonts.poppins(fontSize: 12)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          )))),
      ],
    ]),
  );

  Widget _btn(String label, Color color, IconData icon,
      {required VoidCallback onTap}) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: color.withOpacity(0.30), width: 1)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.poppins(
            fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ]),
      ),
    );
}