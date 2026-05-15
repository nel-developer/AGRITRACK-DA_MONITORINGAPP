import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:io';
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
    this.groupName = '',
  });

  final MemberModel member;
  final RecordModel record;
  final String
      groupName; // For grouping display (Collective, Project, or Group name)
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
    print('🔷 initState: Creating initial _membersFuture');
    _membersFuture = _loadMembers();
    print(
        '🔷 initState: _membersFuture created, future object hash: ${_membersFuture.hashCode}');
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
    try {
      print('🔍🔍🔍 _loadMembers START');
      final session = await UserSessionService.instance.getCurrentSession();
      // ✅ Read unsync records directly from local farmer folders
      final unsyncRecordsFromFolders =
          await LocalFarmerStorageService.instance.getAllUnsyncRecords();
      print(
          '🔍 Got ${unsyncRecordsFromFolders.length} unsync records from folders');
      _remoteStatusMessage = null;

      // ✅ For COLLECTIVE widget.record, load group.json if commodities missing
      // BUT ONLY for UNSYNC records! PENDING records must use Firebase only
      if (widget.record.implType.toLowerCase() == 'collective' &&
          widget.record.status == 'unsync' &&
          ((widget.record.data?['completedCommodities'] as List?)?.isEmpty ??
              true)) {
        try {
          const baseDir =
              '/storage/emulated/0/Android/data/com.example.da_monitoring_app/files/monitoring_records';
          final groupJsonPath =
              '$baseDir/${widget.record.productionType.toLowerCase()}/${widget.record.name.replaceAll(' ', '_')}/group.json';
          final groupFile = File(groupJsonPath);

          print(
              '🔍 [LOAD COLLECTIVE] Loading widget.record group.json from: $groupJsonPath');

          if (groupFile.existsSync()) {
            final content = groupFile.readAsStringSync();
            final groupJson = jsonDecode(content) as Map<String, dynamic>;

            // Update widget.record.data with loaded commodities
            if (widget.record.data != null) {
              if (groupJson.containsKey('completedCommodities')) {
                widget.record.data!['completedCommodities'] =
                    groupJson['completedCommodities'];
              }
              if (groupJson.containsKey('trainings')) {
                widget.record.data!['trainings'] = groupJson['trainings'];
              }
            }
            print(
                '✅ [LOAD COLLECTIVE] Loaded ${(groupJson['completedCommodities'] as List?)?.length ?? 0} commodities into widget.record');
          }
        } catch (e) {
          print('⚠️ [LOAD COLLECTIVE] Error: $e');
        }
      } else if (widget.record.status == 'pending' &&
          widget.record.data != null) {
        // ✅ CRITICAL: For PENDING records, clear any local completedCommodities
        // Force using ONLY Firebase data (stored in 'commodities' key)
        print(
            '🔍 PENDING record: Clearing local completedCommodities to use Firebase only');
        widget.record.data!.remove('completedCommodities');
        // Rename Firebase 'commodities' to 'completedCommodities' for display compatibility
        if (widget.record.data!.containsKey('commodities')) {
          widget.record.data!['completedCommodities'] =
              widget.record.data!['commodities'];
        }
        print(
            '   ✅ Cleared local completedCommodities, using Firebase "commodities" only');
      }

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

        // Copy ALL group-level fields from parent (NOT commodities or farmer-specific data)
        // This includes the FULL Project Background (Step 01) fields
        final parentData = parent.data ?? {};
        final projectBackgroundFields = [
          'fcaName',
          'reportingPeriod',
          'projectTitle',
          'implementationType',
          'productionType',
          'enumerator',
          'location',
          'region',
          'province', // ✅ NOW INCLUDED - was missing!
          'municipality', // ✅ NOW INCLUDED - was missing!
          'barangay', // ✅ NOW INCLUDED - was missing!
          'primaryIntervention', // ✅ NOW INCLUDED - was missing!
          'primaryInterventionOther', // ✅ NOW INCLUDED - was missing!
          'supportInterventions', // ✅ NOW INCLUDED - was missing!
          'district',
          'ward'
        ];
        for (final key in projectBackgroundFields) {
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

          // DEBUG: Check ALL fields for each commodity
          for (int i = 0; i < farmerCommodities.length; i++) {
            final comm = farmerCommodities[i];
            if (comm is Map<String, dynamic>) {
              final photoGPS = comm['photoGPS'];
              print(
                  '   - commodity[$i] photoGPS: ${photoGPS != null ? "EXISTS" : "NULL"}');
              if (photoGPS is Map) {
                print(
                    '      lat: ${photoGPS['latitude']}, lon: ${photoGPS['longitude']}');
              }
              print('      All fields in commodity[$i]: ${comm.keys.toList()}');
            }
          }

          // Also merge the first commodity's data for display
          final commodityData = farmerCommodities.first;
          if (commodityData is Map<String, dynamic>) {
            // Merge commodity fields but preserve farmerName/saadIdNo
            final farmerIdentity = {
              'farmerName': memberName,
              'saadIdNo': memberSaadId,
            };
            final spreadData = {...commodityData, ...farmerIdentity};
            print(
                '   📍 First commodity photoGPS after spread: ${spreadData['photoGPS'] != null ? "EXISTS" : "NULL"}');
            mergedData.addAll(spreadData);
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
      // Group by productionType + groupName first
      print(
          '🔍 ====== Starting unsync records loop: unsyncRecordsFromFolders.length = ${unsyncRecordsFromFolders.length} ======');

      final unsyncByGroup = <String, List<Map<String, dynamic>>>{};
      final unsyncGroupInfo = <String, Map<String, dynamic>>{};

      for (final record in unsyncRecordsFromFolders) {
        final rawData = (record['data'] as Map<String, dynamic>?) ?? {};
        final productionType =
            (record['productionType'] as String? ?? '').toLowerCase();
        final groupName = (record['groupName'] as String? ?? '').trim();
        final detectedImplType =
            (record['implType'] as String? ?? 'individual').toLowerCase();

        print(
            '   🔹 Raw record: groupName=$groupName, prodType=$productionType, implType=$detectedImplType');

        // Only load unsync records matching production type
        if (productionType == widget.record.productionType.toLowerCase()) {
          final groupKey = '$productionType/$groupName';

          // Add to grouped list
          unsyncByGroup.putIfAbsent(groupKey, () => []).add(record);

          // Store group info (fcaName, etc) from first record of this group
          if (!unsyncGroupInfo.containsKey(groupKey)) {
            unsyncGroupInfo[groupKey] = {
              'groupName': groupName,
              'productionType': productionType,
              'implType': detectedImplType,
              'fcaName': (rawData['fcaName'] as String? ?? groupName).trim(),
            };
          }

          print('✅ GROUPED: $groupKey');
        } else {
          print('❌ SKIP: $groupName/$productionType');
        }
      }

      // Now create ONE group record per group, with all farmers in membersByFarmerId
      print('🔍 Processing ${unsyncByGroup.length} groups to create records');
      for (final groupKey in unsyncByGroup.keys) {
        final farmerRecords = unsyncByGroup[groupKey] ?? [];
        final groupInfo = unsyncGroupInfo[groupKey] ?? {};
        final groupName = groupInfo['groupName'] as String? ?? '';
        final implType = (groupInfo['implType'] as String? ?? '').toLowerCase();

        // ✅ CRITICAL: Filter - only include unsync groups matching current record's group name
        final currentGroupName = widget.record.name.trim();

        // Normalize both names: convert underscores to spaces for comparison
        final normalizedGroupName = groupName.replaceAll('_', ' ').trim();
        final normalizedCurrentName =
            currentGroupName.replaceAll('_', ' ').trim();

        print(
            '   📍 Checking groupName="$groupName" (normalized: "$normalizedGroupName") vs currentGroupName="$currentGroupName" (normalized: "$normalizedCurrentName")');
        if (normalizedGroupName != normalizedCurrentName) {
          print(
              '   ⏭️  SKIP GROUP: $groupName (not matching current view: $currentGroupName)');
          continue;
        }

        print(
            '   🔄 Creating group record for $groupKey with ${farmerRecords.length} farmers, implType=$implType');

        // Build membersByFarmerId map with all farmers
        final membersByFarmerId = <String, dynamic>{};
        for (final record in farmerRecords) {
          final farmerName = (record['farmerName'] as String? ?? '').trim();
          final saadId = (record['saadId'] as String? ?? '').trim();
          final farmerData = (record['data'] as Map<String, dynamic>?) ?? {};

          if (farmerName.isNotEmpty && saadId.isNotEmpty) {
            membersByFarmerId[saadId] = {
              'name': farmerName,
              'farmerName': farmerName,
              'saadIdNo': saadId,
              ...farmerData, // Include all farmer-specific data
            };
            print('      ✅ Added farmer: $farmerName ($saadId)');
          }
        }

        // ✅ CRITICAL FIX: For COLLECTIVE, load group.json EVEN if no farmer records
        // COLLECTIVE saves everything to group.json with no farmer subfolders
        if (membersByFarmerId.isNotEmpty || implType == 'collective') {
          // Create single group record with all farmers
          final groupData = <String, dynamic>{
            'groupName': groupName,
            'membersByFarmerId': membersByFarmerId,
            'fcaName': groupInfo['fcaName'] ?? groupName,
            'implType': groupInfo['implType'],
          };

          // ✅ Load group.json for BOTH COLLECTIVE AND INDIVIDUAL to get project background
          final implTypeStr =
              (groupInfo['implType'] as String? ?? '').toLowerCase();
          try {
            // Use Android external files directory path
            const baseDir =
                '/storage/emulated/0/Android/data/com.example.da_monitoring_app/files/monitoring_records';
            final groupJsonPath =
                '$baseDir/${(groupInfo['productionType'] as String? ?? '').toLowerCase()}/${groupName.replaceAll(' ', '_')}/group.json';
            final groupFile = File(groupJsonPath);

            print(
                '📂 [LOAD GROUP JSON] Trying to load group.json for $implTypeStr from: $groupJsonPath');

            if (groupFile.existsSync()) {
              final content = groupFile.readAsStringSync();
              final groupJson = jsonDecode(content) as Map<String, dynamic>;

              print(
                  '✅ [LOAD GROUP JSON] group.json found for $implTypeStr! Keys: ${groupJson.keys.toList()}');

              // ✅ For ALL types: First merge ALL fields from group.json, then selectively override with group-specific ones
              groupData.addAll(groupJson);

              // ✅ Explicitly ensure project background fields are set (even if empty)
              final projectBackgroundKeys = [
                'fcaName',
                'reportingPeriod',
                'projectTitle',
                'implementationType',
                'region',
                'province',
                'municipality',
                'barangay',
                'primaryIntervention',
                'primaryInterventionOther',
                'supportInterventions',
              ];

              for (final key in projectBackgroundKeys) {
                if (groupJson.containsKey(key) && groupData[key] == null) {
                  groupData[key] = groupJson[key];
                }
              }

              print(
                  '✅ Loaded group.json for $implTypeStr $groupName. Project Background Fields:');
              for (final key in projectBackgroundKeys) {
                final value = groupData[key];
                print('   - $key: "$value"');
              }
            } else {
              print(
                  '⚠️ group.json not found for $implTypeStr $groupName at $groupJsonPath');
            }
          } catch (e) {
            print(
                '⚠️ Error loading group.json for $implTypeStr $groupName: $e');
          }

          final groupRecord = RecordModel(
            id: groupKey,
            name: groupName,
            productionType: widget.record.productionType,
            implType:
                _titleCase(groupInfo['implType'] as String? ?? 'individual'),
            enumerator: 'Offline Profiler',
            date: _formatDate(DateTime.now().toIso8601String()),
            status: 'unsync',
            data: groupData,
            isLocal: true,
          );
          relatedRecords.add(groupRecord);
          print(
              '   ✅ Added GROUP record: $groupName with ${membersByFarmerId.length} members to relatedRecords. relatedRecords now has ${relatedRecords.length} records');
        } else {
          print('   ⚠️ No farmers in membersByFarmerId for $groupKey');
        }
      }

      print(
          '🔍 ====== End unsync records loop: relatedRecords.length = ${relatedRecords.length} ======');

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
              implType:
                  _titleCase(record['implementationType'] as String? ?? ''),
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

        // For unsync records, use record.name if farmerName is not in data
        final effectiveFarmerName = farmerName.isNotEmpty
            ? farmerName
            : (record.status == 'unsync' ? record.name : '').trim();

        final membersList = (record.data?['members'] as List?) ?? [];
        final rawMembersByFarmerId = record.data?['membersByFarmerId'];
        var membersByFarmerId = rawMembersByFarmerId is Map
            ? Map<String, dynamic>.from(rawMembersByFarmerId)
            : <String, dynamic>{};

        // ✅ For PENDING records, convert each member's 'commodities' → 'completedCommodities'
        if (record.status == 'pending' && membersByFarmerId.isNotEmpty) {
          final processedMembers = <String, dynamic>{};
          for (final entry in membersByFarmerId.entries) {
            final saadId = entry.key;
            final memberData = entry.value;
            if (memberData is Map) {
              final processedMemberData = Map<String, dynamic>.from(memberData);
              // Convert Firebase 'commodities' → 'completedCommodities'
              if (processedMemberData.containsKey('commodities') &&
                  !processedMemberData.containsKey('completedCommodities')) {
                processedMemberData['completedCommodities'] =
                    processedMemberData['commodities'];
              }
              processedMembers[saadId] = processedMemberData;
            }
          }
          membersByFarmerId = processedMembers;
        }

        print(
            '🔍 Processing record: name=${record.name}, status=${record.status}, farmerName="$farmerName", effectiveFarmerName="$effectiveFarmerName", membersByFarmerId=${membersByFarmerId.length}, membersList=${membersList.length}');
        print(
            '   🔑 membersByFarmerId keys: ${membersByFarmerId.keys.toList()}');

        // ✅ CRITICAL: For PENDING records
        // COLLECTIVE: Add group directly (no members extraction)
        // INDIVIDUAL/HYBRID: Extract members from the record's members data (DO NOT add group itself)
        if (record.status == 'pending') {
          final implType = (record.data?['implementationType'] as String? ?? '')
              .toLowerCase();
          print(
              '   ✅ PENDING record detected: implType=$implType, checking if COLLECTIVE or INDIVIDUAL/HYBRID');

          // For COLLECTIVE pending records: add group directly
          if (implType == 'collective') {
            print(
                '   ✅ PENDING COLLECTIVE - adding group directly without member extraction');
            const status = 'completed';
            final groupName = (record.data?['fcaName'] as String? ?? '').trim();
            final candidate = _DynamicMemberRecord(
              member: MemberModel(name: record.name, status: status),
              record: record,
              groupName: groupName,
            );
            final existing = members[record.name];
            if (existing == null ||
                _recordPriority(candidate.record) >
                    _recordPriority(existing.record)) {
              members[record.name] = candidate;
              print('   ✅ Added PENDING COLLECTIVE record: ${record.name}');
            }
            continue; // Skip member extraction for COLLECTIVE
          } else {
            // For INDIVIDUAL/HYBRID pending records: extract members (fall through to member extraction logic)
            print(
                '   ✅ PENDING INDIVIDUAL/HYBRID - will extract members below (NOT adding group itself)');
            // Set membersByFarmerId from pending Firebase record if available
            if (record.data?['membersByFarmerId'] != null) {
              final rawMembers = record.data?['membersByFarmerId'];
              if (rawMembers is Map) {
                final firebaseMembers = Map<String, dynamic>.from(rawMembers);
                membersByFarmerId.clear();
                for (final entry in firebaseMembers.entries) {
                  final saadId = entry.key;
                  final memberData = entry.value;
                  if (memberData is Map) {
                    final processedMemberData =
                        Map<String, dynamic>.from(memberData);

                    // ✅ Convert Firebase 'commodities' → 'completedCommodities' for consistency
                    if (processedMemberData.containsKey('commodities') &&
                        !processedMemberData
                            .containsKey('completedCommodities')) {
                      processedMemberData['completedCommodities'] =
                          processedMemberData['commodities'];
                    }

                    membersByFarmerId[saadId] = processedMemberData;
                  }
                }
                print(
                    '      - Extracted ${membersByFarmerId.length} members from Firebase (converted commodities → completedCommodities)');
              }
            }
            // Fall through to member extraction logic below
          }
        }

        // ── Case 1: Individual/Hybrid record with a specific farmer's name ──
        // Only process if this is NOT a group record with membersByFarmerId
        if (effectiveFarmerName.isNotEmpty && membersByFarmerId.isEmpty) {
          final status =
              record.status == 'unsync' ? 'in_progress' : 'completed';
          final groupName = (record.data?['groupName'] as String? ?? '').trim();
          final candidate = _DynamicMemberRecord(
            member: MemberModel(name: effectiveFarmerName, status: status),
            record: record,
            groupName: groupName,
          );
          final existing = members[effectiveFarmerName];
          if (existing == null ||
              _recordPriority(candidate.record) >
                  _recordPriority(existing.record)) {
            members[effectiveFarmerName] = candidate;
            print(
                '✅ Case 1 ADDED: $effectiveFarmerName (status: $status, group: $groupName)');
          } else {
            print(
                'ℹ️ Case 1 SKIP (existing with higher priority): $effectiveFarmerName');
          }
        } else {
          print(
              'ℹ️ Case 1 SKIP: effectiveName empty=${effectiveFarmerName.isEmpty}, hasByFarmerId=${membersByFarmerId.isNotEmpty} (membersByFarmerId entries: ${membersByFarmerId.length})');
        }

        // ── Case 2: Group/Collective record with membersByFarmerId map ──
        // CRITICAL: For COLLECTIVE, DO NOT extract as member - skip entirely
        // For HYBRID/INDIVIDUAL, extract members from membersByFarmerId (safe map)
        final implType =
            (record.data?['implementationType'] as String? ?? '').toLowerCase();

        if (membersByFarmerId.isNotEmpty && implType != 'collective') {
          // HYBRID/INDIVIDUAL: Extract individual farmers from group
          final groupName =
              (record.data?['groupName'] as String? ?? record.name).trim();
          print(
              '   📋 membersByFarmerId has ${membersByFarmerId.length} entries');
          int memberIndex = 0;
          for (final entry in membersByFarmerId.entries) {
            memberIndex++;
            final saadId = entry.key;
            final farmerDataRaw = entry.value;
            print(
                '      🔍 Processing entry #$memberIndex: saadId="$saadId", isMap=${farmerDataRaw is Map}');
            if (farmerDataRaw is Map) {
              final farmerData = Map<String, dynamic>.from(farmerDataRaw);
              var name = ((farmerData['name'] as String?) ??
                      (farmerData['farmerName'] as String?) ??
                      '')
                  .trim();
              if (name.isEmpty) {
                name = saadId.trim();
              }
              print('         - Name: "$name"');
              print('         - farmerData keys: ${farmerData.keys.toList()}');
              print(
                  '         - Has commodities: ${farmerData.containsKey("commodities")}');
              print(
                  '         - Has completedCommodities: ${farmerData.containsKey("completedCommodities")}');
              print(
                  '         - Commodities count: ${(farmerData["commodities"] as List?)?.length ?? 0}');
              print(
                  '         - CompletedCommodities count: ${(farmerData["completedCommodities"] as List?)?.length ?? 0}');
              if (name.isNotEmpty) {
                final status =
                    record.status == 'unsync' ? 'in_progress' : 'completed';
                final memberRecord = withMemberData(record, farmerData);
                final candidate = _DynamicMemberRecord(
                  member: MemberModel(name: name, status: status),
                  record: memberRecord,
                  groupName: groupName,
                );
                // ✅ Use SAAD ID as unique key to avoid overwrites
                final uniqueKey = saadId.isNotEmpty ? saadId : name;
                final existing = members[uniqueKey];
                if (existing == null ||
                    _recordPriority(candidate.record) >
                        _recordPriority(existing.record)) {
                  members[uniqueKey] = candidate;
                  print('         ✅ Added to members with key: $uniqueKey');
                } else {
                  print(
                      '         ℹ️ Skipped - existing has higher priority: $uniqueKey');
                }
              } else {
                print('         ⚠️ Name is empty, skipping');
              }
            } else {
              print('         ⚠️ farmerDataRaw is not a Map, skipping');
            }
          }
        } else if (implType == 'collective') {
          print(
              '⏭️  SKIP Case 2: COLLECTIVE $record.name is group-level only, no member extraction');
        }

        // ── Case 3: Fallback to old members array for backward compatibility ──
        // Only if no membersByFarmerId and no farmerName
        else if (membersList.isNotEmpty && farmerName.isEmpty) {
          final groupName =
              (record.data?['groupName'] as String? ?? record.name).trim();
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
                  groupName: groupName,
                );
                // ✅ Use SAAD ID as unique key to avoid overwrites
                final saadIdFromMember =
                    (member['saadIdNo'] as String? ?? '').trim();
                final uniqueKey =
                    saadIdFromMember.isNotEmpty ? saadIdFromMember : name;
                final existing = members[uniqueKey];
                if (existing == null ||
                    _recordPriority(candidate.record) >
                        _recordPriority(existing.record)) {
                  members[uniqueKey] = candidate;
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
        // Declare mergedData first so it's available for both pending and non-pending paths
        Map<String, dynamic>? mergedData = widget.record.data;
        Map<String, dynamic>? memberData;
        List<dynamic> commodities = [];

        // ✅ CRITICAL: For PENDING records, use Firebase data ONLY - skip all local loading/merging
        if (widget.record.status == 'pending') {
          print(
              '   ✅ PENDING record - using Firebase data only, no local loading');
          print(
              '   - Firebase data keys: ${widget.record.data?.keys.toList()}');

          // ✅ CRITICAL FIX: For pending records, get the MEMBER-specific data from membersByFarmerId
          // NOT the group-level data
          final membersByFarmerId = widget.record.data?['membersByFarmerId']
                  as Map<String, dynamic>? ??
              {};

          if (actualSaadId.isNotEmpty &&
              membersByFarmerId.containsKey(actualSaadId)) {
            // Use member-specific data from Firebase
            memberData =
                membersByFarmerId[actualSaadId] as Map<String, dynamic>?;

            // ✅ CRITICAL: Merge both group-level AND member-specific data
            // Start with group data (for project background fields)
            mergedData = Map<String, dynamic>.from(widget.record.data ?? {});
            // Then overlay member-specific data (commodities, farmer name, etc.)
            if (memberData != null) {
              mergedData.addAll(memberData);
            }

            print('   ✅ Using member-specific data for saadId=$actualSaadId');
            print('   - Member data keys: ${memberData?.keys.toList()}');
            print('   - Merged data keys: ${mergedData?.keys.toList()}');
          } else {
            // Fallback to group data if member not found
            memberData = widget.record.data; // Firebase data only
            mergedData = widget.record.data;
            print(
                '   ⚠️ Member saadId=$actualSaadId not found in membersByFarmerId, using group data');
          }

          print(
              '   - memberData is now set: ${memberData != null ? "yes (${memberData!.length} keys)" : "NULL"}');

          // Extract commodities from pending Firebase data
          commodities = extractCommodities(memberData, widget.record.data);
          print(
              '   - Extracted commodities count for pending: ${commodities.length}');
        } else {
          // For individual records, merge commodity data from subcollection or root commodity collection
          final membersByFarmerId = widget.record.data?['membersByFarmerId']
                  as Map<String, dynamic>? ??
              {};

          print('🔍 LOADING MEMBER DATA for $actualFarmerName:');
          print('   - actualSaadId: "$actualSaadId"');
          print(
              '   - membersByFarmerId keys: ${membersByFarmerId.keys.toList()}');
          print(
              '   - widget.record.data has completedCommodities: ${widget.record.data?['completedCommodities'] != null}');

          // ✅ CRITICAL FIX: Load fresh group.json to ensure we have latest project background
          // This ensures all project background fields are present when viewing farmer records
          Map<String, dynamic> freshGroupData = <String, dynamic>{};
          // ✅ CRITICAL: Load local group.json ONLY for UNSYNC records, NOT for PENDING
          // PENDING records must use Firebase data only
          if ((widget.record.status == 'unsync') && widget.record.isLocal) {
            try {
              final groupName = widget.record.name.trim();
              const baseDir =
                  '/storage/emulated/0/Android/data/com.example.da_monitoring_app/files/monitoring_records';
              final groupJsonPath =
                  '$baseDir/${widget.record.productionType.toLowerCase()}/${groupName.replaceAll(' ', '_')}/group.json';
              final groupFile = File(groupJsonPath);

              print(
                  '📂 [FARMER VIEW] Loading fresh group.json from: $groupJsonPath');

              if (groupFile.existsSync()) {
                final content = groupFile.readAsStringSync();
                freshGroupData = jsonDecode(content) as Map<String, dynamic>;

                print(
                    '✅ [FARMER VIEW] Loaded fresh group.json with keys: ${freshGroupData.keys.toList()}');
              }
            } catch (e) {
              print('⚠️ [FARMER VIEW] Error loading group.json: $e');
            }
          }

          // ✅ CRITICAL FIX: For UNSYNC records (not yet synced), load FRESH data from LocalFarmerStorageService
          // For PENDING records (synced to Firebase), use Firebase data - do NOT load from local cache
          // This ensures: unsync shows latest local, pending shows actual Firebase
          if (widget.record.status == 'unsync' &&
              widget.record.isLocal &&
              actualFarmerName.isNotEmpty) {
            try {
              final fcaName = (widget.record.data?['fcaName'] as String? ?? '')
                  .trim()
                  .replaceAll('_', ' ');
              final farmerId =
                  actualSaadId.isNotEmpty ? actualSaadId : actualFarmerName;

              print(
                  '   📂 LOADING FRESH DATA from LOCAL for unsync: $actualFarmerName (farmerId: $farmerId)');

              final freshFarmerData =
                  await LocalFarmerStorageService.instance.getFarmerData(
                productionType: widget.record.productionType.toLowerCase(),
                groupName: fcaName,
                farmerName: actualFarmerName,
                saadId: farmerId,
              );

              if (freshFarmerData != null && freshFarmerData.isNotEmpty) {
                print(
                    '   ✅ LOADED FRESH LOCAL DATA: ${freshFarmerData.keys.length} fields');
                memberData = freshFarmerData;
              } else {
                print(
                    '   ⚠️ No fresh data found in LocalFarmerStorageService, using cached data');
              }
            } catch (e) {
              print(
                  '   ⚠️ Error loading fresh farmer data from LocalFarmerStorageService: $e');
            }
          }

          if (membersByFarmerId.isNotEmpty && memberData == null) {
            print(
                '   - membersByFarmerId is NOT EMPTY (${membersByFarmerId.length} entries) and memberData is null, attempting fallback');
            if (actualSaadId.isNotEmpty &&
                membersByFarmerId.containsKey(actualSaadId)) {
              memberData =
                  membersByFarmerId[actualSaadId] as Map<String, dynamic>?;
              print(
                  '   - ✅ Found memberData by exact SAAD ID match: $actualSaadId');
            } else {
              print('   - Searching membersByFarmerId by name match...');
              for (final entry in membersByFarmerId.entries) {
                final data = entry.value;
                if (data is Map<String, dynamic>) {
                  final memberSaadId =
                      (data['saadIdNo'] as String? ?? '').trim();
                  final memberName = ((data['name'] as String?) ??
                          (data['farmerName'] as String?) ??
                          '')
                      .trim();
                  if (memberSaadId.isNotEmpty &&
                      actualSaadId.isNotEmpty &&
                      memberSaadId == actualSaadId) {
                    memberData = data;
                    print('   - ✅ Found memberData by SAAD ID: $memberSaadId');
                    break;
                  }
                  if (memberData == null &&
                      memberName.isNotEmpty &&
                      memberName == actualFarmerName) {
                    memberData = data;
                    print(
                        '   - ✅ Found memberData by name match: $memberName (saadId: $memberSaadId)');
                  }
                }
              }
            }
          } else if (membersByFarmerId.isEmpty && memberData == null) {
            print(
                '   - membersByFarmerId is EMPTY and memberData is null: using widget.record.data directly (local record)');
          }

          commodities = extractCommodities(memberData, widget.record.data);

          print('🔍 DEBUG Member Loading for $actualFarmerName:');
          print('   - memberData provided: ${memberData != null}');
          print(
              '   - widget.record.data has completedCommodities: ${widget.record.data?['completedCommodities'] != null}');
          print('   - extracted commodities count: ${commodities.length}');
          if (commodities.isNotEmpty) {
            for (int i = 0; i < commodities.length; i++) {
              final c = commodities[i] as Map<String, dynamic>?;
              print('   - commodity[$i]: ${c?['typeOfCrop']} ${c?['variety']}');
            }
          }

          // ✅ CRITICAL: Start with group project background from widget.record.data
          // This contains Step 01 fields: fcaName, reportingPeriod, projectTitle, region, etc.
          mergedData = Map<String, dynamic>.from(widget.record.data ?? {});

          // ✅ Preserve all Step 01 Project Background fields from group data
          // These should NEVER be overwritten with farmer-specific data
          final projectBackgroundFields = [
            'fcaName',
            'reportingPeriod',
            'projectTitle',
            'implementationType',
            'region',
            'province',
            'municipality',
            'barangay',
            'primaryIntervention',
            'primaryInterventionOther',
            'supportInterventions',
          ];

          final groupProjectBackground = <String, dynamic>{};

          // ✅ Use fresh group.json data from local storage (not cached data)
          // This ensures we have the latest project background fields
          print('   📂 Using FRESH group.json data for project background');
          for (final key in projectBackgroundFields) {
            if (freshGroupData.containsKey(key)) {
              groupProjectBackground[key] = freshGroupData[key];
              print('      ✅ Field "$key": ${freshGroupData[key]}');
            }
          }

          // ✅ Now merge farmer-specific data (step 02-07)
          if (memberData != null && memberData.isNotEmpty) {
            // Only merge farmer-specific fields, NOT group fields
            for (final entry in memberData.entries) {
              if (!projectBackgroundFields.contains(entry.key)) {
                mergedData[entry.key] = entry.value;
              }
            }
          }

          // ✅ Re-apply group project background to ensure it's never lost
          mergedData.addAll(groupProjectBackground);

          print(
              '🔍 DEBUG: After merging group project background for $actualFarmerName:');
          for (final key in projectBackgroundFields) {
            final value = mergedData[key];
            print('   - $key: "$value"');
          }

          if (commodities.isNotEmpty) {
            // ✅ CRITICAL: Preserve the ENTIRE completedCommodities array for display
            // Don't just take the first commodity - we need all of them for the modal
            mergedData['completedCommodities'] = commodities;

            // Also add the first commodity's fields for backward compatibility with top-level display
            final commodityData = commodities.first as Map<String, dynamic>;
            // Don't overwrite project background when merging commodity data
            for (final entry in commodityData.entries) {
              if (!projectBackgroundFields.contains(entry.key)) {
                mergedData[entry.key] = entry.value;
              }
            }
          }

          final trainings = (memberData?['trainings'] as List?) ??
              (widget.record.data?['trainings'] as List?) ??
              [];
          if (trainings.isNotEmpty) {
            mergedData?['trainings'] = trainings;
          }
        }

        // ✅ Ensure mergedData is not null
        mergedData ??= <String, dynamic>{};

        // ✅ ALSO SET COMMODITIES FOR PENDING RECORDS
        if (widget.record.status == 'pending' && commodities.isNotEmpty) {
          mergedData['completedCommodities'] = commodities;
          print(
              '   ✅ Set completedCommodities for pending: ${commodities.length} commodities');
        }

        // ✅ CREATE RECORD - This runs for BOTH pending and non-pending records
        final constructedPath =
            widget.record.status == 'pending' && actualSaadId.isNotEmpty
                ? '${widget.record.documentPath}/members/$actualSaadId'
                : widget.record.documentPath;

        final individualRecord = RecordModel(
          id: widget.record.id,
          name: widget.record.name,
          productionType: widget.record.productionType,
          implType: widget.record.implType,
          enumerator: widget.record.enumerator,
          date: widget.record.date,
          status: widget.record.status,
          // ✅ FIX: For pending records, construct the member document path
          // Group path + /members/{saadId}
          documentPath: constructedPath,
          data: mergedData,
          isLocal: widget.record.isLocal,
        );

        print('   🔗 Member Record Created:');
        print('      - Name: ${individualRecord.name}');
        print('      - SAAD ID: $actualSaadId');
        print('      - Status: ${individualRecord.status}');
        print('      - Original path: ${widget.record.documentPath}');
        print('      - Constructed path: $constructedPath');
        print('      - Final documentPath: ${individualRecord.documentPath}');
        print(
            '      - completedCommodities in data: ${(mergedData?['completedCommodities'] as List?)?.length ?? 0}');

        // ✅ CRITICAL: Use SAAD ID as unique key (not farmer name) to avoid overwrites
        // when multiple farmers have the same name
        final uniqueKey = actualSaadId.isNotEmpty
            ? actualSaadId
            : '${actualFarmerName}_${widget.record.data?.hashCode}';

        members[uniqueKey] = _DynamicMemberRecord(
          member: MemberModel(
            name: actualFarmerName,
            status:
                widget.record.status == 'unsync' ? 'in_progress' : 'completed',
          ),
          record: individualRecord,
        );

        print(
            '   ✅ Added member to map with key: "$uniqueKey" (farmer: $actualFarmerName, saadId: $actualSaadId)');
      }

      final q = _query.toLowerCase();
      final result = members.values
          .where(
              (item) => q.isEmpty || item.member.name.toLowerCase().contains(q))
          .toList()
        ..sort((a, b) => a.member.name.compareTo(b.member.name));
      return result;
    } catch (e) {
      print('❌ ERROR in _loadMembers: $e');
      return [];
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
  Future<void> _addCommodityForMember(String farmerName, String saadId) async {
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
        ..saadIdNo = saadId // ✅ Set SAAD ID for unique identification
        ..isAddingNewCommodity = true // ✅ Adding commodity to existing farmer
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
        ..saadIdNo = saadId // ✅ Set SAAD ID for unique identification
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
        ..saadIdNo = saadId // ✅ Set SAAD ID for unique identification
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
    
    // DEBUG: Log session and role info
    print('🔐 Session Debug:');
    print('   - Session: $session');
    print('   - Session?.uid: ${session?.uid}');
    print('   - Session?.role: ${session?.role}');
    print('   - isModerator: $isModerator');
    print('   - isAdmin: $isAdmin');
    print('   - Record status: ${memberRecord.record.status}');
    print('   - showApprove would be: ${memberRecord.record.status == 'pending' && (isModerator || isAdmin)}');
    print('   - approveLocked would be: ${memberRecord.record.status == 'pending' && !(isModerator || isAdmin)}');

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
                      if (widget.record.implType.toLowerCase() !=
                          'collective') ...[
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
                      ],

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
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Members section (HYBRID/INDIVIDUAL ONLY) ───────────────────────────────
                      if (widget.record.implType.toLowerCase() !=
                          'collective') ...[
                        const _SectionLabel(label: 'Members'),
                        const SizedBox(height: 10),
                        FutureBuilder<List<_DynamicMemberRecord>>(
                          future: _membersFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                  ),
                                ),
                              );
                            }

                            if (snapshot.hasError) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(children: [
                                    const Icon(Icons.error_outline_rounded,
                                        color: Colors.red, size: 40),
                                    const SizedBox(height: 12),
                                    Text('Error loading members',
                                        style: GoogleFonts.poppins(
                                            fontSize: 13, color: Colors.red)),
                                  ]),
                                ),
                              );
                            }

                            final members = snapshot.data ?? [];
                            print(
                                '✅ Members list prepared: ${members.length} members');
                            for (int i = 0; i < members.length; i++) {
                              final m = members[i];
                              final commoditiesCount =
                                  (m.record.data?['completedCommodities']
                                              as List?)
                                          ?.length ??
                                      0;
                              print(
                                  '   [$i] ${m.member.name} - commodities in data: $commoditiesCount');
                            }
                            if (members.isEmpty) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(children: [
                                    const Icon(Icons.people_outline_rounded,
                                        color: DAColors.textMuted, size: 40),
                                    const SizedBox(height: 12),
                                    Text('No members found',
                                        style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: DAColors.textMuted)),
                                  ]),
                                ),
                              );
                            }

                            return Column(
                              children: [
                                for (final memberRecord in members)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _MemberCard(
                                      member: memberRecord.member,
                                      onView: () => _viewMember(memberRecord),
                                      onAddCommodity: () {
                                        final saadId = (memberRecord.record
                                                        .data?['saadIdNo']
                                                    as String? ??
                                                '')
                                            .trim();
                                        _addCommodityForMember(
                                            memberRecord.member.name, saadId);
                                      },
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                      ], // Close if (widget.record.implType.toLowerCase() != 'collective')
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
