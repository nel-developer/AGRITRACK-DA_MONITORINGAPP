import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import '../../theme/da_colors.dart';
import '../../widgets/crop_form_shell.dart';
import '../../services/pending_draft_service.dart';
import '../../services/photo_capture_location_service.dart';
import 'livestock_step_wrapper.dart';

class LivestockStep7Trainings extends StatefulWidget {
  const LivestockStep7Trainings({super.key, required this.wrapper});
  final LivestockStepWrapper wrapper;

  @override
  State<LivestockStep7Trainings> createState() => _LivestockStep7State();
}

class _LivestockStep7State extends State<LivestockStep7Trainings> {
  LivestockStepWrapper get w => widget.wrapper;

  final List<TrainingEntry> _trainings = [TrainingEntry()];
  String _photoPath = '';
  double? _photoLatitude;
  double? _photoLongitude;
  double? _photoAccuracy;
  bool _isCapturingPhoto = false;
  bool _didSaveDraft = false;
  bool _submitRequested = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Load trainings from wrapper only if they contain actual data
    if (w.trainings.isNotEmpty) {
      // Check if any training has actual data (name, date, or attendees)
      bool hasActualData = w.trainings.any((training) =>
          training.name.trim().isNotEmpty ||
          training.date.trim().isNotEmpty ||
          training.attendees.trim().isNotEmpty);

      // Only load if there's actual data, otherwise start fresh
      if (hasActualData) {
        _trainings.clear();
        _trainings.addAll(w.trainings);
      } else {
        // w.trainings is empty or contains only empty entries
        // Keep _trainings as [TrainingEntry()] for fresh form
        _trainings.clear();
        _trainings.add(TrainingEntry());
      }
    } else {
      // w.trainings is empty, initialize _trainings with one empty entry
      _trainings.clear();
      _trainings.add(TrainingEntry());
    }
  }

  @override
  void dispose() {
    if (!_didSaveDraft && _photoPath.isNotEmpty) {
      _deletePhotoSilently(_photoPath);
    }
    super.dispose();
  }

  Future<void> _deletePhotoSilently(String path) async {
    if (path.isEmpty) return;
    try {
      await File(path).delete();
    } catch (_) {}
  }

  Future<void> _onSubmit() async {
    if (_isSaving) return;

    if (!_canSaveDraft()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please complete at least one training entry before submit.',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }

    if (_photoPath.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Farm photo is required before submit.',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }

    _isSaving = true;
    _submitRequested = true;
    await _save();
    _isSaving = false;
  }

  bool _canSaveDraft() {
    bool hasAnyEntry = false;
    bool hasCompleteEntry = false;

    for (final training in _trainings) {
      final name = training.name.trim();
      final date = training.date.trim();
      final attendees = training.attendees.trim();

      final hasAnyValue =
          name.isNotEmpty || date.isNotEmpty || attendees.isNotEmpty;
      if (!hasAnyValue) continue;

      hasAnyEntry = true;
      final isComplete =
          name.isNotEmpty && date.isNotEmpty && attendees.isNotEmpty;
      if (!isComplete) return false;

      hasCompleteEntry = true;
    }

    return !hasAnyEntry || hasCompleteEntry;
  }

  Future<void> _save() async {
    if (!_submitRequested) return;

    w.trainings = List<TrainingEntry>.from(_trainings);
    w.farmPhoto = _photoPath;

    // Persist current batch data before saving
    _persistCurrentLivestockBatch();

    // Save locally first. Firebase is only used during manual sync.
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: DAColors.greenMid),
                SizedBox(height: 16),
                Text('Saving offline...', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ),
      );
    }

    try {
      var jsonData = w.toJson();

      // ✅ CRITICAL: For collective records, clear all member-related fields
      if (w.implementationType?.toLowerCase() == 'collective') {
        jsonData['members'] = [];
        jsonData['saadIdNo'] = '';
        jsonData['farmerName'] = '';
        jsonData['membersByFarmerId'] = {};
        print('✅ COLLECTIVE: Cleared all member-related fields');
      }

      // ✅ CRITICAL: Build membersByFarmerId map for ALL record types
      // (both group and individual with single farmer)
      final members = jsonData['members'] as List? ?? [];
      final batches = jsonData['completedBatches'] as List? ?? [];
      final farmerName = (jsonData['farmerName'] as String? ?? '').trim();
      final saadIdNo = (jsonData['saadIdNo'] as String? ?? '').trim();

      Map<String, dynamic> membersByFarmerId = {};

      // Case 1: Group record with multiple farmers
      if (members.isNotEmpty) {
        for (final member in members) {
          if (member is Map<String, dynamic>) {
            final memberName = (member['name'] as String? ??
                    member['farmerName'] as String? ??
                    '')
                .trim();
            final memberSaadId = (member['saadIdNo'] as String? ?? '').trim();
            final memberId =
                memberSaadId.isNotEmpty ? memberSaadId : memberName;

            if (memberId.isNotEmpty) {
              // Filter batches for this farmer
              final farmerBatches = batches.where((batch) {
                if (batch is! Map<String, dynamic>) return false;
                final batchName = (batch['farmerName'] as String? ?? '').trim();
                final batchSaadId = (batch['saadIdNo'] as String? ?? '').trim();
                return batchName == memberName || batchSaadId == memberSaadId;
              }).toList();

              membersByFarmerId[memberId] = {
                'name': memberName,
                'farmerName': memberName,
                'saadIdNo': memberSaadId,
                'completedBatches': farmerBatches,
              };
            }
          }
        }
        print(
            '✅ Built membersByFarmerId for group: ${membersByFarmerId.keys.toList()}');
      }
      // Case 2: Collective record with no farmers, store data directly at root level
      else if (w.implementationType?.toLowerCase() == 'collective' &&
          batches.isNotEmpty) {
        // For collective records, load existing group_data.json, append batches, merge trainings
        try {
          // Get external storage directory
          Directory? appDocDir;
          try {
            const platform =
                MethodChannel('com.example.da_monitoring_app/storage');
            final String result =
                await platform.invokeMethod('getExternalFilesDir');
            appDocDir = Directory(result);
          } catch (e) {
            appDocDir = await getApplicationDocumentsDirectory();
          }

          final sanitizedGroup =
              _sanitizeFolderName(w.fcaName.isNotEmpty ? w.fcaName : 'default');
          final groupDir = Directory(
              '${appDocDir.path}/monitoring_records/livestock/$sanitizedGroup');

          // Load existing group_data.json if it exists
          Map<String, dynamic> existingGroupData = {};
          final groupDataFile = File('${groupDir.path}/group_data.json');

          if (await groupDataFile.exists()) {
            try {
              final content = await groupDataFile.readAsString();
              existingGroupData = jsonDecode(content) as Map<String, dynamic>;
              print(
                  '✅ Loaded existing group_data.json for collective batch merge');
            } catch (e) {
              print(
                  '⚠️ Could not read existing group_data.json: $e, starting fresh');
              existingGroupData = {};
            }
          }

          // Get existing batches and preserve them
          final existingBatches =
              (existingGroupData['completedBatches'] as List?)
                      ?.cast<Map<String, dynamic>>() ??
                  [];

          // Append new batch(es) to existing batches
          final newBatches = (jsonData['completedBatches'] as List?)
                  ?.cast<Map<String, dynamic>>() ??
              [];
          existingBatches.addAll(newBatches);

          // Get existing trainings and merge with new ones
          final existingTrainings = (existingGroupData['trainings'] as List?)
                  ?.cast<Map<String, dynamic>>() ??
              [];
          final newTrainings =
              w.trainings.map((item) => item.toJson()).toList();
          existingTrainings.addAll(newTrainings);

          // Update jsonData with merged data
          jsonData['completedBatches'] = existingBatches;
          jsonData['trainings'] = existingTrainings;

          print(
              '✅ Merged collective batches: ${existingBatches.length} total, trainings: ${existingTrainings.length}');
        } catch (e) {
          print(
              '⚠️ Warning: Could not merge collective batch data: $e, will store only current batch');
          // Fallback: just store current batch without merging
          jsonData['completedBatches'] = batches;
          jsonData['trainings'] =
              w.trainings.map((item) => item.toJson()).toList();
        }
      }
      // Case 3: Individual record with single farmer
      // ✅ CRITICAL: Include individual farmers even if they have NO batches yet
      // In-progress individuals must still sync to preserve their data
      else if (farmerName.isNotEmpty) {
        final memberId = saadIdNo.isNotEmpty ? saadIdNo : farmerName;
        membersByFarmerId[memberId] = {
          'name': farmerName,
          'farmerName': farmerName,
          'saadIdNo': saadIdNo,
          'completedBatches': batches,
          'trainings':
              w.trainings, // ✅ Individual farmers have their own trainings
        };
        print('✅ Built membersByFarmerId for individual: $memberId');
      }

      if (membersByFarmerId.isNotEmpty) {
        jsonData['membersByFarmerId'] = membersByFarmerId;
        // Only clear root level batches for non-collective records
        if (w.implementationType?.toLowerCase() != 'collective') {
          jsonData['completedBatches'] = [];
        }
      }

      print('🔥 Livestock - About to save:');
      print('   implementationType: ${w.implementationType}');
      print('   members: ${jsonData['members']}');
      print(
          '   membersByFarmerId: ${(jsonData['membersByFarmerId'] as Map?)?.keys.toList()}');
      print('   farmerName: ${jsonData['farmerName']}');
      print('   fcaName: ${jsonData['fcaName']}');

      // ✅ CRITICAL: For COLLECTIVE records, save directly to group.json (matches crop format)
      if (w.implementationType?.toLowerCase() == 'collective') {
        try {
          // Get external storage directory
          Directory? appDocDir;
          try {
            const platform =
                MethodChannel('com.example.da_monitoring_app/storage');
            final String result =
                await platform.invokeMethod('getExternalFilesDir');
            appDocDir = Directory(result);
          } catch (e) {
            appDocDir = await getApplicationDocumentsDirectory();
          }

          final sanitizedGroup =
              _sanitizeFolderName(w.fcaName.isNotEmpty ? w.fcaName : 'default');
          final groupDir = Directory(
              '${appDocDir.path}/monitoring_records/livestock/$sanitizedGroup');

          // Ensure group folder exists
          if (!await groupDir.exists()) {
            await groupDir.create(recursive: true);
          }

          // ✅ Use group.json (NOT group_data.json) to match crop format
          final groupJsonFile = File('${groupDir.path}/group.json');
          Map<String, dynamic> groupData = {};

          // Load existing group.json if it exists
          if (await groupJsonFile.exists()) {
            try {
              final content = await groupJsonFile.readAsString();
              groupData = jsonDecode(content) as Map<String, dynamic>;
              print('✅ Loaded existing group.json for collective merge');
            } catch (e) {
              print('⚠️ Could not read existing group.json: $e');
              groupData = {};
            }
          }

          // Get existing batches and preserve them
          final existingBatches = (groupData['completedBatches'] as List?)
                  ?.cast<Map<String, dynamic>>() ??
              [];

          // Append only NEW batches (not ones already in file)
          final newBatches = (jsonData['completedBatches'] as List?)
                  ?.cast<Map<String, dynamic>>() ??
              [];

          // ✅ Only append batches that aren't already in the file
          for (final newBatch in newBatches) {
            // Check if this batch already exists (by comparing photoGPS as unique identifier)
            final photoGPS = newBatch['photoGPS'];
            final alreadyExists = existingBatches.any((existing) {
              final existingGPS = existing['photoGPS'];
              return photoGPS != null &&
                  existingGPS != null &&
                  photoGPS['latitude'] == existingGPS['latitude'] &&
                  photoGPS['longitude'] == existingGPS['longitude'] &&
                  photoGPS['accuracy'] == existingGPS['accuracy'];
            });

            if (!alreadyExists) {
              existingBatches.add(newBatch);
              print('✅ Added new batch: ${newBatch['breed']}');
            } else {
              print('⏭️ Skipped duplicate batch: ${newBatch['breed']}');
            }
          }

          // Merge trainings arrays - only add NEW trainings
          final existingTrainings =
              (groupData['trainings'] as List?)?.cast<Map<String, dynamic>>() ??
                  [];
          final newTrainings =
              (jsonData['trainings'] as List?)?.cast<Map<String, dynamic>>() ??
                  [];

          // ✅ Only append trainings that aren't already in the file
          for (final newTraining in newTrainings) {
            final trainingName = newTraining['name'];
            final trainingDate = newTraining['date'];
            final alreadyExists = existingTrainings.any((existing) {
              return existing['name'] == trainingName &&
                  existing['date'] == trainingDate;
            });

            if (!alreadyExists) {
              existingTrainings.add(newTraining);
              print('✅ Added new training: $trainingName on $trainingDate');
            } else {
              print(
                  '⏭️ Skipped duplicate training: $trainingName on $trainingDate');
            }
          }

          // Update group data with merged batches and trainings
          groupData['implementationType'] = jsonData['implementationType'];
          groupData['reportingPeriod'] = jsonData['reportingPeriod'];
          groupData['fcaName'] = w.fcaName;
          groupData['region'] = jsonData['region'];
          groupData['province'] = jsonData['province'];
          groupData['municipality'] = jsonData['municipality'];
          groupData['barangay'] = jsonData['barangay'];
          groupData['projectTitle'] = jsonData['projectTitle'];
          groupData['primaryIntervention'] = jsonData['primaryIntervention'];
          groupData['supportInterventions'] = jsonData['supportInterventions'];
          groupData['members'] = [];
          groupData['completedBatches'] = existingBatches;
          groupData['trainings'] = existingTrainings;

          // Write merged data back to same file (NO new folder)
          await groupJsonFile.writeAsString(jsonEncode(groupData));
          print(
              '✅ COLLECTIVE: Merged to group.json - ${existingBatches.length} batches, ${existingTrainings.length} trainings');
          _didSaveDraft = true;
        } catch (e) {
          print('❌ ERROR saving collective: $e');
          rethrow;
        }
      } else {
        // ✅ For INDIVIDUAL/HYBRID records, use folder-based structure (like crops)
        await _saveLivestockRecordByFolders(jsonData, 'livestock');
        _didSaveDraft = true;
      }

      // ✅ CRITICAL: Save photo locally with GPS metadata
      if (_photoPath.isNotEmpty) {
        try {
          await _saveLivestockPhotoLocally();
        } catch (e) {
          print('⚠️ Photo save error (non-blocking): $e');
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saved locally as unsync.',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor: DAColors.greenMid,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save locally: $e',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Map<String, dynamic> _persistCurrentLivestockBatch() {
    if (w.breed == null || w.breed!.trim().isEmpty) return {};

    final batch = {
      'breed': w.breed,
      'inputsReceived': w.inputsReceived.map((item) => item.toJson()).toList(),
      'inputsPurchased':
          w.inputsPurchased.map((item) => item.toJson()).toList(),
      'farmgatePrices': w.farmgatePrices,
      'stocksReceived': w.stocksReceived,
      'dateReceived': w.dateReceived,
      'maleStocks': w.maleStocks,
      'femaleStocks': w.femaleStocks,
      'maleToFemaleRatio': w.maleToFemaleRatio,
      'ageUponReceipt': w.ageUponReceipt,
      'avgWeightUponReceipt': w.avgWeightUponReceipt,
      'pregnantStocks': w.pregnantStocks,
      'housingType': w.housingType,
      'farmOwnership': w.farmOwnership,
      'farmOwnershipOther': w.farmOwnershipOther,
      'usufruct': w.usufruct,
      'usufructRemarks': w.usufructRemarks,
      'healthActivities': w.healthActivities,
      'healthOthers': w.healthOthers,
      'wasteManagement': w.wasteManagement,
      'growOutPeriod': w.growOutPeriod,
      'lactationPeriod': w.lactationPeriod,
      'dryPeriod': w.dryPeriod,
      'producedOffspring': w.producedOffspring,
      'offspringMale': w.offspringMale,
      'offspringFemale': w.offspringFemale,
      'offspringMFRatio': w.offspringMFRatio,
      'mortalitiesAfterBirth': w.mortalitiesAfterBirth,
      'remainingOffspring': w.remainingOffspring,
      'grazingArea': w.grazingArea,
      'feeds': w.feeds,
      'waterSources': w.waterSources,
      'soldAsLiveweight': w.soldAsLiveweight,
      'soldAsLiveweightRemarks': w.soldAsLiveweightRemarks,
      'avgMarketableWeight': w.avgMarketableWeight,
      'milkVolumeDaily': w.milkVolumeDaily,
      'farmgatePriceMilk': w.farmgatePriceMilk,
      'milkUnit': w.milkUnit,
      'slaughteredCount': w.slaughteredCount,
      'slaughteredPrice': w.slaughteredPrice,
      'postharvest': w.postharvest,
      'postharvestRemarks': w.postharvestRemarks,
      'processing': w.processing,
      'processingRemarks': w.processingRemarks,
      'hasPest': w.hasPest,
      'pestOccurrence': w.pestOccurrence,
      'pestDate': w.pestDate,
      'pestMortality': w.pestMortality,
      'pestTreatment': w.pestTreatment,
      'pestAttached': w.pestAttached,
      'hasDisease': w.hasDisease,
      'diseaseOccurrence': w.diseaseOccurrence,
      'diseaseDate': w.diseaseDate,
      'diseaseMortality': w.diseaseMortality,
      'diseaseTreatment': w.diseaseTreatment,
      'diseaseAttached': w.diseaseAttached,
      'hasEnvHazard': w.hasEnvHazard,
      'envOccurrence': w.envOccurrence,
      'envDate': w.envDate,
      'envMortality': w.envMortality,
      'envTreatment': w.envTreatment,
      'envAttached': w.envAttached,
      'hasHumanInduced': w.hasHumanInduced,
      'humanOccurrence': w.humanOccurrence,
      'humanDate': w.humanDate,
      'humanMortality': w.humanMortality,
      'humanRemainingStocks': w.humanRemainingStocks,
      'humanTreatment': w.humanTreatment,
      'humanAttached': w.humanAttached,
      // ── Step 07: Trainings Attended ──
      'trainings': w.trainings.map((t) => t.toJson()).toList(),
      'farmPhoto': w.farmPhoto,
      // ✅ Add GPS coordinates to batch data (like crops do)
      if (_photoLatitude != null && _photoLongitude != null)
        'photoGPS': {
          'latitude': _photoLatitude!,
          'longitude': _photoLongitude!,
          'accuracy': _photoAccuracy ?? 0.0,
        },
    };

    final currentFarmerName = w.farmerName.trim();
    final currentSaadId = w.saadIdNo.trim();
    final hasCurrentFarmer =
        currentFarmerName.isNotEmpty || currentSaadId.isNotEmpty;

    // ✅ CRITICAL: Handle collective records differently - store batches directly
    final candidates = <Map<String, dynamic>>[];
    if (w.implementationType?.toLowerCase() == 'collective') {
      // For collective records, store batch directly without farmer info
      candidates.add(batch);
    } else if (hasCurrentFarmer) {
      // For individual/hybrid records, add farmer info
      candidates.add({
        ...batch,
        'farmerName': currentFarmerName,
        'saadIdNo':
            currentSaadId.isNotEmpty ? currentSaadId : currentFarmerName,
      });
    }
    // NOTE: Removed the "else if (w.members.isNotEmpty)" branch
    // Each farmer adds their own batches, not batches for all group members

    for (final candidate in candidates) {
      final candidateJson = jsonEncode(candidate);
      final exists = w.completedBatches.any(
        (item) => jsonEncode(item) == candidateJson,
      );
      if (!exists) {
        w.completedBatches.add(candidate);
      }
    }

    // ✅ Return the batch for use in folder-based save
    return batch;
  }

  /// Save livestock photo locally with GPS metadata
  /// COLLECTIVE: Single group folder with photos
  /// INDIVIDUAL/HYBRID: Group folder + farmer subfolders with photos
  Future<void> _saveLivestockPhotoLocally() async {
    if (_photoPath.isEmpty) return;

    try {
      final sourceFile = File(_photoPath);
      if (!await sourceFile.exists()) return;

      // Get external storage directory
      Directory? appDocDir;
      try {
        const platform = MethodChannel('com.example.da_monitoring_app/storage');
        final String result =
            await platform.invokeMethod('getExternalFilesDir');
        appDocDir = Directory(result);
      } catch (e) {
        appDocDir = await getApplicationDocumentsDirectory();
      }

      final implementationType =
          w.implementationType?.toLowerCase() ?? 'collective';
      final isCollective = implementationType == 'collective';
      final sanitizedGroup =
          _sanitizeFolderName(w.fcaName.isNotEmpty ? w.fcaName : 'default');

      // Determine photo directory based on record type
      Directory photoDir;
      if (isCollective) {
        // COLLECTIVE: Photo directly in group folder
        photoDir = Directory(
            '${appDocDir.path}/monitoring_records/livestock/$sanitizedGroup');
      } else {
        // INDIVIDUAL/HYBRID: Photo in farmer subfolder (with SAAD ID)
        final sanitizedFarmer = _sanitizeFolderName(
            w.farmerName.isNotEmpty ? w.farmerName : 'farmer');
        final sanitizedSaadId =
            w.saadIdNo.isEmpty ? '' : '_${_sanitizeFolderName(w.saadIdNo)}';
        final farmerFolderName = '$sanitizedFarmer$sanitizedSaadId';
        photoDir = Directory(
            '${appDocDir.path}/monitoring_records/livestock/$sanitizedGroup/$farmerFolderName');
      }

      if (!await photoDir.exists()) {
        await photoDir.create(recursive: true);
      }

      // Create filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = _photoPath.split('.').last;
      final photoDestPath = '${photoDir.path}/picture_$timestamp.$extension';

      // Copy photo to destination
      await sourceFile.copy(photoDestPath);
      print(
          '✅ Livestock photo saved: $photoDestPath (${isCollective ? 'collective' : 'individual/hybrid'})');

      // Add GPS to EXIF metadata if available
      if (_photoLatitude != null && _photoLongitude != null) {
        try {
          const platform = MethodChannel('com.example.da_monitoring_app/exif');
          await platform.invokeMethod('setExifGPS', {
            'imagePath': photoDestPath,
            'latitude': _photoLatitude!,
            'longitude': _photoLongitude!,
            'accuracy': _photoAccuracy ?? 0.0,
          });
          print(
              '✅ GPS metadata embedded: $_photoLatitude, $_photoLongitude (±${_photoAccuracy?.toStringAsFixed(0)}m)');
        } catch (e) {
          print('⚠️ Failed to embed GPS metadata: $e (photo still saved)');
        }
      }
    } catch (e) {
      print('❌ Error saving livestock photo: $e');
      rethrow;
    }
  }

  /// ✅ Save INDIVIDUAL/HYBRID livestock records using folder-based structure
  ///
  /// BOTH INDIVIDUAL & HYBRID use the same structure with farmer subfolders:
  ///
  /// INDIVIDUAL: Single farmer
  /// monitoring_records/livestock/
  ///   GroupName/
  ///     ├── group.json          ← Step 01 data only (empty members)
  ///     └── Farmer1_SAAD01/
  ///         └── data.json       ← Steps 02-07 (farmer's batches + trainings)
  ///
  /// HYBRID: Multiple farmers
  /// monitoring_records/livestock/
  ///   GroupName/
  ///     ├── group.json          ← Step 01 data (project background + members)
  ///     ├── Farmer1_SAAD01/
  ///     │   └── data.json       ← Steps 02-07 (farmer 1 only)
  ///     └── Farmer2_SAAD02/
  ///         └── data.json       ← Steps 02-07 (farmer 2 only)
  Future<void> _saveLivestockRecordByFolders(
    Map<String, dynamic> jsonData,
    String productionType,
  ) async {
    print('\n📁 LIVESTOCK: Saving using folder structure...');
    final implementationType =
        (jsonData['implementationType'] as String? ?? '').toLowerCase();
    final isHybrid = implementationType == 'hybrid';
    final isIndividual = implementationType == 'individual';
    final farmerName = (jsonData['farmerName'] as String? ?? '').trim();
    final saadIdNo = (jsonData['saadIdNo'] as String? ?? '').trim();
    final fcaName = (jsonData['fcaName'] as String? ?? '').trim();

    print(
        '   Type: ${isHybrid ? 'HYBRID' : 'INDIVIDUAL'} | Farmer: $farmerName | Group: $fcaName');

    // Get monitoring records directory
    Directory? appDocDir;
    try {
      const platform = MethodChannel('com.example.da_monitoring_app/storage');
      final String result = await platform.invokeMethod('getExternalFilesDir');
      appDocDir = Directory(result);
    } catch (e) {
      appDocDir = await getApplicationDocumentsDirectory();
    }

    final monitoringDir =
        Directory('${appDocDir.path}/monitoring_records/$productionType');

    if (!await monitoringDir.exists()) {
      await monitoringDir.create(recursive: true);
    }

    if (farmerName.isEmpty) {
      throw Exception(
          '❌ ERROR: Farmer name is REQUIRED! Please select or enter a farmer name.');
    }

    if (isHybrid && fcaName.isEmpty) {
      throw Exception('FCA name is required for hybrid records');
    }

    // Determine folder structure
    final groupName =
        isHybrid ? fcaName : (fcaName.isNotEmpty ? fcaName : farmerName);
    final sanitizedGroupName = _sanitizeFolderName(groupName);
    final groupDir = Directory('${monitoringDir.path}/$sanitizedGroupName');

    if (!await groupDir.exists()) {
      await groupDir.create(recursive: true);
    }

    // Save group.json with ONLY Step 01 data (created once per group)
    final groupJsonFile = File('${groupDir.path}/group.json');
    if (!await groupJsonFile.exists()) {
      final groupData = <String, dynamic>{
        'implementationType': jsonData['implementationType'],
        'reportingPeriod': jsonData['reportingPeriod'],
        'fcaName': fcaName,
        'region': jsonData['region'],
        'province': jsonData['province'],
        'municipality': jsonData['municipality'],
        'barangay': jsonData['barangay'],
        'projectTitle': jsonData['projectTitle'],
        'primaryIntervention': jsonData['primaryIntervention'],
        'supportInterventions': jsonData['supportInterventions'],
        'members': isHybrid ? (jsonData['members'] as List? ?? []) : [],
        'createdAt': DateTime.now().toIso8601String(),
      };
      await groupJsonFile.writeAsString(jsonEncode(groupData));
      print('✅ Created group.json');
    }

    // Save farmer's data in their own folder
    final sanitizedFarmerName = _sanitizeFolderName(farmerName);
    final sanitizedSaadId =
        saadIdNo.isEmpty ? '' : '_${_sanitizeFolderName(saadIdNo)}';
    final farmerFolderName = '$sanitizedFarmerName$sanitizedSaadId';

    final farmerDir = Directory('${groupDir.path}/$farmerFolderName');
    if (!await farmerDir.exists()) {
      await farmerDir.create(recursive: true);
    }

    // Build farmer-specific data (Steps 02-07 only)
    final farmerData = <String, dynamic>{
      'name': farmerName,
      'saadIdNo': saadIdNo,
      'completedBatches': [],
      'trainings': [],
    };

    // Extract current batch
    final currentBatch = _persistCurrentLivestockBatch();
    final farmerBatches = <Map<String, dynamic>>[currentBatch];

    // Build trainings list
    final trainings = _trainings
        .where((t) => t.name.trim().isNotEmpty)
        .map((t) => t.toJson() as Map<String, dynamic>)
        .toList();

    farmerData['completedBatches'] = farmerBatches;
    farmerData['trainings'] = trainings;

    final farmerJsonFile = File('${farmerDir.path}/data.json');

    // ✅ CRITICAL: If data.json exists, MERGE batches (don't replace)
    if (await farmerJsonFile.exists()) {
      try {
        final existingContent = await farmerJsonFile.readAsString();
        final existingData =
            jsonDecode(existingContent) as Map<String, dynamic>;

        // Get existing batches
        final existingBatches = (existingData['completedBatches'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [];

        // ✅ Only append NEW batch if it doesn't already exist (by GPS)
        final newBatch = farmerBatches.first;
        final photoGPS = newBatch['photoGPS'];
        final alreadyExists = existingBatches.any((existing) {
          final existingGPS = existing['photoGPS'];
          return photoGPS != null &&
              existingGPS != null &&
              photoGPS['latitude'] == existingGPS['latitude'] &&
              photoGPS['longitude'] == existingGPS['longitude'] &&
              photoGPS['accuracy'] == existingGPS['accuracy'];
        });

        if (!alreadyExists) {
          existingBatches.add(newBatch);
          print('✅ Added new batch: ${newBatch['breed']}');
        } else {
          print('⏭️ Skipped duplicate batch: ${newBatch['breed']}');
        }

        // Merge trainings (only add new trainings)
        final existingTrainings = (existingData['trainings'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [];

        for (final newTraining in trainings) {
          final trainingName = newTraining['name'];
          final trainingDate = newTraining['date'];
          final trainingExists = existingTrainings.any((existing) =>
              existing['name'] == trainingName &&
              existing['date'] == trainingDate);

          if (!trainingExists) {
            existingTrainings.add(newTraining);
            print('✅ Added training: $trainingName on $trainingDate');
          } else {
            print('⏭️ Skipped duplicate training: $trainingName');
          }
        }

        // Update farmer data
        farmerData['completedBatches'] = existingBatches;
        farmerData['trainings'] = existingTrainings;

        // Write merged data
        await farmerJsonFile.writeAsString(jsonEncode(farmerData));
        print(
            '✅ Merged data.json - ${existingBatches.length} batches, ${existingTrainings.length} trainings');
      } catch (e) {
        print('⚠️ Could not merge existing data: $e, will overwrite');
        await farmerJsonFile.writeAsString(jsonEncode(farmerData));
      }
    } else {
      // First time saving for this farmer
      await farmerJsonFile.writeAsString(jsonEncode(farmerData));
      print('✅ Created data.json');
    }

    // Update group.json members list (hybrid only)
    if (isHybrid) {
      try {
        final groupJsonContent = jsonDecode(await groupJsonFile.readAsString())
            as Map<String, dynamic>;
        final existingMembers = (groupJsonContent['members'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [];

        final farmerExists = existingMembers.any((m) =>
            (m['name']?.toString().trim().toLowerCase() ==
                farmerName.trim().toLowerCase()) &&
            (m['saadIdNo']?.toString().trim() == saadIdNo.trim()));

        if (!farmerExists) {
          existingMembers.add({
            'name': farmerName.trim(),
            'saadIdNo': saadIdNo.trim(),
          });
          groupJsonContent['members'] = existingMembers;
          await groupJsonFile.writeAsString(jsonEncode(groupJsonContent));
          print('✅ Added farmer to members list');
        }
      } catch (e) {
        print('⚠️ Could not update members list: $e');
      }
    }

    print('✅ LIVESTOCK: Record saved to folder structure');
  }

  /// Sanitize folder names by removing invalid characters
  String _sanitizeFolderName(String name) {
    return name
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll('__', '_')
        .replaceFirst(RegExp(r'^_+'), '')
        .replaceFirst(RegExp(r'_+$'), '');
  }

  Future<void> _handleBack() async {
    if (!_didSaveDraft && _photoPath.isNotEmpty) {
      await _deletePhotoSilently(_photoPath);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _takePhotoWithLocation() async {
    if (_isCapturingPhoto) return;
    setState(() => _isCapturingPhoto = true);

    try {
      final result =
          await PhotoCaptureLocationService.instance.captureFromCamera(
        productionType: 'livestock',
        implementationType: w.implementationType ?? '',
        groupName: w.fcaName,
        farmerName: w.farmerName,
      );
      if (!mounted) return;

      setState(() {
        _photoPath = result.path;
        _photoLatitude = result.latitude;
        _photoLongitude = result.longitude;
        _photoAccuracy = result.accuracy;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Photo captured with location (${result.accuracy.toStringAsFixed(0)}m accuracy).',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor: DAColors.greenMid,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCapturingPhoto = false);
      }
    }
  }

  void _clearPhoto() {
    final previousPath = _photoPath;
    setState(() {
      _photoPath = '';
      _photoLatitude = null;
      _photoLongitude = null;
      _photoAccuracy = null;
    });
    if (previousPath.isNotEmpty) {
      _deletePhotoSilently(previousPath);
    }
  }

  Widget _addBtn(String label, VoidCallback onTap) => GestureDetector(
      onTap: onTap,
      child: Row(children: [
        Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
                color: DAColors.greenMid, shape: BoxShape.circle),
            child:
                const Icon(Icons.add_rounded, color: Colors.white, size: 18)),
        const SizedBox(width: 8),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: DAColors.greenMid)),
      ]));

  Widget _removeBtn(VoidCallback onTap) => GestureDetector(
      onTap: onTap,
      child: Container(
          width: 32,
          height: 32,
          decoration:
              BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
          child:
              Icon(Icons.close_rounded, color: Colors.red.shade400, size: 18)));

  Widget _bareField(
          {required String hint,
          required ValueChanged<String> onChanged,
          String? initial}) =>
      TextFormField(
          initialValue: initial,
          onChanged: onChanged,
          style: GoogleFonts.poppins(fontSize: 14, color: DAColors.textDark),
          decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  GoogleFonts.poppins(fontSize: 14, color: DAColors.textMuted),
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: Color(0xFFDDDDDD), width: 1.5)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: Color(0xFFDDDDDD), width: 1.5)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: DAColors.greenMid, width: 2.0))));

  @override
  Widget build(BuildContext context) => WillPopScope(
        onWillPop: () async {
          await _handleBack();
          return false;
        },
        child: CropFormShell(
          formTitle: 'LIVESTOCK PRODUCTION',
          formSubtitle: 'Livestock Production Monitoring Form',
          currentStep: 6,
          totalSteps: 7,
          nextLabel: 'Submit',
          onNext: _onSubmit,
          onBack: () {
            _handleBack();
          },
          child: _buildForm(),
        ),
      );

  Widget _buildForm() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Trainings Attended',
          style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: DAColors.textDark)),
      const SizedBox(height: 24),
      Text('Trainings Attended',
          style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: DAColors.textDark)),
      const SizedBox(height: 12),
      ..._trainings.asMap().entries.map((e) {
        final i = e.key;
        final t = e.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE0E0E0), width: 1.2)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: Text('Training ${i + 1}',
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: DAColors.greenMid))),
                if (i > 0)
                  _removeBtn(() => setState(() => _trainings.removeAt(i))),
              ]),
              const SizedBox(height: 10),
              Text('Name of Training',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: DAColors.textDark)),
              const SizedBox(height: 6),
              _bareField(
                  hint: 'Enter training name',
                  initial: t.name,
                  onChanged: (v) => t.name = v),
              const SizedBox(height: 10),
              Text('Date',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: DAColors.textDark)),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () async {
                  final p = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      builder: (ctx, child) => Theme(
                          data: Theme.of(ctx).copyWith(
                              colorScheme: const ColorScheme.light(
                                  primary: DAColors.greenMid)),
                          child: child!));
                  if (p != null) {
                    setState(() => t.date =
                        '${p.year}-${p.month.toString().padLeft(2, '0')}-${p.day.toString().padLeft(2, '0')}');
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFFDDDDDD), width: 1.5)),
                  child: Row(children: [
                    Expanded(
                        child: Text(t.date.isEmpty ? 'Choose Date' : t.date,
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: t.date.isEmpty
                                    ? DAColors.textMuted
                                    : DAColors.textDark))),
                    const Icon(Icons.calendar_month_rounded,
                        color: DAColors.greenMid, size: 22),
                  ]),
                ),
              ),
              const SizedBox(height: 10),
              Text('Number of Attendees',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: DAColors.textDark)),
              const SizedBox(height: 6),
              TextFormField(
                initialValue: t.attendees,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (v) => t.attendees = v,
                style:
                    GoogleFonts.poppins(fontSize: 14, color: DAColors.textDark),
                decoration: InputDecoration(
                    hintText: 'Enter number of attendees',
                    hintStyle: GoogleFonts.poppins(
                        fontSize: 14, color: DAColors.textMuted),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: Color(0xFFDDDDDD), width: 1.5)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: Color(0xFFDDDDDD), width: 1.5)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: DAColors.greenMid, width: 2.0))),
              ),
            ]),
          ),
        );
      }),
      _addBtn('Add Training',
          () => setState(() => _trainings.add(TrainingEntry()))),
      const SizedBox(height: 28),
      Text('Picture of the Farm',
          style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: DAColors.textDark)),
      const SizedBox(height: 10),
      if (_photoPath.isNotEmpty) ...[
        Stack(children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                File(_photoPath),
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: double.infinity,
                  height: 180,
                  color: DAColors.greenLight.withOpacity(0.2),
                  child: const Icon(Icons.image_rounded,
                      size: 64, color: DAColors.greenMid),
                ),
              )),
          Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                  onTap: _clearPhoto,
                  child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                          color: Colors.red.shade400, shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 18)))),
        ]),
        if (_photoLatitude != null &&
            _photoLongitude != null &&
            _photoAccuracy != null) ...[
          const SizedBox(height: 8),
          Text(
            'Location: ${_photoLatitude!.toStringAsFixed(6)}, ${_photoLongitude!.toStringAsFixed(6)} (±${_photoAccuracy!.toStringAsFixed(0)}m)',
            style: GoogleFonts.poppins(fontSize: 12, color: DAColors.textMuted),
          ),
        ],
        const SizedBox(height: 10),
        GestureDetector(
            onTap: _isCapturingPhoto ? null : _takePhotoWithLocation,
            child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                    color: DAColors.greenMid.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: DAColors.greenMid, width: 1.5)),
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.camera_alt_outlined,
                      color: DAColors.greenMid, size: 22),
                  const SizedBox(width: 8),
                  Text(_isCapturingPhoto ? 'Capturing...' : 'Retake Photo',
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: DAColors.greenMid)),
                ]))),
      ] else
        GestureDetector(
            onTap: _isCapturingPhoto ? null : _takePhotoWithLocation,
            child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                    color: DAColors.greenMid,
                    borderRadius: BorderRadius.circular(16)),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                          padding: const EdgeInsets.only(left: 24),
                          child: Text(
                              _isCapturingPhoto ? 'Capturing...' : 'Take Photo',
                              style: GoogleFonts.bebasNeue(
                                  fontSize: 24,
                                  color: Colors.white,
                                  letterSpacing: 1))),
                      const Padding(
                          padding: EdgeInsets.only(right: 24),
                          child: Icon(Icons.camera_alt_outlined,
                              color: Colors.white, size: 32)),
                    ]))),
      const SizedBox(height: 32),
    ]);
  }
}
