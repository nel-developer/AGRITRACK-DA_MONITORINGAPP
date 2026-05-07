import 'dart:io';
import 'dart:convert';

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
    final appExternalDir = await getExternalStorageDirectory();
    if (appExternalDir == null) {
      throw Exception('Unable to resolve Android external storage directory.');
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
        ? farmerName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        : '';

    final folderName = sanitizedSaadId.isNotEmpty
        ? sanitizedSaadId
        : (sanitizedFarmerName.isNotEmpty
            ? sanitizedFarmerName
            : 'unknown_farmer');

    final farmerDir = Directory('${groupDir.path}/$folderName');

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
    final farmerDir = await _getFarmerDirectory(
      groupName,
      farmerName,
      saadId,
      productionType: productionType,
    );
    final dataFile = File('${farmerDir.path}/data.json');

    if (!await dataFile.exists()) {
      return null;
    }

    final content = await dataFile.readAsString();
    return jsonDecode(content) as Map<String, dynamic>;
  }

  /// Get farmer picture
  Future<File?> getFarmerPicture({
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

    // Check for common image formats
    for (final extension in ['jpg', 'jpeg', 'png', 'gif']) {
      final pictureFile = File('${farmerDir.path}/picture.$extension');
      if (await pictureFile.exists()) {
        return pictureFile;
      }
    }

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
    final groupDir = await _getGroupDirectory(
      groupName,
      productionType: productionType,
    );
    final groupDataFile = File('${groupDir.path}/group_data.json');

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

    final groupData = {
      for (final entry in data.entries)
        if (allowedGroupKeys.contains(entry.key))
          entry.key: entry.key == 'members' ? sanitizedMembers : entry.value,
      'savedAt': DateTime.now().toIso8601String(),
    };

    await groupDataFile.writeAsString(jsonEncode(groupData));
    print(
        '📁 LocalFarmerStorageService: wrote group_data.json to ${groupDataFile.path}');
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
    final groupDataFile = File('${groupDir.path}/group_data.json');

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

        // Iterate through all farmers in this group
        final farmerContents = groupEntity.listSync();
        for (final farmerEntity in farmerContents) {
          if (farmerEntity is! Directory) continue;

          final farmerFolder =
              farmerEntity.path.split(Platform.pathSeparator).last;
          final dataFile = File('${farmerEntity.path}/data.json');

          if (await dataFile.exists()) {
            try {
              final content = await dataFile.readAsString();
              final data = jsonDecode(content) as Map<String, dynamic>;

              // Extract farmer info from data
              final farmerName = (data['farmerName'] as String? ?? '').trim();
              final saadId = (data['saadIdNo'] as String? ?? '').trim();

              records.add({
                'productionType': productionType,
                'groupName': groupName,
                'farmerName': farmerName.isEmpty ? farmerFolder : farmerName,
                'saadId': saadId.isEmpty ? farmerFolder : saadId,
                'data': data,
              });
            } catch (e) {
              print('⚠️ Failed to read unsync record from $farmerFolder: $e');
            }
          }
        }
      }
    }

    return records;
  }
}
