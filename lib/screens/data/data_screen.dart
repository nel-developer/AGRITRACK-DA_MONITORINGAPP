import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../services/monitoring_record_service.dart';
import '../../services/pending_draft_service.dart';
import '../../services/user_session_service.dart';
import '../../services/local_farmer_storage_service.dart';
import '../../theme/da_colors.dart';
import '../../widgets/record_card.dart';
import '../../widgets/search_bar_widget.dart';
import 'member_records_screen.dart';
import 'record_view_modal.dart';

class DataScreen extends StatefulWidget {
  const DataScreen({super.key, this.refreshNotifier});

  final ValueNotifier<bool>? refreshNotifier;

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  String _query = '';
  Future<List<RecordModel>>? _recordsFuture;
  String _lastSessionKey = '';
  UserSession? _activeSession;
  String? _remoteStatusMessage;
  ValueNotifier<bool>? _refreshNotifier;

  static const _tabs = ['Unsync', 'Pending', 'Approved'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text));
    _recordsFuture = Future.value(const <RecordModel>[]);
    _refreshNotifier = widget.refreshNotifier;
    _refreshNotifier?.addListener(_refreshRecordsFromNotifier);
    PendingDraftService.instance.pendingDraftsUpdated
        .addListener(_refreshRecordsFromNotifier);
  }

  @override
  void didUpdateWidget(covariant DataScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshNotifier != widget.refreshNotifier) {
      oldWidget.refreshNotifier?.removeListener(_refreshRecordsFromNotifier);
      _refreshNotifier = widget.refreshNotifier;
      _refreshNotifier?.addListener(_refreshRecordsFromNotifier);
    }
  }

  @override
  void dispose() {
    _refreshNotifier?.removeListener(_refreshRecordsFromNotifier);
    PendingDraftService.instance.pendingDraftsUpdated
        .removeListener(_refreshRecordsFromNotifier);
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _refreshRecordsFromNotifier() {
    if (!mounted) return;
    setState(() {
      _recordsFuture = _loadRecords(_activeSession);
    });
  }

  List<RecordModel> _filtered(List<RecordModel> records, String status) {
    final q = _query.toLowerCase();
    return records
        .where((r) {
          if (status == 'unsync') {
            return r.status == 'unsync' || r.status == 'draft';
          }
          // Pending and approved lists must come from Firebase only
          if (status == 'pending' || status == 'approved') {
            return r.status == status && !r.isLocal;
          }
          return r.status == status;
        })
        .where((r) =>
            q.isEmpty ||
            r.name.toLowerCase().contains(q) ||
            r.productionType.toLowerCase().contains(q))
        .toList();
  }

  Future<List<RecordModel>> _loadRecords(UserSession? session) async {
    // Load all local records including draft, unsync, pending, approved
    final allLocalDrafts =
        await PendingDraftService.instance.getPendingDrafts();
    final localRecords = allLocalDrafts.map(_mapLocalDraftToRecord).toList();
    _remoteStatusMessage = null;

    // ALSO load unsync records from file system
    try {
      final unsyncRecordsFromDisk =
          await LocalFarmerStorageService.instance.getAllUnsyncRecords();

      // Group unsync records by productionType/groupName
      final unsyncByGroup = <String, List<Map<String, dynamic>>>{};
      for (final record in unsyncRecordsFromDisk) {
        final groupKey = '${record['productionType']}/${record['groupName']}';
        unsyncByGroup.putIfAbsent(groupKey, () => []).add(record);
      }

      // Convert grouped unsync records to RecordModel
      final unsyncModels = <RecordModel>[];
      for (final groupKey in unsyncByGroup.keys) {
        final farmerRecords = unsyncByGroup[groupKey] ?? [];
        final firstRecord = farmerRecords.first;

        final groupName = (firstRecord['groupName'] as String? ?? '').trim();
        final implType =
            (firstRecord['implType'] as String? ?? 'individual').toLowerCase();
        final productionType =
            firstRecord['productionType'] as String? ?? 'crop';

        // Build membersByFarmerId from all farmers in this group
        final membersByFarmerId = <String, dynamic>{};
        for (final farmerRecord in farmerRecords) {
          final farmerName =
              (farmerRecord['farmerName'] as String? ?? '').trim();
          final saadId = (farmerRecord['saadId'] as String? ?? '').trim();
          final farmerData =
              (farmerRecord['data'] as Map<String, dynamic>?) ?? {};

          if (farmerName.isNotEmpty && saadId.isNotEmpty) {
            membersByFarmerId[saadId] = {
              'name': farmerName,
              'farmerName': farmerName,
              'saadIdNo': saadId,
              ...farmerData,
            };
          }
        }

        // Extract project background data from first farmer record (which has merged group.json data)
        final firstFarmerData =
            (firstRecord['data'] as Map<String, dynamic>?) ?? {};
        final projectBackgroundFields = {
          // Group/FCA info
          'fcaName': firstFarmerData['fcaName'] ?? '',
          'implementationType': firstFarmerData['implementationType'] ?? '',
          // Project/Location info
          'projectTitle': firstFarmerData['projectTitle'] ?? '',
          'reportingPeriod': firstFarmerData['reportingPeriod'] ?? '',
          'region': firstFarmerData['region'] ?? '',
          'province': firstFarmerData['province'] ?? '',
          'municipality': firstFarmerData['municipality'] ?? '',
          'barangay': firstFarmerData['barangay'] ?? '',
          // Interventions
          'primaryIntervention': firstFarmerData['primaryIntervention'] ?? '',
          'primaryInterventionOther':
              firstFarmerData['primaryInterventionOther'] ?? '',
          'supportInterventions': firstFarmerData['supportInterventions'] ?? '',
          // Members for collective
          'members': firstFarmerData['members'] ?? [],
        };

        final unsyncModel = RecordModel(
          id: groupKey,
          name: groupName,
          productionType: productionType,
          implType: _titleCase(implType),
          enumerator: 'Offline Profiler',
          date: _formatDateForModel(DateTime.now()),
          status: 'unsync',
          data: {
            ...projectBackgroundFields,
            'groupName': groupName,
            'membersByFarmerId': membersByFarmerId,
          },
          isLocal: true,
        );
        unsyncModels.add(unsyncModel);
      }

      // Combine local drafts and unsync records (but avoid duplicates)
      for (final unsyncModel in unsyncModels) {
        // Only add if not already in localRecords (by ID)
        if (!localRecords.any((r) => r.id == unsyncModel.id)) {
          localRecords.add(unsyncModel);
        }
      }
    } catch (e) {
      print('❌ Error loading unsync records from disk: $e');
    }

    if (session == null) {
      _remoteStatusMessage = 'Sign in to load and sync records from Firebase.';
      return localRecords;
    }

    try {
      // Fetch pending records from pending_monitoring collection
      final pendingRecords =
          await MonitoringRecordService.instance.fetchPendingRecords(
        createdBy: session.isModerator ? null : session.uid,
      );

      // Fetch approved records from approved_monitoring collection
      final approvedRecords =
          await MonitoringRecordService.instance.fetchApprovedRecords(
        createdBy: session.isModerator ? null : session.uid,
      );

      return [
        ...localRecords,
        ...pendingRecords.map(_mapRemoteRecordToRecord),
        ...approvedRecords.map((r) {
          final record = _mapRemoteRecordToRecord(r);
          return RecordModel(
            id: record.id,
            name: record.name,
            productionType: record.productionType,
            implType: record.implType,
            enumerator: record.enumerator,
            date: record.date,
            status: 'approved',
            documentPath: record.documentPath,
            data: record.data,
          );
        }),
      ];
    } catch (error) {
      _remoteStatusMessage = _isNetworkError(error)
          ? 'No internet connection. Showing local records only.'
          : 'Unable to load pending and approved records from Firebase.';
      return localRecords;
    }
  }

  Future<void> _deleteRecord(RecordModel record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Record'),
        content: Text(
            'Are you sure you want to delete "${record.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Delete from PendingDraftService (local storage)
      await PendingDraftService.instance.deleteDraftByLocalId(record.id ?? '');

      // Also delete from file system if it's an unsync folder-based record
      if (record.status.toLowerCase() == 'unsync' && record.isLocal) {
        await LocalFarmerStorageService.instance.deleteGroupRecord(
          productionType: record.productionType.toLowerCase(),
          groupName: record.name,
        );
      }

      // Get updated session and refresh the list
      final session = await UserSessionService.instance.getCurrentSession();
      if (mounted) {
        setState(() {
          _recordsFuture = _loadRecords(session);
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${record.name} deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  RecordModel _mapLocalDraftToRecord(Map<String, dynamic> draft) {
    final data = Map<String, dynamic>.from(draft['data'] as Map? ?? {});
    final implementationType =
        (draft['implementationType'] as String? ?? '').toLowerCase();
    final fcaName = (data['fcaName'] as String? ?? '').trim();
    final farmerName = (data['farmerName'] as String? ?? '').trim();
    final saadIdNo = (data['saadIdNo'] as String? ?? '').trim();
    final fileName = (draft['fileName'] as String?)?.trim() ?? '';

    // For ALL types (collective, individual, hybrid), prioritize Group/FCA name
    // Farmer name shows only in Members Monitoring section
    final isGroup = implementationType == 'collective';

    String displayName;

    // PRIORITY: Always show Group/FCA name for all implementation types
    if (fcaName.isNotEmpty) {
      if (isGroup) {
        // For collectives, show with member count
        final members = (data['members'] as List?)?.length ?? 0;
        displayName = members > 0 ? '$fcaName ($members members)' : fcaName;
      } else {
        // For individuals/hybrids, just show group name (farmer info in Members section)
        displayName = fcaName;
      }
    } else if (saadIdNo.isNotEmpty && farmerName.isNotEmpty) {
      // Fallback: For individuals with SAAD ID (no FCA name)
      displayName = '$saadIdNo - $farmerName';
    } else if (farmerName.isNotEmpty) {
      // Fallback: For individuals without SAAD ID (no FCA name)
      displayName = farmerName;
    } else if (fileName.isNotEmpty) {
      displayName = fileName;
    } else {
      displayName = 'Offline Record';
    }

    final rawStatus = (draft['status'] as String? ?? 'unsync').toLowerCase();
    final normalizedStatus = rawStatus == 'draft' ? 'unsync' : rawStatus;

    return RecordModel(
      id: draft['localId'] as String?,
      name: displayName,
      productionType:
          _toDisplayProductionType(draft['productionType'] as String? ?? ''),
      implType: _toDisplayImplementationType(
          draft['implementationType'] as String? ?? ''),
      enumerator: (data['enumerator'] as String?) ?? 'Offline Profiler',
      date: _formatDate(draft['savedLocallyAt'] as String?),
      status: normalizedStatus,
      data: data,
      isLocal: true,
    );
  }

  RecordModel _mapRemoteRecordToRecord(Map<String, dynamic> record) {
    final saadIdNo = (record['saadIdNo'] as String? ?? '').trim();
    final farmerName = (record['farmerName'] as String? ?? '').trim();
    final fcaName = (record['fcaName'] as String? ?? '').trim();

    return RecordModel(
      id: record['id'] as String?,
      name: saadIdNo.isNotEmpty && farmerName.isNotEmpty
          ? '$saadIdNo - $farmerName'
          : (fcaName.isNotEmpty
              ? fcaName
              : (farmerName.isNotEmpty ? farmerName : 'Synced Record')),
      productionType:
          _toDisplayProductionType(record['productionType'] as String? ?? ''),
      implType: _toDisplayImplementationType(
          record['implementationType'] as String? ?? ''),
      enumerator: (record['enumerator'] as String?) ?? 'Profiler',
      date: _formatDate(record['createdAt']?.toString()),
      status: 'pending', // Will be overridden by caller if approved
      documentPath: record['documentPath'] as String?,
      data: record,
    );
  }

  String _toDisplayProductionType(String value) {
    switch (value.toLowerCase()) {
      case 'crop':
      case 'crop_production':
        return 'Crop';
      case 'livestock':
      case 'livestock_production':
        return 'Livestock';
      case 'poultry':
      case 'poultry_production':
        return 'Poultry';
      default:
        return value.isEmpty ? 'Unknown' : value;
    }
  }

  String _toDisplayImplementationType(String value) {
    switch (value.toLowerCase()) {
      case 'collective':
        return 'Collective';
      case 'individual':
        return 'Individual';
      case 'hybrid':
        return 'Hybrid';
      default:
        return value.isEmpty ? 'Unknown' : value;
    }
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return 'No date';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final month = parsed.month.toString().padLeft(2, '0');
    final day = parsed.day.toString().padLeft(2, '0');
    return '${parsed.year}-$month-$day';
  }

  Future<void> _updateReviewStatus(RecordModel record, String reviewStatus,
      {bool isModerator = false, bool isAdmin = false}) async {
    try {
      // If it's a local record (draft/unsync), update locally
      if (record.isLocal && record.id != null) {
        await PendingDraftService.instance
            .updateDraftStatus(record.id!, reviewStatus);

        if (!mounted) return;
        setState(() {
          _recordsFuture = _loadRecords(_activeSession);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              reviewStatus == 'approved'
                  ? '${record.name} marked as approved'
                  : '${record.name} marked as declined',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            backgroundColor:
                reviewStatus == 'approved' ? DAColors.greenMid : Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // For remote records, check role and move between collections
      if (record.id == null) return;

      if (reviewStatus == 'approved') {
        // Approve: move from pending to approved (moderator/admin only)
        await MonitoringRecordService.instance.approveRecord(
          recordId: record.id!,
          isModerator: isModerator,
          isAdmin: isAdmin,
        );
      } else {
        // Decline: delete from pending (moderator/admin only)
        await MonitoringRecordService.instance.declineRecord(
          recordId: record.id!,
          isModerator: isModerator,
          isAdmin: isAdmin,
        );
      }

      if (!mounted) return;
      setState(() {
        _recordsFuture = _loadRecords(_activeSession);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            reviewStatus == 'approved'
                ? '${record.name} approved!'
                : '${record.name} declined.',
            style: GoogleFonts.poppins(fontSize: 12),
          ),
          backgroundColor:
              reviewStatus == 'approved' ? DAColors.greenMid : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final errorMsg = error.toString();
      _showActionError(
        errorMsg.contains('Only moderators')
            ? 'Only moderators and admins can approve records.'
            : (_isNetworkError(error)
                ? 'Review actions need internet connection.'
                : 'Unable to update review status right now. $errorMsg'),
      );
    }
  }

  void _showActionError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(fontSize: 12),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _titleCase(String str) {
    if (str.isEmpty) return str;
    return str[0].toUpperCase() + str.substring(1).toLowerCase();
  }

  String _formatDateForModel(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  bool _isNetworkError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('network-request-failed') ||
        message.contains('failed host lookup') ||
        message.contains('socketexception') ||
        message.contains('unavailable') ||
        message.contains('network is unreachable');
  }

  /// ✅ Check if device has active internet connection
  Future<bool> _hasInternetConnection() async {
    try {
      final result = await Connectivity().checkConnectivity();
      print('📡 Connectivity status: $result');

      // Check if connected to WiFi, Mobile, Ethernet, or VPN
      final hasConnection = result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn;

      print('   Has connection: $hasConnection');
      return hasConnection;
    } catch (e) {
      print('⚠️ Could not check connectivity: $e');
      return false;
    }
  }

  Future<void> _handleView(
    BuildContext context,
    RecordModel record, {
    bool showEdit = false,
    bool showSync = false,
    bool showApprove = false,
    bool approveLocked = false,
    VoidCallback? onSync,
    VoidCallback? onApprove,
    VoidCallback? onDecline,
    VoidCallback? onKeepAsDraft,
  }) async {
    final implType = record.implType.toLowerCase();
    final hasMemberData = (record.data?['membersByFarmerId'] is Map &&
            (record.data?['membersByFarmerId'] as Map).isNotEmpty) ||
        (record.data?['members'] is List &&
            (record.data?['members'] as List).isNotEmpty);

    print(
        '🔍 _handleView: record.name=${record.name}, implType=$implType, status=${record.status}');
    print('   data keys: ${record.data?.keys.toList() ?? "null"}');
    print(
        '   membersByFarmerId: ${record.data?['membersByFarmerId'] is Map ? (record.data?['membersByFarmerId'] as Map).length : "not a map"} members');
    print(
        '   members: ${record.data?['members'] is List ? (record.data?['members'] as List).length : "not a list"}');
    print(
        '   hasMemberData=$hasMemberData, implType matches collective/hybrid: ${implType == 'collective' || implType == 'hybrid'}');

    if (implType == 'collective' || implType == 'hybrid' || hasMemberData) {
      print('   ✅ Going to MemberRecordsScreen');
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MemberRecordsScreen(record: record),
        ),
      );
    } else {
      print('   ✅ Showing modal (old behavior)');
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => RecordViewModal(
          record: record,
          showEdit: showEdit,
          showSync: showSync,
          showApprove: showApprove,
          approveLocked: approveLocked,
          onSync: onSync,
          onApprove: onApprove,
          onDecline: onDecline,
          onKeepAsDraft: onKeepAsDraft,
        ),
      );
    }

    if (!mounted) return;
    setState(() {
      _recordsFuture = _loadRecords(_activeSession);
    });
  }

  Future<void> _syncLocalRecordToFirebase(RecordModel record) async {
    try {
      if (record.id == null || record.id!.isEmpty) {
        throw Exception('Missing local record id for sync.');
      }

      // ✅ CHECK INTERNET CONNECTION FIRST
      print('🔍 Checking internet connection before sync...');
      final hasInternet = await _hasInternetConnection();

      if (!hasInternet) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No internet connection. Please check your WiFi or mobile data and try again.',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(DAColors.greenMid),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Syncing to Firebase...',
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      );

      print('📤 Starting sync for record: ${record.id}');
      await PendingDraftService.instance.syncDraftByLocalId(record.id!);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${record.name} synced to Firebase!',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor: DAColors.greenMid,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      setState(() {
        _recordsFuture = _loadRecords(_activeSession);
      });
    } catch (error) {
      print('❌ SYNC ERROR: $error');
      print('   Error type: ${error.runtimeType}');
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isNetworkError(error)
                ? 'Sync needs internet connection. Please check your connection and try again.'
                : 'Unable to sync to Firebase right now. Please try again.',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenH = mq.size.height;
    final screenW = mq.size.width;
    final topPad = mq.padding.top;
    final botPad = mq.padding.bottom;
    final navH = kBottomNavigationBarHeight + botPad;
    final totalH = screenH - topPad - navH;
    final imageH = totalH * 0.22;
    final titleFSz = (imageH * 0.26).clamp(22.0, 36.0);
    final subtitleFSz = (imageH * 0.07).clamp(11.0, 14.0);
    final hPad = screenW * 0.048;

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return StreamBuilder<UserSession?>(
      stream: UserSessionService.instance.sessionStream,
      builder: (context, snapshot) {
        _activeSession = snapshot.data;
        final sessionKey = _activeSession?.uid ?? 'guest';
        if (_recordsFuture == null || _lastSessionKey != sessionKey) {
          _lastSessionKey = sessionKey;
          _recordsFuture = _loadRecords(_activeSession);
        }

        final isModerator = _activeSession?.isModerator ?? false;
        final isAdmin = _activeSession?.isAdmin ?? false;

        return Scaffold(
          backgroundColor: const Color(0xFFF2F2F2),
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
                          end: Alignment.bottomCenter,
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
                                fontSize: titleFSz,
                                color: Colors.white,
                                letterSpacing: 4)),
                        SizedBox(height: imageH * 0.04),
                        Text('All of those numbers are available here',
                            style: GoogleFonts.poppins(
                                fontSize: subtitleFSz,
                                fontStyle: FontStyle.italic,
                                color: Colors.white.withOpacity(0.85))),
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
                      // Search + Clear Drafts (Debug)
                      Padding(
                        padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: DASearchBar(controller: _searchCtrl),
                            ),
                            const SizedBox(width: 12),
                            // Debug: Clear all drafts button
                            Material(
                              color: Colors.transparent,
                              child: Tooltip(
                                message: 'Clear all draft records',
                                child: InkWell(
                                  onTap: () async {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Clear All Drafts?'),
                                        content: const Text(
                                          'This will delete all local draft records. This cannot be undone.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              await PendingDraftService.instance
                                                  .clearAllDrafts();
                                              if (mounted) {
                                                Navigator.pop(ctx);
                                                setState(() {
                                                  _recordsFuture = _loadRecords(
                                                      _activeSession);
                                                });
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        'All drafts cleared'),
                                                    duration:
                                                        Duration(seconds: 2),
                                                  ),
                                                );
                                              }
                                            },
                                            child: const Text('Clear',
                                                style: TextStyle(
                                                    color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Icon(
                                      Icons.delete_outline,
                                      color: DAColors.textMuted,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Tabs
                      TabBar(
                        controller: _tabController,
                        isScrollable: false,
                        tabAlignment: TabAlignment.fill,
                        indicatorColor: Colors.transparent,
                        dividerColor: Colors.transparent,
                        labelPadding: EdgeInsets.zero,
                        padding: EdgeInsets.symmetric(horizontal: hPad),
                        tabs: _tabs
                            .map((t) => _TabChip(
                                  label: t,
                                  color: statusColor(t.toLowerCase()),
                                ))
                            .toList(),
                      ),

                      const SizedBox(height: 8),

                      // Tab views
                      Expanded(
                        child: FutureBuilder<List<RecordModel>>(
                          future: _recordsFuture,
                          builder: (context, recordsSnapshot) {
                            final allRecords =
                                recordsSnapshot.data ?? const <RecordModel>[];
                            final remoteStatusMessage = _remoteStatusMessage;

                            if (recordsSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                    color: DAColors.greenMid),
                              );
                            }

                            return TabBarView(
                              controller: _tabController,
                              children: [
                                // Unsync
                                _TabContent(
                                  records: _filtered(allRecords, 'unsync'),
                                  tabColor: statusColor('unsync'),
                                  hPad: hPad,
                                  emptyMessage: 'No unsynced records found',
                                  onDelete: _deleteRecord,
                                  locked: false,
                                  lockMsg: '',
                                  onView: (ctx, r) => _handleView(
                                    ctx,
                                    r,
                                    showEdit: true,
                                    showSync: true,
                                    onSync: () => _syncLocalRecordToFirebase(r),
                                    onKeepAsDraft: () {
                                      // Keep as draft - just refresh the list
                                      setState(() {
                                        _recordsFuture =
                                            _loadRecords(_activeSession);
                                      });
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text('Kept as draft'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                // Pending
                                _TabContent(
                                  records: _filtered(allRecords, 'pending'),
                                  tabColor: statusColor('pending'),
                                  hPad: hPad,
                                  emptyMessage: remoteStatusMessage ??
                                      'No pending records found',
                                  onDelete: _deleteRecord,
                                  locked: false,
                                  lockMsg: '',
                                  onView: (ctx, r) {
                                    // For local pending records, show approve/decline without moderator check
                                    final isLocalPending =
                                        r.isLocal && r.status == 'pending';
                                    final isModeratorOrAdmin = isModerator ||
                                        (_activeSession?.isAdmin ?? false);
                                    _handleView(
                                      ctx,
                                      r,
                                      showApprove:
                                          isModeratorOrAdmin || isLocalPending,
                                      approveLocked: isModeratorOrAdmin
                                          ? false
                                          : !isLocalPending,
                                      onApprove: () => _updateReviewStatus(
                                          r, 'approved',
                                          isModerator: isModerator,
                                          isAdmin:
                                              _activeSession?.isAdmin ?? false),
                                      onDecline: () => _updateReviewStatus(
                                          r, 'declined',
                                          isModerator: isModerator,
                                          isAdmin:
                                              _activeSession?.isAdmin ?? false),
                                    );
                                  },
                                ),

                                // Approved
                                _TabContent(
                                  records: _filtered(allRecords, 'approved'),
                                  tabColor: statusColor('approved'),
                                  hPad: hPad,
                                  emptyMessage: remoteStatusMessage ??
                                      'No approved records found',
                                  onDelete: _deleteRecord,
                                  locked: false,
                                  lockMsg: '',
                                  onView: (ctx, r) => _handleView(
                                    ctx,
                                    r,
                                  ),
                                ),
                              ],
                            );
                          },
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
      },
    );
  }
}

// ── Tab chip ──────────────────────────────────────────────────────
class _TabChip extends StatelessWidget {
  const _TabChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Tab(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(50),
            border: Border(bottom: BorderSide(color: color, width: 3)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ],
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
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
    required this.emptyMessage,
    this.onDelete,
    this.locked = false,
    this.lockMsg = '',
  });

  final List<RecordModel> records;
  final Color tabColor;
  final double hPad;
  final _OnView onView;
  final Function(RecordModel)? onDelete;
  final String emptyMessage;
  final bool locked;
  final String lockMsg;
  final bool showSync = false;
  final bool showApprove = false;

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      records.isEmpty
          ? Center(
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_rounded,
                    size: 48, color: DAColors.textMuted.withOpacity(0.4)),
                const SizedBox(height: 12),
                Text(emptyMessage,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: DAColors.textMuted)),
              ],
            ))
          : ListView.separated(
              padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 24),
              itemCount: records.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final r = records[i];
                return Column(children: [
                  RecordCard(
                    record: r,
                    tabColor: tabColor,
                    onTap: () => onView(ctx, r),
                    onDelete: onDelete != null ? () => onDelete!(r) : null,
                  ),
                  if (showSync || showApprove)
                    _ActionRow(
                      record: r,
                      showSync: showSync,
                      showApprove: showApprove,
                      context: ctx,
                    ),
                ]);
              },
            ),
      if (locked)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.62),
              borderRadius: BorderRadius.vertical(top: Radius.circular(hPad)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_rounded, color: Colors.white, size: 44),
                const SizedBox(height: 14),
                Text(lockMsg,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white,
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
  final bool showSync;
  final bool showApprove;
  final BuildContext context;

  @override
  Widget build(BuildContext ctx) => Container(
        margin: const EdgeInsets.only(top: 1),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(14)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2))
            ]),
        child: Row(children: [
          if (showSync)
            Expanded(
                child: _btn('Sync', DAColors.greenMid, Icons.sync_rounded,
                    onTap: () =>
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Syncing ${record.name}...',
                              style: GoogleFonts.poppins(fontSize: 12)),
                          backgroundColor: DAColors.greenMid,
                          behavior: SnackBarBehavior.floating,
                        )))),
          if (showApprove) ...[
            Expanded(
                child: _btn('Approve', DAColors.greenMid,
                    Icons.check_circle_outline_rounded,
                    onTap: () =>
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('${record.name} approved!',
                              style: GoogleFonts.poppins(fontSize: 12)),
                          backgroundColor: DAColors.greenMid,
                          behavior: SnackBarBehavior.floating,
                        )))),
            const SizedBox(width: 8),
            Expanded(
                child: _btn('Decline', Colors.red, Icons.cancel_outlined,
                    onTap: () =>
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
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
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ]),
        ),
      );
}
