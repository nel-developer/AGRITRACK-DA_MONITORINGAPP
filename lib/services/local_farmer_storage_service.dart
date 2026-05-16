import 'dart:io';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class LocalFarmerStorageService {
  LocalFarmerStorageService._();

  static final LocalFarmerStorageService instance =
      LocalFarmerStorageService._();

  /// Get the base monitoring records directory
  Future<Directory> _getMonitoringDirectory() async {
    Directory baseDir;

    if (Platform.isAndroid) {
      baseDir = await _getAndroidVisibleStorageDirectory();
      await _cleanupAndroidHiddenDirectory(baseDir);
    } else {
      baseDir = await getApplicationDocumentsDirectory();
    }

    final monitoringDir = Directory('${baseDir.path}/monitoring_records');

    if (!await monitoringDir.exists()) {
      await monitoringDir.create(recursive: true);
    }
    print(
        '📁 LocalFarmerStorageService: monitoring directory = ${monitoringDir.path}');

    return monitoringDir;
  }

  Future<Directory> _getAndroidVisibleStorageDirectory() async {
    Directory? appExternalDir;

    try {
      // Use platform channel to get the correct Android external files dir
      const platform = MethodChannel('com.example.da_monitoring_app/storage');
      final String result = await platform.invokeMethod('getExternalFilesDir');
      appExternalDir = Directory(result);
    } catch (e) {
      print('⚠️ Platform channel failed: $e, falling back to app docs');
      appExternalDir = await getApplicationDocumentsDirectory();
    }

    if (!await appExternalDir.exists()) {
      await appExternalDir.create(recursive: true);
    }

    print(
        '📁 LocalFarmerStorageService: using Android app storage directory = ${appExternalDir.path}');
    return appExternalDir;
  }

  Future<void> _cleanupAndroidHiddenDirectory(Directory visibleDir) async {
    try {
      final hiddenDir = await getExternalStorageDirectory();
      if (hiddenDir == null) return;

      final visiblePath = visibleDir.path;
      final hiddenPath = hiddenDir.path;
      if (visiblePath == hiddenPath) return;

      final hiddenDirectory = Directory(hiddenPath);
      if (await hiddenDirectory.exists()) {
        print(
            '🧹 LocalFarmerStorageService: deleting old hidden Android directory = $hiddenPath');
        await hiddenDirectory.delete(recursive: true);
        print('🧹 LocalFarmerStorageService: old hidden Android data cleared');
      }
    } catch (error) {
      print(
          '⚠️ LocalFarmerStorageService: failed to clean hidden Android directory: $error');
    }
  }

  String _buildGroupFolderName(
    String groupName,
  ) {
    final sanitizedGroupName =
        groupName.trim().isNotEmpty ? groupName : 'unknown_group';
    return sanitizedGroupName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
  }

  String _buildProductionTypeFolderName(String productionType) {
    return productionType.trim().isNotEmpty
        ? productionType
            .trim()
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        : 'unknown_production';
  }

  /// Get the group folder path under the production type root
  Future<Directory> _getGroupDirectory(String groupName,
      {required String productionType,
      String? reportingPeriod,
      String? projectTitle}) async {
    final baseDir = await _getMonitoringDirectory();
    final productionDir = Directory(
        '${baseDir.path}/${_buildProductionTypeFolderName(productionType)}');
    if (!await productionDir.exists()) {
      await productionDir.create(recursive: true);
    }

    final sanitizedGroupName = _buildGroupFolderName(groupName);
    final groupDir = Directory('${productionDir.path}/$sanitizedGroupName');

    if (!await groupDir.exists()) {
      await groupDir.create(recursive: true);
    }
    print('📁 LocalFarmerStorageService: group directory = ${groupDir.path}');

    return groupDir;
  }

  /// Get the farmer folder path
  /// Folder name format: "SAADID" (fallback to unknown_farmer if empty)
  /// Also checks for legacy format: "FARMERNAME_SAADID"
  Future<Directory> _getFarmerDirectory(
      String groupName, String farmerName, String saadId,
      {required String productionType,
      String? reportingPeriod,
      String? projectTitle}) async {
    final groupDir = await _getGroupDirectory(
      groupName,
      productionType: productionType,
      reportingPeriod: reportingPeriod,
      projectTitle: projectTitle,
    );

    final sanitizedSaadId = saadId.trim().isNotEmpty
        ? saadId.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        : '';
    final sanitizedFarmerName = farmerName.trim().isNotEmpty
        ? farmerName
            .trim()
            .replaceAll(RegExp(r'\s+'), '_') // Replace spaces with underscore
            .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_') // Remove special chars
        : '';

    print('📁 _getFarmerDirectory DEBUG:');
    print('   Original: farmerName="$farmerName", saadId="$saadId"');
    print(
        '   Sanitized: farmerName="$sanitizedFarmerName", saadId="$sanitizedSaadId"');

    // Try new format first: just saadId
    var farmerDir = Directory('${groupDir.path}/$sanitizedSaadId');
    print('   Checking format 1 (saadId): ${farmerDir.path}');
    print('      Exists: ${await farmerDir.exists()}');

    // If not found, try legacy format: farmerName_saadId
    if (!await farmerDir.exists() &&
        sanitizedSaadId.isNotEmpty &&
        sanitizedFarmerName.isNotEmpty) {
      farmerDir =
          Directory('${groupDir.path}/${sanitizedFarmerName}_$sanitizedSaadId');
      print('   Checking format 2 (farmerName_saadId): ${farmerDir.path}');
      print('      Exists: ${await farmerDir.exists()}');
    }

    // If still not found, try just farmerName
    if (!await farmerDir.exists() && sanitizedFarmerName.isNotEmpty) {
      farmerDir = Directory('${groupDir.path}/$sanitizedFarmerName');
      print('   Checking format 3 (farmerName only): ${farmerDir.path}');
      print('      Exists: ${await farmerDir.exists()}');
    }

    // If none exist, list what's actually in the group directory
    if (!await farmerDir.exists()) {
      print('   ❌ No matching folder found. Group directory contents:');
      try {
        final contents = groupDir.listSync();
        for (final item in contents) {
          if (item is Directory) {
            final name = item.path.split('/').last;
            print('      📁 $name');
          }
        }
      } catch (e) {
        print('      Could not list group directory: $e');
      }

      // Create using saadId format as fallback
      final folderName = sanitizedSaadId.isNotEmpty
          ? sanitizedSaadId
          : (sanitizedFarmerName.isNotEmpty
              ? sanitizedFarmerName
              : 'unknown_farmer');
      farmerDir = Directory('${groupDir.path}/$folderName');
      print('   Creating new folder: ${farmerDir.path}');
      await farmerDir.create(recursive: true);
    }

    if (!await farmerDir.exists()) {
      await farmerDir.create(recursive: true);
    }
    print('📁 LocalFarmerStorageService: farmer directory = ${farmerDir.path}');

    return farmerDir;
  }

  /// Save farmer data (JSON)
  /// Returns the path where data was saved
  Future<String> saveFarmerData({
    required String productionType,
    required String groupName,
    required String farmerName,
    required String saadId,
    required Map<String, dynamic> data,
  }) async {
    final farmerDir = await _getFarmerDirectory(
      groupName,
      farmerName,
      saadId,
      productionType: productionType,
      reportingPeriod: data['reportingPeriod'] as String?,
      projectTitle: data['projectTitle'] as String?,
    );
    final dataFile = File('${farmerDir.path}/data.json');

    await dataFile.writeAsString(jsonEncode(data));
    print(
        '📁 LocalFarmerStorageService: wrote farmer data.json to ${dataFile.path}');

    return dataFile.path;
  }

  /// Save farmer picture
  /// pictureBytes: raw image bytes
  /// imageExtension: 'jpg', 'png', etc (without the dot)
  /// Returns the path where picture was saved
  Future<String> saveFarmerPicture({
    required String productionType,
    required String groupName,
    required String farmerName,
    required String saadId,
    required List<int> pictureBytes,
    String imageExtension = 'jpg',
  }) async {
    final farmerDir = await _getFarmerDirectory(
      groupName,
      farmerName,
      saadId,
      productionType: productionType,
    );
    final pictureFile = File('${farmerDir.path}/picture.$imageExtension');

    await pictureFile.writeAsBytes(pictureBytes);

    return pictureFile.path;
  }

  /// Get farmer data
  Future<Map<String, dynamic>?> getFarmerData({
    required String productionType,
    required String groupName,
    required String farmerName,
    required String saadId,
  }) async {
    print('🔍 getFarmerData called:');
    print('   productionType: $productionType');
    print('   groupName: $groupName');
    print('   farmerName: $farmerName');
    print('   saadId: $saadId');

    final groupDir = await _getGroupDirectory(
      groupName,
      productionType: productionType,
    );

    final sanitizedSaadId = saadId.trim().isNotEmpty
        ? saadId.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        : '';
    final sanitizedFarmerName = farmerName.trim().isNotEmpty
        ? farmerName
            .trim()
            .replaceAll(RegExp(r'\s+'), '_') // Replace spaces with underscore
            .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_') // Remove special chars
        : '';

    // Try multiple folder formats and check which one has data.json
    List<String> folderFormatsToTry = [];

    if (sanitizedSaadId.isNotEmpty) {
      folderFormatsToTry.add(sanitizedSaadId);
    }

    if (sanitizedSaadId.isNotEmpty && sanitizedFarmerName.isNotEmpty) {
      folderFormatsToTry.add('${sanitizedFarmerName}_$sanitizedSaadId');
    }

    if (sanitizedFarmerName.isNotEmpty) {
      folderFormatsToTry.add(sanitizedFarmerName);
    }

    // Try each format and return the one that has data.json
    for (final folderName in folderFormatsToTry) {
      final farmerDir = Directory('${groupDir.path}/$folderName');
      final dataFile = File('${farmerDir.path}/data.json');

      print('   Trying: $folderName');
      print('      Path: ${farmerDir.path}');
      print('      data.json exists: ${await dataFile.exists()}');

      if (await dataFile.exists()) {
        print('   ✅ Found data.json in format: $folderName');
        final content = await dataFile.readAsString();
        print('   ✅ data.json read successfully (${content.length} bytes)');
        return jsonDecode(content) as Map<String, dynamic>;
      }
    }

    print('   ❌ data.json NOT FOUND in any format');
    return null;
  }

  /// Get all farmers in a group
  Future<List<Map<String, dynamic>>> getAllFarmersInGroup(
    String productionType,
    String groupName,
  ) async {
    final groupDir = await _getGroupDirectory(
      groupName,
      productionType: productionType,
    );
    final farmers = <Map<String, dynamic>>[];

    final contents = groupDir.listSync();
    for (final entity in contents) {
      if (entity is Directory) {
        final folderName = entity.path.split(Platform.pathSeparator).last;
        var saadId = folderName;
        if (folderName.contains('_')) {
          saadId = folderName.split('_').last;
        }

        final dataFile = File('${entity.path}/data.json');
        Map<String, dynamic>? data;

        if (await dataFile.exists()) {
          final content = await dataFile.readAsString();
          data = jsonDecode(content) as Map<String, dynamic>;
        }

        File? pictureFile;
        for (final ext in ['jpg', 'jpeg', 'png', 'gif']) {
          final file = File('${entity.path}/picture.$ext');
          if (await file.exists()) {
            pictureFile = file;
            break;
          }
        }

        farmers.add({
          'farmerName':
              data != null ? (data['farmerName'] as String? ?? '') : '',
          'saadId': saadId,
          'folderPath': entity.path,
          'data': data,
          'picturePath': pictureFile?.path,
        });
      }
    }

    return farmers;
  }

  /// Delete farmer folder and all contents
  Future<void> deleteFarmer({
    required String productionType,
    required String groupName,
    required String farmerName,
    required String saadId,
  }) async {
    final farmerDir = await _getFarmerDirectory(
      groupName,
      farmerName,
      saadId,
      productionType: productionType,
    );

    if (await farmerDir.exists()) {
      await farmerDir.delete(recursive: true);
    }
  }

  /// Delete entire group folder and all farmers
  Future<void> deleteGroup(String productionType, String groupName) async {
    final groupDir = await _getGroupDirectory(
      groupName,
      productionType: productionType,
    );

    if (await groupDir.exists()) {
      await groupDir.delete(recursive: true);
    }
  }

  /// Delete a group record (alias for deleteGroup)
  Future<void> deleteGroupRecord({
    required String productionType,
    required String groupName,
  }) async {
    await deleteGroup(productionType, groupName);
  }

  /// Get group folder path (for browsing/debugging)
  Future<String> getGroupFolderPath(
      String productionType, String groupName) async {
    final groupDir = await _getGroupDirectory(
      groupName,
      productionType: productionType,
    );
    return groupDir.path;
  }

  /// Save group metadata file inside the group folder
  /// Only keep group-level fields to avoid storing farmer-specific records
  Future<String> saveGroupData({
    required String productionType,
    required String groupName,
    required Map<String, dynamic> data,
  }) async {
    print(
        '💾 ⭐ saveGroupData CALLED: productionType=$productionType, groupName=$groupName, members.length=${(data['members'] as List?)?.length ?? 0}');
    final groupDir = await _getGroupDirectory(
      groupName,
      productionType: productionType,
    );
    final groupDataFile = File('${groupDir.path}/group.json');

    final allowedGroupKeys = <String>{
      'implementationType',
      'isAddFarmer',
      'reportingPeriod',
      'fcaName',
      'region',
      'province',
      'municipality',
      'barangay',
      'projectTitle',
      'primaryIntervention',
      'primaryInterventionOther',
      'supportInterventions',
      'purposeBreeding',
      'purposeMeat',
      'purposeDairy',
      'members',
      'trainings',
      'completedCommodities',
      'completedBatches',
      'farmPhoto',
    };

    final sanitizedMembers = (data['members'] as List<dynamic>?)?.map((member) {
          if (member is Map<String, dynamic>) {
            final memberName = (member['name'] as String?)?.trim() ??
                (member['farmerName'] as String?)?.trim() ??
                '';
            return {'name': memberName};
          }
          return member;
        }).where((member) {
          if (member is Map<String, dynamic>) {
            return (member['name'] as String?)?.isNotEmpty ?? false;
          }
          return true;
        }).toList() ??
        [];

    // ✅ CRITICAL FIX: For hybrid/group implementations, merge members instead of replacing
    // This ensures all farmers are preserved when saveGroupData is called multiple times
    print('   🔄 ⭐ STARTING MEMBER MERGE LOGIC');
    Map<String, dynamic> existingGroupData = {};

    if (await groupDataFile.exists()) {
      try {
        final existingContent = await groupDataFile.readAsString();
        existingGroupData = jsonDecode(existingContent) as Map<String, dynamic>;
        final memberCount =
            (existingGroupData['members'] as List?)?.length ?? 0;
        print('   📖 ⭐ Found existing group.json with members: $memberCount');
      } catch (e) {
        print('⚠️ ⭐ Could not read existing group.json: $e, will overwrite');
      }
    } else {
      print('   📝 ⭐ group.json not found, creating new');
    }

    // Merge members: keep existing members and add new ones (avoid duplicates)
    final existingMembers =
        (existingGroupData['members'] as List<dynamic>?)?.toList() ?? [];
    final sanitizedCount = sanitizedMembers.length;
    print(
        '   🔄 ⭐ MERGE: existingMembers=${existingMembers.length}, sanitized=$sanitizedCount');

    final allMembers = <Map<String, dynamic>>[];
    final seenNames = <String>{};

    // Add existing members
    for (final member in existingMembers) {
      if (member is Map<String, dynamic>) {
        final name = (member['name'] as String?)?.trim() ?? '';
        if (name.isNotEmpty && !seenNames.contains(name)) {
          allMembers.add(member);
          seenNames.add(name);
          print('      ✅ ⭐ EXISTING: added "$name"');
        }
      }
    }

    // Add new members from current data
    for (final member in sanitizedMembers) {
      if (member is Map<String, dynamic>) {
        final name = (member['name'] as String?)?.trim() ?? '';
        if (name.isNotEmpty && !seenNames.contains(name)) {
          allMembers.add(member);
          seenNames.add(name);
          print('      ✅ ⭐ NEW: added "$name"');
        } else if (name.isNotEmpty) {
          print('      ⏭️ ⭐ DUPLICATE: skipped "$name"');
        }
      }
    }
    print('   🔄 ⭐ MERGE RESULT: final allMembers=${allMembers.length}');

    // ✅ CRITICAL: Preserve ALL existing fields from file, merge with new data
    final groupData = Map<String, dynamic>.from(existingGroupData);

    // Update with new data, but only for allowed keys
    for (final entry in data.entries) {
      if (allowedGroupKeys.contains(entry.key)) {
        if (entry.key == 'members') {
          groupData['members'] = allMembers;
          print('   ✅ ⭐ SET: members = ${allMembers.length} items');
        } else {
          groupData[entry.key] = entry.value;
          if (entry.key == 'implementationType') {
            print('   ✅ ⭐ SET: implementationType = ${entry.value}');
          }
        }
      }
    }

    groupData['savedAt'] = DateTime.now().toIso8601String();

    await groupDataFile.writeAsString(jsonEncode(groupData));
    print(
        '📁 ⭐ LocalFarmerStorageService: WROTE group.json to ${groupDataFile.path} with ${allMembers.length} members');
    return groupDataFile.path;
  }

  /// Get saved group metadata
  Future<Map<String, dynamic>?> getGroupData({
    required String productionType,
    required String groupName,
  }) async {
    final groupDir = await _getGroupDirectory(
      groupName,
      productionType: productionType,
    );

    // Read group.json
    var groupDataFile = File('${groupDir.path}/group.json');

    if (!await groupDataFile.exists()) {
      return null;
    }

    final content = await groupDataFile.readAsString();
    return jsonDecode(content) as Map<String, dynamic>;
  }

  /// Get farmer folder path (for browsing/debugging)
  Future<String> getFarmerFolderPath(
    String productionType,
    String groupName,
    String farmerName,
    String saadId,
  ) async {
    final farmerDir = await _getFarmerDirectory(
      groupName,
      farmerName,
      saadId,
      productionType: productionType,
    );
    return farmerDir.path;
  }

  /// Get all groups across all production types
  Future<List<String>> getAllGroups() async {
    final baseDir = await _getMonitoringDirectory();
    final groups = <String>[];

    final contents = baseDir.listSync();
    for (final entity in contents) {
      if (entity is Directory) {
        final productionTypeDir = entity;
        for (final child in productionTypeDir.listSync()) {
          if (child is Directory) {
            final groupName = child.path.split(Platform.pathSeparator).last;
            groups.add(groupName);
          }
        }
      }
    }

    return groups;
  }

  /// Read all unsync records from local farmer folders
  /// Returns list of records with structure:
  /// {
  ///   'productionType': 'crop|livestock|poultry',
  ///   'groupName': 'group_name',
  ///   'farmerName': 'farmer_name',
  ///   'saadId': 'saad_id',
  ///   'data': {...farmer data from data.json}
  /// }
  Future<List<Map<String, dynamic>>> getAllUnsyncRecords() async {
    final records = <Map<String, dynamic>>[];
    final baseDir = await _getMonitoringDirectory();

    // Iterate through all production types (crop, livestock, poultry)
    final contents = baseDir.listSync();

    for (final productionEntity in contents) {
      if (productionEntity is! Directory) continue;

      final productionType =
          productionEntity.path.split(Platform.pathSeparator).last;

      // Iterate through all groups
      final groupContents = productionEntity.listSync();

      for (final groupEntity in groupContents) {
        if (groupEntity is! Directory) continue;

        final groupName = groupEntity.path.split(Platform.pathSeparator).last;

        // Check if this is a COLLECTIVE (group.json at root, no farmer subfolders)
        final groupJsonFile = File('${groupEntity.path}/group.json');
        final groupJsonExists = await groupJsonFile.exists();

        // Iterate through contents to detect type
        final groupContentsForDetection = groupEntity.listSync();
        var hasOnlyGroupJson = true;
        var farmerSubfolderCount = 0;

        for (final item in groupContentsForDetection) {
          if (item is Directory) {
            farmerSubfolderCount++;
            hasOnlyGroupJson = false;
          } else if (item is File &&
              !item.path.endsWith('group.json') &&
              !item.path.endsWith('.jpg')) {
            hasOnlyGroupJson = false;
          }
        }

        final isCollective =
            groupJsonExists && hasOnlyGroupJson && farmerSubfolderCount == 0;

        if (isCollective && groupJsonExists) {
          // COLLECTIVE: Load data from group.json directly
          try {
            final content = await groupJsonFile.readAsString();
            final data = jsonDecode(content) as Map<String, dynamic>;

            records.add({
              'productionType': productionType,
              'groupName': groupName,
              'farmerName': groupName,
              'saadId': groupName,
              'implType': 'collective',
              'data': data,
            });
          } catch (e) {
            print('❌ Failed to read collective from $groupName: $e');
          }
        } else {
          // INDIVIDUAL/HYBRID: Both now use farmer subfolders
          // Load group.json for project background
          Map<String, dynamic>? groupData;
          if (groupJsonExists) {
            try {
              final content = await groupJsonFile.readAsString();
              groupData = jsonDecode(content) as Map<String, dynamic>;
            } catch (e) {
              print('❌ Failed to read group.json: $e');
            }
          }

          // Count farmer subfolders for detection
          final farmerCount = groupContentsForDetection
              .whereType<Directory>()
              .where((dir) => File('${dir.path}/data.json').existsSync())
              .length;

          // Load from farmer subfolders (works for both individual and hybrid)
          for (final farmerEntity in groupContentsForDetection) {
            if (farmerEntity is! Directory) continue;

            final farmerFolder =
                farmerEntity.path.split(Platform.pathSeparator).last;
            final dataFile = File('${farmerEntity.path}/data.json');

            if (await dataFile.exists()) {
              try {
                final content = await dataFile.readAsString();
                final data = jsonDecode(content) as Map<String, dynamic>;

                // Extract farmer info
                final farmerName = (data['name'] as String? ??
                        data['farmerName'] as String? ??
                        '')
                    .trim();
                final saadId = (data['saadIdNo'] as String? ?? '').trim();

                // ✅ INDIVIDUAL has 1 farmer, HYBRID has multiple
                final implType = farmerCount == 1 ? 'individual' : 'hybrid';

                // MERGE group background + farmer data
                final mergedData = {
                  ...?groupData,
                  ...data,
                };

                records.add({
                  'productionType': productionType,
                  'groupName': groupName,
                  'farmerName': farmerName.isEmpty ? farmerFolder : farmerName,
                  'saadId': saadId.isEmpty ? farmerFolder : saadId,
                  'implType': implType,
                  'data': mergedData,
                });
              } catch (e) {
                print(
                    '❌ Failed to read record from $groupName/$farmerFolder: $e');
              }
            }
          }
        }
      }
    }

    return records;
  }

  /// Delete a record by group name and production type
  Future<void> deleteRecord(String productionType, String groupName) async {
    try {
      final baseDir = await _getMonitoringDirectory();
      final productionDir = Directory(
          '${baseDir.path}/${_buildProductionTypeFolderName(productionType)}');
      final groupDir = Directory('${productionDir.path}/$groupName');

      if (await groupDir.exists()) {
        print('🗑️ Deleting folder: ${groupDir.path}');
        await groupDir.delete(recursive: true);
        print('✅ Deleted folder: $groupName from $productionType');
      } else {
        print('⚠️ Folder not found: ${groupDir.path}');
      }
    } catch (e) {
      print('❌ Error deleting record: $e');
      rethrow;
    }
  }

  /// Delete a specific farmer record within a group
  Future<void> deleteFarmerRecord(
      String productionType, String groupName, String farmerFolderName) async {
    try {
      final baseDir = await _getMonitoringDirectory();
      final productionDir = Directory(
          '${baseDir.path}/${_buildProductionTypeFolderName(productionType)}');
      final groupDir = Directory('${productionDir.path}/$groupName');
      final farmerDir = Directory('${groupDir.path}/$farmerFolderName');

      if (await farmerDir.exists()) {
        print('🗑️ Deleting farmer folder: ${farmerDir.path}');
        await farmerDir.delete(recursive: true);
        print('✅ Deleted farmer: $farmerFolderName from $groupName');
      } else {
        print('⚠️ Farmer folder not found: ${farmerDir.path}');
      }
    } catch (e) {
      print('❌ Error deleting farmer record: $e');
      rethrow;
    }
  }

  /// Get all commodities for a farmer from data.json
  /// Returns list of commodity maps
  Future<List<Map<String, dynamic>>> getFarmerCommodities({
    required String productionType,
    required String groupName,
    required String farmerName,
    required String saadId,
  }) async {
    final data = await getFarmerData(
      productionType: productionType,
      groupName: groupName,
      farmerName: farmerName,
      saadId: saadId,
    );

    if (data == null) return [];

    final commodities =
        (data['completedCommodities'] as List?)?.cast<Map<String, dynamic>>() ??
            [];
    return commodities;
  }

  /// Get all trainings for a farmer from data.json
  /// Returns list of training maps
  Future<List<Map<String, dynamic>>> getFarmerTrainings({
    required String productionType,
    required String groupName,
    required String farmerName,
    required String saadId,
  }) async {
    final data = await getFarmerData(
      productionType: productionType,
      groupName: groupName,
      farmerName: farmerName,
      saadId: saadId,
    );

    if (data == null) return [];

    final trainings =
        (data['trainings'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return trainings;
  }

  /// Append a new commodity to farmer's data.json
  /// Merges with existing commodities without overwriting
  /// Also saves commodity picture if provided
  Future<void> appendCommodityToFarmer({
    required String productionType,
    required String groupName,
    required String farmerName,
    required String saadId,
    required Map<String, dynamic> newCommodity,
    Map<String, dynamic>? farmerMeta,
    List<int>? commodityPictureBytes,
    String commodityImageExtension = 'jpg',
  }) async {
    final farmerDir = await _getFarmerDirectory(
      groupName,
      farmerName,
      saadId,
      productionType: productionType,
    );
    final dataFile = File('${farmerDir.path}/data.json');

    // Load existing data
    Map<String, dynamic> data = {};
    if (await dataFile.exists()) {
      final content = await dataFile.readAsString();
      data = jsonDecode(content) as Map<String, dynamic>;
    }

    // Get existing commodities list
    final commoditiesList =
        (data['completedCommodities'] as List?) ?? <Map<String, dynamic>>[];
    final existingCommodities =
        commoditiesList.cast<Map<String, dynamic>>().toList();

    // Append new commodity
    existingCommodities.add(newCommodity);

    // Update data with merged commodities
    data['completedCommodities'] = existingCommodities;

    // Merge farmerMeta if provided (trainings, etc)
    if (farmerMeta != null) {
      for (final entry in farmerMeta.entries) {
        if (entry.key == 'trainings' && entry.value is List) {
          // Merge trainings without duplicates
          final existingTrainings =
              (data['trainings'] as List?) ?? <Map<String, dynamic>>[];
          final newTrainings =
              (entry.value as List).cast<Map<String, dynamic>>();

          final mergedTrainings = <Map<String, dynamic>>[
            ...existingTrainings.cast<Map<String, dynamic>>(),
          ];

          for (final newTraining in newTrainings) {
            final exists = mergedTrainings
                .any((old) => jsonEncode(old) == jsonEncode(newTraining));
            if (!exists) {
              mergedTrainings.add(newTraining);
            }
          }

          data['trainings'] = mergedTrainings;
        } else {
          data[entry.key] = entry.value;
        }
      }
    }

    // Save updated data.json
    await dataFile.writeAsString(jsonEncode(data));
    print(
        '📝 LocalFarmerStorageService: appended commodity to ${dataFile.path}');

    // Save commodity picture if provided
    if (commodityPictureBytes != null && commodityPictureBytes.isNotEmpty) {
      final variety = (newCommodity['variety'] as String? ?? '').trim();

      // Get GPS coordinates from photoGPS if available
      final photoGPS = newCommodity['photoGPS'] as Map<String, dynamic>? ?? {};
      final latitude = photoGPS['latitude'];
      final longitude = photoGPS['longitude'];

      // Format filename: crops_{variety}_{latitude}_{longitude}.jpg
      String pictureName;
      if (variety.isNotEmpty && latitude != null && longitude != null) {
        // Format coordinates: remove decimal point and limit precision
        final latStr = latitude.toString().replaceAll('.', '_');
        final lonStr = longitude.toString().replaceAll('.', '_');
        pictureName =
            'crops_${variety}_${latStr}_$lonStr.$commodityImageExtension';
      } else if (variety.isNotEmpty) {
        pictureName = 'crops_$variety.$commodityImageExtension';
      } else {
        pictureName = 'commodity.$commodityImageExtension';
      }

      final pictureFile = File('${farmerDir.path}/$pictureName');

      await pictureFile.writeAsBytes(commodityPictureBytes);
      print(
          '📸 LocalFarmerStorageService: saved commodity picture to ${pictureFile.path}');
    }
  }
}
