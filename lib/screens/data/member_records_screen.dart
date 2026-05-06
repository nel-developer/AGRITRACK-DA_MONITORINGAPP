import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/monitoring_record_service.dart';
import '../../services/pending_draft_service.dart';
import '../../services/user_session_service.dart';
import '../../services/local_farmer_storage_service.dart';
import '../../theme/da_colors.dart';
import '../../widgets/member_card.dart';
import '../../widgets/record_card.dart';
import '../../routes/app_routes.dart';
import '../crop/crop_step_wrapper.dart';
import '../livestock/livestock_step_wrapper.dart';
import '../poultry/poultry_step_wrapper.dart';
import 'record_view_modal.dart';

class _DynamicMemberRecord {
  const _DynamicMemberRecord({
    required this.member,
    required this.record,
  });

  final MemberModel member;
  final RecordModel record;
}

class MemberRecordsScreen extends StatefulWidget {
  const MemberRecordsScreen({super.key, required this.record});
  final RecordModel record;

  @override
  State<MemberRecordsScreen> createState() => _MemberRecordsScreenState();
}

class _MemberRecordsScreenState extends State<MemberRecordsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  late Future<UserSession?> _sessionFuture;
  Future<List<_DynamicMemberRecord>>? _membersFuture;
  String? _remoteStatusMessage;

  String _targetFcaNameForNavigation() {
    final fromRecord = (widget.record.data?['fcaName'] as String? ?? '').trim();
    if (fromRecord.isNotEmpty) return fromRecord;
    return widget.record.name.trim();
  }

  bool get _isHybrid => widget.record.implType == 'Hybrid';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text));
    _sessionFuture = UserSessionService.instance.getCurrentSession();
    _membersFuture = _loadMembers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  int _recordPriority(RecordModel record) {
    switch (record.status) {
      // ✅ Pending has highest priority (manually synced to Firebase)
      case 'pending':
        return 3;
      case 'unsync':
        return 2;
      case 'approved':
        return 1;
      default:
        return 0;
    }
  }

  Future<List<_DynamicMemberRecord>> _loadMembers() async {
    final session = await UserSessionService.instance.getCurrentSession();
    // ✅ Read unsync records directly from local farmer folders
    final unsyncRecordsFromFolders =
        await LocalFarmerStorageService.instance.getAllUnsyncRecords();
    _remoteStatusMessage = null;

    final parentFcaName =
        (widget.record.data?['fcaName'] as String? ?? '').trim();

    String normalizeName(String value) => value.trim().toLowerCase();
    String normalizeKey(String value) =>
        normalizeName(value).replaceAll(RegExp(r'[\s_]+'), '_');

    final targetFcaNames = {
      normalizeName(widget.record.name),
      normalizeName(parentFcaName),
      normalizeKey(widget.record.name),
      normalizeKey(parentFcaName),
    }..removeWhere((name) => name.isEmpty);

    var remoteRecords = <Map<String, dynamic>>[];
    if (session == null) {
      _remoteStatusMessage = 'Sign in to load member records from Firebase.';
    } else {
      try {
        // Fetch both pending and approved records
        final pendingRecords =
            await MonitoringRecordService.instance.fetchPendingRecords(
          createdBy: session.isModerator ? null : session.uid,
        );
        final approvedRecords =
            await MonitoringRecordService.instance.fetchApprovedRecords(
          createdBy: session.isModerator ? null : session.uid,
        );
        remoteRecords = [...pendingRecords, ...approvedRecords];
      } catch (error) {
        _remoteStatusMessage = _isNetworkError(error)
            ? 'No internet connection. Member records from Firebase are unavailable offline.'
            : 'Unable to load member records from Firebase.';
      }
    }

    final relatedRecords = <RecordModel>[];

    List<dynamic> extractCommodities(
      Map<String, dynamic>? source,
      Map<String, dynamic>? fallback,
    ) {
      return (source?['commodities'] as List?) ??
          (source?['completedCommodities'] as List?) ??
          (source?['completedBatches'] as List?) ??
          (fallback?['commodities'] as List?) ??
          (fallback?['completedCommodities'] as List?) ??
          (fallback?['completedBatches'] as List?) ??
          const [];
    }

    RecordModel withMemberData(
      RecordModel parent,
      Map<String, dynamic> memberData,
    ) {
      // ✅ CRITICAL: Start with ONLY farmer-specific data from memberData
      // Do NOT copy all parent data which contains all commodities/batches
      final mergedData = <String, dynamic>{};

      // Copy group-level fields from parent (NOT commodities or farmer-specific data)
      final parentData = parent.data ?? {};
      for (final key in [
        'fcaName',
        'reportingPeriod',
        'projectTitle',
        'implementationType',
        'productionType',
        'enumerator',
        'location',
        'region',
        'district',
        'ward'
      ]) {
        if (parentData.containsKey(key)) {
          mergedData[key] = parentData[key];
        }
      }

      // For a member-specific view, show this as an individual record.
      mergedData['implementationType'] = 'individual';

      // ✅ Set farmer-specific identity
      final memberName = ((memberData['name'] as String?) ??
              (memberData['farmerName'] as String?) ??
              '')
          .trim();
      if (memberName.isNotEmpty) {
        mergedData['farmerName'] = memberName;
      }
      final memberSaadId = (memberData['saadIdNo'] as String? ?? '').trim();
      if (memberSaadId.isNotEmpty) {
        mergedData['saadIdNo'] = memberSaadId;
      }

      // ✅ Use ONLY this farmer's commodities/batches (not shared)
      // SAFETY: These must come from memberData, NOT from parent.data
      // For Firestore synced records, commodities are stored directly
      // For local drafts, they may be completedCommodities or completedBatches
      final farmerCommodities = (memberData['commodities'] as List?) ??
          (memberData['completedCommodities'] as List?) ??
          [];
      final farmerBatches = (memberData['completedBatches'] as List?) ?? [];

      print(
          '🔍 withMemberData for $memberName: ${farmerCommodities.length} commodities, ${farmerBatches.length} batches');

      if (farmerCommodities.isNotEmpty) {
        mergedData['completedCommodities'] = farmerCommodities;
        mergedData['commodities'] = farmerCommodities;
        // Also merge the first commodity's data for display
        final commodityData = farmerCommodities.first;
        if (commodityData is Map<String, dynamic>) {
          // Merge commodity fields but preserve farmerName/saadIdNo
          final farmerIdentity = {
            'farmerName': memberName,
            'saadIdNo': memberSaadId,
          };
          mergedData.addAll({...commodityData, ...farmerIdentity});
        }
      }

      if (farmerBatches.isNotEmpty) {
        mergedData['completedBatches'] = farmerBatches;
        mergedData['commodities'] = farmerBatches;
        // Also merge the first batch's data for display
        final batchData = farmerBatches.first;
        if (batchData is Map<String, dynamic>) {
          // Merge batch fields but preserve farmerName/saadIdNo
          final farmerIdentity = {
            'farmerName': memberName,
            'saadIdNo': memberSaadId,
          };
          mergedData.addAll({...batchData, ...farmerIdentity});
        }
      }

      final trainings = (memberData['trainings'] as List?) ?? [];
      if (trainings.isNotEmpty) {
        mergedData['trainings'] = trainings;
      }

      return RecordModel(
        id: parent.id,
        name: memberName.isNotEmpty ? memberName : parent.name,
        productionType: parent.productionType,
        implType: 'Individual',
        enumerator: parent.enumerator,
        date: parent.date,
        status: parent.status,
        documentPath: parent.documentPath,
        data: mergedData,
        isLocal: parent.isLocal,
      );
    }

    // ✅ Process unsync records directly from local folders
    for (final record in unsyncRecordsFromFolders) {
      final rawData = (record['data'] as Map<String, dynamic>?) ?? {};
      final data = Map<String, dynamic>.from(rawData);
      final productionType =
          (record['productionType'] as String? ?? '').toLowerCase();
      final groupName = (record['groupName'] as String? ?? '').trim();
      final folderFarmerName = (record['farmerName'] as String? ?? '').trim();
      final folderSaadId = (record['saadId'] as String? ?? '').trim();
      final fcaName = (data['fcaName'] as String? ?? groupName).trim();

      if ((data['farmerName'] as String?)?.trim().isEmpty == true) {
        data['farmerName'] = folderFarmerName;
      }
      if ((data['saadIdNo'] as String?)?.trim().isEmpty == true) {
        data['saadIdNo'] = folderSaadId;
      }

      final localGroupNames = {
        normalizeName(fcaName),
        normalizeName(groupName),
        normalizeKey(fcaName),
        normalizeKey(groupName),
      }..removeWhere((name) => name.isEmpty);

      final isSameFca = targetFcaNames.isEmpty
          ? localGroupNames.isEmpty
          : targetFcaNames.any(localGroupNames.contains);

      if (isSameFca &&
          productionType == widget.record.productionType.toLowerCase()) {
        print('✅ Loading unsync record: $groupName / $productionType');
        relatedRecords.add(
          RecordModel(
            id: '${groupName}_${record['saadId']}',
            name: folderFarmerName.isNotEmpty
                ? folderFarmerName
                : (fcaName.isEmpty ? groupName : fcaName),
            productionType: widget.record.productionType,
            implType: 'Individual',
            enumerator: 'Offline Profiler',
            date: _formatDate(DateTime.now().toIso8601String()),
            status: 'unsync',
            data: data,
            isLocal: true,
          ),
        );
      }
    }

    for (final record in remoteRecords) {
      final fcaName = (record['fcaName'] as String? ?? '').trim();
      final productionType =
          (record['productionType'] as String? ?? '').toLowerCase();
      final remoteGroupNames = {
        normalizeName(fcaName),
        normalizeKey(fcaName),
      }..removeWhere((name) => name.isEmpty);
      final isSameFca = targetFcaNames.isEmpty
          ? remoteGroupNames.isEmpty
          : targetFcaNames.any(remoteGroupNames.contains);

      if (isSameFca &&
          (productionType == widget.record.productionType.toLowerCase() ||
              productionType ==
                  '${widget.record.productionType.toLowerCase()}_production')) {
        relatedRecords.add(
          RecordModel(
            id: record['id'] as String?,
            name: fcaName,
            productionType: widget.record.productionType,
            implType: _titleCase(record['implementationType'] as String? ?? ''),
            enumerator: (record['enumerator'] as String?) ?? 'Profiler',
            date: _formatDate(record['createdAt']?.toString()),
            status: ((record['reviewStatus'] as String?)?.toLowerCase() ==
                    'approved')
                ? 'approved'
                : 'pending',
            data: record,
            documentPath: record['documentPath'] as String?,
          ),
        );
      }
    }

    final members = <String, _DynamicMemberRecord>{};
    print(
        '🔍 _loadMembers: Processing ${relatedRecords.length} related records');

    for (final record in relatedRecords) {
      final farmerName = (record.data?['farmerName'] as String? ?? '').trim();
      final membersList = (record.data?['members'] as List?) ?? [];
      final rawMembersByFarmerId = record.data?['membersByFarmerId'];
      final membersByFarmerId = rawMembersByFarmerId is Map
          ? Map<String, dynamic>.from(rawMembersByFarmerId)
          : <String, dynamic>{};

      print(
          '🔍 Processing record: ${record.name}, implType: ${record.implType}, farmerName: "$farmerName", membersByFarmerId: ${membersByFarmerId.length} entries, membersList: ${membersList.length} entries');

      // ── Case 1: Individual/Hybrid record with a specific farmer's name ──
      // Only process if this is NOT a group record with membersByFarmerId
      if (farmerName.isNotEmpty && membersByFarmerId.isEmpty) {
        final status = record.status == 'unsync' ? 'in_progress' : 'completed';
        final candidate = _DynamicMemberRecord(
          member: MemberModel(name: farmerName, status: status),
          record: record,
        );
        final existing = members[farmerName];
        if (existing == null ||
            _recordPriority(candidate.record) >
                _recordPriority(existing.record)) {
          members[farmerName] = candidate;
        }
      }

      // ── Case 2: Group/Collective record with membersByFarmerId map ──
      // CRITICAL: Read from membersByFarmerId (safe map) instead of members array (old array)
      // Process this for ALL records that have membersByFarmerId, regardless of root farmerName
      if (membersByFarmerId.isNotEmpty) {
        for (final entry in membersByFarmerId.entries) {
          final saadId = entry.key;
          final farmerDataRaw = entry.value;
          if (farmerDataRaw is Map) {
            final farmerData = Map<String, dynamic>.from(farmerDataRaw);
            var name = ((farmerData['name'] as String?) ??
                    (farmerData['farmerName'] as String?) ??
                    '')
                .trim();
            if (name.isEmpty) {
              name = saadId.trim();
            }
            if (name.isNotEmpty) {
              final status =
                  record.status == 'unsync' ? 'in_progress' : 'completed';
              final memberRecord = withMemberData(record, farmerData);
              final candidate = _DynamicMemberRecord(
                member: MemberModel(name: name, status: status),
                record: memberRecord,
              );
              final existing = members[name];
              if (existing == null ||
                  _recordPriority(candidate.record) >
                      _recordPriority(existing.record)) {
                members[name] = candidate;
              }
              print('✅ Extracted member from Case 2: $name (saadId: $saadId)');
            }
          }
        }
      }

      // ── Case 3: Fallback to old members array for backward compatibility ──
      // Only if no membersByFarmerId and no farmerName
      else if (membersList.isNotEmpty && farmerName.isEmpty) {
        for (final memberRaw in membersList) {
          if (memberRaw is Map) {
            final member = Map<String, dynamic>.from(memberRaw);
            var name = ((member['name'] as String?) ??
                    (member['farmerName'] as String?) ??
                    '')
                .trim();
            if (name.isEmpty) {
              name = (member['saadIdNo'] as String? ?? '').trim();
            }
            if (name.isNotEmpty) {
              final status =
                  record.status == 'unsync' ? 'in_progress' : 'completed';
              final memberRecord = withMemberData(record, member);
              final candidate = _DynamicMemberRecord(
                member: MemberModel(name: name, status: status),
                record: memberRecord,
              );
              final existing = members[name];
              if (existing == null ||
                  _recordPriority(candidate.record) >
                      _recordPriority(existing.record)) {
                members[name] = candidate;
              }
              print('✅ Extracted member from Case 3: $name');
            }
          }
        }
      }
    }

    final currentFarmerName =
        (widget.record.data?['farmerName'] as String? ?? '').trim();

    // For synced individual records, farmerName might not be at top level
    // Check if this is an individual record and look in membersByFarmerId
    String actualFarmerName = currentFarmerName;
    String actualSaadId =
        (widget.record.data?['saadIdNo'] as String? ?? '').trim();

    if (actualFarmerName.isEmpty &&
        widget.record.implType.toLowerCase() == 'individual') {
      final membersByFarmerId =
          widget.record.data?['membersByFarmerId'] as Map<String, dynamic>? ??
              {};
      if (membersByFarmerId.isNotEmpty) {
        // For individual records, there should be only one member
        final firstMemberKey = membersByFarmerId.keys.first;
        final firstMemberData =
            membersByFarmerId[firstMemberKey] as Map<String, dynamic>? ?? {};
        actualFarmerName = (firstMemberData['name'] as String? ??
                firstMemberData['farmerName'] as String? ??
                '')
            .trim();
        actualSaadId = (firstMemberData['saadIdNo'] as String? ?? '').trim();
      }
    }

    if (actualFarmerName.isNotEmpty) {
      // For individual records, merge commodity data from subcollection or root commodity collection
      final membersByFarmerId =
          widget.record.data?['membersByFarmerId'] as Map<String, dynamic>? ??
              {};

      Map<String, dynamic>? mergedData = widget.record.data;
      Map<String, dynamic>? memberData;

      if (membersByFarmerId.isNotEmpty) {
        if (actualSaadId.isNotEmpty &&
            membersByFarmerId.containsKey(actualSaadId)) {
          memberData = membersByFarmerId[actualSaadId] as Map<String, dynamic>?;
        } else {
          for (final entry in membersByFarmerId.entries) {
            final data = entry.value;
            if (data is Map<String, dynamic>) {
              final memberSaadId = (data['saadIdNo'] as String? ?? '').trim();
              final memberName = ((data['name'] as String?) ??
                      (data['farmerName'] as String?) ??
                      '')
                  .trim();
              if (memberSaadId.isNotEmpty &&
                  actualSaadId.isNotEmpty &&
                  memberSaadId == actualSaadId) {
                memberData = data;
                break;
              }
              if (memberData == null &&
                  memberName.isNotEmpty &&
                  memberName == actualFarmerName) {
                memberData = data;
              }
            }
          }
        }
      }

      final commodities = extractCommodities(memberData, widget.record.data);

      mergedData = Map<String, dynamic>.from(widget.record.data ?? {});
      if (commodities.isNotEmpty) {
        final commodityData = commodities.first as Map<String, dynamic>;
        mergedData.addAll(commodityData);
      }

      final trainings = (memberData?['trainings'] as List?) ??
          (widget.record.data?['trainings'] as List?) ??
          [];
      if (trainings.isNotEmpty) {
        mergedData['trainings'] = trainings;
      }

      // Create record with merged data
      final individualRecord = RecordModel(
        id: widget.record.id,
        name: widget.record.name,
        productionType: widget.record.productionType,
        implType: widget.record.implType,
        enumerator: widget.record.enumerator,
        date: widget.record.date,
        status: widget.record.status,
        documentPath: widget.record.documentPath,
        data: mergedData,
        isLocal: widget.record.isLocal,
      );

      members[actualFarmerName] = _DynamicMemberRecord(
        member: MemberModel(
          name: actualFarmerName,
          status:
              widget.record.status == 'unsync' ? 'in_progress' : 'completed',
        ),
        record: individualRecord,
      );
    }

    final q = _query.toLowerCase();
    return members.values
        .where(
            (item) => q.isEmpty || item.member.name.toLowerCase().contains(q))
        .toList()
      ..sort((a, b) => a.member.name.compareTo(b.member.name));
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return 'No date';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final month = parsed.month.toString().padLeft(2, '0');
    final day = parsed.day.toString().padLeft(2, '0');
    return '${parsed.year}-$month-$day';
  }

  String _titleCase(String value) {
    if (value.isEmpty) return 'Unknown';
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  Future<void> _updateReviewStatus(RecordModel record, String reviewStatus,
      {bool isModerator = false, bool isAdmin = false}) async {
    if (record.id == null) return;

    try {
      if (reviewStatus == 'approved') {
        await MonitoringRecordService.instance.approveRecord(
          recordId: record.id!,
          isModerator: isModerator,
          isAdmin: isAdmin,
        );
      } else {
        await MonitoringRecordService.instance.declineRecord(
          recordId: record.id!,
          isModerator: isModerator,
          isAdmin: isAdmin,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            reviewStatus == 'approved'
                ? '${record.name} approved!'
                : '${record.name} declined.',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor:
              reviewStatus == 'approved' ? DAColors.greenMid : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.of(context).pop();
      setState(() {
        _membersFuture = _loadMembers();
      });
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
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  bool _isNetworkError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('network-request-failed') ||
        message.contains('failed host lookup') ||
        message.contains('socketexception') ||
        message.contains('unavailable') ||
        message.contains('network is unreachable');
  }

  // ✅ Sync group record to Firebase and update status to 'pending'
  Future<void> _syncGroupRecordToFirebase() async {
    try {
      // Show loading dialog
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

      // Sync the group record to Firebase and update local status to pending
      if (widget.record.id == null) {
        throw Exception('Record missing local id for sync.');
      }
      await PendingDraftService.instance.syncDraftByLocalId(widget.record.id!);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      Navigator.pop(context); // Close record view modal

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.record.name} synced to Firebase!',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor: DAColors.greenMid,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      // Refresh the member list
      setState(() {
        _membersFuture = _loadMembers();
      });
    } catch (error) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      _showActionError(
        _isNetworkError(error)
            ? 'Sync needs internet connection. Please check your connection and try again.'
            : 'Unable to sync to Firebase right now. Please try again.',
      );
    }
  }

  // ── Navigate to step 2 of the correct production type ────────
  Future<void> _addCommodityForMember(String farmerName) async {
    final type = widget.record.productionType.toLowerCase();
    final fcaName = _targetFcaNameForNavigation();
    final data = Map<String, dynamic>.from(
        widget.record.data ?? const <String, dynamic>{});
    final supportInterventions = (data['supportInterventions'] as List?)
            ?.map((item) => item.toString())
            .toList() ??
        const <String>[];
    // CRITICAL: Copy all project background data to prevent loss
    final existingMembers = List<Map<String, dynamic>>.from(
      (data['members'] as List?)?.cast<Map<String, dynamic>>() ?? [],
    );

    if (type == 'crop') {
      final w = CropStepWrapper()
        ..fcaName = fcaName
        ..implementationType = widget.record.implType.toLowerCase()
        ..reportingPeriod = (data['reportingPeriod'] as String? ?? '').trim()
        ..region = (data['region'] as String?)?.trim()
        ..province = (data['province'] as String?)?.trim()
        ..municipality = (data['municipality'] as String?)?.trim()
        ..barangay = (data['barangay'] as String?)?.trim()
        ..projectTitle = (data['projectTitle'] as String? ?? '').trim()
        ..primaryIntervention = (data['primaryIntervention'] as String?)?.trim()
        ..primaryInterventionOther =
            (data['primaryInterventionOther'] as String? ?? '').trim()
        ..supportInterventions = List<String>.from(supportInterventions)
        ..farmerName = farmerName
        ..members = existingMembers;
      await Navigator.of(context).pushNamed(AppRoutes.cropStep2, arguments: w);
    } else if (type == 'livestock') {
      final w = LivestockStepWrapper()
        ..fcaName = fcaName
        ..implementationType = widget.record.implType.toLowerCase()
        ..region = (data['region'] as String?)?.trim()
        ..province = (data['province'] as String?)?.trim()
        ..municipality = (data['municipality'] as String?)?.trim()
        ..barangay = (data['barangay'] as String?)?.trim()
        ..projectTitle = (data['projectTitle'] as String? ?? '').trim()
        ..primaryIntervention = (data['primaryIntervention'] as String?)?.trim()
        ..supportInterventions = List<String>.from(supportInterventions)
        ..farmerName = farmerName
        ..members = existingMembers;
      await Navigator.of(context)
          .pushNamed(AppRoutes.livestockStep2, arguments: w);
    } else {
      final w = PoultryStepWrapper()
        ..fcaName = fcaName
        ..implementationType = widget.record.implType.toLowerCase()
        ..reportingPeriod = (data['reportingPeriod'] as String? ?? '').trim()
        ..region = (data['region'] as String?)?.trim()
        ..province = (data['province'] as String?)?.trim()
        ..municipality = (data['municipality'] as String?)?.trim()
        ..barangay = (data['barangay'] as String?)?.trim()
        ..projectTitle = (data['projectTitle'] as String? ?? '').trim()
        ..primaryIntervention = (data['primaryIntervention'] as String?)?.trim()
        ..supportInterventions = List<String>.from(supportInterventions)
        ..farmerName = farmerName
        ..members = existingMembers;
      await Navigator.of(context)
          .pushNamed(AppRoutes.poultryStep2, arguments: w);
    }

    if (!mounted) return;
    setState(() {
      _membersFuture = _loadMembers();
    });
  }

  Future<void> _addCommodityForGroup() async {
    final type = widget.record.productionType.toLowerCase();
    final fcaName = _targetFcaNameForNavigation();
    final data = Map<String, dynamic>.from(
        widget.record.data ?? const <String, dynamic>{});
    final supportInterventions = (data['supportInterventions'] as List?)
            ?.map((item) => item.toString())
            .toList() ??
        const <String>[];
    // CRITICAL: Copy existing members list to prevent loss
    final existingMembers = List<Map<String, dynamic>>.from(
      (data['members'] as List?)?.cast<Map<String, dynamic>>() ?? [],
    );

    if (type == 'crop') {
      final w = CropStepWrapper()
        ..fcaName = fcaName
        ..implementationType = widget.record.implType.toLowerCase()
        ..reportingPeriod = (data['reportingPeriod'] as String? ?? '').trim()
        ..region = (data['region'] as String?)?.trim()
        ..province = (data['province'] as String?)?.trim()
        ..municipality = (data['municipality'] as String?)?.trim()
        ..barangay = (data['barangay'] as String?)?.trim()
        ..projectTitle = (data['projectTitle'] as String? ?? '').trim()
        ..primaryIntervention = (data['primaryIntervention'] as String?)?.trim()
        ..primaryInterventionOther =
            (data['primaryInterventionOther'] as String? ?? '').trim()
        ..supportInterventions = List<String>.from(supportInterventions)
        ..members = existingMembers;
      await Navigator.of(context).pushNamed(AppRoutes.cropStep2, arguments: w);
    } else if (type == 'livestock') {
      final w = LivestockStepWrapper()
        ..fcaName = fcaName
        ..implementationType = widget.record.implType.toLowerCase()
        ..region = (data['region'] as String?)?.trim()
        ..province = (data['province'] as String?)?.trim()
        ..municipality = (data['municipality'] as String?)?.trim()
        ..barangay = (data['barangay'] as String?)?.trim()
        ..projectTitle = (data['projectTitle'] as String? ?? '').trim()
        ..primaryIntervention = (data['primaryIntervention'] as String?)?.trim()
        ..supportInterventions = List<String>.from(supportInterventions)
        ..members = existingMembers;
      await Navigator.of(context)
          .pushNamed(AppRoutes.livestockStep2, arguments: w);
    } else {
      final w = PoultryStepWrapper()
        ..fcaName = fcaName
        ..implementationType = widget.record.implType.toLowerCase()
        ..reportingPeriod = (data['reportingPeriod'] as String? ?? '').trim()
        ..region = (data['region'] as String?)?.trim()
        ..province = (data['province'] as String?)?.trim()
        ..municipality = (data['municipality'] as String?)?.trim()
        ..barangay = (data['barangay'] as String?)?.trim()
        ..projectTitle = (data['projectTitle'] as String? ?? '').trim()
        ..primaryIntervention = (data['primaryIntervention'] as String?)?.trim()
        ..supportInterventions = List<String>.from(supportInterventions)
        ..members = existingMembers;

      // For collective poultry, go to monitoring summary for commodity management
      if (widget.record.implType.toLowerCase() == 'collective') {
        await Navigator.of(context)
            .pushNamed(AppRoutes.poultryMonitoringSummary, arguments: w);
      } else {
        await Navigator.of(context)
            .pushNamed(AppRoutes.poultryStep2, arguments: w);
      }
    }

    if (!mounted) return;
    setState(() {
      _membersFuture = _loadMembers();
    });
  }

  Future<void> _addAnotherFarmer() async {
    final type = widget.record.productionType.toLowerCase();
    final fcaName = _targetFcaNameForNavigation();
    final data = Map<String, dynamic>.from(
        widget.record.data ?? const <String, dynamic>{});
    final supportInterventions = (data['supportInterventions'] as List?)
            ?.map((item) => item.toString())
            .toList() ??
        const <String>[];

    // ✅ CRITICAL: Load existing members from either members array OR membersByFarmerId
    // (After the fix, group records store members ONLY in membersByFarmerId)
    var existingMembers = List<Map<String, dynamic>>.from(
      (data['members'] as List?)?.cast<Map<String, dynamic>>() ?? [],
    );

    // If members array is empty but membersByFarmerId exists, rebuild members from it
    if (existingMembers.isEmpty && data['membersByFarmerId'] is Map) {
      final membersByFarmerId =
          data['membersByFarmerId'] as Map<String, dynamic>;
      existingMembers = membersByFarmerId.entries
          .map((entry) {
            final farmerData = entry.value as Map<String, dynamic>?;
            if (farmerData != null) {
              return {
                'name': (farmerData['name'] as String? ??
                        farmerData['farmerName'] as String? ??
                        '')
                    .trim(),
                'saadIdNo':
                    (farmerData['saadIdNo'] as String? ?? entry.key).trim(),
              };
            }
            return null;
          })
          .whereType<Map<String, dynamic>>()
          .toList();
      print(
          '🔍 Loaded ${existingMembers.length} existing farmers from membersByFarmerId');
    }

    if (type == 'crop') {
      final w = CropStepWrapper()
        ..fcaName = fcaName
        ..implementationType = widget.record.implType.toLowerCase()
        ..reportingPeriod = (data['reportingPeriod'] as String? ?? '').trim()
        ..region = (data['region'] as String?)?.trim()
        ..province = (data['province'] as String?)?.trim()
        ..municipality = (data['municipality'] as String?)?.trim()
        ..barangay = (data['barangay'] as String?)?.trim()
        ..projectTitle = (data['projectTitle'] as String? ?? '').trim()
        ..primaryIntervention = (data['primaryIntervention'] as String?)?.trim()
        ..primaryInterventionOther =
            (data['primaryInterventionOther'] as String? ?? '').trim()
        ..supportInterventions = List<String>.from(supportInterventions)
        ..members = existingMembers;
      w.isAddFarmer = true;
      await Navigator.of(context).pushNamed(AppRoutes.cropStep2, arguments: w);
    } else if (type == 'livestock') {
      final w = LivestockStepWrapper()
        ..fcaName = fcaName
        ..implementationType = widget.record.implType.toLowerCase()
        ..region = (data['region'] as String?)?.trim()
        ..province = (data['province'] as String?)?.trim()
        ..municipality = (data['municipality'] as String?)?.trim()
        ..barangay = (data['barangay'] as String?)?.trim()
        ..projectTitle = (data['projectTitle'] as String? ?? '').trim()
        ..primaryIntervention = (data['primaryIntervention'] as String?)?.trim()
        ..supportInterventions = List<String>.from(supportInterventions)
        ..members = existingMembers;
      w.isAddFarmer = true;
      await Navigator.of(context)
          .pushNamed(AppRoutes.livestockStep2, arguments: w);
    } else {
      final w = PoultryStepWrapper()
        ..fcaName = fcaName
        ..implementationType = widget.record.implType.toLowerCase()
        ..reportingPeriod = (data['reportingPeriod'] as String? ?? '').trim()
        ..region = (data['region'] as String?)?.trim()
        ..province = (data['province'] as String?)?.trim()
        ..municipality = (data['municipality'] as String?)?.trim()
        ..barangay = (data['barangay'] as String?)?.trim()
        ..projectTitle = (data['projectTitle'] as String? ?? '').trim()
        ..primaryIntervention = (data['primaryIntervention'] as String?)?.trim()
        ..supportInterventions = List<String>.from(supportInterventions)
        ..members = existingMembers;
      w.isAddFarmer = true;
      await Navigator.of(context)
          .pushNamed(AppRoutes.poultryStep2, arguments: w);
    }

    if (!mounted) return;
    setState(() {
      _membersFuture = _loadMembers();
    });
  }

  void _viewMember(_DynamicMemberRecord memberRecord) async {
    print(
        '🔍 _viewMember called with member: ${memberRecord.member.name}, record implType: ${memberRecord.record.implType}');
    final session = await UserSessionService.instance.getCurrentSession();
    final isModerator = session?.isModerator ?? false;
    final isAdmin = session?.isAdmin ?? false;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecordViewModal(
        record: memberRecord.record,
        memberName: memberRecord.member.name,
        isMemberEditOnly:
            true, // Farmers can only edit their own commodity data
        // Farmers can edit only their own draft/pending records (NOT approved ones)
        // Moderators can edit approved records
        showEdit: (memberRecord.record.status == 'unsync' ||
                memberRecord.record.status == 'pending')
            ? true
            : (memberRecord.record.status == 'approved' && isModerator),
        showApprove:
            memberRecord.record.status == 'pending' && (isModerator || isAdmin),
        approveLocked: memberRecord.record.status == 'pending' &&
            !(isModerator || isAdmin),
        // CRITICAL: Don't allow sync on individual farmer records
        // Sync happens at GROUP level only, not per farmer
        onSync: null,
        onApprove:
            memberRecord.record.status == 'pending' && (isModerator || isAdmin)
                ? () => _updateReviewStatus(memberRecord.record, 'approved',
                    isModerator: isModerator, isAdmin: isAdmin)
                : null,
        onDecline:
            memberRecord.record.status == 'pending' && (isModerator || isAdmin)
                ? () => _updateReviewStatus(memberRecord.record, 'declined',
                    isModerator: isModerator, isAdmin: isAdmin)
                : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final topPad = mq.padding.top;
    final botPad = mq.padding.bottom;
    final screenW = mq.size.width;
    final hPad = screenW * 0.048;

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return FutureBuilder<UserSession?>(
      future: _sessionFuture,
      builder: (context, sessionSnapshot) {
        final isModerator = sessionSnapshot.data?.isModerator ?? false;

        return Scaffold(
          backgroundColor: const Color(0xFFF2F2F2),
          body: Column(children: [
            // ── Green header ────────────────────────────────────────
            Container(
              padding: EdgeInsets.fromLTRB(hPad, topPad + 12, hPad, 20),
              decoration: const BoxDecoration(
                color: DAColors.greenDark,
                image: DecorationImage(
                  image: AssetImage('assets/images/splash_bg.png'),
                  fit: BoxFit.cover,
                  opacity: 0.18,
                ),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.20),
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.arrow_back_rounded,
                                  color: Colors.white, size: 20))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text('Member Records',
                              style: GoogleFonts.bebasNeue(
                                  fontSize: 22,
                                  color: Colors.white,
                                  letterSpacing: 2))),
                    ]),
                    const SizedBox(height: 14),
                    Text(
                        (widget.record.data?['fcaName'] as String? ?? '')
                                .isNotEmpty
                            ? (widget.record.data?['fcaName'] as String? ?? '')
                            : widget.record.name,
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
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
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search
                      Container(
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.07),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2))
                            ]),
                        child: TextField(
                          controller: _searchCtrl,
                          style: GoogleFonts.poppins(fontSize: 13),
                          decoration: InputDecoration(
                              hintText: 'Search member name',
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
                      if (widget.record.implType.toLowerCase() !=
                          'collective') ...[
                        GestureDetector(
                          onTap: _addAnotherFarmer,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2))
                                ]),
                            child: Row(children: [
                              Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                      color: DAColors.amber.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12)),
                                  child: const Icon(Icons.person_add_rounded,
                                      color: DAColors.amber, size: 22)),
                              const SizedBox(width: 14),
                              Expanded(
                                  child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Add Another Farmer',
                                      style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: DAColors.textDark)),
                                  Text('Start monitoring a new farmer',
                                      style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: DAColors.textMuted)),
                                ],
                              )),
                              const Icon(Icons.chevron_right_rounded,
                                  color: DAColors.amber, size: 24),
                            ]),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // ── FCA / Group card ──────────────────────────────
                      const _SectionLabel(label: 'Group / FCA'),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: DAColors.greenMid.withOpacity(0.25),
                                width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2))
                            ]),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                      color:
                                          DAColors.greenLight.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12)),
                                  child: const Icon(Icons.groups_rounded,
                                      color: DAColors.greenMid, size: 24)),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Expanded(
                                        child: Text(widget.record.name,
                                            style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: DAColors.textDark))),
                                    // View button — inline with group name (for collectives/groups)
                                    GestureDetector(
                                      onTap: () => showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (_) => RecordViewModal(
                                          record: widget.record,
                                          isGroup: true,
                                          // ✅ For draft/pending: Show sync button (not edit)
                                          // For approved: Show edit button (moderators only)
                                          showEdit: (widget.record.status ==
                                                  'approved' &&
                                              isModerator),
                                          showSync: widget.record.status ==
                                                  'unsync' ||
                                              widget.record.status == 'pending',
                                          showApprove: widget.record.status ==
                                                  'pending' &&
                                              isModerator,
                                          approveLocked: widget.record.status ==
                                                  'pending' &&
                                              !isModerator,
                                          // ✅ Sync to Firebase on demand
                                          onSync:
                                              widget.record.status == 'unsync'
                                                  ? _syncGroupRecordToFirebase
                                                  : null,
                                          onApprove: widget.record.status ==
                                                      'pending' &&
                                                  isModerator
                                              ? () => _updateReviewStatus(
                                                  widget.record, 'approved')
                                              : null,
                                          onDecline: widget.record.status ==
                                                      'pending' &&
                                                  isModerator
                                              ? () => _updateReviewStatus(
                                                  widget.record, 'declined')
                                              : null,
                                        ),
                                      ),
                                      child: Container(
                                          margin:
                                              const EdgeInsets.only(left: 8),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 4),
                                          decoration: BoxDecoration(
                                              color: DAColors.greenMid
                                                  .withOpacity(0.10),
                                              borderRadius:
                                                  BorderRadius.circular(50)),
                                          child: Text('View',
                                              style: GoogleFonts.poppins(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: DAColors.greenMid))),
                                    ),
                                  ]),
                                  Text(
                                      '${widget.record.productionType} · ${widget.record.implType}',
                                      style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: DAColors.textMuted)),
                                ],
                              )),
                            ]),

                            // Add Another Commodity — for collective only
                            if (widget.record.implType.toLowerCase() ==
                                'collective') ...[
                              const SizedBox(height: 10),
                              const Divider(
                                  height: 1, color: Color(0xFFF0F0F0)),
                              const SizedBox(height: 10),
                              GestureDetector(
                                onTap: _addCommodityForGroup,
                                child: Row(children: [
                                  Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                          color: DAColors.greenMid
                                              .withOpacity(0.10),
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      child: const Icon(Icons.add_rounded,
                                          color: DAColors.greenMid, size: 16)),
                                  const SizedBox(width: 8),
                                  Text('Add Another Commodity',
                                      style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: DAColors.greenMid)),
                                ]),
                              ),
                            ],

                            // ── Members Monitoring ─────────────────────────
                            // Only show for non-collective types (collectives have no members)
                            if (widget.record.implType.toLowerCase() !=
                                'collective') ...[
                              const SizedBox(height: 14),
                              const Divider(
                                  height: 1, color: Color(0xFFF0F0F0)),
                              const SizedBox(height: 14),
                              Text('Members Monitoring',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: DAColors.textDark)),
                              const SizedBox(height: 10),
                              FutureBuilder<List<_DynamicMemberRecord>>(
                                future: _membersFuture,
                                builder: (context, snapshot) {
                                  final members = snapshot.data ??
                                      const <_DynamicMemberRecord>[];
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Padding(
                                      padding: EdgeInsets.only(top: 20),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                            color: DAColors.greenMid),
                                      ),
                                    );
                                  }

                                  if (members.isEmpty) {
                                    return Center(
                                        child: Padding(
                                      padding: const EdgeInsets.only(top: 20),
                                      child: Text(
                                          _remoteStatusMessage ??
                                              'No member records found',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: DAColors.textMuted)),
                                    ));
                                  }

                                  return ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: members.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 10),
                                    itemBuilder: (ctx, i) {
                                      final memberRecord = members[i];
                                      return _MemberCard(
                                        member: memberRecord.member,
                                        onView: () => _viewMember(memberRecord),
                                        onAddCommodity: () =>
                                            _addCommodityForMember(
                                                memberRecord.member.name),
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ]),
              ),
            ),

            // ── Bottom action bar (Pending → Approve/Decline, Approved → Edit) ──
            // ✅ No sync button - manual sync is triggered explicitly by the user
            if (widget.record.status == 'pending' ||
                widget.record.status == 'approved')
              Container(
                color: Colors.white,
                padding: EdgeInsets.fromLTRB(hPad, 12, hPad, botPad + 16),
                child: Row(children: [
                  if (widget.record.status == 'approved' && isModerator)
                    Expanded(
                        child: _actionBtn(
                      context: context,
                      label: 'Edit',
                      color: const Color(0xFF1565C0),
                      icon: Icons.edit_outlined,
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => RecordViewModal(
                          record: widget.record,
                          showEdit: true,
                        ),
                      ),
                    )),
                  if (widget.record.status == 'pending' && isModerator) ...[
                    Expanded(
                        child: _actionBtn(
                      context: context,
                      label: 'Approve',
                      color: DAColors.greenMid,
                      icon: Icons.check_circle_outline_rounded,
                      onTap: () =>
                          _updateReviewStatus(widget.record, 'approved'),
                    )),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _actionBtn(
                      context: context,
                      label: 'Decline',
                      color: Colors.red,
                      icon: Icons.cancel_outlined,
                      onTap: () =>
                          _updateReviewStatus(widget.record, 'declined'),
                    )),
                  ],
                ]),
              ),
          ]),
        );
      },
    );
  }

  Widget _actionBtn({
    required BuildContext context,
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(50)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
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
  final MemberModel member;
  final VoidCallback onView;
  final VoidCallback onAddCommodity;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                width: 42,
                height: 42,
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
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: DAColors.textDark)),
                const SizedBox(height: 2),
                Row(children: [
                  Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                          color: _statusColor(member.status),
                          shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Text(_statusLabel(member.status),
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: _statusColor(member.status))),
                ]),
              ],
            )),
            // View button
            GestureDetector(
                onTap: onView,
                child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withOpacity(0.10),
                        borderRadius: BorderRadius.circular(50)),
                    child: Text('View',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1565C0))))),
          ]),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onAddCommodity,
            child: Row(children: [
              Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                      color: DAColors.greenMid.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.add_rounded,
                      color: DAColors.greenMid, size: 16)),
              const SizedBox(width: 8),
              Text('Add Another Commodity',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: DAColors.greenMid)),
            ]),
          ),
        ]),
      );

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return DAColors.greenMid;
      case 'in_progress':
        return DAColors.amber;
      default:
        return const Color(0xFFBBBBBB);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'in_progress':
        return 'In Progress';
      default:
        return 'Not yet monitored';
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
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: Colors.white.withOpacity(0.40))),
      child: Text(label,
          style: GoogleFonts.poppins(
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
