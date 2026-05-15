import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'monitoring_record_service.dart';
import 'local_farmer_storage_service.dart';

class PendingDraftSyncResult {
  const PendingDraftSyncResult({
    required this.syncedCount,
    required this.failedCount,
  });

  final int syncedCount;
  final int failedCount;
}

class PendingDraftService {
  final ValueNotifier<bool> pendingDraftsUpdated = ValueNotifier<bool>(false);

  Future<void> deleteDraftByLocalId(String localId) async {
    final drafts = await readDrafts();
    final updatedDrafts =
        drafts.where((draft) => draft['localId'] != localId).toList();
    await writeDrafts(updatedDrafts);
    _notifyDraftsUpdated();
  }

  Future<void> updateDraftStatus(String localId, String newStatus) async {
    final drafts = await readDrafts();
    final updatedDrafts = drafts.map((draft) {
      if (draft['localId'] == localId) {
        return {
          ...draft,
          'status': newStatus,
          'updatedLocallyAt': DateTime.now().toIso8601String(),
        };
      }
      return draft;
    }).toList();
    await writeDrafts(updatedDrafts);
    _notifyDraftsUpdated();
  }

  Future<void> clearAllDrafts() async {
    // Get all unsync records from folders and delete them
    try {
      final unsyncRecords =
          await LocalFarmerStorageService.instance.getAllUnsyncRecords();
      for (final record in unsyncRecords) {
        final productionType =
            (record['productionType'] as String? ?? '').toLowerCase();
        final groupName = (record['groupName'] as String? ?? '').trim();

        if (productionType.isNotEmpty && groupName.isNotEmpty) {
          try {
            await LocalFarmerStorageService.instance
                .deleteRecord(productionType, groupName);
            print('✅ Deleted unsync folder: $groupName/$productionType');
          } catch (e) {
            print('⚠️ Failed to delete folder for $groupName: $e');
          }
        }
      }
    } catch (e) {
      print('⚠️ Failed to retrieve unsync records for deletion: $e');
    }

    // Also clear from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    print('✅ Cleared all drafts from storage');
  }

  PendingDraftService._();

  static final PendingDraftService instance = PendingDraftService._();

  static const String _storageKey = 'pending_profiling_drafts_v1';

