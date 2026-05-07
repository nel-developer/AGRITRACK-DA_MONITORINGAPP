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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
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

    // CRITICAL: Detect group-like drafts even for individual UI flow.
    // This fixes add-farmer behavior where the record still contains a members map.
    final isGroupRecord = normalizedImplementationType == 'collective' ||
        normalizedImplementationType == 'hybrid' ||
        hasGroupMembers;
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
          draftImplementationType == 'hybrid' ||
          draftHasGroupMembers;
      final dataHasGroupMembers =
          ((data['membersByFarmerId'] as Map?)?.isNotEmpty == true) ||
              ((data['members'] as List?)?.isNotEmpty == true);
      final dataIsGroup = normalizedImplementationType == 'collective' ||
          normalizedImplementationType == 'hybrid' ||
          dataHasGroupMembers;
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

      final sameSaad = draftSaadId.isNotEmpty &&
          dataSaadId.isNotEmpty &&
          draftSaadId == dataSaadId;
      final sameFarmerName = draftFarmerName.isNotEmpty &&
          dataFarmerName.isNotEmpty &&
          draftFarmerName == dataFarmerName;

      if (sameSaad || sameFarmerName) {
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
          existingImplementationType == 'hybrid' ||
          existingHasGroupMembers;
      final incomingIsGroup = isGroupRecord;
      final shouldTreatAsGroup = existingIsGroup || incomingIsGroup;

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
      await writeDrafts(drafts);
      _notifyDraftsUpdated();

      // For collectives and hybrid group records, save each farmer's data to their own folder
      final shouldSaveAsGroupRecord = shouldTreatAsGroup ||
          resolvedImplementationType == 'collective' ||
          resolvedImplementationType == 'hybrid';

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
        // For individual, save farmer's own data to folder
        print(
            '👤 INDIVIDUAL RECORD - About to save folder for ${mergedData['farmerName']}');
        await saveSingleFarmerData(
          productionType: normalizedProductionType,
          groupName: mergedData['fcaName'] as String? ?? 'Unknown Group',
          farmerName: mergedData['farmerName'] as String? ?? 'Unknown Farmer',
          saadId: mergedData['saadIdNo'] as String? ?? 'NoSAAD',
          data: mergedData,
        );
      }
    } else {
      // Create new draft
      print('❌ NO existing draft found - creating NEW draft');
      print('   This might overwrite old data if FCA/period/project match!');
      print(
          '   Searched for: $normalizedProductionType / $normalizedImplementationType / ${data['fcaName']}');
      localId = DateTime.now().microsecondsSinceEpoch.toString();
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
      await writeDrafts(drafts);
      _notifyDraftsUpdated();

      // For collectives and hybrid group records, save each farmer's data to their own folder
      if (isGroupRecord) {
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
        // For individual, save farmer's own data to folder
        print(
            '👤 NEW INDIVIDUAL RECORD - About to save folder for ${data['farmerName']}');
        await saveSingleFarmerData(
          productionType: normalizedProductionType,
          groupName: data['fcaName'] as String? ?? 'Unknown Group',
          farmerName: data['farmerName'] as String? ?? 'Unknown Farmer',
          saadId: data['saadIdNo'] as String? ?? 'NoSAAD',
          data: data,
        );
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
        return;
      }
    }

    throw Exception('Local draft not found.');
  }

  Future<void> syncDraftByLocalId(String localId) async {
    final drafts = await readDrafts();
    final remainingDrafts = <Map<String, dynamic>>[];
    Map<String, dynamic>? targetDraft;

    for (final draft in drafts) {
      if (draft['localId'] == localId) {
        targetDraft = draft;
      } else {
        remainingDrafts.add(draft);
      }
    }

    if (targetDraft == null) {
      throw Exception('Local draft not found.');
    }

    await MonitoringRecordService.instance.savePendingRecord(
      productionType: targetDraft['productionType'] as String,
      implementationType: targetDraft['implementationType'] as String,
      data: Map<String, dynamic>.from(targetDraft['data'] as Map),
    );

    // ✅ After successful sync, remove the local unsynced draft.
    // The record now appears in Firebase pending data instead.
    await writeDrafts(remainingDrafts);
    _notifyDraftsUpdated();
  }

  void _notifyDraftsUpdated() {
    pendingDraftsUpdated.value = !pendingDraftsUpdated.value;
  }

  Map<String, dynamic> _buildFarmerDataForSave({
    required Map<String, dynamic> data,
    required String farmerName,
    required String saadId,
  }) {
    print('   🔍 Filtering commodities for farmer: $farmerName ($saadId)');

    // ✅ CRITICAL: First try to get pre-filtered commodities from membersByFarmerId
    // This is more reliable than filtering ourselves
    var filteredCommodities = <Map<String, dynamic>>[];
    var filteredBatches = <Map<String, dynamic>>[];

    final membersByFarmerId = data['membersByFarmerId'] as Map? ?? {};
    final memberId = saadId.isNotEmpty ? saadId : farmerName;

    if (membersByFarmerId.containsKey(memberId)) {
      final memberData = membersByFarmerId[memberId] as Map<String, dynamic>?;
      if (memberData != null) {
        filteredCommodities = List<Map<String, dynamic>>.from(
            memberData['completedCommodities'] as List? ?? []);
        filteredBatches = List<Map<String, dynamic>>.from(
            memberData['completedBatches'] as List? ?? []);
        print(
            '      ✅ Found in membersByFarmerId: ${filteredCommodities.length} commodities, ${filteredBatches.length} batches');
      }
    } else {
      // Fallback: filter from root-level if membersByFarmerId not available
      print(
          '      ⚠️  membersByFarmerId not found for $memberId, filtering from root');

      final isCommodities = data['completedCommodities'] is List;
      final isBatches = data['completedBatches'] is List;
      final allCommodities = isCommodities
          ? List<Map<String, dynamic>>.from(data['completedCommodities'])
          : isBatches
              ? List<Map<String, dynamic>>.from(data['completedBatches'])
              : <Map<String, dynamic>>[];

      print('      Total commodities available: ${allCommodities.length}');

      for (final commodity in allCommodities) {
        final commoditySaadId = (commodity['saadIdNo'] as String? ?? '').trim();
        final commodityFarmerName =
            (commodity['farmerName'] as String? ?? '').trim();
        final matchesSaad = saadId.isNotEmpty && commoditySaadId.isNotEmpty
            ? commoditySaadId == saadId
            : false;
        final matchesName =
            commodityFarmerName.isNotEmpty && commodityFarmerName == farmerName;

        if (matchesSaad || matchesName) {
          print('         ✅ INCLUDED: $commoditySaadId / $commodityFarmerName');
          filteredCommodities.add(commodity);
        }
      }
    }

    print(
        '      Final commodities for this farmer: ${filteredCommodities.length}');
    print('      Final batches for this farmer: ${filteredBatches.length}');

    final farmerData = Map<String, dynamic>.from(data);
    farmerData['farmerName'] = farmerName;
    farmerData['saadId'] = saadId;
    farmerData['saadIdNo'] = saadId;
    farmerData['members'] = [
      {'name': farmerName},
    ];
    farmerData['completedCommodities'] = filteredCommodities;
    farmerData['completedBatches'] = filteredBatches;
    farmerData['savedAt'] = DateTime.now().toIso8601String();
    // ✅ Clear membersByFarmerId from individual farmer's saved data (they don't need it)
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

      await storageService.saveFarmerData(
        productionType: productionType,
        groupName: groupName,
        farmerName: farmerName,
        saadId: saadId,
        data: farmerData,
      );
      print(
          '📁 saveSingleFarmerData: saved farmer data for $farmerName ($saadId)');

      final farmPhotoPath = data['farmPhoto'] as String? ?? '';
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
    } catch (e) {
      print('Warning: Could not save individual farmer data: $e');
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

      var localMembers = members;
      if (localMembers.isEmpty && data['membersByFarmerId'] is Map) {
        final groupMap = Map<String, dynamic>.from(
            data['membersByFarmerId'] as Map<String, dynamic>);
        localMembers = groupMap.entries.map((entry) {
          final farmerData =
              Map<String, dynamic>.from(entry.value as Map<String, dynamic>);
          final name = (farmerData['farmerName'] as String?)?.trim() ?? '';
          final saadId = entry.key.toString().trim();
          return {
            'name': name,
            'saadIdNo': saadId,
          };
        }).where((member) {
          final name = (member['name'])?.trim() ?? '';
          final saadId = (member['saadIdNo'])?.trim() ?? '';
          return name.isNotEmpty || saadId.isNotEmpty;
        }).toList();
        print(
            'ℹ️  Fallback members generated from membersByFarmerId: $localMembers');
      }

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
        if (member is Map<String, dynamic>) {
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

          final farmPhotoPath = data['farmPhoto'] as String? ?? '';
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
      }
    } catch (e) {
      print('Warning: Could not save farmer folder structure: $e');
    }
  }

  Future<List<Map<String, dynamic>>> readDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final rawDrafts = prefs.getStringList(_storageKey) ?? <String>[];

    var drafts = rawDrafts
        .map((draft) => jsonDecode(draft) as Map<String, dynamic>)
        .toList();

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
      final isGroupRecord = implementationType == 'collective' ||
          implementationType == 'hybrid' ||
          hasGroupMembers;

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
    final prefs = await SharedPreferences.getInstance();
    final rawDrafts = deduplicated.map(jsonEncode).toList();
    await prefs.setStringList(_storageKey, rawDrafts);
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

    // Collect ALL commodities for filtering later
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
    final allCommodities = [...existingCommodities, ...incomingCommodities];

    // Collect ALL batches for filtering later
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
    final allBatches = [...existingBatches, ...incomingBatches];

    // ✅ Build membersByFarmerId: each farmer gets ONLY their filtered commodities/batches
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

          membersByFarmerId[memberId] = {
            'name': memberName,
            'farmerName': memberName,
            'saadIdNo': memberSaadId,
            'completedCommodities': farmerCommodities,
            'completedBatches': farmerBatches,
          };

          print(
              '      → $memberName: ${farmerCommodities.length} commodities, ${farmerBatches.length} batches');
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
