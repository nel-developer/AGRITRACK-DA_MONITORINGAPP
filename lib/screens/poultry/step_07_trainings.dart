import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import '../../theme/da_colors.dart';
import '../../widgets/crop_form_shell.dart';
import '../../services/photo_capture_location_service.dart';
import 'poultry_step_wrapper.dart';

class PoultryStep7Trainings extends StatefulWidget {
  const PoultryStep7Trainings({super.key, required this.wrapper});
  final PoultryStepWrapper wrapper;

  @override
  State<PoultryStep7Trainings> createState() => _PoultryStep7State();
}

class _PoultryStep7State extends State<PoultryStep7Trainings> {
  PoultryStepWrapper get w => widget.wrapper;

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

    if (w.trainings.isNotEmpty) {
      bool hasActualData = w.trainings.any((training) =>
          training.name.trim().isNotEmpty ||
          training.date.trim().isNotEmpty ||
          training.attendees.trim().isNotEmpty);
      if (hasActualData) {
        _trainings.clear();
        _trainings.addAll(w.trainings);
      } else {
        _trainings.clear();
        _trainings.add(TrainingEntry());
      }
    } else {
      _trainings.clear();
      _trainings.add(TrainingEntry());
    }

    if (w.farmPhoto.isNotEmpty) {
      _photoPath = w.farmPhoto;
    }
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

    _persistCurrentPoultryCommodity();