  Future<String> saveDraft({
    required String productionType,
    required String implementationType,
    required Map<String, dynamic> data,
    String source = 'draft',
  }) async {
    final drafts = await readDrafts();
    // ✅ Always save as 'unsync' locally first
    const status = 'unsync';

    final normalizedProductionType = productionType.trim().toLowerCase();
    final normalizedImplementationType =
        implementationType.trim().toLowerCase();

    print('🔥 saveDraft called:');
    print('   productionType: $normalizedProductionType');
    print('   implementationType: $normalizedImplementationType');
    print('   fcaName: ${data['fcaName']}');
    print('   members count: ${(data['members'] as List?)?.length ?? 0}');
    print(
        '   membersByFarmerId count: ${(data['membersByFarmerId'] as Map?)?.length ?? 0}');

    // Debug: show actual members data
    final membersList = data['members'] as List?;
    if (membersList != null && membersList.isNotEmpty) {
      print('   members details:');
      for (final m in membersList) {
        print('      - ${m['name']} (${m['saadIdNo']})');
      }
    }

    final bool hasGroupMembers =
        ((data['membersByFarmerId'] as Map?)?.isNotEmpty == true) ||
            ((data['members'] as List?)?.isNotEmpty == true);

    // CRITICAL: Explicitly treat explicit individual records as individual
    // even if they contain a members structure from the UI.
    final isGroupRecord = normalizedImplementationType == 'collective' ||
        normalizedImplementationType == 'hybrid';
    if (normalizedImplementationType == 'collective') {
      final fcaName = (data['fcaName'] as String?)?.trim() ?? '';
      data = {
        ...data,
        'farmerName': '',
        'fcaName': fcaName,
      };
      // Remove farmer-specific fields for collective
      data.remove('farmerName');
      data.remove('saadIdNo');
    }

    data = {...data, 'implementationType': normalizedImplementationType};

    // Normalize key fields to prevent duplicate drafts
    data['fcaName'] = (data['fcaName'] as String?)?.trim() ?? '';
    data['reportingPeriod'] =
        (data['reportingPeriod'] as String?)?.trim() ?? '';
    data['projectTitle'] = (data['projectTitle'] as String?)?.trim() ?? '';
    data['farmerName'] = (data['farmerName'] as String?)?.trim() ?? '';
    data['saadIdNo'] = (data['saadIdNo'] as String?)?.trim() ?? '';

    final fileName = buildDraftFileName(
      productionType: normalizedProductionType,
      implementationType: normalizedImplementationType,
      data: data,
    );

    // Check for existing draft with same key fields
    // For collectives, check: productionType, implementationType, fcaName, typeOfCrop/breed, AND members
    // For individuals, check: productionType, farmerName, fcaName, typeOfCrop/breed
    final isCropType = normalizedProductionType == 'crop';

    // Determine the commodity field based on production type
    final commodityValue = isCropType
        ? (data['typeOfCrop'] as String? ?? '')
        : (data['breed'] as String? ?? '');

    final existingIndex = drafts.indexWhere((draft) {
      final draftProductionType =
          (draft['productionType'] as String? ?? '').trim().toLowerCase();
      final draftImplementationType =
          (draft['implementationType'] as String? ?? '').trim().toLowerCase();
      if (draftProductionType != normalizedProductionType) {
        return false;
      }

      // Allow matching if both are group types, even if implementationType differs
      // or if the record contains a group-like member structure.
      final draftData = draft['data'] as Map<String, dynamic>? ?? {};
      final draftHasGroupMembers =
          ((draftData['membersByFarmerId'] as Map?)?.isNotEmpty == true) ||
              ((draftData['members'] as List?)?.isNotEmpty == true);
      final draftIsGroup = draftImplementationType == 'collective' ||
          draftImplementationType == 'hybrid';
      final dataHasGroupMembers =
          ((data['membersByFarmerId'] as Map?)?.isNotEmpty == true) ||
              ((data['members'] as List?)?.isNotEmpty == true);
      final dataIsGroup = normalizedImplementationType == 'collective' ||
          normalizedImplementationType == 'hybrid';
      print(
          '   draftImplementationType: $draftImplementationType, normalizedImplementationType: $normalizedImplementationType');
      print(
          '   draftHasGroupMembers: $draftHasGroupMembers, dataHasGroupMembers: $dataHasGroupMembers');
      if (draftImplementationType != normalizedImplementationType &&
          !(draftIsGroup && dataIsGroup)) {
        return false;
      }
      final draftFcaName =
          (draftData['fcaName'] as String? ?? '').trim().toLowerCase();
      final dataFcaName =
          (data['fcaName'] as String? ?? '').trim().toLowerCase();

      print('🔍 Comparing draft:');
      print('   isGroupRecord: $isGroupRecord');
      print('   draftFcaName="$draftFcaName", dataFcaName="$dataFcaName"');

      // ✅ GROUP RECORDS: match on FCA name only — skip period/project check
      if (isGroupRecord) {
        if (draftFcaName == dataFcaName) {
          print('   ✅ MATCH! (same group FCA: $draftFcaName)');
          return true;
        }
        print('   ❌ No match - different FCA name');
        return false;
      }

      // ✅ NEW: If the EXISTING draft is a group record but incoming is individual,
      // still merge them if they have the same FCA+period+project
      // (This handles adding new farmers to existing groups)
      if (draftIsGroup && !dataIsGroup) {
        final draftReportingPeriod =
            (draftData['reportingPeriod'] as String? ?? '')
                .trim()
                .toLowerCase();
        final draftProjectTitle =
            (draftData['projectTitle'] as String? ?? '').trim().toLowerCase();
        final dataReportingPeriod =
            (data['reportingPeriod'] as String? ?? '').trim().toLowerCase();
        final dataProjectTitle =
            (data['projectTitle'] as String? ?? '').trim().toLowerCase();

        if (draftFcaName == dataFcaName &&
            draftReportingPeriod == dataReportingPeriod &&
            draftProjectTitle == dataProjectTitle) {
          print('   ✅ MATCH! (new farmer added to existing group)');
          return true;
        }
      }

      // INDIVIDUAL RECORDS: also require period + project + farmer identity
      final draftReportingPeriod =
          (draftData['reportingPeriod'] as String? ?? '').trim().toLowerCase();
      final draftProjectTitle =
          (draftData['projectTitle'] as String? ?? '').trim().toLowerCase();
      final dataReportingPeriod =
          (data['reportingPeriod'] as String? ?? '').trim().toLowerCase();
      final dataProjectTitle =
          (data['projectTitle'] as String? ?? '').trim().toLowerCase();

      print(
          '   Draft: $draftFcaName / $draftReportingPeriod / $draftProjectTitle');
      print(
          '   New:   $dataFcaName / $dataReportingPeriod / $dataProjectTitle');

      if (draftFcaName != dataFcaName ||
          draftReportingPeriod != dataReportingPeriod ||
          draftProjectTitle != dataProjectTitle) {
        print('   ❌ No match - different FCA/period/project');
        return false;
      }

      // For INDIVIDUAL/HYBRID: also match by commodity so different commodities stay separate
      final draftFarmerName =
          (draftData['farmerName'] as String? ?? '').trim().toLowerCase();
      final dataFarmerName =
          (data['farmerName'] as String? ?? '').trim().toLowerCase();
      final draftSaadId = (draftData['saadIdNo'] as String? ??
              draftData['saadId'] as String? ??
              '')
          .trim()
          .toLowerCase();
      final dataSaadId =
          (data['saadIdNo'] as String? ?? data['saadId'] as String? ?? '')
              .trim()
              .toLowerCase();

      print('   Checking identity: ');
      print('      draft farmerName="$draftFarmerName" saadId="$draftSaadId"');
      print('      new   farmerName="$dataFarmerName" saadId="$dataSaadId"');

      // ✅ FIX: Both are individual records sharing the same FCA/period/project
      // = same group of individually-managed farmers → merge into one draft.
      // Strict: NEVER matches collective ↔ individual.
      if (draftImplementationType == 'individual' &&
          normalizedImplementationType == 'individual' &&
          draftHasGroupMembers &&
          dataHasGroupMembers &&
          draftFcaName == dataFcaName &&
          draftReportingPeriod == dataReportingPeriod &&
          draftProjectTitle == dataProjectTitle) {
        print(
            '   ✅ MATCH! (individual group: same FCA/period/project, both have members)');
        return true;
      }

      final sameSaad = draftSaadId.isNotEmpty &&
          dataSaadId.isNotEmpty &&
          draftSaadId == dataSaadId;
      final sameFarmerName = draftFarmerName.isNotEmpty &&
          dataFarmerName.isNotEmpty &&
          draftFarmerName == dataFarmerName;

      print('      sameSaad=$sameSaad, sameFarmerName=$sameFarmerName');

      // NEW: Fallback match group draft by FCA + period + project
      // when adding an individual farmer into an existing group record.
      if (draftIsGroup &&
          !dataIsGroup &&
          draftFcaName == dataFcaName &&
          draftReportingPeriod == dataReportingPeriod &&
          draftProjectTitle == dataProjectTitle) {
        print('   ✅ MATCH! (group fallback by FCA/period/project)');
        return true;
      }

      if (sameSaad && sameFarmerName) {
        print('   ✅ MATCH! (same individual farmer)');
        return true;
      }

      print('   ❌ No match - different individual farmer');
      return false;
    });

    String localId;
    if (existingIndex != -1) {
      // Update existing draft
      print('✅ FOUND existing draft at index $existingIndex');
      print('   Will merge new data with existing data');
      localId = drafts[existingIndex]['localId'] as String;
      final existingDraftData =
          Map<String, dynamic>.from(drafts[existingIndex]['data'] as Map);

      final existingImplementationType =
          (drafts[existingIndex]['implementationType'] as String? ?? '')
              .trim()
              .toLowerCase();
      final existingHasGroupMembers =
          ((existingDraftData['membersByFarmerId'] as Map?)?.isNotEmpty ==
                  true) ||
              ((existingDraftData['members'] as List?)?.isNotEmpty == true);
      final existingIsGroup = existingImplementationType == 'collective' ||
          existingImplementationType == 'hybrid';
      final incomingIsGroup = isGroupRecord;
      final shouldTreatAsGroup = existingIsGroup ||
          incomingIsGroup ||
          (existingHasGroupMembers && hasGroupMembers);

      final resolvedImplementationType = shouldTreatAsGroup
          ? (existingIsGroup
              ? existingImplementationType
              : normalizedImplementationType)
          : normalizedImplementationType;
      var mergedData = data;

      if (shouldTreatAsGroup) {
        print('   Merging as group draft data...');
        mergedData = _mergeGroupDraftData(
          existingDraftData: existingDraftData,
          incomingDraftData: data,
        );
        print(
            '   After merge - membersByFarmerId: ${mergedData['membersByFarmerId']}');
        print('   After merge - members: ${mergedData['members']}');
      } else {
        print('   Merging as individual draft data...');
        mergedData = _mergeIndividualDraftData(
          existingDraftData: existingDraftData,
          incomingDraftData: data,
        );
      }

      drafts[existingIndex] = {
        ...drafts[existingIndex],
        'fileName': buildDraftFileName(
          productionType: normalizedProductionType,
          implementationType: resolvedImplementationType,
          data: mergedData,
        ),
        'implementationType': resolvedImplementationType,
        'data': mergedData,
        'source': source,
        'status': status,
        'updatedLocallyAt': DateTime.now().toIso8601String(),
      };

      print('   ✍️ Writing updated draft to storage...');
      try {
        await writeDrafts(drafts);
        print('   ✅ Draft overwritten successfully');
      } catch (e) {
        print('   ❌ ERROR writing draft to storage: $e');
        print('   This might be a storage permission or device issue');
        rethrow;
      }
      _notifyDraftsUpdated();

      // For collectives and hybrid group records, save each farmer's data to their own folder
      // CRITICAL: Never treat individual farmers as group records, even if they have members data
      final shouldSaveAsGroupRecord = (shouldTreatAsGroup ||
              resolvedImplementationType == 'collective' ||
              resolvedImplementationType == 'hybrid') &&
          resolvedImplementationType != 'individual';

      if (shouldSaveAsGroupRecord) {
        final groupMembersForSave = (mergedData['members'] as List?) ?? [];
        print(
            '📂 GROUP RECORD - About to save local folders for ${groupMembersForSave.length} farmers');
        for (final m in groupMembersForSave) {
          if (m is Map) {
            print('   - ${m['name']} (${m['saadIdNo']})');
          }
        }
        await saveFarmerDataFolders(
          productionType: normalizedProductionType,
          groupName: mergedData['fcaName'] as String? ?? 'Unknown Group',
          members: groupMembersForSave,
          data: mergedData,
        );
      } else if (resolvedImplementationType == 'individual') {
        // ✅ FIX: For each farmer in membersByFarmerId, save their own folder
        // Do NOT use mergedData['farmerName'] — that may be stale from a previous farmer
        final membersToSave = mergedData['membersByFarmerId'] as Map? ?? {};
        if (membersToSave.isEmpty) {
          // Fallback for truly individual with no group
          final farmerName =
              mergedData['farmerName'] as String? ?? 'Unknown Farmer';
          final saadId = mergedData['saadIdNo'] as String? ?? 'NoSAAD';
          print('👤 INDIVIDUAL RECORD - Saving folder for $farmerName');
          await saveSingleFarmerData(
            productionType: normalizedProductionType,
            groupName: mergedData['fcaName'] as String? ?? 'Unknown Group',
            farmerName: farmerName,
            saadId: saadId,
            data: mergedData,
          );
        } else {
          // ✅ Save each farmer in membersByFarmerId to their own folder
          for (final entry in membersToSave.entries) {
            final memberId = entry.key as String;
            final memberData = entry.value is Map
                ? Map<String, dynamic>.from(entry.value as Map)
                : <String, dynamic>{};
            final farmerName = (memberData['farmerName'] as String? ??
                    memberData['name'] as String? ??
                    '')
                .trim();
            final saadId = memberId;
            if (farmerName.isEmpty && saadId.isEmpty) continue;
            print(
                '👤 INDIVIDUAL RECORD - Saving folder for $farmerName ($saadId)');
            await saveSingleFarmerData(
              productionType: normalizedProductionType,
              groupName: mergedData['fcaName'] as String? ?? 'Unknown Group',
              farmerName: farmerName,
              saadId: saadId,
              data: mergedData,
            );
          }
        }
      }
    } else {
      // Create new draft
      print('❌ NO existing draft found - creating NEW draft');
      print('   This might overwrite old data if FCA/period/project match!');
      print(
          '   Searched for: $normalizedProductionType / $normalizedImplementationType / ${data['fcaName']}');

      // ✅ FIX: For group records (collective/hybrid), use productionType/groupName as localId
      // This matches the groupKey format used in member_records_screen.dart
      // For individual records, use timestamp-based localId
      if (isGroupRecord && normalizedImplementationType != 'individual') {
        final groupName = (data['fcaName'] as String? ?? 'Unknown').trim();
        localId = '$normalizedProductionType/$groupName';
        print('   📍 Group record: localId set to "$localId"');
      } else {
        localId = DateTime.now().microsecondsSinceEpoch.toString();
        print('   📍 Individual record: localId set to "$localId"');
      }

      drafts.add({
        'localId': localId,
        'fileName': fileName,
        'productionType': normalizedProductionType,
        'implementationType': normalizedImplementationType,
        'data': data,
        'source': source,
        'status': status,
        'savedLocallyAt': DateTime.now().toIso8601String(),
      });

      print('   ✍️ Writing new draft to storage...');
      try {
        await writeDrafts(drafts);
        print('   ✅ New draft saved successfully');
      } catch (e) {
        print('   ❌ ERROR saving new draft: $e');
        print('   This might be a storage permission or device issue');
        rethrow;
      }
      _notifyDraftsUpdated();

      // For collectives and hybrid group records, save each farmer's data to their own folder
      // CRITICAL: Never treat individual farmers as group records, even if they have members data
      if (isGroupRecord && normalizedImplementationType != 'individual') {
        final groupMembersForSave = (data['members'] as List?) ?? [];
        print(
            '📂 NEW GROUP RECORD - About to save local folders for ${groupMembersForSave.length} farmers');
        for (final m in groupMembersForSave) {
          if (m is Map) {
            print('   - ${m['name']} (${m['saadIdNo']})');
          }
        }
        await saveFarmerDataFolders(
          productionType: normalizedProductionType,
          groupName: data['fcaName'] as String? ?? 'Unknown Group',
          members: groupMembersForSave,
          data: data,
        );
      } else if (normalizedImplementationType == 'individual') {
        // ✅ FIX: For each farmer in membersByFarmerId, save their own folder
        // Do NOT use data['farmerName'] — that may be stale from a previous farmer
        final membersToSave = data['membersByFarmerId'] as Map? ?? {};
        if (membersToSave.isEmpty) {
          // Fallback for truly individual with no group
          final farmerName = data['farmerName'] as String? ?? 'Unknown Farmer';
          final saadId = data['saadIdNo'] as String? ?? 'NoSAAD';
          print('👤 NEW INDIVIDUAL RECORD - Saving folder for $farmerName');
          await saveSingleFarmerData(
            productionType: normalizedProductionType,
            groupName: data['fcaName'] as String? ?? 'Unknown Group',
            farmerName: farmerName,
            saadId: saadId,
            data: data,
          );
        } else {
          // ✅ Save each farmer in membersByFarmerId to their own folder
          for (final entry in membersToSave.entries) {
            final memberId = entry.key as String;
            final memberData = entry.value is Map
                ? Map<String, dynamic>.from(entry.value as Map)
                : <String, dynamic>{};
            final farmerName = (memberData['farmerName'] as String? ??
                    memberData['name'] as String? ??
                    '')
                .trim();
            final saadId = memberId;
            if (farmerName.isEmpty && saadId.isEmpty) continue;
            print(
                '👤 NEW INDIVIDUAL RECORD - Saving folder for $farmerName ($saadId)');
            await saveSingleFarmerData(
              productionType: normalizedProductionType,
              groupName: data['fcaName'] as String? ?? 'Unknown Group',
              farmerName: farmerName,
              saadId: saadId,
              data: data,
            );
          }
        }
      }
    }

    // ✅ Manual sync only: do not auto-sync on save.
    // Local records remain status 'unsync' until the user explicitly syncs them.
    return localId;
  }

