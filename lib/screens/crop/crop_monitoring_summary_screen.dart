import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import '../../services/pending_draft_service.dart';
import '../../services/local_farmer_storage_service.dart';
import '../../theme/da_colors.dart';
import '../../routes/app_routes.dart';
import 'crop_step_wrapper.dart';

// ── Record model ──────────────────────────────────────────────────
class CropMonitoringRecord {
  final String farmerName;
  final String typeOfCrop;
  final String variety;
  final DateTime completedAt;

  const CropMonitoringRecord({
    required this.farmerName,
    required this.typeOfCrop,
    required this.variety,
    required this.completedAt,
  });
}

// ── Member model ──────────────────────────────────────────────────
class CropMember {
  final String name;
  final String? saadIdNo;
  bool monitored;
  List<String> commodities; // commodities monitored for this member

  CropMember({
    required this.name,
    this.saadIdNo,
    this.monitored = false,
    List<String>? commodities,
  }) : commodities = commodities ?? [];
}

class CropMonitoringSummaryScreen extends StatefulWidget {
  const CropMonitoringSummaryScreen({
    super.key,
    required this.wrapper,
    required this.completedRecords,
    this.members,
  });

  final CropStepWrapper wrapper;
  final List<CropMonitoringRecord> completedRecords;
  final List<CropMember>? members;

  @override
  State<CropMonitoringSummaryScreen> createState() =>
      _CropMonitoringSummaryScreenState();
}