    try {
      var jsonData = w.toJson();

      // ALL types use folder structure
      await _savePoultryRecordByFolders(jsonData, 'poultry');

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

  void _persistCurrentPoultryCommodity() {
    if (w.breed.trim().isEmpty) return;

    final commodity = {
      'breed': w.breed,
      'inputsReceived': w.inputsReceived.map((item) => item.toJson()).toList(),
      'inputsPurchased':
          w.inputsPurchased.map((item) => item.toJson()).toList(),
      'farmgatePrices': w.farmgatePrices,
      'stocksReceived': w.stocksReceived,
      'dateReceived': w.dateReceived,
      'ageUponReceipt': w.ageUponReceipt,
      'avgWeightUponReceipt': w.avgWeightUponReceipt,
      'totalProductiveCycle': w.totalProductiveCycle,
      'housingType': w.housingType,
      'landOwnership': w.landOwnership,
      'landOwnershipOther': w.landOwnershipOther,
      'usufruct': w.usufruct,
      'maleToFemaleRatio': w.maleToFemaleRatio,
      'eggsProduced': w.eggsProduced,
      'fertilEggs': w.fertilEggs,
      'eggsIncubated': w.eggsIncubated,
      'eggsHatched': w.eggsHatched,
      'hatchingRate': w.hatchingRate,
      'mortalitiesAfterHatch': w.mortalitiesAfterHatch,
      'chicksSold': w.chicksSold,
      'eggsSold': w.eggsSold,
      'harvestedBirds': w.harvestedBirds,
      'totalWeightHarvested': w.totalWeightHarvested,
      'avgDailyGain': w.avgDailyGain,
      'harvestRecovery': w.harvestRecovery,
      'avgLiveWeight': w.avgLiveWeight,
      'feedConversionRatio': w.feedConversionRatio,
      'avgAgeHarvested': w.avgAgeHarvested,
      'broilerPerformanceIndex': w.broilerPerformanceIndex,
      'rangingAge': w.rangingAge,
      'totalEggsHarvested': w.totalEggsHarvested,
      'avgHarvestRate': w.avgHarvestRate,
      'weeklyHenDayEggProduction': w.weeklyHenDayEggProduction,
      'weeklyHDEPFile': w.weeklyHDEPFile,
      'daysUnderMolting': w.daysUnderMolting,
      'hasPest': w.hasPest,
      'pestOccurrence': w.pestOccurrence,
      'pestDate': w.pestDate,
      'pestMortality': w.pestMortality,
      'hasDisease': w.hasDisease,
      'diseaseOccurrence': w.diseaseOccurrence,
      'diseaseDate': w.diseaseDate,
      'diseaseMortality': w.diseaseMortality,
      'hasEnvHazard': w.hasEnvHazard,
      'envOccurrence': w.envOccurrence,
      'envDate': w.envDate,
      'envMortality': w.envMortality,
      'hasHumanInduced': w.hasHumanInduced,
      'humanOccurrence': w.humanOccurrence,
      'humanDate': w.humanDate,
      'humanMortality': w.humanMortality,
      'treatment': w.treatment,
      'attachedReport': w.attachedReport,
      'totalMortalities': w.totalMortalities,
      'rejectsCulled': w.rejectsCulled,
      'remainingStocks': w.remainingStocks,
      'feedType': w.feedType,
      'totalFeedConsumed': w.totalFeedConsumed,
      'feedPerDay': w.feedPerDay,
      'waterSources': w.waterSources,
      'sacksManureProduced': w.sacksManureProduced,
      'sacksManureSold': w.sacksManureSold,
      'sacksManureUsed': w.sacksManureUsed,
      'manurePricePerSack': w.manurePricePerSack,
      'farmPhoto': w.farmPhoto,
    };

    final currentFarmerName = w.farmerName.trim();
    final currentSaadId = w.saadIdNo.trim();
    final hasCurrentFarmer =
        currentFarmerName.isNotEmpty || currentSaadId.isNotEmpty;

    final candidates = <Map<String, dynamic>>[];
    if (hasCurrentFarmer) {
      candidates.add({
        ...commodity,
        'farmerName': currentFarmerName,
        'saadIdNo':
            currentSaadId.isNotEmpty ? currentSaadId : currentFarmerName,
      });
    }

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

  Future<void> _savePoultryRecordByFolders(
    Map<String, dynamic> jsonData,
    String productionType,
  ) async {
    print('\n📁 SAVING: Poultry record...');
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

    if (isCollective) {
      if (fcaName.isEmpty) {
        throw Exception('FCA name is required for collective records');
      }

      final sanitizedName = _sanitizeFolderName(fcaName);
      final mainDir = Directory('${monitoringDir.path}/$sanitizedName');

      if (!await mainDir.exists()) {
        await mainDir.create(recursive: true);
      }

      final groupJsonFile = File('${mainDir.path}/group.json');
      Map<String, dynamic> groupData = {};

      if (await groupJsonFile.exists()) {
        try {
          final existingContent = await groupJsonFile.readAsString();
          groupData = jsonDecode(existingContent) as Map<String, dynamic>;
        } catch (e) {
          print('⚠️ WARNING: Could not read existing group.json: $e');
          groupData = {};
        }
      }

      // Preserve existing completedCommodities and append new one
      final existingCommodities = (groupData['completedCommodities'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          [];

      // Extract current commodity fields directly from jsonData
      final currentCommodity = <String, dynamic>{};
      final commodityFields = [
        'breed',
        'inputsReceived',
        'inputsPurchased',
        'farmgatePrices',
        'stocksReceived',
        'dateReceived',
        'ageUponReceipt',
        'avgWeightUponReceipt',
        'totalProductiveCycle',
        'housingType',
        'landOwnership',
        'landOwnershipOther',
        'usufruct',
        'maleToFemaleRatio',
        'eggsProduced',
        'fertilEggs',
        'eggsIncubated',
        'eggsHatched',
        'hatchingRate',
        'mortalitiesAfterHatch',
        'chicksSold',
        'eggsSold',
        'harvestedBirds',
        'totalWeightHarvested',
        'avgDailyGain',
        'harvestRecovery',
        'avgLiveWeight',
        'feedConversionRatio',
        'avgAgeHarvested',
        'broilerPerformanceIndex',
        'rangingAge',
        'totalEggsHarvested',
        'avgHarvestRate',
        'weeklyHenDayEggProduction',
        'weeklyHDEPFile',
        'daysUnderMolting',
        'hasPest',
        'pestOccurrence',
        'pestDate',
        'pestMortality',
        'hasDisease',
        'diseaseOccurrence',
        'diseaseDate',
        'diseaseMortality',
        'hasEnvHazard',
        'envOccurrence',
        'envDate',
        'envMortality',
        'hasHumanInduced',
        'humanOccurrence',
        'humanDate',
        'humanMortality',
        'treatment',
        'attachedReport',
        'totalMortalities',
        'rejectsCulled',
        'remainingStocks',
        'feedType',
        'totalFeedConsumed',
        'feedPerDay',
        'waterSources',
        'sacksManureProduced',
        'sacksManureSold',
        'sacksManureUsed',
        'manurePricePerSack',
        'farmPhoto',
      ];

      for (final field in commodityFields) {
        if (jsonData.containsKey(field)) {
          currentCommodity[field] = jsonData[field];
        }
      }

      // Add GPS to commodity
      if (_photoLatitude != null && _photoLongitude != null) {
        currentCommodity['photoGPS'] = {
          'latitude': _photoLatitude!,
          'longitude': _photoLongitude!,
          'accuracy': _photoAccuracy ?? 0.0,
        };
      }

      existingCommodities.add(currentCommodity);

      // Merge trainings
      final mergedTrainings =
          (groupData['trainings'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final newTrainings =
          (jsonData['trainings'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      mergedTrainings.addAll(newTrainings);

      groupData['implementationType'] = jsonData['implementationType'];
      groupData['reportingPeriod'] = jsonData['reportingPeriod'];
      groupData['fcaName'] = fcaName;
      groupData['region'] = jsonData['region'];
      groupData['province'] = jsonData['province'];
      groupData['municipality'] = jsonData['municipality'];
      groupData['barangay'] = jsonData['barangay'];
      groupData['projectTitle'] = jsonData['projectTitle'];
      groupData['primaryIntervention'] = jsonData['primaryIntervention'];
      groupData['supportInterventions'] = jsonData['supportInterventions'];
      groupData['completedCommodities'] = existingCommodities;
      groupData['trainings'] = mergedTrainings;

      await groupJsonFile.writeAsString(jsonEncode(groupData));
      print('✅ Saved group.json - ${existingCommodities.length} commodities');

      // Save photo
      if (_photoPath.isNotEmpty) {
        final extension = _photoPath.split('.').last;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final photoDestPath = '${mainDir.path}/picture_$timestamp.$extension';
        await _savePhotoWithLocation(_photoPath, photoDestPath);
      }
    } else if (isHybrid || isIndividual) {
      if (farmerName.isEmpty) {
        throw Exception(
            'Farmer name is required for individual/hybrid records');
      }
      if (isHybrid && fcaName.isEmpty) {
        throw Exception('FCA name is required for hybrid records');
      }

      final groupName =
          isHybrid ? fcaName : (fcaName.isNotEmpty ? fcaName : farmerName);
      final sanitizedGroupName = _sanitizeFolderName(groupName);
      final groupDir = Directory('${monitoringDir.path}/$sanitizedGroupName');

      if (!await groupDir.exists()) {
        await groupDir.create(recursive: true);
      }

      // Save group.json with Step 01 data only
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
          'members': isHybrid ? members : <Map<String, dynamic>>[],
          'createdAt': DateTime.now().toIso8601String(),
        };
        await groupJsonFile.writeAsString(jsonEncode(groupData));
      }

      // Save farmer's data in their own folder
      if (farmerName.isNotEmpty) {
        final sanitizedFarmerName = _sanitizeFolderName(farmerName);
        final sanitizedSaadId =
            saadIdNo.isEmpty ? '' : '_${_sanitizeFolderName(saadIdNo)}';
        final farmerFolderName = '$sanitizedFarmerName$sanitizedSaadId';

        final farmerDir = Directory('${groupDir.path}/$farmerFolderName');
        if (!await farmerDir.exists()) {
          await farmerDir.create(recursive: true);
        }

        final farmerData = _buildFarmerData(jsonData, farmerName, saadIdNo);

        // Add GPS to first commodity
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
          }
        }

        final farmerJsonFile = File('${farmerDir.path}/data.json');

        if (await farmerJsonFile.exists()) {
          try {
            final existingContent = await farmerJsonFile.readAsString();
            final existingData =
                jsonDecode(existingContent) as Map<String, dynamic>;

            final existingCommodities =
                (existingData['completedCommodities'] as List?)
                        ?.cast<Map<String, dynamic>>() ??
                    [];

            final newCommodity = w.completedCommodities.isNotEmpty
                ? w.completedCommodities.last
                : <String, dynamic>{};

            if (newCommodity.isNotEmpty) {
              if (_photoLatitude != null && _photoLongitude != null) {
                newCommodity['photoGPS'] = {
                  'latitude': _photoLatitude!,
                  'longitude': _photoLongitude!,
                  'accuracy': _photoAccuracy ?? 0.0,
                };
              }
              existingCommodities.add(newCommodity);
            }

            final existingTrainings = (existingData['trainings'] as List?)
                    ?.cast<Map<String, dynamic>>() ??
                [];
            final mergedTrainings = [
              ...existingTrainings,
              ...w.trainings.map((item) => item.toJson()),
            ];

            final mergedData = Map<String, dynamic>.from(existingData);
            mergedData['completedCommodities'] = existingCommodities;
            mergedData['trainings'] = mergedTrainings;

            await farmerJsonFile.writeAsString(jsonEncode(mergedData));
          } catch (e) {
            print('⚠️ Could not merge: $e, overwriting');
            await farmerJsonFile.writeAsString(jsonEncode(farmerData));
          }
        } else {
          await farmerJsonFile.writeAsString(jsonEncode(farmerData));
        }

        // Save photo in farmer folder
        if (_photoPath.isNotEmpty) {
          final breed = (jsonData['breed'] as String? ?? '').trim();
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final photoDestPath = '${farmerDir.path}/${breed}_$timestamp.jpg';
          await _savePhotoWithLocation(_photoPath, photoDestPath);
        }

        // Update group.json members list
        try {
          if (await groupJsonFile.exists()) {
            final groupJsonContent =
                jsonDecode(await groupJsonFile.readAsString())
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
            }
          }
        } catch (e) {
          print('⚠️ Could not update members list: $e');
        }
      }
    } else {
      throw Exception('Unknown implementation type: $implementationType');
    }

    print('✅ Poultry record saved to folder structure');
  }

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
      'breed': jsonData['breed'],
      'inputsReceived': jsonData['inputsReceived'],
      'inputsPurchased': jsonData['inputsPurchased'],
      'farmgatePrices': jsonData['farmgatePrices'],
      'stocksReceived': jsonData['stocksReceived'],
      'dateReceived': jsonData['dateReceived'],
      'ageUponReceipt': jsonData['ageUponReceipt'],
      'avgWeightUponReceipt': jsonData['avgWeightUponReceipt'],
      'totalProductiveCycle': jsonData['totalProductiveCycle'],
      'housingType': jsonData['housingType'],
      'landOwnership': jsonData['landOwnership'],
      'landOwnershipOther': jsonData['landOwnershipOther'],
      'usufruct': jsonData['usufruct'],
      'maleToFemaleRatio': jsonData['maleToFemaleRatio'],
      'eggsProduced': jsonData['eggsProduced'],
      'fertilEggs': jsonData['fertilEggs'],
      'eggsIncubated': jsonData['eggsIncubated'],
      'eggsHatched': jsonData['eggsHatched'],
      'hatchingRate': jsonData['hatchingRate'],
      'mortalitiesAfterHatch': jsonData['mortalitiesAfterHatch'],
      'chicksSold': jsonData['chicksSold'],
      'eggsSold': jsonData['eggsSold'],
      'harvestedBirds': jsonData['harvestedBirds'],
      'totalWeightHarvested': jsonData['totalWeightHarvested'],
      'avgDailyGain': jsonData['avgDailyGain'],
      'harvestRecovery': jsonData['harvestRecovery'],
      'avgLiveWeight': jsonData['avgLiveWeight'],
      'feedConversionRatio': jsonData['feedConversionRatio'],
      'avgAgeHarvested': jsonData['avgAgeHarvested'],
      'broilerPerformanceIndex': jsonData['broilerPerformanceIndex'],
      'rangingAge': jsonData['rangingAge'],
      'totalEggsHarvested': jsonData['totalEggsHarvested'],
      'avgHarvestRate': jsonData['avgHarvestRate'],
      'weeklyHenDayEggProduction': jsonData['weeklyHenDayEggProduction'],
      'weeklyHDEPFile': jsonData['weeklyHDEPFile'],
      'daysUnderMolting': jsonData['daysUnderMolting'],
      'hasPest': jsonData['hasPest'],
      'pestOccurrence': jsonData['pestOccurrence'],
      'pestDate': jsonData['pestDate'],
      'pestMortality': jsonData['pestMortality'],
      'hasDisease': jsonData['hasDisease'],
      'diseaseOccurrence': jsonData['diseaseOccurrence'],
      'diseaseDate': jsonData['diseaseDate'],
      'diseaseMortality': jsonData['diseaseMortality'],
      'hasEnvHazard': jsonData['hasEnvHazard'],
      'envOccurrence': jsonData['envOccurrence'],
      'envDate': jsonData['envDate'],
      'envMortality': jsonData['envMortality'],
      'hasHumanInduced': jsonData['hasHumanInduced'],
      'humanOccurrence': jsonData['humanOccurrence'],
      'humanDate': jsonData['humanDate'],
      'humanMortality': jsonData['humanMortality'],
      'treatment': jsonData['treatment'],
      'attachedReport': jsonData['attachedReport'],
      'totalMortalities': jsonData['totalMortalities'],
      'rejectsCulled': jsonData['rejectsCulled'],
      'remainingStocks': jsonData['remainingStocks'],
      'feedType': jsonData['feedType'],
      'totalFeedConsumed': jsonData['totalFeedConsumed'],
      'feedPerDay': jsonData['feedPerDay'],
      'waterSources': jsonData['waterSources'],
      'sacksManureProduced': jsonData['sacksManureProduced'],
      'sacksManureSold': jsonData['sacksManureSold'],
      'sacksManureUsed': jsonData['sacksManureUsed'],
      'manurePricePerSack': jsonData['manurePricePerSack'],
      'farmPhoto': jsonData['farmPhoto'],
    };
  }

  Future<void> _savePhotoWithLocation(
      String sourcePhotoPath, String destPhotoPath) async {
    if (sourcePhotoPath.isEmpty) return;

    final photoFile = File(sourcePhotoPath);
    if (!await photoFile.exists()) return;

    try {
      await photoFile.copy(destPhotoPath);
      print('✅ Photo copied to: $destPhotoPath');

      if (_photoLatitude != null && _photoLongitude != null) {
        try {
          const platform = MethodChannel('com.example.da_monitoring_app/exif');
          await platform.invokeMethod('setExifGPS', {
            'imagePath': destPhotoPath,
            'latitude': _photoLatitude!,
            'longitude': _photoLongitude!,
            'accuracy': _photoAccuracy ?? 0.0,
          });
          print('✅ GPS metadata added: $_photoLatitude, $_photoLongitude');
        } catch (e) {
          print('❌ Failed to add GPS metadata: $e');
        }
      }
    } catch (e) {
      print('❌ Error saving photo: $e');
      rethrow;
    }
  }

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
        productionType: 'poultry',
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
            formTitle: 'POULTRY PRODUCTION',
            formSubtitle: 'Poultry Production Monitoring Form',
            currentStep: 6,
            totalSteps: 7,
            nextLabel: 'Submit',
            onNext: _onSubmit,
            onBack: () {
              _handleBack();
            },
            child: _buildForm()),
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
