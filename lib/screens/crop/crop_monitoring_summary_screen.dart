import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import '../../services/pending_draft_service.dart';
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

    for (final draft in allDrafts) {
      final draftProductionType =
          (draft['productionType'] as String? ?? '').trim().toLowerCase();
      final draftImplementationType =
          (draft['implementationType'] as String? ?? '').trim().toLowerCase();
      final wrapperImplementationType =
          (widget.wrapper.implementationType ?? '').trim().toLowerCase();

      if (draftProductionType != 'crop' ||
          draftImplementationType != wrapperImplementationType) {
        continue;
      }

      final draftData = draft['data'] as Map<String, dynamic>? ?? {};
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
    try {
      // ✅ Accumulate current commodity if it has data
      if (widget.wrapper.typeOfCrop.isNotEmpty) {
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
          'postharvestRemarks': widget.wrapper.postharvestRemarks,
          'processingRemarks': widget.wrapper.processingRemarks,
          'hasPest': widget.wrapper.hasPest,
          'pestOccurrence': widget.wrapper.pestOccurrence,
          'pestDate': widget.wrapper.pestDate,
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
        } else if (widget.wrapper.members.isNotEmpty) {
          for (final member in widget.wrapper.members) {
            final memberName = (member['name'] as String? ?? '').trim();
            final memberSaadId = (member['saadIdNo'] as String? ?? '').trim();
            if (memberName.isNotEmpty) {
              widget.wrapper.completedCommodities.add({
                ...commodity,
                'farmerName': memberName,
                'saadIdNo': memberSaadId.isNotEmpty ? memberSaadId : memberName,
              });
            }
          }
        } else {
          widget.wrapper.completedCommodities.add({
            ...commodity,
            'farmerName': currentFarmerName,
            'saadIdNo': currentSaadId,
          });
        }
      }

      // ✅ Preserve existing group draft data when saving from summary
      Map<String, dynamic> membersByFarmerId = {};
      final saadId = widget.wrapper.saadIdNo.trim();
      final farmerName = widget.wrapper.farmerName.trim();
      final trainingsData =
          widget.wrapper.trainings.map((t) => t.toJson()).toList();
      final hasCurrentFarmer = saadId.isNotEmpty || farmerName.isNotEmpty;

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
        // Individual: Only current farmer
        final farmerId = saadId.isNotEmpty ? saadId : farmerName;
        if (farmerId.isNotEmpty) {
          membersByFarmerId[farmerId] = {
            'farmerName': farmerName,
            'saadIdNo': saadId,
            'trainings': trainingsData,
            'addedDate': DateTime.now().toIso8601String(),
          };
        }
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
          }
        }

        print(
            '📋 Group farmers after processing: ${membersByFarmerId.keys.toList()}');
      }

      // ✅ Save with membersByFarmerId for ALL types
      final dataToSave = widget.wrapper.toJson();

      // CRITICAL: For individual farmers, ensure farmerName and saadIdNo are preserved
      if (widget.wrapper.implementationType?.toLowerCase() == 'individual') {
        dataToSave['farmerName'] = widget.wrapper.farmerName;
        dataToSave['saadIdNo'] = widget.wrapper.saadIdNo;
        dataToSave['members'] = [];
        dataToSave['membersByFarmerId'] = {};
        print(
            '👤 INDIVIDUAL RECORD: farmerName=${dataToSave['farmerName']}, saadIdNo=${dataToSave['saadIdNo']}');
      } else if (widget.wrapper.implementationType?.toLowerCase() ==
          'collective') {
        // For collective records, store commodities and trainings directly at root level
        // Don't use membersByFarmerId for collective - store data directly in group record
        dataToSave['membersByFarmerId'] = {};
        dataToSave['members'] = [];
        print('👥 COLLECTIVE RECORD: Storing data directly in group record');
      } else {
        // For hybrid/group records, use membersByFarmerId
        dataToSave['membersByFarmerId'] = membersByFarmerId;
      }
      // Update members list to include all farmers for local folder saving (only for collectives/hybrids)
      if (widget.wrapper.implementationType?.toLowerCase() != 'individual' &&
          widget.wrapper.implementationType?.toLowerCase() != 'collective') {
        dataToSave['membersByFarmerId'] = membersByFarmerId;
        dataToSave['members'] = membersByFarmerId.entries.map((entry) {
          final farmerData = entry.value as Map<String, dynamic>;
          return {
            'name': farmerData['farmerName'] ?? '',
            'saadIdNo': entry.key,
          };
        }).toList();
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

      await PendingDraftService.instance.saveDraft(
        productionType: 'crop',
        implementationType: widget.wrapper.implementationType ?? '',
        data: dataToSave,
      );

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
        'postharvestRemarks': widget.wrapper.postharvestRemarks,
        'processingRemarks': widget.wrapper.processingRemarks,
        'hasPest': widget.wrapper.hasPest,
        'pestOccurrence': widget.wrapper.pestOccurrence,
        'pestDate': widget.wrapper.pestDate,
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

    // CRITICAL: Add current farmer to members array BEFORE saving
    // This ensures all farmers are preserved in the saved group record
    if (widget.wrapper.implementationType != 'individual' &&
        widget.wrapper.farmerName.isNotEmpty &&
        !widget.wrapper.members.any((m) =>
            (m['name'] as String?)?.trim() ==
            widget.wrapper.farmerName.trim())) {
      widget.wrapper.members.add({'name': widget.wrapper.farmerName.trim()});
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

    // ONLY for non-individual types
    if (widget.wrapper.implementationType != 'individual') {
      for (final member in widget.wrapper.members) {
        final memberName = (member['name'] as String? ?? '').trim();
        if (memberName.isNotEmpty) {
          membersByFarmerId[memberName] = {
            'farmerName': memberName,
            'saadIdNo': '',
            'addedDate': DateTime.now().toIso8601String(),
          };
        }
      }
    }

    final dataToSave = widget.wrapper.toJson();

    // CRITICAL: For individual farmers, preserve identity and clear members
    if (widget.wrapper.implementationType == 'individual') {
      dataToSave['farmerName'] = widget.wrapper.farmerName;
      dataToSave['saadIdNo'] = widget.wrapper.saadIdNo;
      dataToSave['members'] = [];
      dataToSave['membersByFarmerId'] = {};
      print(
          '👤 _addAnotherFarmer: Saving individual farmer: ${dataToSave['farmerName']} (${dataToSave['saadIdNo']})');
    } else {
      dataToSave['membersByFarmerId'] = membersByFarmerId;
      print(
          '👥 _addAnotherFarmer: Saving group with members: ${membersByFarmerId.keys.toList()}');
    }

    // CRITICAL: Save to ONE group record (fcaName-based dedup)
    // This ensures all farmers in the group are stored together WITH membersByFarmerId for sync
    await PendingDraftService.instance.saveDraft(
      productionType: 'crop',
      implementationType: widget.wrapper.implementationType ?? '',
      data: dataToSave,
    );

    if (!mounted) return;

    // Create new wrapper for next farmer with group info preserved
    // Commodity fields are cleared for new farmer entry
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
      ..members = widget.wrapper.implementationType == 'individual'
          ? []
          : List.from(widget.wrapper.members)
      ..completedCommodities = []
      ..implementationType = widget.wrapper.implementationType
      ..isAddFarmer = true
      ..farmerName = ''
      ..saadIdNo = ''
      ..approvedFarmerProfile = {}
      ..trainings = [TrainingEntry()]
      ..farmPhoto = '';

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

  // ── Add another commodity for a member ───────────────────────
  void _addCommodityForMember(CropMember member) async {
    // CRITICAL: Before navigating, accumulate current commodity data
    // This prevents overwrites when adding another commodity for same farmer
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
        'postharvestRemarks': widget.wrapper.postharvestRemarks,
        'processingRemarks': widget.wrapper.processingRemarks,
        'hasPest': widget.wrapper.hasPest,
        'pestOccurrence': widget.wrapper.pestOccurrence,
        'pestDate': widget.wrapper.pestDate,
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
      });
    }

    if (!mounted) return;

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
      ..completedCommodities = List.from(widget.wrapper.completedCommodities)
      ..implementationType = widget.wrapper.implementationType
      ..members = List.from(widget.wrapper.members)
      ..farmerName = member.name
      ..saadIdNo = member.saadIdNo ?? '';

    // Navigate and wait for return
    final updatedWrapper = await Navigator.of(context)
        .pushNamed(AppRoutes.cropStep2, arguments: next) as CropStepWrapper?;

    if (!mounted) return;

    // ✅ If returned with data, update the wrapper with new commodity data
    if (updatedWrapper != null) {
      widget.wrapper.completedCommodities = updatedWrapper.completedCommodities;
      // Clear current commodity fields for next entry
      widget.wrapper.typeOfCrop = '';
      widget.wrapper.variety = '';
      widget.wrapper.inputsReceived = [InputReceived()];
      widget.wrapper.inputsPurchased = [InputPurchased()];
      widget.wrapper.qtyVsArea = '';
      widget.wrapper.totalCostPurchased = '';
      widget.wrapper.croppingCycles = '';
      widget.wrapper.qtyVsCycles = '';
      widget.wrapper.peakVolume = '';
      widget.wrapper.peakMonth = '';
      widget.wrapper.volumesPerCycle = [''];
      widget.wrapper.farmgatePrice = '';
      setState(() => member.monitored = true);
    }
  }

  // ── Add another commodity for group/collective ─────────────────
  Future<void> _addAnotherCommodityForGroup() async {
    // CRITICAL: Before navigating, accumulate current commodity data
    // This prevents overwrites when adding another commodity
    if (widget.wrapper.typeOfCrop.isNotEmpty) {
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
        'postharvestRemarks': widget.wrapper.postharvestRemarks,
        'processingRemarks': widget.wrapper.processingRemarks,
        'hasPest': widget.wrapper.hasPest,
        'pestOccurrence': widget.wrapper.pestOccurrence,
        'pestDate': widget.wrapper.pestDate,
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

      if (widget.wrapper.implementationType?.toLowerCase() == 'collective') {
        // For collective, add commodity for the collective group itself
        widget.wrapper.completedCommodities.add({
          ...commodity,
          'farmerName': widget.wrapper.farmerName,
          'saadIdNo': '',
        });
      } else if (widget.wrapper.members.isNotEmpty) {
        for (final member in widget.wrapper.members) {
          final memberName = (member['name'] as String? ?? '').trim();
          final memberSaadId = (member['saadIdNo'] as String? ?? '').trim();
          if (memberName.isNotEmpty) {
            widget.wrapper.completedCommodities.add({
              ...commodity,
              'farmerName': memberName,
              'saadIdNo': memberSaadId.isNotEmpty ? memberSaadId : memberName,
            });
          }
        }
      } else {
        widget.wrapper.completedCommodities.add({
          ...commodity,
          'farmerName': widget.wrapper.farmerName,
          'saadIdNo': widget.wrapper.saadIdNo,
        });
      }
    }

    // CRITICAL: Build membersByFarmerId BEFORE saving to ensure sync to Firebase
    Map<String, dynamic> membersByFarmerId = {};

    // Only for non-collective types
    if (widget.wrapper.implementationType?.toLowerCase() != 'collective') {
      for (final member in widget.wrapper.members) {
        final memberName = (member['name'] as String? ?? '').trim();
        if (memberName.isNotEmpty) {
          membersByFarmerId[memberName] = {
            'farmerName': memberName,
            'saadIdNo': '',
            'addedDate': DateTime.now().toIso8601String(),
          };
        }
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
      ..implementationType = widget.wrapper.implementationType
      ..members = widget.wrapper.implementationType == 'collective'
          ? []
          : List.from(widget.wrapper.members)
      ..completedCommodities = List.from(widget.wrapper.completedCommodities)
      ..farmerName = widget.wrapper.farmerName
      ..saadIdNo = widget.wrapper.implementationType == 'collective'
          ? ''
          : widget.wrapper.saadIdNo;
    next.resetCommodityStageFields();
    Navigator.of(context).pushNamed(AppRoutes.cropStep2, arguments: next);
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
                  : _addAnotherFarmer,
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
                              : 'Add Another Farmer',
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: DAColors.textDark)),
                      const SizedBox(height: 2),
                      Text(
                          w.implementationType?.toLowerCase() == 'collective'
                              ? 'Monitor another commodity for this collective'
                              : 'Monitor a new farmer',
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
                    onTap: () {
                      final next = CropStepWrapper()
                        ..reportingPeriod = w.reportingPeriod
                        ..fcaName = w.fcaName
                        ..region = w.region
                        ..province = w.province
                        ..municipality = w.municipality
                        ..barangay = w.barangay
                        ..projectTitle = w.projectTitle
                        ..primaryIntervention = w.primaryIntervention
                        ..primaryInterventionOther = w.primaryInterventionOther
                        ..supportInterventions =
                            List.from(w.supportInterventions)
                        ..implementationType = w.implementationType
                        ..members = w.implementationType == 'individual'
                            ? []
                            : List.from(w.members)
                        ..completedCommodities = []
                        ..farmerName = w.farmerName
                        ..saadIdNo = w.saadIdNo;
                      next.resetCommodityStageFields();
                      Navigator.of(context)
                          .pushNamed(AppRoutes.cropStep2, arguments: next);
                    },
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
