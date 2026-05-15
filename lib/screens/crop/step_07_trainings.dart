import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import '../../theme/da_colors.dart';
import '../../widgets/crop_form_shell.dart';
import '../../services/photo_capture_location_service.dart';
import 'crop_step_wrapper.dart';

class CropStep7Trainings extends StatefulWidget {
  const CropStep7Trainings({super.key, required this.wrapper});
  final CropStepWrapper wrapper;

  @override
  State<CropStep7Trainings> createState() => _CropStep7State();
}

class _CropStep7State extends State<CropStep7Trainings> {
  CropStepWrapper get w => widget.wrapper;

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

    print('📁 Step07 initState: wrapper arrived with:');
    print('   farmerName: "${w.farmerName}"');
    print('   saadIdNo: "${w.saadIdNo}"');
    print('   fcaName: "${w.fcaName}"');
    print('   implementationType: ${w.implementationType}');
    print('   isAddFarmer: ${w.isAddFarmer}');

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

    // Load photo from wrapper if it exists
    if (w.farmPhoto.isNotEmpty) {
      _photoPath = w.farmPhoto;
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

    // ✅ Trainings NOT required when adding commodity to existing farmer
    final trainingRequired = !w.isAddingNewCommodity;

    if (trainingRequired && !_canSaveDraft()) {
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

  void _persistCurrentCropCommodity() {
    if (w.typeOfCrop.trim().isEmpty) return;

    final commodity = {
      'typeOfCrop': w.typeOfCrop,
      'variety': w.variety,
      'inputsReceived': w.inputsReceived.map((item) => item.toJson()).toList(),
      'inputsPurchased':
          w.inputsPurchased.map((item) => item.toJson()).toList(),
      'totalCostPurchased': w.totalCostPurchased,
      'qtyVsArea': w.qtyVsArea,
      'croppingCycles': w.croppingCycles,
      'qtyVsCycles': w.qtyVsCycles,
      'peakVolume': w.peakVolume,
      'peakMonth': w.peakMonth,
      'volumesPerCycle': w.volumesPerCycle,
      'farmgatePrice': w.farmgatePrice,
      'totalLandArea': w.totalLandArea,
      'landOwnership': w.landOwnership,
      'landOwnershipOther': w.landOwnershipOther,
      'usufructAgreement': w.usufructAgreement,
      'landRemarks': w.landRemarks,
      'machineryType': w.machineryType,
      'machineryOther': w.machineryOther,
      'machineryRemarks': w.machineryRemarks,
      'landPrepCostPerCycle': w.landPrepCostPerCycle,
      'landPrepStartDate': w.landPrepStartDate,
      'landPrepDays': w.landPrepDays,
      'sourceOfWater': w.sourceOfWater,
      'plantingDate': w.plantingDate,
      'seedAmount': w.seedAmount,
      'seedUnit': w.seedUnit,
      'germinationRate': w.germinationRate,
      'goodGermination': w.goodGermination,
      'germinationReason': w.germinationReason,
      'fertilizerType': w.fertilizerType,
      'organicSource': w.organicSource,
      'organicBagsSAAD': w.organicBagsSAAD,
      'organicBagsCommercial': w.organicBagsCommercial,
      'organicTotalCost': w.organicTotalCost,
      'organicBagsCycle': w.organicBagsCycle,
      'organicFrequency': w.organicFrequency,
      'inorganicType': w.inorganicType,
      'inorganicBagsSAAD': w.inorganicBagsSAAD,
      'inorganicMeasure': w.inorganicMeasure,
      'inorganicTotalCost': w.inorganicTotalCost,
      'inorganicBagsCycle': w.inorganicBagsCycle,
      'inorganicFrequency': w.inorganicFrequency,
      'pesticideRequirement': w.pesticideRequirement,
      'landAreaCycles': w.landAreaCycles,
      'dateHarvestCycles': w.dateHarvestCycles,
      'quantityCycles': w.quantityCycles,
      'avgHarvestPerHa': w.avgHarvestPerHa,
      'harvestCostCycles': w.harvestCostCycles,
      'foodConsumptionPct': w.foodConsumptionPct,
      'processingRemarks': w.processingRemarks,
      'hasPest': w.hasPest,
      'pestOccurrence': w.pestOccurrence,
      'pestDate': w.pestDate,
      'pestDamageArea': w.pestDamageArea,
      'pestDamageHa': w.pestDamageHa,
      'pestTreatment': w.pestTreatment,
      'pestAttached': w.pestAttached,
      'hasDisease': w.hasDisease,
      'diseaseOccurrence': w.diseaseOccurrence,
      'diseaseDate': w.diseaseDate,
      'diseaseDamageArea': w.diseaseDamageArea,
      'diseaseDamageHa': w.diseaseDamageHa,
      'diseaseTreatment': w.diseaseTreatment,
      'diseaseAttached': w.diseaseAttached,
      'hasEnvHazard': w.hasEnvHazard,
      'envHazards': w.envHazards,
      'envDate': w.envDate,
      'envDamageArea': w.envDamageArea,
      'envDamageHa': w.envDamageHa,
      'envTreatment': w.envTreatment,
      'envAttached': w.envAttached,
      'hasHumanDamage': w.hasHumanDamage,
      'humanDamage': w.humanDamage,
      'humanMortality': w.humanMortality,
      'humanTreatment': w.humanTreatment,
      'humanAttached': w.humanAttached,
    };

    final currentFarmerName = w.farmerName.trim();
    final currentSaadId = w.saadIdNo.trim();
    final hasCurrentFarmer =
        currentFarmerName.isNotEmpty || currentSaadId.isNotEmpty;

    // ✅ CRITICAL: Only add commodity for CURRENT farmer being edited
    // Do NOT add commodities for all members - each farmer should add their own
    final candidates = <Map<String, dynamic>>[];
    if (hasCurrentFarmer) {
      candidates.add({
        ...commodity,
        'farmerName': currentFarmerName,
        'saadIdNo':
            currentSaadId.isNotEmpty ? currentSaadId : currentFarmerName,
      });
    }
    // NOTE: Removed the "else if (w.members.isNotEmpty)" branch
    // Each farmer adds their own commodities, not commodities for all group members

    for (final candidate in candidates) {
      final candidateJson = jsonEncode(candidate);
      final exists = w.completedCommodities.any(
        (item) => jsonEncode(item) == candidateJson,
      );
      if (!exists) {
        w.completedCommodities.add(candidate);
      }
    }
  }

  Future<void> _save() async {
    if (!_submitRequested) return;

    w.trainings = List<TrainingEntry>.from(_trainings);
    w.farmPhoto = _photoPath;

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

    _persistCurrentCropCommodity();

    try {
      var jsonData = w.toJson();

      // ✅ ALL types (Collective, Individual, Hybrid) use folder structure
      await _saveFarmerRecordByFolders(jsonData, 'crop');

      _didSaveDraft = true;

      if (!mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saved locally.',
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
      print('❌ ERROR: Failed to save - $e');
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

  /// ✅ Save ALL record types using folder-based structure
  ///
  /// COLLECTIVE: Single group, all data in one folder
  /// monitoring_records/{productionType}/
  ///   CollectiveName/
  ///     ├── group.json       ← ALL data (Steps 01-07)
  ///     └── picture.jpg      ← Group photo
  ///
  /// INDIVIDUAL: Single farmer, shared folder structure
  /// monitoring_records/{productionType}/
  ///   FarmerName_SAADID/
  ///     ├── group.json       ← ALL data (Steps 01-07)
  ///     └── picture.jpg      ← Farmer's photo
  ///
  /// HYBRID: Multiple farmers with group background
  /// monitoring_records/{productionType}/
  ///   GroupName/
  ///     ├── group.json          ← Step 01 data (project background)
  ///     ├── FarmerName_SAAD01/
  ///     │   ├── data.json       ← Steps 02-07 (farmer 1 only)
  ///     │   └── picture.jpg
  ///     └── FarmerName_SAAD02/
  ///         ├── data.json       ← Steps 02-07 (farmer 2 only)
  ///         └── picture.jpg
  Future<void> _saveFarmerRecordByFolders(
    Map<String, dynamic> jsonData,
    String productionType,
  ) async {
    print('\n📁 SAVING: Adding farmer to group...');
    final implementationType =
        (jsonData['implementationType'] as String? ?? '').toLowerCase();
    final isCollective = implementationType == 'collective';
    final isHybrid = implementationType == 'hybrid';
    final isIndividual = implementationType == 'individual';
    final farmerName = (jsonData['farmerName'] as String? ?? '').trim();
    final saadIdNo = (jsonData['saadIdNo'] as String? ?? '').trim();
    final fcaName = (jsonData['fcaName'] as String? ?? '').trim();
    final members = jsonData['members'] as List? ?? [];

    print(
        '   Type: ${isCollective ? 'COLLECTIVE' : isHybrid ? 'HYBRID' : 'INDIVIDUAL'} | Farmer: $farmerName | Group: $fcaName');

    // Get monitoring records directory (external storage)
    Directory? appDocDir;
    try {
      // Try platform channel to get Android external files dir
      const platform = MethodChannel('com.example.da_monitoring_app/storage');
      final String result = await platform.invokeMethod('getExternalFilesDir');
      appDocDir = Directory(result);
    } catch (e) {
      appDocDir = await getApplicationDocumentsDirectory();
    }

    final monitoringDir =
        Directory('${appDocDir.path}/monitoring_records/$productionType');

    if (!await monitoringDir.exists()) {
      try {
        await monitoringDir.create(recursive: true);
      } catch (e) {
        print('❌ ERROR creating monitoring_records: $e');
        rethrow;
      }
    }

    // Determine folder name and structure
    String folderName;
    Directory mainDir;

    if (isCollective) {
      // COLLECTIVE: Group-level data stored in group.json
      if (fcaName.isEmpty) {
        throw Exception('FCA name is required for collective records');
      }
      folderName = fcaName;
      final sanitizedName = _sanitizeFolderName(folderName);
      mainDir = Directory('${monitoringDir.path}/$sanitizedName');

      if (!await mainDir.exists()) {
        try {
          await mainDir.create(recursive: true);
        } catch (e) {
          print('❌ ERROR creating group folder: $e');
          rethrow;
        }
      }

      // Load existing group.json or create new
      final groupJsonFile = File('${mainDir.path}/group.json');
      Map<String, dynamic> groupData;

      if (await groupJsonFile.exists()) {
        try {
          final existingContent = await groupJsonFile.readAsString();
          groupData = jsonDecode(existingContent) as Map<String, dynamic>;
        } catch (e) {
          print('⚠️ WARNING: Could not read existing group.json: $e');
          groupData = {};
        }
      } else {
        groupData = {};
      }

      // Preserve existing completedCommodities array and append new one
      final existingCommodities = (groupData['completedCommodities'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          [];

      // Extract current commodity from jsonData
      final currentCommodity = <String, dynamic>{};
      final commodityFields = [
        'typeOfCrop',
        'variety',
        'inputsReceived',
        'inputsPurchased',
        'totalCostPurchased',
        'qtyVsArea',
        'croppingCycles',
        'qtyVsCycles',
        'peakVolume',
        'peakMonth',
        'volumesPerCycle',
        'farmgatePrice',
        'totalLandArea',
        'landOwnership',
        'landOwnershipOther',
        'usufructAgreement',
        'landRemarks',
        'machineryType',
        'machineryOther',
        'machineryRemarks',
        'landPrepCostPerCycle',
        'landPrepStartDate',
        'landPrepDays',
        'sourceOfWater',
        'plantingDate',
        'seedAmount',
        'seedUnit',
        'germinationRate',
        'goodGermination',
        'germinationReason',
        'fertilizerType',
        'organicSource',
        'organicBagsSAAD',
        'organicBagsCommercial',
        'organicTotalCost',
        'organicBagsCycle',
        'organicFrequency',
        'inorganicType',
        'inorganicBagsSAAD',
        'inorganicMeasure',
        'inorganicTotalCost',
        'inorganicBagsCycle',
        'inorganicFrequency',
        'pesticideRequirement',
        'landAreaCycles',
        'dateHarvestCycles',
        'quantityCycles',
        'avgHarvestPerHa',
        'harvestCostCycles',
        'foodConsumptionPct',
        'processingRemarks',
        'hasPest',
        'pestOccurrence',
        'pestDate',
        'pestDamageArea',
        'pestDamageHa',
        'pestTreatment',
        'pestAttached',
        'hasDisease',
        'diseaseOccurrence',
        'diseaseDate',
        'diseaseDamageArea',
        'diseaseDamageHa',
        'diseaseTreatment',
        'diseaseAttached',
        'hasEnvHazard',
        'envHazards',
        'envDate',
        'envDamageArea',
        'envDamageHa',
        'envTreatment',
        'envAttached',
        'hasHumanDamage',
        'humanDamage',
        'humanMortality',
        'humanTreatment',
        'humanAttached',
      ];

      for (final field in commodityFields) {
        if (jsonData.containsKey(field)) {
          currentCommodity[field] = jsonData[field];
        }
      }

      // ✅ Add GPS coordinates to commodity data
      if (_photoLatitude != null && _photoLongitude != null) {
        currentCommodity['photoGPS'] = {
          'latitude': _photoLatitude!,
          'longitude': _photoLongitude!,
          'accuracy': _photoAccuracy ?? 0.0,
        };
      }

      existingCommodities.add(currentCommodity);

      // Merge all group data (Step 1 + all commodities + trainings)
      final mergedTrainings =
          (groupData['trainings'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final trainings =
          (jsonData['trainings'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      mergedTrainings.addAll(trainings);

      groupData['implementationType'] = jsonData['implementationType'];
      groupData['reportingPeriod'] = jsonData['reportingPeriod'];
      groupData['fcaName'] = fcaName;
      groupData['region'] = jsonData['region'];
      groupData['province'] = jsonData['province'];
      groupData['municipality'] = jsonData['municipality'];
      groupData['barangay'] = jsonData['barangay'];
      groupData['projectTitle'] = jsonData['projectTitle'];
      groupData['primaryIntervention'] = jsonData['primaryIntervention'];
      groupData['primaryInterventionOther'] =
          jsonData['primaryInterventionOther'];
      groupData['supportInterventions'] = jsonData['supportInterventions'];
      groupData['completedCommodities'] = existingCommodities;
      groupData['trainings'] = mergedTrainings;

      try {
        await groupJsonFile.writeAsString(jsonEncode(groupData));
        print(
            '✅ Saved group commodity to group.json (total: ${existingCommodities.length} commodities)');
      } catch (e) {
        print('❌ ERROR writing group.json: $e');
        rethrow;
      }

      // Save photo if exists with GPS location metadata
      if (_photoPath.isNotEmpty) {
        final extension = _photoPath.split('.').last;
        // ✅ Use timestamp to create unique filename for each commodity photo
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final photoDestPath = '${mainDir.path}/picture_$timestamp.$extension';
        await _savePhotoWithLocation(_photoPath, photoDestPath);
        print(
            '✅ Saved collective picture_$timestamp.$extension with location metadata');
      }
    } else if (isHybrid || isIndividual) {
      // HYBRID/INDIVIDUAL: Same structure - group.json + farmer subfolders
      if (farmerName.isEmpty) {
        throw Exception(
            '❌ ERROR: Farmer name is REQUIRED! Please select or enter a farmer name from the dropdown before proceeding.');
      }
      if (isHybrid && fcaName.isEmpty) {
        throw Exception('FCA name is required for hybrid records');
      }

      // For hybrid, always use fcaName. For individual, use fcaName or fallback to farmerName
      final groupName =
          isHybrid ? fcaName : (fcaName.isNotEmpty ? fcaName : farmerName);
      final sanitizedGroupName = _sanitizeFolderName(groupName);
      final groupDir = Directory('${monitoringDir.path}/$sanitizedGroupName');

      if (!await groupDir.exists()) {
        try {
          await groupDir.create(recursive: true);
        } catch (e) {
          print('❌ ERROR creating group folder: $e');
          rethrow;
        }
      }

      // Save group.json with ONLY Step 01 data
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
          'primaryInterventionOther': jsonData['primaryInterventionOther'],
          'supportInterventions': jsonData['supportInterventions'],
          'members': isHybrid ? members : <Map<String, dynamic>>[],
          'createdAt': DateTime.now().toIso8601String(),
        };
        await groupJsonFile.writeAsString(jsonEncode(groupData));
      }

      // Save current farmer's data in their own folder
      if (farmerName.isNotEmpty) {
        final sanitizedFarmerName = _sanitizeFolderName(farmerName);
        final sanitizedSaadId =
            saadIdNo.isEmpty ? '' : '_${_sanitizeFolderName(saadIdNo)}';
        final farmerFolderName = '$sanitizedFarmerName$sanitizedSaadId';

        final farmerDir = Directory('${groupDir.path}/$farmerFolderName');
        if (!await farmerDir.exists()) {
          await farmerDir.create(recursive: true);
        }

        // Build farmer data (Steps 02-07 only)
        final farmerData = _buildFarmerData(jsonData, farmerName, saadIdNo);

        // ✅ FIX: Add photoGPS to first commodity if GPS data exists
        if (_photoLatitude != null && _photoLongitude != null) {
          final commodities = (farmerData['completedCommodities'] as List?)
                  ?.cast<Map<String, dynamic>>() ??
              [];
          if (commodities.isNotEmpty) {
            commodities[0]['photoGPS'] = {
              'latitude': _photoLatitude!,
              'longitude': _photoLongitude!,
              'accuracy': _photoAccuracy ?? 0.0,
            };
            print(
                '✅ [FIX] Added photoGPS to FIRST commodity: ${commodities[0]['photoGPS']}');
          }
        }

        final farmerJsonFile = File('${farmerDir.path}/data.json');

        // ✅ CRITICAL: If data.json already exists, load it and MERGE commodities
        if (await farmerJsonFile.exists()) {
          try {
            final existingContent = await farmerJsonFile.readAsString();
            final existingData =
                jsonDecode(existingContent) as Map<String, dynamic>;

            // Get existing completed commodities
            final existingCommodities =
                (existingData['completedCommodities'] as List?)
                        ?.cast<Map<String, dynamic>>() ??
                    [];

            // Add the new commodity from wrapper to existing list
            final newCommodity = w.completedCommodities.isNotEmpty
                ? w.completedCommodities.last // Get the last (newest) commodity
                : <String, dynamic>{};

            if (newCommodity.isNotEmpty) {
              // ✅ Add GPS coordinates to commodity data
              if (_photoLatitude != null && _photoLongitude != null) {
                newCommodity['photoGPS'] = {
                  'latitude': _photoLatitude!,
                  'longitude': _photoLongitude!,
                  'accuracy': _photoAccuracy ?? 0.0,
                };
              }
              existingCommodities.add(newCommodity);
            }

            // Get existing trainings and merge with new ones
            final existingTrainings = (existingData['trainings'] as List?)
                    ?.cast<Map<String, dynamic>>() ??
                [];
            final mergedTrainings = [
              ...existingTrainings,
              ...w.trainings.map((item) => item.toJson())
            ];

            // ✅ CRITICAL: Preserve ALL existing fields + only update commodities & trainings
            // Start with existing data (preserves everything)
            final mergedData = Map<String, dynamic>.from(existingData);

            // Update ONLY the commodities and trainings arrays
            mergedData['completedCommodities'] = existingCommodities;
            mergedData['trainings'] = mergedTrainings;

            // Save merged data
            await farmerJsonFile.writeAsString(jsonEncode(mergedData));
          } catch (e) {
            print(
                '⚠️ Warning: Could not merge existing data: $e, will overwrite');
            // Fallback: just write the new data
            await farmerJsonFile.writeAsString(jsonEncode(farmerData));
          }
        } else {
          // First time saving for this farmer
          await farmerJsonFile.writeAsString(jsonEncode(farmerData));
        }

        // Save photo in farmer folder with GPS location metadata
        // Photo is named: {typeOfCrop}_{variety}_{timestamp}.jpg
        if (_photoPath.isNotEmpty) {
          final typeOfCrop = (jsonData['typeOfCrop'] as String? ?? '').trim();
          final variety = (jsonData['variety'] as String? ?? '').trim();
          final commodityName =
              variety.isNotEmpty ? '${typeOfCrop}_$variety' : typeOfCrop;
          // ✅ Use timestamp to create unique filename for each commodity photo
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final photoDestPath =
              '${farmerDir.path}/${commodityName}_$timestamp.jpg';
          await _savePhotoWithLocation(_photoPath, photoDestPath);
        }

        // ✅ UPDATE group.json members list to include this new farmer
        try {
          final groupJsonFile = File('${groupDir.path}/group.json');
          if (await groupJsonFile.exists()) {
            final groupJsonContent =
                jsonDecode(await groupJsonFile.readAsString())
                    as Map<String, dynamic>;
            final existingMembers = (groupJsonContent['members'] as List?)
                    ?.cast<Map<String, dynamic>>() ??
                [];

            // Check if this farmer is already in the members list
            final farmerExists = existingMembers.any((m) =>
                (m['name']?.toString().trim().toLowerCase() ==
                    farmerName.trim().toLowerCase()) &&
                (m['saadIdNo']?.toString().trim() == saadIdNo.trim()));

            if (!farmerExists) {
              // Add new farmer to members list
              existingMembers.add({
                'name': farmerName.trim(),
                'saadIdNo': saadIdNo.trim(),
              });
              groupJsonContent['members'] = existingMembers;

              // Write updated group.json
              await groupJsonFile.writeAsString(jsonEncode(groupJsonContent));
            }
          }
        } catch (e) {
          print('⚠️  WARNING: Could not update group.json members list: $e');
          // Don't rethrow - farmer data is already saved, this is just housekeeping
        }
      }
    } else {
      throw Exception(
          '❌ ERROR: Unknown implementation type: $implementationType');
    }

    print('✅ Record saved to folder structure');
  }

  /// Build farmer data (Steps 02-07 only) for hybrid records
  Map<String, dynamic> _buildFarmerData(
    Map<String, dynamic> jsonData,
    String farmerName,
    String saadIdNo,
  ) {
    return <String, dynamic>{
      'name': farmerName,
      'farmerName': farmerName,
      'saadIdNo': saadIdNo,
      'completedCommodities': w.completedCommodities,
      'trainings': w.trainings.map((item) => item.toJson()).toList(),
      'typeOfCrop': jsonData['typeOfCrop'],
      'variety': jsonData['variety'],
      'inputsReceived': jsonData['inputsReceived'],
      'inputsPurchased': jsonData['inputsPurchased'],
      'totalCostPurchased': jsonData['totalCostPurchased'],
      'qtyVsArea': jsonData['qtyVsArea'],
      'croppingCycles': jsonData['croppingCycles'],
      'qtyVsCycles': jsonData['qtyVsCycles'],
      'peakVolume': jsonData['peakVolume'],
      'peakMonth': jsonData['peakMonth'],
      'volumesPerCycle': jsonData['volumesPerCycle'],
      'farmgatePrice': jsonData['farmgatePrice'],
      'totalLandArea': jsonData['totalLandArea'],
      'landOwnership': jsonData['landOwnership'],
      'landOwnershipOther': jsonData['landOwnershipOther'],
      'usufructAgreement': jsonData['usufructAgreement'],
      'landRemarks': jsonData['landRemarks'],
      'machineryType': jsonData['machineryType'],
      'machineryOther': jsonData['machineryOther'],
      'machineryRemarks': jsonData['machineryRemarks'],
      'landPrepCostPerCycle': jsonData['landPrepCostPerCycle'],
      'landPrepStartDate': jsonData['landPrepStartDate'],
      'landPrepDays': jsonData['landPrepDays'],
      'sourceOfWater': jsonData['sourceOfWater'],
      'plantingDate': jsonData['plantingDate'],
      'seedAmount': jsonData['seedAmount'],
      'seedUnit': jsonData['seedUnit'],
      'germinationRate': jsonData['germinationRate'],
      'goodGermination': jsonData['goodGermination'],
      'germinationReason': jsonData['germinationReason'],
      'fertilizerType': jsonData['fertilizerType'],
      'organicSource': jsonData['organicSource'],
      'organicBagsSAAD': jsonData['organicBagsSAAD'],
      'organicBagsCommercial': jsonData['organicBagsCommercial'],
      'organicTotalCost': jsonData['organicTotalCost'],
      'organicBagsCycle': jsonData['organicBagsCycle'],
      'organicFrequency': jsonData['organicFrequency'],
      'inorganicType': jsonData['inorganicType'],
      'inorganicBagsSAAD': jsonData['inorganicBagsSAAD'],
      'inorganicMeasure': jsonData['inorganicMeasure'],
      'inorganicTotalCost': jsonData['inorganicTotalCost'],
      'inorganicBagsCycle': jsonData['inorganicBagsCycle'],
      'inorganicFrequency': jsonData['inorganicFrequency'],
      'pesticideRequirement': jsonData['pesticideRequirement'],
      'landAreaCycles': jsonData['landAreaCycles'],
      'dateHarvestCycles': jsonData['dateHarvestCycles'],
      'quantityCycles': jsonData['quantityCycles'],
      'avgHarvestPerHa': jsonData['avgHarvestPerHa'],
      'harvestCostCycles': jsonData['harvestCostCycles'],
      'foodConsumptionPct': jsonData['foodConsumptionPct'],
      'processingFile': jsonData['processingFile'],
      'processingRemarks': jsonData['processingRemarks'],
      'hasPest': jsonData['hasPest'],
      'pestOccurrence': jsonData['pestOccurrence'],
      'pestDate': jsonData['pestDate'],
      'pestDamageArea': jsonData['pestDamageArea'],
      'pestDamageHa': jsonData['pestDamageHa'],
      'pestTreatment': jsonData['pestTreatment'],
      'pestAttached': jsonData['pestAttached'],
      'hasDisease': jsonData['hasDisease'],
      'diseaseOccurrence': jsonData['diseaseOccurrence'],
      'diseaseDate': jsonData['diseaseDate'],
      'diseaseDamageArea': jsonData['diseaseDamageArea'],
      'diseaseDamageHa': jsonData['diseaseDamageHa'],
      'diseaseTreatment': jsonData['diseaseTreatment'],
      'diseaseAttached': jsonData['diseaseAttached'],
      'hasEnvHazard': jsonData['hasEnvHazard'],
      'envHazards': jsonData['envHazards'],
      'envDate': jsonData['envDate'],
      'envDamageArea': jsonData['envDamageArea'],
      'envDamageHa': jsonData['envDamageHa'],
      'envTreatment': jsonData['envTreatment'],
      'envAttached': jsonData['envAttached'],
      'hasHumanDamage': jsonData['hasHumanDamage'],
      'humanDamage': jsonData['humanDamage'],
      'humanMortality': jsonData['humanMortality'],
      'humanTreatment': jsonData['humanTreatment'],
      'humanAttached': jsonData['humanAttached'],
    };
  }

  /// Save photo with GPS location metadata (EXIF)
  Future<void> _savePhotoWithLocation(
      String sourcePhotoPath, String destPhotoPath) async {
    if (sourcePhotoPath.isEmpty) return;

    final photoFile = File(sourcePhotoPath);
    if (!await photoFile.exists()) return;

    try {
      // Copy photo to destination
      await photoFile.copy(destPhotoPath);
      print('✅ Photo copied to: $destPhotoPath');

      // Add GPS location to EXIF if available
      if (_photoLatitude != null && _photoLongitude != null) {
        try {
          print(
              '📍 [STEP7] Attempting to embed GPS: lat=$_photoLatitude, lon=$_photoLongitude, acc=$_photoAccuracy');
          const platform = MethodChannel('com.example.da_monitoring_app/exif');
          final result = await platform.invokeMethod('setExifGPS', {
            'imagePath': destPhotoPath,
            'latitude': _photoLatitude!,
            'longitude': _photoLongitude!,
            'accuracy': _photoAccuracy ?? 0.0,
          });
          print(
              '✅ [STEP7] GPS metadata added: $_photoLatitude, $_photoLongitude (±${_photoAccuracy?.toStringAsFixed(0)}m)');
          print('   Android result: $result');
        } catch (e) {
          print('❌ [STEP7] FAILED to add GPS metadata: $e');
          print('   Image path: $destPhotoPath');
          print('   Latitude: $_photoLatitude, Longitude: $_photoLongitude');
          print(
              '   (GPS should have been embedded during capture - verifying...)');
        }
      } else {
        print(
            '⚠️ [STEP7] GPS not available - Latitude: $_photoLatitude, Longitude: $_photoLongitude');
      }
    } catch (e) {
      print('❌ Error saving photo: $e');
      rethrow;
    }
  }

  /// Sanitize folder names by removing invalid characters
  String _sanitizeFolderName(String name) {
    return name
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
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
        productionType: 'crop',
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
    setState(() {
      _photoPath = '';
      _photoLatitude = null;
      _photoLongitude = null;
      _photoAccuracy = null;
    });
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

  Widget _bareField({
    required String hint,
    required ValueChanged<String> onChanged,
    String? initial,
  }) =>
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
                    const BorderSide(color: DAColors.greenMid, width: 2.0)),
          ));

  @override
  Widget build(BuildContext context) => WillPopScope(
        onWillPop: () async {
          await _handleBack();
          return false;
        },
        child: CropFormShell(
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
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Trainings Attended',
              style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: DAColors.textDark)),
        ],
      ),
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
                    final y = p.year.toString();
                    final mo = p.month.toString().padLeft(2, '0');
                    final dy = p.day.toString().padLeft(2, '0');
                    setState(() => t.date = '$y-$mo-$dy');
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
      Text('Picture of the Farm?',
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
                  color: DAColors.greenMid.withOpacity(0.15),
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