  bool _isLocalUnsyncedStatus(String status) {
    return status == 'unsync' || status == 'draft';
  }

  Future<int> getPendingDraftCount() async {
    final drafts = await readDrafts();
    // ✅ Count both current unsynced and legacy draft records
    return drafts.where((draft) {
      final status = draft['status'] as String? ?? 'unsync';
      return _isLocalUnsyncedStatus(status);
    }).length;
  }

  Future<List<Map<String, dynamic>>> getPendingDrafts() async {
    final drafts = await readDrafts();
    // ✅ Only get local unsynced records, including legacy drafts
    return drafts.where((draft) {
      final status = draft['status'] as String? ?? 'unsync';
      return _isLocalUnsyncedStatus(status);
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getDraftsByStatus(String status) async {
    final drafts = await readDrafts();
    if (status == 'unsync') {
      return drafts.where((draft) {
        final currentStatus = draft['status'] as String? ?? 'unsync';
        return _isLocalUnsyncedStatus(currentStatus);
      }).toList();
    }
    return drafts.where((draft) => draft['status'] == status).toList();
  }

  Future<Map<String, dynamic>?> getDraftByLocalId(String localId) async {
    final drafts = await readDrafts();
    try {
      return drafts.firstWhere((draft) => draft['localId'] == localId);
    } catch (e) {
      return null;
    }
  }

  Future<PendingDraftSyncResult> syncPendingDrafts() async {
    final drafts = await readDrafts();
    final remainingDrafts = <Map<String, dynamic>>[];
    var syncedCount = 0;
    var failedCount = 0;

    for (final draft in drafts) {
      final status = draft['status'] as String? ?? 'unsync';
      // ✅ Only sync local unsynced records, including legacy drafts
      if (!_isLocalUnsyncedStatus(status)) {
        remainingDrafts.add(draft);
        continue;
      }

      try {
        await MonitoringRecordService.instance.savePendingRecord(
          productionType: draft['productionType'] as String,
          implementationType: draft['implementationType'] as String,
          data: Map<String, dynamic>.from(draft['data'] as Map),
        );
        // ✅ Remove local unsynced draft after successful sync
        syncedCount++;
      } catch (error) {
        failedCount++;
        remainingDrafts.add({
          ...draft,
          'lastSyncError': error.toString(),
          'lastSyncAttemptAt': DateTime.now().toIso8601String(),
        });
      }
    }

    await writeDrafts(remainingDrafts);
    _notifyDraftsUpdated();

    return PendingDraftSyncResult(
      syncedCount: syncedCount,
      failedCount: failedCount,
    );
  }

  Future<void> updateDraft({
    required String localId,
    required Map<String, dynamic> data,
  }) async {
    final drafts = await readDrafts();

    for (var index = 0; index < drafts.length; index++) {
      if (drafts[index]['localId'] == localId) {
        final productionType = drafts[index]['productionType'] as String? ?? '';
        final implementationType =
            drafts[index]['implementationType'] as String? ?? '';
        final normalizedImplementationType =
            implementationType.trim().toLowerCase();

        // CRITICAL: For collectives, always clear farmerName to prevent overwriting
        var updateData = {...data};
        if (normalizedImplementationType == 'collective') {
          updateData = {...updateData, 'farmerName': ''};
        }

        drafts[index] = {
          ...drafts[index],
          'fileName': buildDraftFileName(
            productionType: productionType,
            implementationType: implementationType,
            data: updateData,
          ),
          'data': updateData,
          'updatedLocallyAt': DateTime.now().toIso8601String(),
        };
        await writeDrafts(drafts);
        _notifyDraftsUpdated();
        return;
      }
    }

    throw Exception('Local draft not found.');
  }

  Future<void> syncDraftByLocalId(String localId) async {
    try {
      print('🔍 syncDraftByLocalId: Looking for draft with localId=$localId');
      final drafts = await readDrafts();
      print('   Total drafts in local storage: ${drafts.length}');

      final remainingDrafts = <Map<String, dynamic>>[];
      Map<String, dynamic>? targetDraft;

      for (final draft in drafts) {
        if (draft['localId'] == localId) {
          targetDraft = draft;
          print('   ✅ Found target draft');
        } else {
          remainingDrafts.add(draft);
        }
      }

      // ✅ FALLBACK: If draft not in SharedPreferences, try to load from folder structure
      if (targetDraft == null) {
        print(
            '   ⚠️ Draft not found in SharedPreferences, attempting to load from folders...');
        // localId format: "productionType/groupName" e.g., "crop/holy"
        final parts = localId.split('/');
        if (parts.length == 2) {
          final productionType = parts[0];
          final groupName = parts[1];
          print('   📂 Trying to load from: $productionType/$groupName');

          // Try to load group data from folders
          final groupData =
              await LocalFarmerStorageService.instance.getGroupData(
            productionType: productionType,
            groupName: groupName,
          );

          if (groupData != null) {
            print('   ✅ Loaded group data from folders');

            // ✅ Transform members array to membersByFarmerId map (old group.json format)
            Map<String, dynamic> transformedData =
                Map<String, dynamic>.from(groupData);

            if (groupData['members'] != null && groupData['members'] is List) {
              final membersList =
                  List<dynamic>.from(groupData['members'] as List);
              final membersByFarmerId = <String, dynamic>{};

              for (final member in membersList) {
                if (member is Map<String, dynamic>) {
                  final name = member['name'] as String? ??
                      member['farmerName'] as String? ??
                      '';
                  final saadId = member['saadIdNo'] as String? ??
                      member['saadId'] as String? ??
                      '';
                  final memberId = saadId.isNotEmpty ? saadId : name;

                  if (memberId.isNotEmpty) {
                    membersByFarmerId[memberId] = {
                      'farmerName': name,
                      'name': name,
                      'saadIdNo': saadId,
                    };
                  }
                }
              }

              transformedData['membersByFarmerId'] = membersByFarmerId;
              print(
                  '   📋 Transformed ${membersList.length} members to membersByFarmerId map');

              // ✅ CRITICAL: Load farmer-specific commodities from subfolders
              // This ensures commodities have the correct saadIdNo
              final allFarmerCommodities = <Map<String, dynamic>>[];
              final foundFarmerIds = <String>{};

              for (final saadId in membersByFarmerId.keys) {
                final member =
                    membersByFarmerId[saadId] as Map<String, dynamic>;
                final farmerName = member['farmerName'] as String? ?? '';

                print('   🔍 Attempting to load farmer data:');
                print('      saadId: $saadId');
                print('      farmerName: "$farmerName"');
                print('      groupName: "$groupName"');
                print('      productionType: "$productionType"');

                // Try to get farmer data from folder
                try {
                  final farmerData =
                      await LocalFarmerStorageService.instance.getFarmerData(
                    productionType: productionType,
                    groupName: groupName,
                    farmerName: farmerName,
                    saadId: saadId,
                  );

                  print(
                      '   getFarmerData returned: ${farmerData != null ? "DATA" : "NULL"}');

                  if (farmerData != null) {
                    foundFarmerIds.add(saadId);
                    final farmerCommodities =
                        farmerData['completedCommodities'] as List? ?? [];
                    final farmerTrainings =
                        farmerData['trainings'] as List? ?? [];

                    print(
                        '   📂 Loaded ${farmerCommodities.length} commodities and ${farmerTrainings.length} trainings for farmer: $farmerName ($saadId)');

                    // Update membersByFarmerId with trainings from the farmer's data
                    membersByFarmerId[saadId] = {
                      'farmerName': farmerName,
                      'name': farmerName,
                      'saadIdNo': saadId,
                      'trainings': farmerTrainings,
                    };

                    // Ensure each commodity has the farmer's saadIdNo set
                    for (final commodity in farmerCommodities) {
                      if (commodity is Map<String, dynamic>) {
                        commodity['saadIdNo'] = saadId;
                        commodity['farmerName'] = farmerName;
                        allFarmerCommodities.add(commodity);
                      }
                    }
                  } else {
                    print(
                        '   ⚠️ No data.json found for farmer: $farmerName ($saadId)');
                  }
                } catch (e) {
                  print('   ❌ ERROR loading farmer data: $e');
                  print('      StackTrace: $e');
                }
              }

              // ✅ FALLBACK: If some farmers weren't found, scan directory for all subfolders
              if (foundFarmerIds.length < membersByFarmerId.length) {
                print(
                    '   ⚠️  Some farmers not found. Scanning directory for all farmer folders...');
                try {
                  final allFarmers = await LocalFarmerStorageService.instance
                      .getAllFarmersInGroup(
                    productionType,
                    groupName,
                  );

                  print(
                      '   🔍 Found ${allFarmers.length} farmer folders in directory');

                  for (final farmer in allFarmers) {
                    final farmerSaadId = farmer['saadIdNo'] as String? ?? '';
                    final farmerName = farmer['farmerName'] as String? ?? '';

                    if (farmerSaadId.isNotEmpty &&
                        !foundFarmerIds.contains(farmerSaadId)) {
                      print(
                          '   ✅ Auto-discovered farmer: $farmerName ($farmerSaadId)');

                      // Add to membersByFarmerId if not already there
                      if (!membersByFarmerId.containsKey(farmerSaadId)) {
                        membersByFarmerId[farmerSaadId] = {
                          'farmerName': farmerName,
                          'name': farmerName,
                          'saadIdNo': farmerSaadId,
                          'trainings': farmer['trainings'] ?? [],
                        };
                      }

                      // Add their commodities
                      final farmerCommodities =
                          farmer['commodities'] as List? ?? [];
                      for (final commodity in farmerCommodities) {
                        if (commodity is Map<String, dynamic>) {
                          commodity['saadIdNo'] = farmerSaadId;
                          commodity['farmerName'] = farmerName;
                          allFarmerCommodities.add(commodity);
                        }
                      }
                      foundFarmerIds.add(farmerSaadId);
                    }
                  }
                } catch (e) {
                  print('   ❌ ERROR scanning directory: $e');
                }
              }

              // Replace completedCommodities with farmer-specific ones
              if (allFarmerCommodities.isNotEmpty) {
                transformedData['completedCommodities'] = allFarmerCommodities;
                print(
                    '   ✅ Merged ${allFarmerCommodities.length} farmer-specific commodities');
              }
            }

            targetDraft = {
              'localId': localId,
              'productionType': productionType,
              'implementationType':
                  transformedData['implementationType'] ?? 'collective',
              'data': transformedData,
              'status': 'unsync',
              'source': 'folder',
            };
          } else {
            print('   ❌ No group data found in folders');
          }
        }
      }

      if (targetDraft == null) {
        throw Exception(
            'Local draft not found with localId: $localId (neither in SharedPreferences nor in folders)');
      }

      print('📊 Draft details:');
      print('   productionType: ${targetDraft['productionType']}');
      print('   implementationType: ${targetDraft['implementationType']}');
      final dataMap = targetDraft['data'] is Map
          ? Map<String, dynamic>.from(targetDraft['data'] as Map)
          : <String, dynamic>{};
      print('   fcaName: ${dataMap['fcaName'] ?? 'unknown'}');

      print(' Calling savePendingRecord...');
      await MonitoringRecordService.instance.savePendingRecord(
        productionType: targetDraft['productionType'] as String,
        implementationType: targetDraft['implementationType'] as String,
        data: Map<String, dynamic>.from(targetDraft['data'] as Map),
      );

      print('✅ savePendingRecord succeeded');

      // ✅ After successful sync, remove the local unsynced draft from SharedPreferences.
      // The record now appears in Firebase pending data instead.
      if (targetDraft['source'] != 'folder') {
        await writeDrafts(remainingDrafts);
        print('   Removed draft from local storage');
      }

      _notifyDraftsUpdated();
      print('🎉 Sync completed successfully');
    } catch (e) {
      print('❌ syncDraftByLocalId ERROR: $e');
      print('   Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  void _notifyDraftsUpdated() {
    pendingDraftsUpdated.value = !pendingDraftsUpdated.value;
  }

  List<Map<String, dynamic>> _normalizeListOfMaps(dynamic raw) {
    if (raw is List) {
      return raw
          .map<Map<String, dynamic>>((item) {
            if (item is Map<String, dynamic>) return item;
            if (item is Map) return Map<String, dynamic>.from(item);
            try {
              final rawJson = item.toJson();
              if (rawJson is Map<String, dynamic>) {
                return Map<String, dynamic>.from(rawJson);
              }
            } catch (_) {
              // ignore
            }
            return <String, dynamic>{};
          })
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  Map<String, dynamic>? _resolveMemberDataForFarmer({
    required Map<String, dynamic> data,
    required String farmerName,
    required String saadId,
  }) {
    final membersByFarmerId = data['membersByFarmerId'] as Map? ?? {};
    if (saadId.isNotEmpty && membersByFarmerId.containsKey(saadId)) {
      final memberData = membersByFarmerId[saadId];
      if (memberData is Map) {
        return Map<String, dynamic>.from(memberData);
      }
    }

    for (final entry in membersByFarmerId.entries) {
      final memberData = entry.value;
      if (memberData is! Map) continue;

      final entrySaad = (memberData['saadIdNo'] as String? ??
              memberData['saadId'] as String? ??
              '')
          .trim();
      final entryName = (memberData['farmerName'] as String? ??
              memberData['name'] as String? ??
              '')
          .trim();

      if (entrySaad.isNotEmpty && saadId.isNotEmpty && entrySaad == saadId) {
        return Map<String, dynamic>.from(memberData);
      }
      if (entryName.isNotEmpty &&
          farmerName.isNotEmpty &&
          entryName == farmerName) {
        return Map<String, dynamic>.from(memberData);
      }
    }

    return null;
  }

  Map<String, dynamic> _buildFarmerDataForSave({
    required Map<String, dynamic> data,
    required String farmerName,
    required String saadId,
  }) {
    print('   🔍 Filtering commodities for farmer: $farmerName ($saadId)');

    var filteredCommodities = <Map<String, dynamic>>[];
    var filteredBatches = <Map<String, dynamic>>[];

    final membersByFarmerId = data['membersByFarmerId'] as Map? ?? {};
    final memberData = _resolveMemberDataForFarmer(
      data: data,
      farmerName: farmerName,
      saadId: saadId,
    );

    if (memberData != null) {
      filteredCommodities = List<Map<String, dynamic>>.from(
          memberData['completedCommodities'] as List? ?? []);
      filteredBatches = List<Map<String, dynamic>>.from(
          memberData['completedBatches'] as List? ?? []);
      print(
          '      ✅ Found member-specific data in membersByFarmerId: ${filteredCommodities.length} commodities, ${filteredBatches.length} batches');
    } else {
      print(
          '      ⚠️  No specific member entry found for $farmerName ($saadId), filtering root-level commodities');

      final allCommodities = <Map<String, dynamic>>[];
      if (data['completedCommodities'] is List) {
        allCommodities
            .addAll(_normalizeListOfMaps(data['completedCommodities']));
      } else if (data['completedBatches'] is List) {
        allCommodities.addAll(_normalizeListOfMaps(data['completedBatches']));
      }

      final distinctFarmerIds = <String>{};
      final distinctFarmerNames = <String>{};
      for (final commodity in allCommodities) {
        final commoditySaadId = (commodity['saadIdNo'] as String? ?? '').trim();
        final commodityFarmerName =
            (commodity['farmerName'] as String? ?? '').trim();
        if (commoditySaadId.isNotEmpty) distinctFarmerIds.add(commoditySaadId);
        if (commodityFarmerName.isNotEmpty) {
          distinctFarmerNames.add(commodityFarmerName);
        }
      }

      for (final commodity in allCommodities) {
        final commoditySaadId = (commodity['saadIdNo'] as String? ?? '').trim();
        final commodityFarmerName =
            (commodity['farmerName'] as String? ?? '').trim();
        final matchesSaad = saadId.isNotEmpty && commoditySaadId.isNotEmpty
            ? commoditySaadId == saadId
            : false;
        final matchesName =
            commodityFarmerName.isNotEmpty && commodityFarmerName == farmerName;
        final isUnattributed = commodityFarmerName.isEmpty &&
            commoditySaadId.isEmpty &&
            farmerName.isNotEmpty &&
            distinctFarmerIds.isEmpty &&
            distinctFarmerNames.isEmpty;

        if (matchesSaad || matchesName || isUnattributed) {
          filteredCommodities.add(commodity);
          print(
              '         ✅ INCLUDED root commodity: $commoditySaadId / $commodityFarmerName');
        }
      }

      if (filteredCommodities.isEmpty &&
          allCommodities.isNotEmpty &&
          distinctFarmerIds.length <= 1 &&
          distinctFarmerNames.length <= 1) {
        print(
            '      ℹ️  Root commodities appear to belong to a single farmer, including all ${allCommodities.length} items');
        filteredCommodities.addAll(allCommodities);
      }
    }

    print(
        '      Final commodities for this farmer: ${filteredCommodities.length}');
    print('      Final batches for this farmer: ${filteredBatches.length}');

    String? perFarmerPhoto;
    List<Map<String, dynamic>> perFarmerTrainings = [];
    if (memberData != null) {
      perFarmerPhoto = (memberData['farmPhoto'] as String?)?.trim();
      perFarmerTrainings = _normalizeListOfMaps(memberData['trainings']);
    } else if ((data['membersByFarmerId'] as Map?)?.isEmpty == true) {
      perFarmerTrainings = _normalizeListOfMaps(data['trainings']);
    }

    final farmerData = Map<String, dynamic>.from(data);
    farmerData['farmerName'] = farmerName;
    farmerData['saadId'] = saadId;
    farmerData['saadIdNo'] = saadId;
    farmerData['members'] = [
      {'name': farmerName},
    ];
    farmerData['completedCommodities'] = filteredCommodities;
    farmerData['completedBatches'] = filteredBatches;
    farmerData['farmPhoto'] = perFarmerPhoto?.isNotEmpty == true
        ? perFarmerPhoto!
        : (data['farmPhoto'] as String?)?.trim() ?? '';
    farmerData['trainings'] = perFarmerTrainings.isNotEmpty
        ? perFarmerTrainings
        : <Map<String, dynamic>>[];
    farmerData['savedAt'] = DateTime.now().toIso8601String();
    farmerData.remove('membersByFarmerId');

    return farmerData;
  }

  /// Save individual farmer's data and picture to their folder
  Future<void> saveSingleFarmerData({
    required String productionType,
    required String groupName,
    required String farmerName,
    required String saadId,
    required Map<String, dynamic> data,
  }) async {
    final storageService = LocalFarmerStorageService.instance;

    try {
      // Save group metadata at the group root
      await storageService.saveGroupData(
        productionType: productionType,
        groupName: groupName,
        data: data,
      );
      print('📁 saveSingleFarmerData: saved group metadata for $groupName');

      final farmerData = _buildFarmerDataForSave(
        data: data,
        farmerName: farmerName,
        saadId: saadId,
      );

      // ✅ CRITICAL: Always save farmer data even if empty, to create the folder structure
      await storageService.saveFarmerData(
        productionType: productionType,
        groupName: groupName,
        farmerName: farmerName,
        saadId: saadId,
        data: farmerData,
      );
      print(
          '📁 saveSingleFarmerData: saved farmer data for $farmerName ($saadId)');

      // ✅ CRITICAL: Save picture if available in farmerData
      //      Do not use root data farmPhoto for individuals if member-specific photo exists.
      final photoFromFarmerData =
          (farmerData['farmPhoto'] as String? ?? '').trim();
      if (photoFromFarmerData.isNotEmpty) {
        try {
          final sourceFile = File(photoFromFarmerData);
          if (await sourceFile.exists()) {
            final extension = photoFromFarmerData.split('.').last;
            await storageService.saveFarmerPicture(
              productionType: productionType,
              groupName: groupName,
              farmerName: farmerName,
              saadId: saadId,
              pictureBytes: await sourceFile.readAsBytes(),
              imageExtension: extension,
            );
            print(
                '📷 saveSingleFarmerData: saved farmer picture for $farmerName');
          } else {
            print(
                '⚠️ Warning: farmer photo file does not exist for $farmerName: $photoFromFarmerData');
          }
        } catch (e) {
          print('⚠️ Warning: Could not copy farm photo for $farmerName: $e');
        }
      } else {
        print('   ℹ️ No farmer-specific photo found for $farmerName');
      }
    } catch (e) {
      print('❌ Warning: Could not save individual farmer data: $e');
      rethrow; // Re-throw to see the error in logs
    }
  }

  /// Save each farmer's data to their individual folder within the group
  Future<void> saveFarmerDataFolders({
    required String productionType,
    required String groupName,
    required List<dynamic> members,
    required Map<String, dynamic> data,
  }) async {
    final storageService = LocalFarmerStorageService.instance;

    print('🔍 DEBUG saveFarmerDataFolders:');
    print('   Group: $groupName');
    print('   Members count: ${members.length}');

    // Show all commodities that will be filtered
    final allCommodities = data['completedCommodities'] as List?;
    print('   Total commodities in data: ${allCommodities?.length ?? 0}');
    if (allCommodities != null && allCommodities.isNotEmpty) {
      print('   Commodities details:');
      for (final comm in allCommodities) {
        if (comm is Map) {
          final type = comm['typeOfCrop'] ?? comm['breed'] ?? 'N/A';
          final fname = comm['farmerName'] ?? 'NO_NAME';
          final saad = comm['saadIdNo'] ?? 'NO_SAAD';
          print('      - $type (farmerName: $fname, saadIdNo: $saad)');
        }
      }
    }
    print('   Members data type: ${members.runtimeType}');
    if (members.isNotEmpty) {
      print('   First member structure:');
      final first = members.first;
      if (first is Map) {
        print('      Keys: ${(first).keys.toList()}');
        print('      Full data: $first');
      } else {
        print('      Type: ${first.runtimeType}');
      }
    }

    try {
      await storageService.saveGroupData(
        productionType: productionType,
        groupName: groupName,
        data: data,
      );
      print('✅ Group data saved to local folder');

      final localMembersById = <String, Map<String, dynamic>>{};
      for (final member in members) {
        if (member is Map<String, dynamic>) {
          final name = (member['name'] as String?)?.trim() ??
              (member['farmerName'] as String?)?.trim() ??
              '';
          final saadId = (member['saadIdNo'] as String?)?.trim() ??
              (member['saadId'] as String?)?.trim() ??
              '';
          final memberId = saadId.isNotEmpty ? saadId : name;
          if (memberId.isNotEmpty) {
            localMembersById[memberId] = {
              'name': name,
              'saadIdNo': saadId,
            };
          }
        }
      }

      if (data['membersByFarmerId'] is Map) {
        final groupMap = Map<String, dynamic>.from(
            data['membersByFarmerId'] as Map<String, dynamic>);
        for (final entry in groupMap.entries) {
          final memberId = entry.key.toString().trim();
          if (memberId.isEmpty) {
            continue;
          }
          final farmerData = entry.value is Map
              ? Map<String, dynamic>.from(entry.value as Map)
              : <String, dynamic>{};
          final name = (farmerData['farmerName'] as String?)?.trim() ??
              (farmerData['name'] as String?)?.trim() ??
              '';
          localMembersById.putIfAbsent(
              memberId,
              () => {
                    'name': name,
                    'saadIdNo': memberId,
                  });
        }
      }

      final localMembers = localMembersById.values.toList();
      if (localMembers.isEmpty) {
        print(
            '⚠️  WARNING: Members list is empty! No farmer folders will be created.');
        print(
            '   Did membersByFarmerId exist? ${data['membersByFarmerId'] != null}');
        if (data['membersByFarmerId'] is Map) {
          print(
              '   membersByFarmerId keys: ${(data['membersByFarmerId'] as Map).keys.toList()}');
        }
        return;
      }

      print('   Final localMembers count: ${localMembers.length}');
      for (final member in localMembers) {
        print('   Processing member: $member');
        final farmerName = member['name'] as String? ??
            member['farmerName'] as String? ??
            'Unknown Farmer';
        final saadId = member['saadIdNo'] as String? ??
            member['saadId'] as String? ??
            'NoSAAD';

        print('   -> Saving farmer: $farmerName ($saadId)');
        print(
            '      Calling _buildFarmerDataForSave with: farmerName="$farmerName", saadId="$saadId"');

        final farmerData = _buildFarmerDataForSave(
          data: data,
          farmerName: farmerName,
          saadId: saadId,
        );

        await storageService.saveFarmerData(
          productionType: productionType,
          groupName: groupName,
          farmerName: farmerName,
          saadId: saadId,
          data: farmerData,
        );
        print('   ✅ Farmer data saved');

        final farmPhotoPath = farmerData['farmPhoto'] as String? ?? '';
        if (farmPhotoPath.isNotEmpty) {
          try {
            final sourceFile = File(farmPhotoPath);
            if (await sourceFile.exists()) {
              final extension = farmPhotoPath.split('.').last;
              await storageService.saveFarmerPicture(
                productionType: productionType,
                groupName: groupName,
                farmerName: farmerName,
                saadId: saadId,
                pictureBytes: await sourceFile.readAsBytes(),
                imageExtension: extension,
              );
            }
          } catch (e) {
            print('Warning: Could not copy farm photo for $farmerName: $e');
          }
        }
      }
    } catch (e) {
      print('Warning: Could not save farmer folder structure: $e');
    }
  }

  Future<List<Map<String, dynamic>>> readDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final rawDrafts = prefs.getStringList(_storageKey) ?? <String>[];
    print(
        '📖 readDrafts: Retrieved ${rawDrafts.length} raw draft strings from SharedPreferences');
    for (var i = 0; i < rawDrafts.length; i++) {
      print(
          '   [$i] ${rawDrafts[i].substring(0, (rawDrafts[i].length > 100 ? 100 : rawDrafts[i].length))}...');
    }

    var drafts = rawDrafts
        .map((draft) => jsonDecode(draft) as Map<String, dynamic>)
        .toList();
    print('📖 readDrafts: Decoded ${drafts.length} drafts');
    for (final draft in drafts) {
      print(
          '   - localId: ${draft['localId']}, productionType: ${draft['productionType']}, status: ${draft['status']}');
    }

    // ✅ Deduplication: Remove duplicate group records with identical key fields
    final deduplicated = _deduplicateDrafts(drafts);

    // ✅ If duplicates were found and removed, persist the cleaned list back
    if (deduplicated.length < drafts.length) {
      print(
          '🧹 Cleaning up ${drafts.length - deduplicated.length} duplicate draft(s)');
      final cleanedRawDrafts = deduplicated.map(jsonEncode).toList();
      await prefs.setStringList(_storageKey, cleanedRawDrafts);
    }

    return deduplicated;
  }

  List<Map<String, dynamic>> _deduplicateDrafts(
    List<Map<String, dynamic>> drafts,
  ) {
    final seen = <String>{};
    final deduplicated = <Map<String, dynamic>>[];

    for (final draft in drafts) {
      final productionType =
          (draft['productionType'] as String? ?? '').trim().toLowerCase();
      final implementationType =
          (draft['implementationType'] as String? ?? '').trim().toLowerCase();
      final data = draft['data'] as Map<String, dynamic>? ?? {};
      final fcaName = (data['fcaName'] as String? ?? '').trim().toLowerCase();
      final reportingPeriod =
          (data['reportingPeriod'] as String? ?? '').trim().toLowerCase();
      final projectTitle =
          (data['projectTitle'] as String? ?? '').trim().toLowerCase();
      final farmerName =
          (data['farmerName'] as String? ?? '').trim().toLowerCase();
      final saadId =
          (data['saadIdNo'] as String? ?? data['saadId'] as String? ?? '')
              .trim()
              .toLowerCase();
      final hasGroupMembers =
          ((data['membersByFarmerId'] as Map?)?.isNotEmpty == true) ||
              ((data['members'] as List?)?.isNotEmpty == true);

      // For group records: key is productionType + implementationType + fcaName
      // For individual records: key is productionType + implementationType + farmerName + saadId + reportingPeriod + projectTitle
      final isGroupRecord =
          implementationType == 'collective' || implementationType == 'hybrid';

      final key = isGroupRecord
          ? '$productionType|$fcaName'
          : '$productionType|$implementationType|$farmerName|$saadId|$reportingPeriod|$projectTitle';

      if (!seen.contains(key)) {
        seen.add(key);
        deduplicated.add(draft);
      } else {
        print(
            '🔄 Deduplicating draft: ${draft['fileName']} (duplicate of: $key)');
      }
    }

    return deduplicated;
  }

  Future<void> writeDrafts(List<Map<String, dynamic>> drafts) async {
    // ✅ Deduplicate before writing to prevent duplicate entries
    final deduplicated = _deduplicateDrafts(drafts);
    print('💾 writeDrafts: Starting write process...');
    print('   Deduplicated drafts count: ${deduplicated.length}');

    try {
      final prefs = await SharedPreferences.getInstance();
      print('   ✅ SharedPreferences instance obtained');

      final rawDrafts = deduplicated.map(jsonEncode).toList();
      print(
          '💾 writeDrafts: About to write ${deduplicated.length} drafts to SharedPreferences');
      for (final draft in deduplicated) {
        print(
            '   - localId: ${draft['localId']}, productionType: ${draft['productionType']}, status: ${draft['status']}');
      }

      print('   📝 Encoding JSON for ${rawDrafts.length} drafts...');
      for (var i = 0; i < rawDrafts.length; i++) {
        print('   [$i] ${rawDrafts[i].length} bytes');
      }

      print('   💾 Writing to SharedPreferences with key: $_storageKey');
      await prefs.setStringList(_storageKey, rawDrafts);

      // ✅ CRITICAL: Flush to ensure data is written to disk
      await prefs.commit();
      print('   ✓ Flushed to disk with commit()');

      print(
          '✅ writeDrafts: Successfully wrote ${deduplicated.length} drafts to SharedPreferences');

      // Verify it was actually saved
      final verification = prefs.getStringList(_storageKey) ?? [];
      print('   ✓ Verification: ${verification.length} drafts now in storage');
    } catch (e) {
      print('❌ writeDrafts ERROR: $e');
      print('   Error type: ${e.runtimeType}');
      print('   Stacktrace: ${StackTrace.current}');
      rethrow;
    }
  }

  String buildDraftFileName({
    required String productionType,
    required String implementationType,
    required Map<String, dynamic> data,
  }) {
    final normalizedImplementationType =
        implementationType.trim().toLowerCase();
    final normalizedProductionType = productionType.trim().toLowerCase();

    // For groups/collectives, use FCA name; otherwise use farmer name
    final isGroup = normalizedImplementationType == 'collective' ||
        (normalizedImplementationType == 'hybrid' &&
            (data['fcaName'] as String?)?.trim().isNotEmpty == true);

    final nameRaw = isGroup
        ? (data['fcaName'] as String?)?.trim() ?? ''
        : (data['farmerName'] as String?)?.trim() ?? '';

    final namePart = farmerNamePart(nameRaw);
    final productionPart = sanitizePart(normalizedProductionType).isEmpty
        ? 'production'
        : sanitizePart(normalizedProductionType);
    final implementationPart =
        sanitizePart(normalizedImplementationType).isEmpty
            ? 'implementation'
            : sanitizePart(normalizedImplementationType);

    return '${namePart}_${productionPart}_$implementationPart.json';
  }

  Map<String, dynamic> _mergeGroupDraftData({
    required Map<String, dynamic> existingDraftData,
    required Map<String, dynamic> incomingDraftData,
  }) {
    // ✅ CRITICAL: For group records, DO NOT store commodities at root level
    // This prevents the circular problem where commodities get shared or overwritten
    // Instead: Store ONLY in membersByFarmerId with each farmer's filtered commodities

    final merged = Map<String, dynamic>.from(existingDraftData);

    // Merge members: add new farmers to the group
    merged['members'] = _mergeListOfMaps(
      existing: existingDraftData['members'] as List?,
      incoming: incomingDraftData['members'] as List?,
      uniqueKeys: const ['saadIdNo', 'name'],
    );

    // ✅ FIX: Also merge incoming membersByFarmerId into existing
    // Without this, a new farmer's commodities added via membersByFarmerId are lost
    // because _buildFarmerDataForSave looks up membersByFarmerId by memberId
    final existingMembersByFarmerId =
        existingDraftData['membersByFarmerId'] is Map
            ? Map<String, dynamic>.from(
                existingDraftData['membersByFarmerId'] as Map)
            : <String, dynamic>{};
    if (incomingDraftData['membersByFarmerId'] is Map) {
      final incomingMap = Map<String, dynamic>.from(
          incomingDraftData['membersByFarmerId'] as Map);
      final existingMap = existingMembersByFarmerId;
      for (final entry in incomingMap.entries) {
        final memberId = entry.key;
        final incomingMemberData = entry.value is Map
            ? Map<String, dynamic>.from(entry.value as Map)
            : <String, dynamic>{};
        if (!existingMap.containsKey(memberId)) {
          // New farmer — add them directly, commodities intact
          existingMap[memberId] = incomingMemberData;
        } else {
          // Existing farmer — merge their commodities append-only
          final existingMember = Map<String, dynamic>.from(
              existingMap[memberId] as Map<String, dynamic>);
          final existingComms = List<Map<String, dynamic>>.from(
              existingMember['completedCommodities'] as List? ?? []);
          final incomingComms = List<Map<String, dynamic>>.from(
              incomingMemberData['completedCommodities'] as List? ?? []);
          for (final c in incomingComms) {
            final fp =
                '${c['typeOfCrop']}|${c['variety']}|${c['plantingDate']}';
            final exists = existingComms.any((e) =>
                '${e['typeOfCrop']}|${e['variety']}|${e['plantingDate']}' ==
                fp);
            if (!exists) existingComms.add(c);
          }
          existingMember['completedCommodities'] = existingComms;

          // Trainings append-only
          final existingTrainings = List<Map<String, dynamic>>.from(
              existingMember['trainings'] as List? ?? []);
          final incomingTrainings = List<Map<String, dynamic>>.from(
              incomingMemberData['trainings'] as List? ?? []);
          for (final t in incomingTrainings) {
            final exists = existingTrainings
                .any((old) => jsonEncode(old) == jsonEncode(t));
            if (!exists) existingTrainings.add(t);
          }
          existingMember['trainings'] = existingTrainings;
          existingMap[memberId] = existingMember;
        }
      }
    }

    // Collect ALL commodities for filtering later
    final existingCommodities = <Map<String, dynamic>>[];
    if (existingMembersByFarmerId.isNotEmpty) {
      for (final memberEntry in existingMembersByFarmerId.entries) {
        final memberData = memberEntry.value;
        if (memberData is Map<String, dynamic>) {
          existingCommodities.addAll(
            List<Map<String, dynamic>>.from(
              memberData['completedCommodities'] as List? ?? [],
            ),
          );
        }
      }
    } else {
      existingCommodities.addAll(
        List<Map<String, dynamic>>.from(
          (existingDraftData['completedCommodities'] as List?) ?? [],
        ),
      );
    }

    final incomingCommodities = <Map<String, dynamic>>[];
    final incomingMembersByFarmerId =
        incomingDraftData['membersByFarmerId'] is Map
            ? Map<String, dynamic>.from(
                incomingDraftData['membersByFarmerId'] as Map)
            : <String, dynamic>{};
    if (incomingMembersByFarmerId.isNotEmpty) {
      for (final memberEntry in incomingMembersByFarmerId.entries) {
        final memberData = memberEntry.value;
        if (memberData is Map<String, dynamic>) {
          incomingCommodities.addAll(
            List<Map<String, dynamic>>.from(
              memberData['completedCommodities'] as List? ?? [],
            ),
          );
        }
      }
    } else {
      incomingCommodities.addAll(
        List<Map<String, dynamic>>.from(
          (incomingDraftData['completedCommodities'] as List?) ?? [],
        ),
      );
    }

    // ✅ DEDUPLICATE commodities: same crop/variety/date = duplicate
    final allCommodities = <Map<String, dynamic>>[];
    final seenCommodities = <String>{};
    for (final comm in [...existingCommodities, ...incomingCommodities]) {
      final fp =
          '${comm['typeOfCrop']}|${comm['variety']}|${comm['plantingDate']}';
      if (!seenCommodities.contains(fp)) {
        seenCommodities.add(fp);
        allCommodities.add(comm);
      } else {
        print('   🔄 Skipping duplicate commodity: $fp');
      }
    }

    // Collect ALL batches for filtering later
    final existingBatches = <Map<String, dynamic>>[];
    if (existingMembersByFarmerId.isNotEmpty) {
      for (final memberEntry in existingMembersByFarmerId.entries) {
        final memberData = memberEntry.value;
        if (memberData is Map<String, dynamic>) {
          existingBatches.addAll(
            List<Map<String, dynamic>>.from(
              memberData['completedBatches'] as List? ?? [],
            ),
          );
        }
      }
    } else {
      existingBatches.addAll(
        List<Map<String, dynamic>>.from(
          (existingDraftData['completedBatches'] as List?) ?? [],
        ),
      );
    }

    final incomingBatches = <Map<String, dynamic>>[];
    if (incomingDraftData['membersByFarmerId'] is Map) {
      final incomingMembersByFarmerId = Map<String, dynamic>.from(
          incomingDraftData['membersByFarmerId'] as Map);
      for (final memberEntry in incomingMembersByFarmerId.entries) {
        final memberData = memberEntry.value;
        if (memberData is Map<String, dynamic>) {
          incomingBatches.addAll(
            List<Map<String, dynamic>>.from(
              memberData['completedBatches'] as List? ?? [],
            ),
          );
        }
      }
    } else {
      incomingBatches.addAll(
        List<Map<String, dynamic>>.from(
          (incomingDraftData['completedBatches'] as List?) ?? [],
        ),
      );
    }
    final allBatches = [...existingBatches, ...incomingBatches];

    // ✅ Build membersByFarmerId: each farmer gets ONLY their filtered commodities/batches
    // ✅ CRITICAL: Use the ALREADY-MERGED existingMembersByFarmerId for trainings/photos
    // This preserves trainings from existing farmers when new farmers are added
    final allMembers = merged['members'] as List? ?? [];
    final membersByFarmerId = <String, dynamic>{};

    for (final member in allMembers) {
      if (member is Map<String, dynamic>) {
        final memberName =
            (member['name'] as String? ?? member['farmerName'] as String? ?? '')
                .trim();
        final memberSaadId =
            (member['saadIdNo'] as String? ?? member['saadId'] as String? ?? '')
                .trim();
        final memberId = memberSaadId.isNotEmpty ? memberSaadId : memberName;

        if (memberId.isNotEmpty) {
          // Filter: get ONLY commodities for this farmer
          final farmerCommodities = allCommodities.where((comm) {
            final commName = (comm['farmerName'] as String? ?? '').trim();
            final commSaadId = (comm['saadIdNo'] as String? ?? '').trim();
            return commName == memberName || commSaadId == memberSaadId;
          }).toList();

          // Filter: get ONLY batches for this farmer
          final farmerBatches = allBatches.where((batch) {
            final batchName = (batch['farmerName'] as String? ?? '').trim();
            final batchSaadId = (batch['saadIdNo'] as String? ?? '').trim();
            return batchName == memberName || batchSaadId == memberSaadId;
          }).toList();

          // ✅ CRITICAL: Use ALREADY-MERGED existingMembersByFarmerId, not re-extracted incoming
          // This preserves trainings/photos from existing farmers
          final mergedMemberData =
              existingMembersByFarmerId[memberId] as Map<String, dynamic>?;
          final existingTrainings = mergedMemberData?['trainings'] as List?;
          final existingPhoto =
              (mergedMemberData?['farmPhoto'] as String?)?.trim();

          membersByFarmerId[memberId] = {
            'name': memberName,
            'farmerName': memberName,
            'saadIdNo': memberSaadId,
            'completedCommodities': farmerCommodities,
            'completedBatches': farmerBatches,
            'trainings': (existingTrainings ?? <Map<String, dynamic>>[])
                .map((item) => item is Map<String, dynamic>
                    ? item
                    : Map<String, dynamic>.from(item as Map))
                .toList(),
            'farmPhoto': existingPhoto ?? '',
          };

          print(
              '      → $memberName: ${farmerCommodities.length} commodities, ${farmerBatches.length} batches, ${(existingTrainings?.length ?? 0)} trainings');
        }
      }
    }

    // If this is a collective/group record with no explicit members,
    // treat the whole group as one synthetic member entry.
    if (membersByFarmerId.isEmpty) {
      final groupName = (merged['fcaName'] as String? ?? '').trim();
      if (groupName.isNotEmpty) {
        membersByFarmerId[groupName] = {
          'name': groupName,
          'farmerName': groupName,
          'saadIdNo': '',
          'completedCommodities': allCommodities,
          'completedBatches': allBatches,
        };
        print(
            '   ✅ GROUP (no members): created synthetic group entry for $groupName');
      }
    }

    merged['membersByFarmerId'] = membersByFarmerId;

    final existingImplementationType =
        (existingDraftData['implementationType'] as String?)
                ?.trim()
                .toLowerCase() ??
            '';
    final incomingImplementationType =
        (incomingDraftData['implementationType'] as String?)
                ?.trim()
                .toLowerCase() ??
            '';
    final shouldPreserveRootCommodities =
        existingImplementationType == 'collective' ||
            incomingImplementationType == 'collective';

    if (shouldPreserveRootCommodities) {
      // ✅ COLLECTIVE group records should store all commodity/batch data at root
      // so that the unsynced group record shows the data directly.
      merged['completedCommodities'] = allCommodities;
      merged['completedBatches'] = allBatches;
      print(
          '   ✅ COLLECTIVE GROUP: preserved root commodities/batches for display');
    } else {
      // ✅ HYBRID/other group records should only store group metadata in the root
      // and keep commodity/batch details inside membersByFarmerId.
      merged['completedCommodities'] = [];
      merged['completedBatches'] = [];
      print(
          '   ✅ GROUP: Rebuilt membersByFarmerId with ${membersByFarmerId.keys.length} farmers (root commodities cleared)');
    }

    return merged;
  }

  Map<String, dynamic> _mergeIndividualDraftData({
    required Map<String, dynamic> existingDraftData,
    required Map<String, dynamic> incomingDraftData,
  }) {
    final merged = Map<String, dynamic>.from(existingDraftData)
      ..addAll(incomingDraftData);

    final existingCommodities = <Map<String, dynamic>>[];
    if (existingDraftData['membersByFarmerId'] is Map) {
      final existingMembersByFarmerId = Map<String, dynamic>.from(
          existingDraftData['membersByFarmerId'] as Map);
      for (final memberEntry in existingMembersByFarmerId.entries) {
        final memberData = memberEntry.value;
        if (memberData is Map<String, dynamic>) {
          existingCommodities.addAll(
            List<Map<String, dynamic>>.from(
              memberData['completedCommodities'] as List? ?? [],
            ),
          );
        }
      }
    } else {
      existingCommodities.addAll(
        List<Map<String, dynamic>>.from(
          (existingDraftData['completedCommodities'] as List?) ?? [],
        ),
      );
    }

    final incomingCommodities = <Map<String, dynamic>>[];
    if (incomingDraftData['membersByFarmerId'] is Map) {
      final incomingMembersByFarmerId = Map<String, dynamic>.from(
          incomingDraftData['membersByFarmerId'] as Map);
      for (final memberEntry in incomingMembersByFarmerId.entries) {
        final memberData = memberEntry.value;
        if (memberData is Map<String, dynamic>) {
          incomingCommodities.addAll(
            List<Map<String, dynamic>>.from(
              memberData['completedCommodities'] as List? ?? [],
            ),
          );
        }
      }
    } else {
      incomingCommodities.addAll(
        List<Map<String, dynamic>>.from(
          (incomingDraftData['completedCommodities'] as List?) ?? [],
        ),
      );
    }

    final mergedCommodities = _mergeListOfMaps(
      existing: existingCommodities,
      incoming: incomingCommodities,
      uniqueKeys: const [],
    );

    final existingBatches = <Map<String, dynamic>>[];
    if (existingDraftData['membersByFarmerId'] is Map) {
      final existingMembersByFarmerId = Map<String, dynamic>.from(
          existingDraftData['membersByFarmerId'] as Map);
      for (final memberEntry in existingMembersByFarmerId.entries) {
        final memberData = memberEntry.value;
        if (memberData is Map<String, dynamic>) {
          existingBatches.addAll(
            List<Map<String, dynamic>>.from(
              memberData['completedBatches'] as List? ?? [],
            ),
          );
        }
      }
    } else {
      existingBatches.addAll(
        List<Map<String, dynamic>>.from(
          (existingDraftData['completedBatches'] as List?) ?? [],
        ),
      );
    }

    final incomingBatches = <Map<String, dynamic>>[];
    if (incomingDraftData['membersByFarmerId'] is Map) {
      final incomingMembersByFarmerId = Map<String, dynamic>.from(
          incomingDraftData['membersByFarmerId'] as Map);
      for (final memberEntry in incomingMembersByFarmerId.entries) {
        final memberData = memberEntry.value;
        if (memberData is Map<String, dynamic>) {
          incomingBatches.addAll(
            List<Map<String, dynamic>>.from(
              memberData['completedBatches'] as List? ?? [],
            ),
          );
        }
      }
    } else {
      incomingBatches.addAll(
        List<Map<String, dynamic>>.from(
          (incomingDraftData['completedBatches'] as List?) ?? [],
        ),
      );
    }

    final mergedBatches = _mergeListOfMaps(
      existing: existingBatches,
      incoming: incomingBatches,
      uniqueKeys: const [],
    );

    merged['completedCommodities'] = mergedCommodities;
    merged['completedBatches'] = mergedBatches;

    final farmerName = (merged['farmerName'] as String?)?.trim() ?? '';
    final saadId =
        (merged['saadIdNo'] as String? ?? merged['saadId'] as String? ?? '')
            .trim();
    final memberId = saadId.isNotEmpty ? saadId : farmerName;

    if (memberId.isNotEmpty) {
      merged['membersByFarmerId'] = {
        memberId: {
          'name': farmerName,
          'farmerName': farmerName,
          'saadIdNo': saadId,
          'completedCommodities': mergedCommodities,
          'completedBatches': mergedBatches,
          // ✅ CRITICAL: Include trainings and farmPhoto so _buildFarmerDataForSave can extract them
          'trainings': _normalizeListOfMaps(merged['trainings']),
          'farmPhoto': (merged['farmPhoto'] as String?)?.trim() ?? '',
        }
      };
    }

    return merged;
  }

  Map<String, dynamic> _mergeMapOfMaps({
    Map<String, dynamic>? existing,
    Map<String, dynamic>? incoming,
  }) {
    if (existing == null && incoming == null) return {};
    final merged = <String, dynamic>{};
    if (existing != null) {
      merged.addAll(existing);
    }
    if (incoming != null) {
      for (final entry in incoming.entries) {
        final existingValue = merged[entry.key];
        if (existingValue is Map<String, dynamic> &&
            entry.value is Map<String, dynamic>) {
          merged[entry.key] = {
            ...existingValue,
            ...Map<String, dynamic>.from(entry.value as Map),
          };
        } else {
          merged[entry.key] = entry.value;
        }
      }
    }
    return merged;
  }

  List<Map<String, dynamic>> _mergeListOfMaps({
    List<dynamic>? existing,
    List<dynamic>? incoming,
    required List<String> uniqueKeys,
  }) {
    final merged = <Map<String, dynamic>>[];
    final seen = <String>{};

    List<Map<String, dynamic>> normalize(List<dynamic>? items) {
      if (items == null) return <Map<String, dynamic>>[];
      return items.whereType<Map<String, dynamic>>().toList();
    }

    for (final item in [...normalize(existing), ...normalize(incoming)]) {
      String key;
      if (uniqueKeys.isNotEmpty) {
        final values =
            uniqueKeys.map((k) => (item[k] ?? '').toString().trim()).join('|');
        key = values.isNotEmpty ? values : jsonEncode(item);
      } else {
        key = jsonEncode(item);
      }
      if (!seen.contains(key)) {
        seen.add(key);
        merged.add(item);
      }
    }

    return merged;
  }

  String farmerNamePart(String farmerName) {
    if (farmerName.isEmpty) return 'unknown_farmer';
    final chunks = farmerName
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();
    if (chunks.isEmpty) return 'unknown_farmer';
    if (chunks.length == 1) return sanitizePart(chunks.first);

    final firstName = sanitizePart(chunks.first);
    final lastName = sanitizePart(chunks.last);
    if (firstName.isEmpty && lastName.isEmpty) return 'unknown_farmer';
    if (lastName.isEmpty) return firstName;
    if (firstName.isEmpty) return lastName;
    return '${firstName}_$lastName';
  }

  String sanitizePart(String value) {
    final lower = value.trim().toLowerCase();
    if (lower.isEmpty) return '';

    final cleaned = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return cleaned.replaceAll(RegExp(r'^_+|_+$'), '');
  }
}