class _CropMonitoringSummaryScreenState
    extends State<CropMonitoringSummaryScreen> {
  // ✅ Helper: Load existing group draft to preserve other farmers
  Future<Map<String, dynamic>?> _loadExistingGroupDraft() async {
    final allDrafts = await PendingDraftService.instance.getPendingDrafts();

    final wrapperImplementationType =
        (widget.wrapper.implementationType ?? '').trim().toLowerCase();
    final isWrapperGroup = wrapperImplementationType != 'individual';

    for (final draft in allDrafts) {
      final draftProductionType =
          (draft['productionType'] as String? ?? '').trim().toLowerCase();
      final draftImplementationType =
          (draft['implementationType'] as String? ?? '').trim().toLowerCase();
      final draftData = draft['data'] as Map<String, dynamic>? ?? {};

      final draftHasGroupMembers =
          ((draftData['membersByFarmerId'] as Map?)?.isNotEmpty == true) ||
              ((draftData['members'] as List?)?.isNotEmpty == true);
      final isDraftGroup = draftImplementationType == 'collective' ||
          draftImplementationType == 'hybrid' ||
          draftHasGroupMembers;

      if (draftProductionType != 'crop') {
        continue;
      }
      if (isWrapperGroup && !isDraftGroup) {
        continue;
      }
      if (!isWrapperGroup && !isDraftGroup) {
        if (draftImplementationType != wrapperImplementationType) {
          continue;
        }
      }

      final draftFcaName =
          (draftData['fcaName'] as String? ?? '').trim().toLowerCase();
      final draftReportingPeriod =
          (draftData['reportingPeriod'] as String? ?? '').trim().toLowerCase();
      final draftProjectTitle =
          (draftData['projectTitle'] as String? ?? '').trim().toLowerCase();

      final currentFcaName = widget.wrapper.fcaName.trim().toLowerCase();
      final currentReportingPeriod =
          widget.wrapper.reportingPeriod.trim().toLowerCase();
      final currentProjectTitle =
          widget.wrapper.projectTitle.trim().toLowerCase();

      if (draftFcaName == currentFcaName &&
          draftReportingPeriod == currentReportingPeriod &&
          draftProjectTitle == currentProjectTitle) {
        return draftData;
      }
    }
    return null;
  }

  int? _expandedCommodityIndex;

  Future<void> _done() async {
    print('🆔 _done() start:');
    print('   farmerName: "${widget.wrapper.farmerName}"');
    print('   saadIdNo: "${widget.wrapper.saadIdNo}"');
    print('   members: ${widget.wrapper.members}');
    print('   isAddFarmer: ${widget.wrapper.isAddFarmer}');
    print('   implementationType: ${widget.wrapper.implementationType}');
    try {
      // ✅ Accumulate current commodity if it has data
      if (widget.wrapper.implementationType?.toLowerCase() == 'individual') {
        print(
            '🔍 completedCommodities at _done start: ${widget.wrapper.completedCommodities.length}');
        print('🔍 typeOfCrop: ${widget.wrapper.typeOfCrop}');

        // ✅ CRITICAL: Load existing commodities AND trainings from farmer's saved data
        // so that new commodities accumulate properly (1 + 1 = 2, not always 1)
        // and trainings are preserved (not overwritten)
        // ONLY load if farmer already has saved data (not a brand new farmer)
        final farmerName = widget.wrapper.farmerName.trim();
        final saadId = widget.wrapper.saadIdNo.trim();
        final farmerId = saadId.isNotEmpty ? saadId : farmerName;
        if (farmerId.isNotEmpty &&
            widget.wrapper.completedCommodities.isEmpty &&
            !widget.wrapper.isAddFarmer) {
          print('   📂 Loading existing commodities for farmer: $farmerName');
          final existingCommodities =
              await LocalFarmerStorageService.instance.getFarmerCommodities(
            productionType: 'crop',
            groupName: widget.wrapper.fcaName,
            farmerName: farmerName,
            saadId: farmerId,
          );
          // ✅ CRITICAL FIX: Only add commodities that actually belong to THIS farmer
          // Filter by farmer name AND saadId to ensure we don't get commodities from other farmers
          if (existingCommodities.isNotEmpty) {
            final filteredCommodities = existingCommodities.where((c) {
              final cFarmerName = (c['farmerName'] as String? ?? '').trim();
              final cSaadId = (c['saadIdNo'] as String? ?? '').trim();
              // Only include if it matches THIS farmer
              if (farmerId.isNotEmpty && cSaadId.isNotEmpty) {
                return cSaadId == farmerId;
              } else if (farmerId.isEmpty && cFarmerName.isNotEmpty) {
                return cFarmerName == farmerName;
              }
              return false;
            }).toList();

            if (filteredCommodities.isNotEmpty) {
              print(
                  '      ✅ Loaded ${filteredCommodities.length} existing commodities for $farmerName');
              widget.wrapper.completedCommodities.addAll(filteredCommodities);
            } else {
              print(
                  '      ℹ️ No commodities found for this specific farmer (new farmer)');
            }
          }

          // ✅ Also load existing trainings so they don't get deleted
          print('   📂 Loading existing trainings for farmer: $farmerName');
          final existingTrainings =
              await LocalFarmerStorageService.instance.getFarmerTrainings(
            productionType: 'crop',
            groupName: widget.wrapper.fcaName,
            farmerName: farmerName,
            saadId: farmerId,
          );
          if (existingTrainings.isNotEmpty) {
            print(
                '      ✅ Loaded ${existingTrainings.length} existing trainings');
            // Merge existing trainings with current ones
            // Remove empty placeholder training if there are existing ones
            if (widget.wrapper.trainings.length == 1 &&
                widget.wrapper.trainings[0].name.isEmpty) {
              widget.wrapper.trainings.clear();
            }

            // Add existing trainings that are not already in current list
            final currentTrainingJsons = widget.wrapper.trainings
                .map((t) => jsonEncode(t.toJson()))
                .toSet();
            for (final existingTrainingMap in existingTrainings) {
              final trainingJson = jsonEncode(existingTrainingMap);
              if (!currentTrainingJsons.contains(trainingJson)) {
                // Convert Map to TrainingEntry and add
                final trainingEntry = TrainingEntry();
                trainingEntry.name = existingTrainingMap['name'] ?? '';
                trainingEntry.date = existingTrainingMap['date'] ?? '';
                trainingEntry.attendees =
                    existingTrainingMap['attendees'] ?? '';
                widget.wrapper.trainings.add(trainingEntry);
                print('      Added existing training: ${trainingEntry.name}');
              }
            }
          }
        }
      }
      if (widget.wrapper.typeOfCrop.isNotEmpty) {
        print(
            '📦 _done() accumulating commodity: ${widget.wrapper.typeOfCrop}');
        final commodity = {
          'typeOfCrop': widget.wrapper.typeOfCrop,
          'variety': widget.wrapper.variety,
          'inputsReceived': widget.wrapper.inputsReceived
              .map((item) => item.toJson())
              .toList(),
          'inputsPurchased': widget.wrapper.inputsPurchased
              .map((item) => item.toJson())
              .toList(),
          'totalCostPurchased': widget.wrapper.totalCostPurchased,
          'qtyVsArea': widget.wrapper.qtyVsArea,
          'croppingCycles': widget.wrapper.croppingCycles,
          'qtyVsCycles': widget.wrapper.qtyVsCycles,
          'peakVolume': widget.wrapper.peakVolume,
          'peakMonth': widget.wrapper.peakMonth,
          'volumesPerCycle': widget.wrapper.volumesPerCycle,
          'farmgatePrice': widget.wrapper.farmgatePrice,
          'totalLandArea': widget.wrapper.totalLandArea,
          'landOwnership': widget.wrapper.landOwnership,
          'landOwnershipOther': widget.wrapper.landOwnershipOther,
          'usufructAgreement': widget.wrapper.usufructAgreement,
          'landRemarks': widget.wrapper.landRemarks,
          'machineryType': widget.wrapper.machineryType,
          'machineryOther': widget.wrapper.machineryOther,
          'machineryRemarks': widget.wrapper.machineryRemarks,
          'landPrepCostPerCycle': widget.wrapper.landPrepCostPerCycle,
          'landPrepStartDate': widget.wrapper.landPrepStartDate,
          'landPrepDays': widget.wrapper.landPrepDays,
          'sourceOfWater': widget.wrapper.sourceOfWater,
          'plantingDate': widget.wrapper.plantingDate,
          'seedAmount': widget.wrapper.seedAmount,
          'seedUnit': widget.wrapper.seedUnit,
          'germinationRate': widget.wrapper.germinationRate,
          'goodGermination': widget.wrapper.goodGermination,
          'germinationReason': widget.wrapper.germinationReason,
          'fertilizerType': widget.wrapper.fertilizerType,
          'organicSource': widget.wrapper.organicSource,
          'organicBagsSAAD': widget.wrapper.organicBagsSAAD,
          'organicBagsCommercial': widget.wrapper.organicBagsCommercial,
          'organicTotalCost': widget.wrapper.organicTotalCost,
          'organicBagsCycle': widget.wrapper.organicBagsCycle,
          'organicFrequency': widget.wrapper.organicFrequency,
          'inorganicType': widget.wrapper.inorganicType,
          'inorganicBagsSAAD': widget.wrapper.inorganicBagsSAAD,
          'inorganicMeasure': widget.wrapper.inorganicMeasure,
          'inorganicTotalCost': widget.wrapper.inorganicTotalCost,
          'inorganicBagsCycle': widget.wrapper.inorganicBagsCycle,
          'inorganicFrequency': widget.wrapper.inorganicFrequency,
          'pesticideRequirement': widget.wrapper.pesticideRequirement,
          'landAreaCycles': widget.wrapper.landAreaCycles,
          'dateHarvestCycles': widget.wrapper.dateHarvestCycles,
          'quantityCycles': widget.wrapper.quantityCycles,
          'avgHarvestPerHa': widget.wrapper.avgHarvestPerHa,
          'harvestCostCycles': widget.wrapper.harvestCostCycles,
          'foodConsumptionPct': widget.wrapper.foodConsumptionPct,
          'processingRemarks': widget.wrapper.processingRemarks,
          'pestOccurrence': widget.wrapper.pestOccurrence,
          'pestDamageArea': widget.wrapper.pestDamageArea,
          'pestDamageHa': widget.wrapper.pestDamageHa,
          'pestTreatment': widget.wrapper.pestTreatment,
          'pestAttached': widget.wrapper.pestAttached,
          'hasDisease': widget.wrapper.hasDisease,
          'diseaseOccurrence': widget.wrapper.diseaseOccurrence,
          'diseaseDate': widget.wrapper.diseaseDate,
          'diseaseDamageArea': widget.wrapper.diseaseDamageArea,
          'diseaseDamageHa': widget.wrapper.diseaseDamageHa,
          'diseaseTreatment': widget.wrapper.diseaseTreatment,
          'diseaseAttached': widget.wrapper.diseaseAttached,
          'hasEnvHazard': widget.wrapper.hasEnvHazard,
          'envHazards': widget.wrapper.envHazards,
          'envDate': widget.wrapper.envDate,
          'envDamageArea': widget.wrapper.envDamageArea,
          'envDamageHa': widget.wrapper.envDamageHa,
          'envTreatment': widget.wrapper.envTreatment,
          'envAttached': widget.wrapper.envAttached,
          'hasHumanDamage': widget.wrapper.hasHumanDamage,
          'humanDamage': widget.wrapper.humanDamage,
          'humanMortality': widget.wrapper.humanMortality,
          'humanTreatment': widget.wrapper.humanTreatment,
          'humanAttached': widget.wrapper.humanAttached,
          'farmPhoto': widget.wrapper.farmPhoto,
          'trainings': widget.wrapper.trainings.map((t) => t.toJson()).toList(),
        };

        // ✅ FIX: only accumulate if typeOfCrop is set AND not already in completedCommodities
        // After _addCommodityForMember, typeOfCrop is reset so this block is skipped correctly
        // The commodity was already added to completedCommodities before navigation
        final fp =
            '${widget.wrapper.typeOfCrop}|${widget.wrapper.variety}|${widget.wrapper.plantingDate}';
        final alreadyExists = widget.wrapper.completedCommodities.any((e) =>
            '${e['typeOfCrop']}|${e['variety']}|${e['plantingDate']}' == fp);
        if (!alreadyExists) {
          final currentFarmerName = widget.wrapper.farmerName.trim();
          final currentSaadId = widget.wrapper.saadIdNo.trim();
          final hasCurrentFarmer =
              currentSaadId.isNotEmpty || currentFarmerName.isNotEmpty;

          if (hasCurrentFarmer) {
            widget.wrapper.completedCommodities.add({
              ...commodity,
              'farmerName': currentFarmerName,
              'saadIdNo':
                  currentSaadId.isNotEmpty ? currentSaadId : currentFarmerName,
            });
            print(
                '   ✅ Added to completedCommodities: farmerName="$currentFarmerName", saadIdNo="${currentSaadId.isNotEmpty ? currentSaadId : currentFarmerName}"');
          } else if (widget.wrapper.members.isNotEmpty) {
            for (final member in widget.wrapper.members) {
              final memberName = (member['name'] as String? ?? '').trim();
              final memberSaadId = (member['saadIdNo'] as String? ?? '').trim();
              if (memberName.isNotEmpty) {
                widget.wrapper.completedCommodities.add({
                  ...commodity,
                  'farmerName': memberName,
                  'saadIdNo':
                      memberSaadId.isNotEmpty ? memberSaadId : memberName,
                });
                print(
                    '   ✅ Added to completedCommodities: farmerName="$memberName", saadIdNo="${memberSaadId.isNotEmpty ? memberSaadId : memberName}"');
              }
            }
          } else {
            widget.wrapper.completedCommodities.add({
              ...commodity,
              'farmerName': currentFarmerName,
              'saadIdNo': currentSaadId,
            });
            print(
                '   ✅ Added to completedCommodities: farmerName="$currentFarmerName", saadIdNo="$currentSaadId"');
          }
        } // end alreadyExists check
      }

      // ✅ Preserve existing group draft data when saving from summary
      Map<String, dynamic> membersByFarmerId = {};
      final saadId = widget.wrapper.saadIdNo.trim();
      final farmerName = widget.wrapper.farmerName.trim();
      final hasCurrentFarmer = saadId.isNotEmpty || farmerName.isNotEmpty;

      // ✅ Create trainingsData NOW - after merging existing trainings with current ones
      final trainingsData =
          widget.wrapper.trainings.map((t) => t.toJson()).toList();

      final isGroupRecord =
          widget.wrapper.implementationType?.toLowerCase() != 'individual';
      Map<String, dynamic>? existingDraftData;
      if (isGroupRecord) {
        existingDraftData = await _loadExistingGroupDraft();
        if (existingDraftData != null &&
            existingDraftData['membersByFarmerId'] is Map) {
          membersByFarmerId.addAll(Map<String, dynamic>.from(
              existingDraftData['membersByFarmerId'] as Map<String, dynamic>));
        }
      }

      if (widget.wrapper.implementationType == 'individual') {
        // Individual: Only current farmer - DO NOT build membersByFarmerId
        // This prevents individual records from being treated as group records
        membersByFarmerId = {}; // Keep empty for individual records
      } else {
        // Collective/Hybrid: Add/update farmers
        // ✅ CRITICAL: Preserve all members from existing draft and wrapper state
        // Start from any existing saved group farmers
        if (widget.wrapper.members.isNotEmpty) {
          for (final member in widget.wrapper.members) {
            final memberName = (member['name'] as String?)?.trim() ?? '';
            final memberSaadId = (member['saadIdNo'] as String?)?.trim() ??
                member['saadId'] as String? ??
                '';
            final memberId =
                memberSaadId.isNotEmpty ? memberSaadId : memberName;
            if (memberId.isNotEmpty &&
                !membersByFarmerId.containsKey(memberId)) {
              membersByFarmerId[memberId] = {
                'farmerName': memberName,
                'saadIdNo': memberSaadId,
                'trainings': <Map<String, dynamic>>[],
                'farmPhoto': '',
                'addedDate': DateTime.now().toIso8601String(),
              };
            }
          }
        }

        final farmerId = saadId.isNotEmpty ? saadId : farmerName;
        if (farmerId.isNotEmpty) {
          if (!membersByFarmerId.containsKey(farmerId)) {
            print('🆕 Adding NEW farmer to group: $farmerName ($farmerId)');
            membersByFarmerId[farmerId] = {
              'farmerName': farmerName,
              'saadIdNo': saadId,
              'trainings': trainingsData,
              'farmPhoto': widget.wrapper.farmPhoto,
              'addedDate': DateTime.now().toIso8601String(),
            };
          } else {
            print('📝 Updating EXISTING farmer: $farmerName ($farmerId)');
            final existing =
                membersByFarmerId[farmerId] as Map<String, dynamic>;
            final oldTrainings = (existing['trainings'] as List?) ?? [];
            final mergedTrainings = <Map<String, dynamic>>[
              ...oldTrainings.cast<Map<String, dynamic>>(),
            ];
            for (final newTraining in trainingsData) {
              bool exists = mergedTrainings
                  .any((old) => jsonEncode(old) == jsonEncode(newTraining));
              if (!exists) {
                mergedTrainings.add(newTraining);
              }
            }
            existing['trainings'] = mergedTrainings;
            existing['farmPhoto'] = widget.wrapper.farmPhoto;
          }
        }

        print(
            '📋 Group farmers after processing: ${membersByFarmerId.keys.toList()}');
      }

      // ✅ Preserve previous member commodities and only update from current wrapper when available
      final previousMemberCommodities = <String, List<Map<String, dynamic>>>{};
      if (existingDraftData != null &&
          existingDraftData['membersByFarmerId'] is Map) {
        final rawPrevMembers = Map<String, dynamic>.from(
            existingDraftData['membersByFarmerId'] as Map<String, dynamic>);
        for (final entry in rawPrevMembers.entries) {
          final rawMember = entry.value;
          if (rawMember is Map<String, dynamic>) {
            final previousCommodities = <Map<String, dynamic>>[];
            final rawCommodityList =
                rawMember['completedCommodities'] as List? ??
                    rawMember['completedBatches'] as List? ??
                    [];
            for (final item in rawCommodityList) {
              if (item is Map<String, dynamic>) {
                previousCommodities.add(item);
              } else if (item is Map) {
                previousCommodities.add(Map<String, dynamic>.from(item));
              }
            }
            if (previousCommodities.isNotEmpty) {
              previousMemberCommodities[entry.key] = previousCommodities;
            }
          }
        }
      }

      for (final memberId in membersByFarmerId.keys) {
        final memberData = membersByFarmerId[memberId] as Map<String, dynamic>;
        final farmerName = memberData['farmerName'] as String;
        final saadId = memberId;
        final memberCommodities =
            widget.wrapper.completedCommodities.where((c) {
          final cSaadId = (c['saadIdNo'] as String? ?? '').trim();
          final cFarmerName = (c['farmerName'] as String? ?? '').trim();
          if (saadId.isNotEmpty && cSaadId.isNotEmpty) {
            return cSaadId == saadId;
          } else if (saadId.isEmpty && cFarmerName.isNotEmpty) {
            return cFarmerName == farmerName;
          }
          return false;
        }).toList();

        if (memberCommodities.isNotEmpty) {
          memberData['completedCommodities'] = memberCommodities;
        } else if (previousMemberCommodities.containsKey(memberId)) {
          memberData['completedCommodities'] =
              previousMemberCommodities[memberId]!;
        } else {
          memberData['completedCommodities'] = <Map<String, dynamic>>[];
        }
      }

      // ✅ Save with membersByFarmerId for ALL types
      var dataToSave = widget.wrapper.toJson();

      // CRITICAL: For individual/hybrid GROUP records (not individual farmers),
      // save ONLY project background at root level. Commodity data goes in membersByFarmerId.
      if (widget.wrapper.implementationType?.toLowerCase() == 'individual') {
        final farmerId = saadId.isNotEmpty ? saadId : farmerName;

        print('🔍 DEBUG _done() individual branch:');
        print('   Entered individual save block');
        print('   farmerName: "$farmerName", farmerId: "$farmerId"');
        print(
            '   completedCommodities count: ${widget.wrapper.completedCommodities.length}');

        for (var i = 0; i < widget.wrapper.completedCommodities.length; i++) {
          final c = widget.wrapper.completedCommodities[i];
          print(
              '   [$i] cFarmerName="${c['farmerName']}", cSaadId="${c['saadIdNo']}"');
        }

        // ✅ Only save NEW commodities — ones not already in data.json
        final existingOnDisk =
            await LocalFarmerStorageService.instance.getFarmerCommodities(
          productionType: 'crop',
          groupName: widget.wrapper.fcaName,
          farmerName: farmerName,
          saadId: farmerId,
        );

        final existingFingerprints = existingOnDisk.map((c) {
          final crop = (c['typeOfCrop'] as String? ?? '').trim();
          final variety = (c['variety'] as String? ?? '').trim();
          final planting = (c['plantingDate'] as String? ?? '').trim();
          return '$crop|$variety|$planting';
        }).toSet();

        for (final commodity in widget.wrapper.completedCommodities) {
          final cFarmerName = (commodity['farmerName'] as String? ?? '').trim();
          final cSaadId = (commodity['saadIdNo'] as String? ?? '').trim();

          print(
              '   📦 Checking commodity: cFarmerName="$cFarmerName", cSaadId="$cSaadId"');

          // Only save commodities belonging to this farmer
          if (cFarmerName != farmerName && cSaadId != farmerId) {
            print(
                '      ⏭️ Skipping (no match to "$farmerName" or "$farmerId")');
            continue;
          }

          final crop = (commodity['typeOfCrop'] as String? ?? '').trim();
          final variety = (commodity['variety'] as String? ?? '').trim();
          final planting = (commodity['plantingDate'] as String? ?? '').trim();
          final fingerprint = '$crop|$variety|$planting';
          if (existingFingerprints.contains(fingerprint)) {
            print('⏭️ Skipping already-saved commodity: $fingerprint');
            continue;
          }

          print('      ✅ Appending commodity: $fingerprint');
          // ✅ Always pass trainings (both new and existing merged together)
          final trainingsDataForCommodity =
              widget.wrapper.trainings.map((t) => t.toJson()).toList();
          print('      Trainings to save: ${trainingsDataForCommodity.length}');
          await LocalFarmerStorageService.instance.appendCommodityToFarmer(
            productionType: 'crop',
            groupName: widget.wrapper.fcaName,
            farmerName: farmerName,
            saadId: farmerId,
            newCommodity: commodity,
            farmerMeta: {
              'trainings': trainingsDataForCommodity,
            },
          );
          print('✅ Saved new commodity: $fingerprint');
        }

        // ✅ For the draft service, ONLY save project background
        // NO membersByFarmerId for individual farmers — that would cause group merging!
        // Commodities already saved to data.json above
        dataToSave['farmerName'] = farmerName;
        dataToSave['saadIdNo'] = saadId;

        // ✅ If this farmer belongs to a group (has siblings),
        // populate membersByFarmerId so data stays isolated per farmer.
        // Only leave it empty for a truly solo individual with no group.
        final isGroupedIndividual = widget.wrapper.members.length > 1 ||
            widget.wrapper.isAddFarmer == true;

        if (isGroupedIndividual && farmerId.isNotEmpty) {
          final trainingsData =
              widget.wrapper.trainings.map((t) => t.toJson()).toList();
          final thisFarmerCommodities =
              widget.wrapper.completedCommodities.where((c) {
            final cSaadId = (c['saadIdNo'] as String? ?? '').trim();
            final cName = (c['farmerName'] as String? ?? '').trim();
            return cSaadId == farmerId || cName == farmerName;
          }).toList();

          dataToSave['membersByFarmerId'] = {
            farmerId: {
              'farmerName': farmerName,
              'saadIdNo': saadId,
              'completedCommodities': thisFarmerCommodities,
              'completedBatches': <Map<String, dynamic>>[],
              'trainings': trainingsData,
              'farmPhoto': widget.wrapper.farmPhoto,
            },
          };

          // Also populate members list for group matching
          dataToSave['members'] = widget.wrapper.members.isNotEmpty
              ? widget.wrapper.members
              : [
                  {'name': farmerName, 'saadIdNo': saadId}
                ];
        } else {
          // Truly solo individual — no group
          dataToSave['membersByFarmerId'] = {};
          dataToSave['members'] = [];
        }
        // Clear commodity fields from root — they live in data.json now
        dataToSave['completedCommodities'] = [];
        dataToSave['typeOfCrop'] = '';
        dataToSave['variety'] = '';

        print('👤 INDIVIDUAL: Saved commodities to data.json for $farmerName');
      } else if (widget.wrapper.implementationType?.toLowerCase() == 'hybrid') {
        // Hybrid/Individual GROUP record - keep ONLY project background at root
        dataToSave = {
          'implementationType': widget.wrapper.implementationType,
          'reportingPeriod': widget.wrapper.reportingPeriod,
          'fcaName': widget.wrapper.fcaName,
          'region': widget.wrapper.region,
          'province': widget.wrapper.province,
          'municipality': widget.wrapper.municipality,
          'barangay': widget.wrapper.barangay,
          'projectTitle': widget.wrapper.projectTitle,
          'primaryIntervention': widget.wrapper.primaryIntervention,
          'supportInterventions': widget.wrapper.supportInterventions,
          'membersByFarmerId': membersByFarmerId,
          'members': membersByFarmerId.entries.map((entry) {
            final farmerData = entry.value as Map<String, dynamic>;
            return {
              'name': farmerData['farmerName'] ?? '',
              'saadIdNo': entry.key,
            };
          }).toList(),
        };
        print('👥 HYBRID/GROUP RECORD: Only project background at root');
      } else if (widget.wrapper.implementationType?.toLowerCase() ==
          'collective') {
        // Collective record - use membersByFarmerId for sync
        dataToSave['membersByFarmerId'] = membersByFarmerId;
        dataToSave['members'] = membersByFarmerId.entries.map((entry) {
          final farmerData = entry.value as Map<String, dynamic>;
          return {
            'name': farmerData['farmerName'] ?? '',
            'saadIdNo': entry.key,
          };
        }).toList();
        print('👥 COLLECTIVE RECORD: Using membersByFarmerId for sync');
      }
      // Update members list to include all farmers for local folder saving
      if (widget.wrapper.implementationType?.toLowerCase() != 'individual') {
        print('📁 Members list for folder save: ${dataToSave['members']}');
        print('📁 Complete members data:');
        for (final m in dataToSave['members']) {
          print('   - ${m['name']} (${m['saadIdNo']})');
        }
      }

      print('💾 === SAVING CROP RECORD ===');
      print('   Production Type: crop');
      print('   Implementation Type: ${widget.wrapper.implementationType}');
      print('   FCA Name: ${dataToSave['fcaName']}');
      print('   Total Farmers: ${membersByFarmerId.length}');
      print('   Farmers: ${membersByFarmerId.keys.toList()}');

      try {
        print('   📌 Calling PendingDraftService.saveDraft()...');
        await PendingDraftService.instance.saveDraft(
          productionType: 'crop',
          implementationType: widget.wrapper.implementationType ?? '',
          data: dataToSave,
        );
        print('   ✅ PendingDraftService.saveDraft() completed successfully');
      } catch (e) {
        print('   ❌ ERROR in saveDraft: $e');
        print('   Error type: ${e.runtimeType}');
        print('   Stacktrace: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving record: ${e.toString()}',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Saved successfully!',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor: DAColors.greenMid,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: ${e.toString()}',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Widget _buildCommodityList(String label, dynamic items) {
    final list = <Map<String, dynamic>>[];
    if (items is List) {
      for (final item in items) {
        if (item is Map<String, dynamic>) {
          list.add(item);
        } else if (item is Map) {
          list.add(Map<String, dynamic>.from(item));
        }
      }
    }
    if (list.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: DAColors.textDark)),
        const SizedBox(height: 8),
        ...list.map((item) {
          final name = (item['name'] as String? ?? '').trim();
          final quantity = (item['quantity'] as String? ?? '').trim();
          final cost = (item['cost'] as String? ?? '').trim();
          final pieces = <String>[];
          if (name.isNotEmpty) pieces.add(name);
          if (quantity.isNotEmpty) pieces.add('Qty: $quantity');
          if (cost.isNotEmpty) pieces.add('Cost: $cost');
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              pieces.isEmpty ? '—' : pieces.join(' • '),
              style: GoogleFonts.poppins(
                  fontSize: 12, color: DAColors.textMuted, height: 1.5),
            ),
          );
        }),
      ],
    );
  }

  // Mock members — in real app pass from FCA data
  late final List<CropMember> _members = widget.members ??
      (widget.wrapper.implementationType == 'collective'
          ? []
          : (widget.wrapper.members.isNotEmpty
              ? widget.wrapper.members
                  .map((member) => CropMember(
                        name: (member['name'] as String?)?.trim() ?? '',
                        saadIdNo: (member['saadIdNo'] as String?)?.trim() ?? '',
                      ))
                  .where((m) => m.name.isNotEmpty)
                  .toList()
              : (widget.wrapper.farmerName.trim().isNotEmpty
                  ? [
                      CropMember(
                        name: widget.wrapper.farmerName.trim(),
                        saadIdNo: widget.wrapper.saadIdNo.trim().isEmpty
                            ? null
                            : widget.wrapper.saadIdNo.trim(),
                      )
                    ]
                  : [])));

  // ── Add Another Farmer ────────────────────────────────────────
  // Only for individual/hybrid — saves current farmer first, then adds new one
  Future<void> _addAnotherFarmer() async {
    // CRITICAL: Before saving, accumulate current farmer's commodity data
    // This ensures all farmers stay in ONE group record (no duplicates)
    if (widget.wrapper.farmerName.isNotEmpty &&
        widget.wrapper.typeOfCrop.isNotEmpty) {
      final commodity = {
        'farmerName': widget.wrapper.farmerName,
        'saadIdNo': widget.wrapper.saadIdNo,
        'typeOfCrop': widget.wrapper.typeOfCrop,
        'variety': widget.wrapper.variety,
        'inputsReceived':
            widget.wrapper.inputsReceived.map((item) => item.toJson()).toList(),
        'inputsPurchased': widget.wrapper.inputsPurchased
            .map((item) => item.toJson())
            .toList(),
        'totalCostPurchased': widget.wrapper.totalCostPurchased,
        'qtyVsArea': widget.wrapper.qtyVsArea,
        'croppingCycles': widget.wrapper.croppingCycles,
        'qtyVsCycles': widget.wrapper.qtyVsCycles,
        'peakVolume': widget.wrapper.peakVolume,
        'peakMonth': widget.wrapper.peakMonth,
        'volumesPerCycle': widget.wrapper.volumesPerCycle,
        'farmgatePrice': widget.wrapper.farmgatePrice,
        'totalLandArea': widget.wrapper.totalLandArea,
        'landOwnership': widget.wrapper.landOwnership,
        'landOwnershipOther': widget.wrapper.landOwnershipOther,
        'usufructAgreement': widget.wrapper.usufructAgreement,
        'landRemarks': widget.wrapper.landRemarks,
        'machineryType': widget.wrapper.machineryType,
        'machineryOther': widget.wrapper.machineryOther,
        'machineryRemarks': widget.wrapper.machineryRemarks,
        'landPrepCostPerCycle': widget.wrapper.landPrepCostPerCycle,
        'landPrepStartDate': widget.wrapper.landPrepStartDate,
        'landPrepDays': widget.wrapper.landPrepDays,
        'sourceOfWater': widget.wrapper.sourceOfWater,
        'plantingDate': widget.wrapper.plantingDate,
        'seedAmount': widget.wrapper.seedAmount,
        'seedUnit': widget.wrapper.seedUnit,
        'germinationRate': widget.wrapper.germinationRate,
        'goodGermination': widget.wrapper.goodGermination,
        'germinationReason': widget.wrapper.germinationReason,
        'fertilizerType': widget.wrapper.fertilizerType,
        'organicSource': widget.wrapper.organicSource,
        'organicBagsSAAD': widget.wrapper.organicBagsSAAD,
        'organicBagsCommercial': widget.wrapper.organicBagsCommercial,
        'organicTotalCost': widget.wrapper.organicTotalCost,
        'organicBagsCycle': widget.wrapper.organicBagsCycle,
        'organicFrequency': widget.wrapper.organicFrequency,
        'inorganicType': widget.wrapper.inorganicType,
        'inorganicBagsSAAD': widget.wrapper.inorganicBagsSAAD,
        'inorganicMeasure': widget.wrapper.inorganicMeasure,
        'inorganicTotalCost': widget.wrapper.inorganicTotalCost,
        'inorganicBagsCycle': widget.wrapper.inorganicBagsCycle,
        'inorganicFrequency': widget.wrapper.inorganicFrequency,
        'pesticideRequirement': widget.wrapper.pesticideRequirement,
        'landAreaCycles': widget.wrapper.landAreaCycles,
        'dateHarvestCycles': widget.wrapper.dateHarvestCycles,
        'quantityCycles': widget.wrapper.quantityCycles,
        'avgHarvestPerHa': widget.wrapper.avgHarvestPerHa,
        'harvestCostCycles': widget.wrapper.harvestCostCycles,
        'foodConsumptionPct': widget.wrapper.foodConsumptionPct,
        'processingRemarks': widget.wrapper.processingRemarks,
        'pestOccurrence': widget.wrapper.pestOccurrence,
        'pestDamageArea': widget.wrapper.pestDamageArea,
        'pestDamageHa': widget.wrapper.pestDamageHa,
        'pestTreatment': widget.wrapper.pestTreatment,
        'pestAttached': widget.wrapper.pestAttached,
        'hasDisease': widget.wrapper.hasDisease,
        'diseaseOccurrence': widget.wrapper.diseaseOccurrence,
        'diseaseDate': widget.wrapper.diseaseDate,
        'diseaseDamageArea': widget.wrapper.diseaseDamageArea,
        'diseaseDamageHa': widget.wrapper.diseaseDamageHa,
        'diseaseTreatment': widget.wrapper.diseaseTreatment,
        'diseaseAttached': widget.wrapper.diseaseAttached,
        'hasEnvHazard': widget.wrapper.hasEnvHazard,
        'envHazards': widget.wrapper.envHazards,
        'envDate': widget.wrapper.envDate,
        'envDamageArea': widget.wrapper.envDamageArea,
        'envDamageHa': widget.wrapper.envDamageHa,
        'envTreatment': widget.wrapper.envTreatment,
        'envAttached': widget.wrapper.envAttached,
        'hasHumanDamage': widget.wrapper.hasHumanDamage,
        'humanDamage': widget.wrapper.humanDamage,
        'humanMortality': widget.wrapper.humanMortality,
        'humanTreatment': widget.wrapper.humanTreatment,
        'humanAttached': widget.wrapper.humanAttached,
      };

      final candidateJson = jsonEncode(commodity);
      final exists = widget.wrapper.completedCommodities.any(
        (item) => jsonEncode(item) == candidateJson,
      );
      if (!exists) {
        widget.wrapper.completedCommodities.add(commodity);
      }
    }

    // 🆔 CRITICAL: Capture current farmer's identity BEFORE any modifications
    // This ensures we correctly identify which trainings/photo belong to the current farmer
    final currentFarmerName = widget.wrapper.farmerName.trim();
    final currentFarmerSaadId = widget.wrapper.saadIdNo.trim();
    final currentFarmerId = currentFarmerSaadId.isNotEmpty
        ? currentFarmerSaadId
        : currentFarmerName;

    // 📸 CRITICAL: Capture current farmer's photo/trainings BEFORE saving
    // This ensures the current farmer's data doesn't get overwritten by old draft data
    final currentFarmerPhoto = widget.wrapper.farmPhoto.trim();
    final currentFarmerTrainings =
        widget.wrapper.trainings.map((t) => t.toJson()).toList();
    print('🔍 DEBUG _addAnotherFarmer:');
    print('   currentFarmerId: "$currentFarmerId"');
    print('   currentFarmerPhoto: "$currentFarmerPhoto"');
    print('   currentFarmerTrainings: ${currentFarmerTrainings.length}');

    // CRITICAL: Add current farmer to members array BEFORE saving
    // This ensures all farmers are preserved in the saved group record
    if (widget.wrapper.implementationType != 'individual' &&
        currentFarmerName.isNotEmpty &&
        !widget.wrapper.members
            .any((m) => (m['name'] as String?)?.trim() == currentFarmerName)) {
      widget.wrapper.members.add({
        'name': currentFarmerName,
        'saadIdNo': currentFarmerSaadId,
        'fcaName': widget.wrapper.fcaName.trim(),
      });
    }

    // CRITICAL: Clear farmerName for group records BEFORE saving
    // This ensures the saved record is recognized as a group in member_records_screen
    if (widget.wrapper.implementationType != 'individual' &&
        widget.wrapper.members.isNotEmpty) {
      widget.wrapper.farmerName = '';
    }

    // CRITICAL: Build membersByFarmerId BEFORE saving to ensure sync to Firebase
    // This converts the members array into membersByFarmerId map for proper Firebase hierarchy
    Map<String, dynamic> membersByFarmerId = {};

    // ✅ FIX: Load existing draft to preserve previously saved commodity data
    final existingDraftData = await _loadExistingGroupDraft();
    final existingMembersByFarmerId =
        existingDraftData?['membersByFarmerId'] as Map<String, dynamic>? ?? {};

    // ONLY for non-individual types
    if (widget.wrapper.implementationType != 'individual') {
      for (final member in widget.wrapper.members) {
        final memberName = (member['name'] as String? ?? '').trim();
        final memberSaadId = (member['saadIdNo'] as String?)?.trim() ?? '';
        final memberId = memberSaadId.isNotEmpty ? memberSaadId : memberName;
        if (memberId.isNotEmpty) {
          // 🆔 CRITICAL: Use CAPTURED current farmer data, not wrapper (which may be stale)
          final isCurrentFarmer = currentFarmerId.isNotEmpty &&
              (memberId == currentFarmerId || memberName == currentFarmerName);

          // ✅ FIX: For current farmer, use FRESHLY CAPTURED trainings/photo
          // For old farmers, preserve from existing draft
          final existingMemberData =
              existingMembersByFarmerId[memberId] as Map<String, dynamic>?;
          final preservedTrainings = isCurrentFarmer
              ? currentFarmerTrainings // 🔥 Use CAPTURED, not wrapper.trainings
              : (existingMemberData?['trainings'] as List? ??
                  <Map<String, dynamic>>[]);
          final preservedPhoto = isCurrentFarmer
              ? currentFarmerPhoto // 🔥 Use CAPTURED, not wrapper.farmPhoto
              : ((existingMemberData?['farmPhoto'] as String?)?.trim() ?? '');

          print(
              '   Member "$memberName" ($memberId): isCurrentFarmer=$isCurrentFarmer, trainings=${preservedTrainings.length}, photo=$preservedPhoto');

          membersByFarmerId[memberId] = {
            'farmerName': memberName,
            'saadIdNo': memberSaadId,
            'trainings': preservedTrainings,
            'farmPhoto': preservedPhoto,
            'addedDate': DateTime.now().toIso8601String(),
            // ✅ FIX: Preserve existing commodities for farmers already in the draft
            'completedCommodities':
                existingMemberData?['completedCommodities'] as List? ??
                    <Map<String, dynamic>>[],
          };
        }
      }

      // 🆕 CRITICAL: NOW filter NEW commodities from wrapper and assign to correct farmer
      // This ensures new commodities only go to the farmer they belong to, not all farmers
      for (final memberId in membersByFarmerId.keys) {
        final memberData = membersByFarmerId[memberId] as Map<String, dynamic>;
        final farmerName = memberData['farmerName'] as String;
        final saadId = memberId;

        // Find NEW commodities for THIS specific farmer
        final newCommoditiesForFarmer =
            widget.wrapper.completedCommodities.where((c) {
          final cSaadId = (c['saadIdNo'] as String? ?? '').trim();
          final cFarmerName = (c['farmerName'] as String? ?? '').trim();

          // Match by ID first (most reliable)
          if (saadId.isNotEmpty && cSaadId.isNotEmpty) {
            return cSaadId == saadId;
          }
          // Match by name if no ID
          else if (saadId.isEmpty && cFarmerName.isNotEmpty) {
            return cFarmerName == farmerName;
          }
          return false;
        }).toList();

        // Merge existing + new commodities for this farmer
        final existingCommodities =
            (memberData['completedCommodities'] as List?) ??
                <Map<String, dynamic>>[];
        final allCommoditiesForFarmer = <Map<String, dynamic>>[
          ...existingCommodities.cast<Map<String, dynamic>>(),
          ...newCommoditiesForFarmer,
        ];

        // Remove duplicates based on fingerprint
        final seen = <String>{};
        final uniqueCommodities = <Map<String, dynamic>>[];
        for (final comm in allCommoditiesForFarmer) {
          final crop = (comm['typeOfCrop'] as String? ?? '').trim();
          final variety = (comm['variety'] as String? ?? '').trim();
          final planting = (comm['plantingDate'] as String? ?? '').trim();
          final fp = '$crop|$variety|$planting';
          if (!seen.contains(fp)) {
            seen.add(fp);
            uniqueCommodities.add(comm);
          }
        }

        memberData['completedCommodities'] = uniqueCommodities;
        print(
            '   ✅ Assigned ${uniqueCommodities.length} commodities to $farmerName ($saadId)');
      }
    }

    final dataToSave = widget.wrapper.toJson();

    // CRITICAL: For individual farmers, preserve identity and clear members
    if (widget.wrapper.implementationType == 'individual') {
      dataToSave['farmerName'] = currentFarmerName; // Use CAPTURED name
      dataToSave['saadIdNo'] = currentFarmerSaadId; // Use CAPTURED ID
      dataToSave['farmPhoto'] = currentFarmerPhoto; // Use CAPTURED photo
      dataToSave['trainings'] =
          currentFarmerTrainings; // Use CAPTURED trainings
      dataToSave['members'] = [];
      dataToSave['membersByFarmerId'] = {};
      print(
          '👤 _addAnotherFarmer: Saving individual farmer: $currentFarmerName ($currentFarmerSaadId)');
      print('   farmPhoto: "$currentFarmerPhoto"');
      print('   trainings: ${currentFarmerTrainings.length}');
    } else {
      // 👥 GROUP TYPE: Use membersByFarmerId for all farmers
      dataToSave['membersByFarmerId'] = membersByFarmerId;
      dataToSave['trainings'] = [];
      dataToSave['farmPhoto'] = '';
      print(
          '👥 _addAnotherFarmer: Saving group with members: ${membersByFarmerId.keys.toList()}');
    }

    // CRITICAL: Save to ONE group record (fcaName-based dedup)
    // This ensures all farmers in the group are stored together WITH membersByFarmerId for sync
    print('💾 _addAnotherFarmer: About to save draft with data:');
    print('   farmerName: ${dataToSave['farmerName']}');
    print('   saadIdNo: ${dataToSave['saadIdNo']}');
    print('   members: ${dataToSave['members']}');
    print(
        '   membersByFarmerId keys: ${(dataToSave['membersByFarmerId'] as Map?)?.keys.toList()}');
    await PendingDraftService.instance.saveDraft(
      productionType: 'crop',
      implementationType: widget.wrapper.implementationType ?? '',
      data: dataToSave,
    );

    if (!mounted) return;

    widget.wrapper.resetCommodityStageFields();
    widget.wrapper.resetTrainingAndPhoto();

    // Create new wrapper for next farmer with group info preserved
    // Commodity fields are cleared for new farmer entry
    print('🆔 Before creating next wrapper:');
    print('   current saadIdNo: "${widget.wrapper.saadIdNo}"');
    print('   current members: ${widget.wrapper.members}');
    print('   current farmerName: "${widget.wrapper.farmerName}"');

    // ✅ Only carry forward members that belong to THIS group
    final currentFcaName = widget.wrapper.fcaName.trim().toLowerCase();
    final filteredMembers = widget.wrapper.implementationType == 'individual'
        ? <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(
            widget.wrapper.members.where((m) {
              // Only keep members that were added under this same FCA
              final mFca = (m['fcaName'] as String? ?? '').trim().toLowerCase();
              // If member has no fcaName tag, assume it belongs to current group
              return mFca.isEmpty || mFca == currentFcaName;
            }),
          );

    final next = CropStepWrapper()
      ..reportingPeriod = widget.wrapper.reportingPeriod
      ..fcaName = widget.wrapper.fcaName
      ..region = widget.wrapper.region
      ..province = widget.wrapper.province
      ..municipality = widget.wrapper.municipality
      ..barangay = widget.wrapper.barangay
      ..projectTitle = widget.wrapper.projectTitle
      ..primaryIntervention = widget.wrapper.primaryIntervention
      ..primaryInterventionOther = widget.wrapper.primaryInterventionOther
      ..supportInterventions = List.from(widget.wrapper.supportInterventions)
      ..members = filteredMembers
      ..completedCommodities = []
      ..implementationType = widget.wrapper.implementationType
      ..isAddFarmer = true
      ..farmerName = ''
      ..saadIdNo = ''
      ..approvedFarmerProfile = {}
      ..trainings = [TrainingEntry()]
      ..farmPhoto = '';

    print('🆔 After creating next wrapper:');
    print('   next saadIdNo: "${next.saadIdNo}"');
    print('   next members: ${next.members}');
    print('   next farmerName: "${next.farmerName}"');

    next.resetCommodityStageFields();

    // Navigate to Step 2 to add new farmer's commodity data
    Navigator.of(context).pushNamed(AppRoutes.cropStep2, arguments: next);
  }

  // ── Monitor member ────────────────────────────────────────────
  void _monitorMember(CropMember member) {
    final next = CropStepWrapper()
      ..reportingPeriod = widget.wrapper.reportingPeriod
      ..fcaName = widget.wrapper.fcaName
      ..region = widget.wrapper.region
      ..province = widget.wrapper.province
      ..municipality = widget.wrapper.municipality
      ..barangay = widget.wrapper.barangay
      ..projectTitle = widget.wrapper.projectTitle
      ..primaryIntervention = widget.wrapper.primaryIntervention
      ..supportInterventions = List.from(widget.wrapper.supportInterventions)
      ..implementationType = widget.wrapper.implementationType ?? 'individual'
      ..members = List.from(widget.wrapper.members)
      ..farmerName = member.name
      ..saadIdNo = member.saadIdNo ?? '';
    Navigator.of(context)
        .pushNamed(AppRoutes.cropStep2, arguments: next)
        .then((_) => setState(() => member.monitored = true));
  }

  Future<void> _addCommodityForCurrentFarmer() async {
    final isIndividual =
        widget.wrapper.implementationType?.toLowerCase() == 'individual';

    final CropMember currentFarmer;

    if (isIndividual) {
      currentFarmer = CropMember(
        name: widget.wrapper.farmerName.trim(),
        saadIdNo: widget.wrapper.saadIdNo.trim().isNotEmpty
            ? widget.wrapper.saadIdNo.trim()
            : null,
      );
    } else if (widget.wrapper.members.isNotEmpty) {
      currentFarmer = CropMember(
        name: (widget.wrapper.members.first['name'] as String? ?? '').trim(),
        saadIdNo: (widget.wrapper.members.first['saadIdNo'] as String?)?.trim(),
      );
    } else {
      currentFarmer = CropMember(
        name: widget.wrapper.farmerName.trim(),
        saadIdNo: widget.wrapper.saadIdNo.trim().isNotEmpty
            ? widget.wrapper.saadIdNo.trim()
            : null,
      );
    }

    print(
        '🧑 currentFarmer: name="${currentFarmer.name}", saadIdNo="${currentFarmer.saadIdNo}"');

    if (currentFarmer.name.trim().isEmpty &&
        (currentFarmer.saadIdNo?.trim().isEmpty ?? true)) {
      print('⛔ No farmer identity — aborting add commodity');
      return;
    }

    await _addCommodityForMember(currentFarmer);
  }

  // ── Add another commodity for a member ───────────────────────
  Future<void> _addCommodityForMember(CropMember member) async {
    // CRITICAL: Before navigating, accumulate current commodity data
    // This prevents overwrites when adding another commodity for same farmer
    // ✅ IMPORTANT: Include farmPhoto and trainings per commodity, not just at wrapper level
    if (widget.wrapper.typeOfCrop.isNotEmpty) {
      widget.wrapper.completedCommodities.add({
        'farmerName': member.name,
        'saadIdNo': member.saadIdNo ?? widget.wrapper.saadIdNo,
        'typeOfCrop': widget.wrapper.typeOfCrop,
        'variety': widget.wrapper.variety,
        'inputsReceived':
            widget.wrapper.inputsReceived.map((item) => item.toJson()).toList(),
        'inputsPurchased': widget.wrapper.inputsPurchased
            .map((item) => item.toJson())
            .toList(),
        'totalCostPurchased': widget.wrapper.totalCostPurchased,
        'qtyVsArea': widget.wrapper.qtyVsArea,
        'croppingCycles': widget.wrapper.croppingCycles,
        'qtyVsCycles': widget.wrapper.qtyVsCycles,
        'peakVolume': widget.wrapper.peakVolume,
        'peakMonth': widget.wrapper.peakMonth,
        'volumesPerCycle': widget.wrapper.volumesPerCycle,
        'farmgatePrice': widget.wrapper.farmgatePrice,
        'totalLandArea': widget.wrapper.totalLandArea,
        'landOwnership': widget.wrapper.landOwnership,
        'landOwnershipOther': widget.wrapper.landOwnershipOther,
        'usufructAgreement': widget.wrapper.usufructAgreement,
        'landRemarks': widget.wrapper.landRemarks,
        'machineryType': widget.wrapper.machineryType,
        'machineryOther': widget.wrapper.machineryOther,
        'machineryRemarks': widget.wrapper.machineryRemarks,
        'landPrepCostPerCycle': widget.wrapper.landPrepCostPerCycle,
        'landPrepStartDate': widget.wrapper.landPrepStartDate,
        'landPrepDays': widget.wrapper.landPrepDays,
        'sourceOfWater': widget.wrapper.sourceOfWater,
        'plantingDate': widget.wrapper.plantingDate,
        'seedAmount': widget.wrapper.seedAmount,
        'seedUnit': widget.wrapper.seedUnit,
        'germinationRate': widget.wrapper.germinationRate,
        'goodGermination': widget.wrapper.goodGermination,
        'germinationReason': widget.wrapper.germinationReason,
        'fertilizerType': widget.wrapper.fertilizerType,
        'organicSource': widget.wrapper.organicSource,
        'organicBagsSAAD': widget.wrapper.organicBagsSAAD,
        'organicBagsCommercial': widget.wrapper.organicBagsCommercial,
        'organicTotalCost': widget.wrapper.organicTotalCost,
        'organicBagsCycle': widget.wrapper.organicBagsCycle,
        'organicFrequency': widget.wrapper.organicFrequency,
        'inorganicType': widget.wrapper.inorganicType,
        'inorganicBagsSAAD': widget.wrapper.inorganicBagsSAAD,
        'inorganicMeasure': widget.wrapper.inorganicMeasure,
        'inorganicTotalCost': widget.wrapper.inorganicTotalCost,
        'inorganicBagsCycle': widget.wrapper.inorganicBagsCycle,
        'inorganicFrequency': widget.wrapper.inorganicFrequency,
        'pesticideRequirement': widget.wrapper.pesticideRequirement,
        'landAreaCycles': widget.wrapper.landAreaCycles,
        'dateHarvestCycles': widget.wrapper.dateHarvestCycles,
        'quantityCycles': widget.wrapper.quantityCycles,
        'avgHarvestPerHa': widget.wrapper.avgHarvestPerHa,
        'harvestCostCycles': widget.wrapper.harvestCostCycles,
        'foodConsumptionPct': widget.wrapper.foodConsumptionPct,
        'processingRemarks': widget.wrapper.processingRemarks,
        'pestOccurrence': widget.wrapper.pestOccurrence,
        'pestDamageArea': widget.wrapper.pestDamageArea,
        'pestDamageHa': widget.wrapper.pestDamageHa,
        'pestTreatment': widget.wrapper.pestTreatment,
        'pestAttached': widget.wrapper.pestAttached,
        'hasDisease': widget.wrapper.hasDisease,
        'diseaseOccurrence': widget.wrapper.diseaseOccurrence,
        'diseaseDate': widget.wrapper.diseaseDate,
        'diseaseDamageArea': widget.wrapper.diseaseDamageArea,
        'diseaseDamageHa': widget.wrapper.diseaseDamageHa,
        'diseaseTreatment': widget.wrapper.diseaseTreatment,
        'diseaseAttached': widget.wrapper.diseaseAttached,
        'hasEnvHazard': widget.wrapper.hasEnvHazard,
        'envHazards': widget.wrapper.envHazards,
        'envDate': widget.wrapper.envDate,
        'envDamageArea': widget.wrapper.envDamageArea,
        'envDamageHa': widget.wrapper.envDamageHa,
        'envTreatment': widget.wrapper.envTreatment,
        'envAttached': widget.wrapper.envAttached,
        'hasHumanDamage': widget.wrapper.hasHumanDamage,
        'humanDamage': widget.wrapper.humanDamage,
        'humanMortality': widget.wrapper.humanMortality,
        'humanTreatment': widget.wrapper.humanTreatment,
        'humanAttached': widget.wrapper.humanAttached,
        'farmPhoto': widget.wrapper.farmPhoto,
        'trainings': widget.wrapper.trainings.map((t) => t.toJson()).toList(),
      });
    }

    if (!mounted) return;

    final memberId = member.saadIdNo?.trim().isNotEmpty == true
        ? member.saadIdNo!.trim()
        : member.name.trim();

    // ✅ Only pass THIS member's own commodities — never other farmers' data
    final thisMemberCommodities =
        widget.wrapper.completedCommodities.where((c) {
      final cSaadId = (c['saadIdNo'] as String? ?? '').trim();
      final cName = (c['farmerName'] as String? ?? '').trim();
      if (memberId.isNotEmpty && cSaadId.isNotEmpty) return cSaadId == memberId;
      return cName == member.name.trim();
    }).toList();

    final next = CropStepWrapper();
    next.resetCommodityStageFields();
    next.resetTrainingAndPhoto();

    next
      ..reportingPeriod = widget.wrapper.reportingPeriod
      ..fcaName = widget.wrapper.fcaName
      ..region = widget.wrapper.region
      ..province = widget.wrapper.province
      ..municipality = widget.wrapper.municipality
      ..barangay = widget.wrapper.barangay
      ..projectTitle = widget.wrapper.projectTitle
      ..primaryIntervention = widget.wrapper.primaryIntervention
      ..primaryInterventionOther = widget.wrapper.primaryInterventionOther
      ..supportInterventions = List.from(widget.wrapper.supportInterventions)
      ..completedCommodities =
          List.from(thisMemberCommodities) // ✅ this member only
      ..implementationType = widget.wrapper.implementationType
      ..members = List.from(widget.wrapper.members)
      ..farmerName = member.name
      ..saadIdNo = member.saadIdNo ?? '';

    next.isAddingNewCommodity = true;

    await Navigator.of(context).pushNamed(AppRoutes.cropStep2, arguments: next);

    if (!mounted) return;

    // ✅ Merge back only THIS member's new commodities — never touch other farmers
    for (final c in next.completedCommodities) {
      final cSaadId = (c['saadIdNo'] as String? ?? '').trim();
      final cName = (c['farmerName'] as String? ?? '').trim();
      // Belongs to this member?
      final belongsToMember = (memberId.isNotEmpty && cSaadId == memberId) ||
          (memberId.isEmpty && cName == member.name.trim());
      if (!belongsToMember) continue;

      final fp = '${c['typeOfCrop']}|${c['variety']}|${c['plantingDate']}';
      final exists = widget.wrapper.completedCommodities.any((e) =>
          '${e['typeOfCrop']}|${e['variety']}|${e['plantingDate']}' == fp);
      if (!exists) {
        // ✅ CRITICAL FIX: Preserve the farmPhoto that was captured for THIS specific commodity
        // DO NOT use wrapper.farmPhoto, which may have changed
        final commodityWithPhoto = {...c};
        if (c['farmPhoto'] == null || (c['farmPhoto'] as String).isEmpty) {
          // If the commodity doesn't have a photo field, use the one from 'next'
          commodityWithPhoto['farmPhoto'] = next.farmPhoto;
        }
        print(
            '   📸 Adding commodity with photo: ${commodityWithPhoto['farmPhoto']}');
        widget.wrapper.completedCommodities.add(commodityWithPhoto);
      }
    }

    // ✅ Merge trainings back — append only
    for (final t in next.trainings) {
      final tJson = t.toJson();
      final exists = widget.wrapper.trainings
          .any((old) => jsonEncode(old.toJson()) == jsonEncode(tJson));
      if (!exists) widget.wrapper.trainings.add(t);
    }

    // ✅ Now reset commodity fields for next entry (AFTER merge, not before)
    widget.wrapper.resetCommodityStageFields();

    // ✅ CRITICAL FIX: Also reset photo and trainings so next commodity starts fresh
    print(
        '📸 DEBUG: Resetting wrapper.farmPhoto after adding commodity for ${member.name}');
    widget.wrapper.farmPhoto = '';
    widget.wrapper.trainings = []; // Reset trainings for next commodity

    setState(() => member.monitored = true);
  }

  // ── Add another commodity for group/collective ─────────────────
  Future<void> _addAnotherCommodityForGroup() async {
    // CRITICAL: Before navigating, accumulate current commodity data
    // This prevents overwrites when adding another commodity
    if (widget.wrapper.typeOfCrop.isNotEmpty) {
      print('📸 DEBUG: Creating commodity object for current commodity');
      print('   Current wrapper.farmPhoto: ${widget.wrapper.farmPhoto}');
      print('   Current wrapper.typeOfCrop: ${widget.wrapper.typeOfCrop}');

      final commodity = {
        'typeOfCrop': widget.wrapper.typeOfCrop,
        'variety': widget.wrapper.variety,
        'inputsReceived':
            widget.wrapper.inputsReceived.map((item) => item.toJson()).toList(),
        'inputsPurchased': widget.wrapper.inputsPurchased
            .map((item) => item.toJson())
            .toList(),
        'totalCostPurchased': widget.wrapper.totalCostPurchased,
        'qtyVsArea': widget.wrapper.qtyVsArea,
        'croppingCycles': widget.wrapper.croppingCycles,
        'qtyVsCycles': widget.wrapper.qtyVsCycles,
        'peakVolume': widget.wrapper.peakVolume,
        'peakMonth': widget.wrapper.peakMonth,
        'volumesPerCycle': widget.wrapper.volumesPerCycle,
        'farmgatePrice': widget.wrapper.farmgatePrice,
        'totalLandArea': widget.wrapper.totalLandArea,
        'landOwnership': widget.wrapper.landOwnership,
        'landOwnershipOther': widget.wrapper.landOwnershipOther,
        'usufructAgreement': widget.wrapper.usufructAgreement,
        'landRemarks': widget.wrapper.landRemarks,
        'machineryType': widget.wrapper.machineryType,
        'machineryOther': widget.wrapper.machineryOther,
        'machineryRemarks': widget.wrapper.machineryRemarks,
        'landPrepCostPerCycle': widget.wrapper.landPrepCostPerCycle,
        'landPrepStartDate': widget.wrapper.landPrepStartDate,
        'landPrepDays': widget.wrapper.landPrepDays,
        'sourceOfWater': widget.wrapper.sourceOfWater,
        'plantingDate': widget.wrapper.plantingDate,
        'seedAmount': widget.wrapper.seedAmount,
        'seedUnit': widget.wrapper.seedUnit,
        'germinationRate': widget.wrapper.germinationRate,
        'goodGermination': widget.wrapper.goodGermination,
        'germinationReason': widget.wrapper.germinationReason,
        'fertilizerType': widget.wrapper.fertilizerType,
        'organicSource': widget.wrapper.organicSource,
        'organicBagsSAAD': widget.wrapper.organicBagsSAAD,
        'organicBagsCommercial': widget.wrapper.organicBagsCommercial,
        'organicTotalCost': widget.wrapper.organicTotalCost,
        'organicBagsCycle': widget.wrapper.organicBagsCycle,
        'organicFrequency': widget.wrapper.organicFrequency,
        'inorganicType': widget.wrapper.inorganicType,
        'inorganicBagsSAAD': widget.wrapper.inorganicBagsSAAD,
        'inorganicMeasure': widget.wrapper.inorganicMeasure,
        'inorganicTotalCost': widget.wrapper.inorganicTotalCost,
        'inorganicBagsCycle': widget.wrapper.inorganicBagsCycle,
        'inorganicFrequency': widget.wrapper.inorganicFrequency,
        'pesticideRequirement': widget.wrapper.pesticideRequirement,
        'landAreaCycles': widget.wrapper.landAreaCycles,
        'dateHarvestCycles': widget.wrapper.dateHarvestCycles,
        'quantityCycles': widget.wrapper.quantityCycles,
        'avgHarvestPerHa': widget.wrapper.avgHarvestPerHa,
        'harvestCostCycles': widget.wrapper.harvestCostCycles,
        'foodConsumptionPct': widget.wrapper.foodConsumptionPct,
        'processingRemarks': widget.wrapper.processingRemarks,
        'pestOccurrence': widget.wrapper.pestOccurrence,
        'pestDamageArea': widget.wrapper.pestDamageArea,
        'pestDamageHa': widget.wrapper.pestDamageHa,
        'pestTreatment': widget.wrapper.pestTreatment,
        'pestAttached': widget.wrapper.pestAttached,
        'hasDisease': widget.wrapper.hasDisease,
        'diseaseOccurrence': widget.wrapper.diseaseOccurrence,
        'diseaseDate': widget.wrapper.diseaseDate,
        'diseaseDamageArea': widget.wrapper.diseaseDamageArea,
        'diseaseDamageHa': widget.wrapper.diseaseDamageHa,
        'diseaseTreatment': widget.wrapper.diseaseTreatment,
        'diseaseAttached': widget.wrapper.diseaseAttached,
        'hasEnvHazard': widget.wrapper.hasEnvHazard,
        'envHazards': widget.wrapper.envHazards,
        'envDate': widget.wrapper.envDate,
        'envDamageArea': widget.wrapper.envDamageArea,
        'envDamageHa': widget.wrapper.envDamageHa,
        'envTreatment': widget.wrapper.envTreatment,
        'envAttached': widget.wrapper.envAttached,
        'hasHumanDamage': widget.wrapper.hasHumanDamage,
        'humanDamage': widget.wrapper.humanDamage,
        'humanMortality': widget.wrapper.humanMortality,
        'humanTreatment': widget.wrapper.humanTreatment,
        'humanAttached': widget.wrapper.humanAttached,
        'farmPhoto': widget.wrapper.farmPhoto,
        'trainings': widget.wrapper.trainings.map((t) => t.toJson()).toList(),
      };

      final currentFarmerName = widget.wrapper.farmerName.trim();
      final currentSaadId = widget.wrapper.saadIdNo.trim();
      final currentFarmerId =
          currentSaadId.isNotEmpty ? currentSaadId : currentFarmerName;

      if (widget.wrapper.implementationType?.toLowerCase() == 'collective') {
        // For collective, add commodity for the collective group itself
        widget.wrapper.completedCommodities.add({
          ...commodity,
          'farmerName': currentFarmerName.isNotEmpty
              ? currentFarmerName
              : widget.wrapper.fcaName,
          'saadIdNo': currentFarmerId,
        });
      } else if (currentFarmerId.isNotEmpty) {
        // Add the commodity only to the active farmer, not to every member.
        widget.wrapper.completedCommodities.add({
          ...commodity,
          'farmerName': currentFarmerName,
          'saadIdNo': currentFarmerId,
        });
      } else if (widget.wrapper.members.isNotEmpty) {
        final firstMember = widget.wrapper.members.first;
        final firstMemberName = (firstMember['name'] as String? ?? '').trim();
        final firstMemberSaadId =
            (firstMember['saadIdNo'] as String? ?? '').trim();
        widget.wrapper.completedCommodities.add({
          ...commodity,
          'farmerName': firstMemberName,
          'saadIdNo': firstMemberSaadId,
        });
      } else {
        widget.wrapper.completedCommodities.add({
          ...commodity,
          'farmerName': widget.wrapper.farmerName,
          'saadIdNo': widget.wrapper.saadIdNo,
        });
      }

      print('📸 DEBUG: Added commodity to completedCommodities');
      print(
          '   Total commodities now: ${widget.wrapper.completedCommodities.length}');
      for (var i = 0; i < widget.wrapper.completedCommodities.length; i++) {
        final c = widget.wrapper.completedCommodities[i];
        print('   [$i] ${c['typeOfCrop']} - farmPhoto: ${c['farmPhoto']}');
      }

      // ✅ CRITICAL FIX: Reset farmPhoto after adding commodity
      // This ensures each commodity keeps its own photo, not shared with next one
      print(
          '📸 DEBUG: Resetting wrapper.farmPhoto to empty after adding commodity');
      widget.wrapper.farmPhoto = '';
      widget.wrapper.trainings = [TrainingEntry()]; // Also reset trainings
    }

    // CRITICAL: Build membersByFarmerId BEFORE saving to ensure sync to Firebase
    Map<String, dynamic> membersByFarmerId = {};

    // Only for non-collective types
    if (widget.wrapper.implementationType?.toLowerCase() != 'collective') {
      final currentFarmerName = widget.wrapper.farmerName.trim();
      final currentSaadId = widget.wrapper.saadIdNo.trim();
      final currentFarmerId =
          currentSaadId.isNotEmpty ? currentSaadId : currentFarmerName;

      List<Map<String, dynamic>> findMemberCommodities(
          String memberId, String memberName) {
        return widget.wrapper.completedCommodities.where((commodity) {
          final commoditySaadId =
              (commodity['saadIdNo'] as String? ?? '').trim();
          final commodityFarmerName =
              (commodity['farmerName'] as String? ?? '').trim();
          if (memberId.isNotEmpty && commoditySaadId.isNotEmpty) {
            return commoditySaadId == memberId;
          }
          return commodityFarmerName == memberName;
        }).toList();
      }

      for (final member in widget.wrapper.members) {
        final memberName = (member['name'] as String? ?? '').trim();
        final memberSaadId = (member['saadIdNo'] as String? ?? '').trim();
        final memberId = memberSaadId.isNotEmpty ? memberSaadId : memberName;
        if (memberId.isEmpty) continue;

        membersByFarmerId[memberId] = {
          'farmerName': memberName,
          'saadIdNo': memberSaadId,
          'completedCommodities': findMemberCommodities(memberId, memberName),
          'trainings': memberId == currentFarmerId
              ? widget.wrapper.trainings.map((t) => t.toJson()).toList()
              : <Map<String, dynamic>>[],
          'farmPhoto':
              memberId == currentFarmerId ? widget.wrapper.farmPhoto : '',
          'addedDate': DateTime.now().toIso8601String(),
        };
      }

      if (membersByFarmerId.isEmpty && currentFarmerId.isNotEmpty) {
        membersByFarmerId[currentFarmerId] = {
          'farmerName': currentFarmerName,
          'saadIdNo': currentSaadId,
          'completedCommodities': List<Map<String, dynamic>>.from(
              widget.wrapper.completedCommodities),
          'trainings': widget.wrapper.trainings.map((t) => t.toJson()).toList(),
          'farmPhoto': widget.wrapper.farmPhoto,
          'addedDate': DateTime.now().toIso8601String(),
        };
      }
    }

    final dataToSave = widget.wrapper.toJson();

    // For collective, preserve identity and clear members
    if (widget.wrapper.implementationType?.toLowerCase() == 'collective') {
      dataToSave['farmerName'] = widget.wrapper.farmerName;
      dataToSave['saadIdNo'] = '';
      dataToSave['members'] = [];
      dataToSave['membersByFarmerId'] = {};
    } else {
      dataToSave['membersByFarmerId'] = membersByFarmerId;
    }

    // CRITICAL: Save current state to prevent data loss
    // This ensures the commodity data is persisted before navigating
    await PendingDraftService.instance.saveDraft(
      productionType: 'crop',
      implementationType: widget.wrapper.implementationType ?? '',
      data: dataToSave,
    );

    if (!mounted) return;

    widget.wrapper.resetCommodityStageFields();
    widget.wrapper.resetTrainingAndPhoto();

    final next = CropStepWrapper();
    next.resetCommodityStageFields();
    next.resetTrainingAndPhoto();

    next
      ..reportingPeriod = widget.wrapper.reportingPeriod
      ..fcaName = widget.wrapper.fcaName
      ..region = widget.wrapper.region
      ..province = widget.wrapper.province
      ..municipality = widget.wrapper.municipality
      ..barangay = widget.wrapper.barangay
      ..projectTitle = widget.wrapper.projectTitle
      ..primaryIntervention = widget.wrapper.primaryIntervention
      ..primaryInterventionOther = widget.wrapper.primaryInterventionOther
      ..supportInterventions = List.from(widget.wrapper.supportInterventions)
      ..implementationType = widget.wrapper.implementationType
      ..members = widget.wrapper.implementationType == 'collective'
          ? []
          : List.from(widget.wrapper.members)
      ..completedCommodities = List.from(widget.wrapper.completedCommodities)
      ..farmerName = widget.wrapper.farmerName
      ..saadIdNo = widget.wrapper.implementationType == 'collective'
          ? ''
          : widget.wrapper.saadIdNo;

    next.isAddingNewCommodity = true;
    await Navigator.of(context).pushNamed(AppRoutes.cropStep2, arguments: next);

    if (!mounted) return;

    // ✅ Collective only — add all returned commodities (no member filtering needed)
    for (final c in next.completedCommodities) {
      final fp = '${c['typeOfCrop']}|${c['variety']}|${c['plantingDate']}';
      final exists = widget.wrapper.completedCommodities.any((e) =>
          '${e['typeOfCrop']}|${e['variety']}|${e['plantingDate']}' == fp);
      if (!exists) widget.wrapper.completedCommodities.add(c);
    }

    // ✅ Trainings append only
    for (final t in next.trainings) {
      final tJson = t.toJson();
      final exists = widget.wrapper.trainings
          .any((old) => jsonEncode(old.toJson()) == jsonEncode(tJson));
      if (!exists) widget.wrapper.trainings.add(t);
    }

    widget.wrapper.resetCommodityStageFields();
  }

  void _showGroupDetailsDialog(CropStepWrapper wrapper) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(wrapper.fcaName,
            style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: DAColors.textDark)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── GROUP BACKGROUND DATA ONLY (no commodity info) ──
              if (wrapper.projectTitle.isNotEmpty) ...[
                _buildDetailRow('Project Title', wrapper.projectTitle),
                const SizedBox(height: 12),
              ],
              _buildDetailRow(
                  'Location',
                  [
                    if (wrapper.region?.isNotEmpty == true) wrapper.region!,
                    if (wrapper.province?.isNotEmpty == true) wrapper.province!,
                    if (wrapper.municipality?.isNotEmpty == true)
                      wrapper.municipality!,
                    if (wrapper.barangay?.isNotEmpty == true) wrapper.barangay!,
                  ].join(', ')),
              const SizedBox(height: 12),
              if (wrapper.primaryIntervention?.isNotEmpty == true) ...[
                _buildDetailRow(
                    'Primary Intervention', wrapper.primaryIntervention ?? ''),
                const SizedBox(height: 12),
              ],
              _buildDetailRow(
                  'Members',
                  wrapper.implementationType?.toLowerCase() == 'collective'
                      ? 'Collective Group'
                      : '${_members.length} member${_members.length != 1 ? 's' : ''}'),
              const SizedBox(height: 16),
              if (wrapper.implementationType?.toLowerCase() !=
                  'collective') ...[
                Text('Members List',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: DAColors.textDark)),
                const SizedBox(height: 8),
                ..._members.map((m) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(children: [
                        const Icon(Icons.person_rounded,
                            size: 16, color: DAColors.textMuted),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(m.name,
                                style: GoogleFonts.poppins(
                                    fontSize: 12, color: DAColors.textDark))),
                      ]),
                    )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: DAColors.greenMid)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: DAColors.textMuted)),
        const SizedBox(height: 4),
        Text(value.isEmpty ? '—' : value,
            style: GoogleFonts.poppins(
                fontSize: 12, color: DAColors.textDark, height: 1.4)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final topPad = mq.padding.top;
    final botPad = mq.padding.bottom;
    final screenW = mq.size.width;
    final hPad = screenW * 0.05;
    final w = widget.wrapper;

    final bodyWidgets = (w.implementationType == 'individual' ||
            w.implementationType?.toLowerCase() == 'collective')
        ? [
            GestureDetector(
              onTap: w.implementationType?.toLowerCase() == 'collective'
                  ? _addAnotherCommodityForGroup
                  : _addCommodityForCurrentFarmer,
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
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                          color: DAColors.amber.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.person_add_rounded,
                          color: DAColors.amber, size: 24)),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          w.implementationType?.toLowerCase() == 'collective'
                              ? 'Add Another Commodity'
                              : 'Add Another Commodity',
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: DAColors.textDark)),
                      const SizedBox(height: 2),
                      Text(
                          w.implementationType?.toLowerCase() == 'collective'
                              ? 'Monitor another commodity for this collective'
                              : 'Add another commodity for this farmer',
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: DAColors.textMuted)),
                    ],
                  )),
                  const Icon(Icons.chevron_right_rounded,
                      color: DAColors.amber, size: 24),
                ]),
              ),
            ),
            const SizedBox(height: 24),
            Text('Group / FCA',
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: DAColors.textDark)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: DAColors.greenMid.withOpacity(0.25), width: 1.5),
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
                            color: DAColors.greenLight.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.groups_rounded,
                            color: DAColors.greenMid, size: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(w.farmerName.isEmpty ? w.fcaName : w.farmerName,
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: DAColors.textDark)),
                        const SizedBox(height: 2),
                        Text(
                            [
                              if (w.typeOfCrop.isNotEmpty) w.typeOfCrop,
                              if (w.municipality != null) w.municipality!,
                            ].join(' · '),
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: DAColors.textMuted)),
                      ],
                    )),
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: DAColors.greenLight.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(50)),
                        child: Text('Completed',
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: DAColors.greenMid))),
                  ]),
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _addAnotherCommodityForGroup,
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
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _showGroupDetailsDialog(w),
                    child: Row(children: [
                      Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                              color: DAColors.pending.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.info_rounded,
                              color: DAColors.pending, size: 16)),
                      const SizedBox(width: 8),
                      Text('View Group Details',
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: DAColors.pending)),
                    ]),
                  ),
                ],
              ),
            ),
          ]
        : [
            const SizedBox(height: 24),
            Text('Group / FCA',
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: DAColors.textDark)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: DAColors.greenMid.withOpacity(0.25), width: 1.5),
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
                            color: DAColors.greenLight.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.groups_rounded,
                            color: DAColors.greenMid, size: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(w.farmerName.isEmpty ? w.fcaName : w.farmerName,
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: DAColors.textDark)),
                        const SizedBox(height: 2),
                        Text(
                            [
                              if (w.typeOfCrop.isNotEmpty) w.typeOfCrop,
                              if (w.municipality != null) w.municipality!,
                            ].join(' · '),
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: DAColors.textMuted)),
                      ],
                    )),
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: DAColors.greenLight.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(50)),
                        child: Text('Completed',
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: DAColors.greenMid))),
                  ]),
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _addAnotherCommodityForGroup,
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
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _showGroupDetailsDialog(w),
                    child: Row(children: [
                      Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                              color: DAColors.pending.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.info_rounded,
                              color: DAColors.pending, size: 16)),
                      const SizedBox(width: 8),
                      Text('View Group Details',
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: DAColors.pending)),
                    ]),
                  ),
                ],
              ),
            ),
          ];

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

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
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              GestureDetector(
                  onTap: _done,
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
                  child: Text('Monitoring Summary',
                      style: GoogleFonts.bebasNeue(
                          fontSize: 22,
                          color: Colors.white,
                          letterSpacing: 2))),
            ]),
            const SizedBox(height: 14),
            Text(w.fcaName,
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const SizedBox(height: 6),
            Row(children: [
              _InfoChip(label: w.municipality ?? ''),
              const SizedBox(width: 8),
              _InfoChip(label: _implLabel(w.implementationType)),
            ]),
          ]),
        ),

        // ── Body ────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(hPad, 20, hPad, botPad + 100),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: bodyWidgets),
          ),
        ),

        // ── Buttons ─────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(hPad, 12, hPad, botPad + 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _done,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DAColors.greenMid,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50)),
                ),
                child: Text('Done & Save',
                    style: GoogleFonts.bebasNeue(
                        fontSize: 18, color: Colors.white, letterSpacing: 1)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  String _implLabel(String? type) {
    switch (type) {
      case 'individual':
        return 'Individually Managed';
      case 'collective':
        return 'Collectively Managed';
      case 'hybrid':
        return 'Hybrid';
      default:
        return '';
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

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.onMonitor,
    required this.onAddCommodity,
  });
  final CropMember member;
  final VoidCallback onMonitor;
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
            // Avatar
            Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: member.monitored
                        ? DAColors.greenLight.withOpacity(0.25)
                        : const Color(0xFFF0F0F0),
                    shape: BoxShape.circle),
                child: Icon(
                    member.monitored
                        ? Icons.check_circle_rounded
                        : Icons.person_rounded,
                    color: member.monitored
                        ? DAColors.greenMid
                        : DAColors.textMuted,
                    size: 22)),
            const SizedBox(width: 12),

            // Name + status
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
                          color: member.monitored
                              ? DAColors.greenMid
                              : const Color(0xFFBBBBBB),
                          shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Text(member.monitored ? 'Monitored' : 'Not yet monitored',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: member.monitored
                              ? DAColors.greenMid
                              : DAColors.textMuted)),
                ]),
              ],
            )),

            // Monitor button
            if (!member.monitored)
              GestureDetector(
                  onTap: onMonitor,
                  child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                          color: DAColors.greenMid,
                          borderRadius: BorderRadius.circular(50)),
                      child: Text('Monitor',
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)))),
          ]),

          // Add Another Commodity — always visible
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
}
