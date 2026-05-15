import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'commodity_id_service.dart';

class MonitoringRecordService {
  MonitoringRecordService._();

  static final MonitoringRecordService instance = MonitoringRecordService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  static const String _pendingCollection = 'pending_monitoring';
  static const String _approvedCollection = 'approved_monitoring';

  /// Save a monitoring record to pending_monitoring collection
  /// ✅ THREE-LEVEL HIERARCHY:
  /// pending_monitoring/{fcaName}/
  ///   ├── Project Background (FCA document fields)
  ///   └── members/{saadId}/
  ///       ├── Personal Data (farmer fields)
  ///       └── commodities/{commodityId}/
  ///           └── Commodity Data (specific batch/record)
  Future<String> savePendingRecord({
    required String productionType,
    required String implementationType,
    required Map<String, dynamic> data,
  }) async {
    try {
      print('🔥 savePendingRecord START:');
      print('   productionType: $productionType');
      print('   implementationType: $implementationType');

      final user = _auth.currentUser;
      print('   user: $user');
      if (user == null) throw Exception('User not authenticated');

      final fcaName = (data['fcaName'] as String? ?? 'Unknown Group').trim();
      print('   fcaName: $fcaName');

      // ✅ DETECT PRODUCTION TYPE EARLY
      final detectedType = productionType.toLowerCase().trim();
      final typePrefix = detectedType == 'crop'
          ? 'crop'
          : detectedType == 'poultry'
              ? 'poultry'
              : detectedType == 'livestock'
                  ? 'livestock'
                  : 'unknown';

      // ✅ VALIDATE PRODUCTION TYPE
      if (typePrefix == 'unknown') {
        throw Exception(
            'Invalid production type: "$productionType". Must be crop, livestock, or poultry.');
      }

      // ✅ LEVEL 1: PROJECT BACKGROUND at FCA document level
      final projectBackground = {
        'fcaName': fcaName,
        'productionType': productionType,
        'implementationType': implementationType,
        'region': data['region'] ?? '',
        'province': data['province'] ?? '',
        'municipality': data['municipality'] ?? '',
        'barangay': data['barangay'] ?? '',
        'projectTitle': data['projectTitle'] ?? '',
        'primaryIntervention': data['primaryIntervention'] ?? '',
        'primaryInterventionOther': data['primaryInterventionOther'] ?? '',
        'supportInterventions': data['supportInterventions'] ?? [],
        'reportingPeriod': data['reportingPeriod'] ?? '',
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'approvalStatus': 'pending',
      };

      // Use FCA name as document ID with detected type prefix
      final groupDocId =
          '${typePrefix}_${fcaName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}';
      final groupDocRef =
          _firestore.collection(_pendingCollection).doc(groupDocId);

      print('   groupDocId: $groupDocId');
      print('   Saving projectBackground...');

      // ✅ Save project background as main FCA document
      await groupDocRef.set(projectBackground, SetOptions(merge: true));

      print('   ✅ projectBackground saved');

      // ✅ Save trainings at group level for COLLECTIVE
      if (implementationType.toLowerCase() == 'collective') {
        final trainingsData = {
          'trainings': data['trainings'] ?? [],
        };
        await groupDocRef.set(trainingsData, SetOptions(merge: true));
        print('   ✅ trainings saved at group level');
      }

      // ✅ LEVEL 2 & 3: Extract and save members with their commodities
      Map<String, dynamic> membersByFarmerId = {};
      List<Map<String, dynamic>> completedCommodities = [];

      if (data['membersByFarmerId'] != null) {
        membersByFarmerId =
            Map<String, dynamic>.from(data['membersByFarmerId']);
      } else if (data['farmerName'] != null &&
          (data['farmerName'] as String).isNotEmpty) {
        // Individual record - treat as single farmer
        final farmerName = (data['farmerName'] as String).trim();
        final saadId = (data['saadIdNo'] as String? ?? '').trim();
        final farmerId = saadId.isNotEmpty ? saadId : farmerName;
        membersByFarmerId[farmerId] = {
          'farmerName': farmerName,
          'saadIdNo': saadId,
        };
      }

      // Collect all completed commodities/batches
      if (data['completedCommodities'] != null) {
        completedCommodities =
            List<Map<String, dynamic>>.from(data['completedCommodities']);
      } else if (data['completedBatches'] != null) {
        completedCommodities =
            List<Map<String, dynamic>>.from(data['completedBatches']);
      }

      // ✅ GLOBAL NUMBERING: Fetch ALL existing commodities from Firebase for this group
      // to determine the next starting number
      int globalNextNumber = 1;
      try {
        final collectiveSnapshot = await groupDocRef
            .collection('commodities')
            .orderBy('commodityId')
            .get();

        for (final doc in collectiveSnapshot.docs) {
          final commodityId = doc['commodityId']?.toString() ?? '';
          if (commodityId.isNotEmpty) {
            try {
              final parts = commodityId.split('_');
              if (parts.length == 2) {
                final number = int.tryParse(parts[1]) ?? 0;
                if (number >= globalNextNumber) {
                  globalNextNumber = number + 1;
                }
              }
            } catch (e) {
              // Ignore parsing errors
            }
          }
        }

        // Also check all member commodities
        final membersSnapshot = await groupDocRef.collection('members').get();
        for (final memberDoc in membersSnapshot.docs) {
          final commSnapshot =
              await memberDoc.reference.collection('commodities').get();
          for (final doc in commSnapshot.docs) {
            final commodityId = doc['commodityId']?.toString() ?? '';
            if (commodityId.isNotEmpty) {
              try {
                final parts = commodityId.split('_');
                if (parts.length == 2) {
                  final number = int.tryParse(parts[1]) ?? 0;
                  if (number >= globalNextNumber) {
                    globalNextNumber = number + 1;
                  }
                }
              } catch (e) {
                // Ignore parsing errors
              }
            }
          }
        }
      } catch (e) {
        // If no existing commodities, start from 1
        globalNextNumber = 1;
      }

      // ✅ COLLECTIVE TYPE: Save commodities directly to group (no members subcollection)
      if (implementationType.toLowerCase() == 'collective') {
        print(
            '🔍 COLLECTIVE SYNC: Processing ${completedCommodities.length} commodities');
        for (int i = 0; i < completedCommodities.length; i++) {
          final commodity = completedCommodities[i];

          // 🔍 DEBUG: Log damage fields from local data
          print('   📦 Commodity $i:');
          print('      - hasPest: ${commodity['hasPest']}');
          print('      - pestOccurrence: ${commodity['pestOccurrence']}');
          print('      - pestDamageArea: ${commodity['pestDamageArea']}');
          print('      - pestDamageHa: ${commodity['pestDamageHa']}');
          print('      - pestTreatment: ${commodity['pestTreatment']}');

          final commodityData = <String, dynamic>{
            'recordedAt': FieldValue.serverTimestamp(),
          };

          switch (productionType.toLowerCase()) {
            case 'crop':
              commodityData.addAll({
                'typeOfCrop': commodity['typeOfCrop'] ?? '',
                'variety': commodity['variety'] ?? '',
                'inputsReceived': commodity['inputsReceived'] ?? [],
                'inputsPurchased': commodity['inputsPurchased'] ?? [],
                'farmgatePrices': commodity['farmgatePrices'] ?? {},
                'totalCostPurchased': commodity['totalCostPurchased'] ?? '',
                'qtyVsArea': commodity['qtyVsArea'] ?? '',
                'croppingCycles': commodity['croppingCycles'] ?? '',
                'qtyVsCycles': commodity['qtyVsCycles'] ?? '',
                'peakVolume': commodity['peakVolume'] ?? '',
                'peakMonth': commodity['peakMonth'] ?? '',
                'volumesPerCycle': commodity['volumesPerCycle'] ?? [],
                'farmgatePrice': commodity['farmgatePrice'] ?? '',
                'totalLandArea':
                    commodity['totalLandArea'] ?? data['totalLandArea'] ?? '',
                'landOwnership':
                    commodity['landOwnership'] ?? data['landOwnership'] ?? '',
                'landOwnershipOther': commodity['landOwnershipOther'] ??
                    data['landOwnershipOther'] ??
                    '',
                'usufructAgreement': commodity['usufructAgreement'] ??
                    data['usufructAgreement'] ??
                    '',
                'landRemarks':
                    commodity['landRemarks'] ?? data['landRemarks'] ?? [],
                'machineryType':
                    commodity['machineryType'] ?? data['machineryType'] ?? '',
                'machineryOther':
                    commodity['machineryOther'] ?? data['machineryOther'] ?? '',
                'machineryRemarks': commodity['machineryRemarks'] ??
                    data['machineryRemarks'] ??
                    [],
                'landPrepCostPerCycle': commodity['landPrepCostPerCycle'] ??
                    data['landPrepCostPerCycle'] ??
                    [],
                'landPrepStartDate': commodity['landPrepStartDate'] ??
                    data['landPrepStartDate'] ??
                    '',
                'landPrepDays':
                    commodity['landPrepDays'] ?? data['landPrepDays'] ?? '',
                'sourceOfWater':
                    commodity['sourceOfWater'] ?? data['sourceOfWater'] ?? '',
                'plantingDate':
                    commodity['plantingDate'] ?? data['plantingDate'] ?? '',
                'seedAmount':
                    commodity['seedAmount'] ?? data['seedAmount'] ?? '',
                'seedUnit': commodity['seedUnit'] ?? data['seedUnit'] ?? '',
                'germinationRate': commodity['germinationRate'] ??
                    data['germinationRate'] ??
                    '',
                'goodGermination': commodity['goodGermination'] ??
                    data['goodGermination'] ??
                    '',
                'germinationReason': commodity['germinationReason'] ??
                    data['germinationReason'] ??
                    '',
                'fertilizerType':
                    commodity['fertilizerType'] ?? data['fertilizerType'] ?? '',
                'organicSource':
                    commodity['organicSource'] ?? data['organicSource'] ?? '',
                'organicBagsSAAD': commodity['organicBagsSAAD'] ??
                    data['organicBagsSAAD'] ??
                    '',
                'organicBagsCommercial': commodity['organicBagsCommercial'] ??
                    data['organicBagsCommercial'] ??
                    '',
                'organicTotalCost': commodity['organicTotalCost'] ??
                    data['organicTotalCost'] ??
                    '',
                'organicBagsCycle': commodity['organicBagsCycle'] ??
                    data['organicBagsCycle'] ??
                    [],
                'organicFrequency': commodity['organicFrequency'] ??
                    data['organicFrequency'] ??
                    '',
                'inorganicType':
                    commodity['inorganicType'] ?? data['inorganicType'] ?? '',
                'inorganicBagsSAAD': commodity['inorganicBagsSAAD'] ??
                    data['inorganicBagsSAAD'] ??
                    '',
                'inorganicMeasure': commodity['inorganicMeasure'] ??
                    data['inorganicMeasure'] ??
                    '',
                'inorganicTotalCost': commodity['inorganicTotalCost'] ??
                    data['inorganicTotalCost'] ??
                    '',
                'inorganicBagsCycle': commodity['inorganicBagsCycle'] ??
                    data['inorganicBagsCycle'] ??
                    [],
                'inorganicFrequency': commodity['inorganicFrequency'] ??
                    data['inorganicFrequency'] ??
                    '',
                'pesticideRequirement': commodity['pesticideRequirement'] ??
                    data['pesticideRequirement'] ??
                    '',
                'landAreaCycles':
                    commodity['landAreaCycles'] ?? data['landAreaCycles'] ?? [],
                'dateHarvestCycles': commodity['dateHarvestCycles'] ??
                    data['dateHarvestCycles'] ??
                    [],
                'quantityCycles':
                    commodity['quantityCycles'] ?? data['quantityCycles'] ?? [],
                'avgHarvestPerHa': commodity['avgHarvestPerHa'] ??
                    data['avgHarvestPerHa'] ??
                    '',
                'harvestCostCycles': commodity['harvestCostCycles'] ??
                    data['harvestCostCycles'] ??
                    [],
                'foodConsumptionPct': commodity['foodConsumptionPct'] ??
                    data['foodConsumptionPct'] ??
                    '',
                'postharvestRemarks': commodity['postharvestRemarks'] ??
                    data['postharvestRemarks'] ??
                    [],
                'processingRemarks': commodity['processingRemarks'] ??
                    data['processingRemarks'] ??
                    [],

                // ✅ PEST DAMAGE FIELDS (Step 06) - NOW INCLUDED FOR COLLECTIVE SYNC
                'hasPest': commodity['hasPest'] ?? data['hasPest'] ?? false,
                'pestOccurrence':
                    commodity['pestOccurrence'] ?? data['pestOccurrence'] ?? '',
                'pestDate': commodity['pestDate'] ?? data['pestDate'] ?? '',
                'pestDamageArea':
                    commodity['pestDamageArea'] ?? data['pestDamageArea'] ?? '',
                'pestDamageHa':
                    commodity['pestDamageHa'] ?? data['pestDamageHa'] ?? '',
                'pestTreatment':
                    commodity['pestTreatment'] ?? data['pestTreatment'] ?? '',
                'pestAttached':
                    commodity['pestAttached'] ?? data['pestAttached'] ?? '',

                // ✅ DISEASE DAMAGE FIELDS (Step 06)
                'hasDisease':
                    commodity['hasDisease'] ?? data['hasDisease'] ?? false,
                'diseaseOccurrence': commodity['diseaseOccurrence'] ??
                    data['diseaseOccurrence'] ??
                    '',
                'diseaseDate':
                    commodity['diseaseDate'] ?? data['diseaseDate'] ?? '',
                'diseaseDamageArea': commodity['diseaseDamageArea'] ??
                    data['diseaseDamageArea'] ??
                    '',
                'diseaseDamageHa': commodity['diseaseDamageHa'] ??
                    data['diseaseDamageHa'] ??
                    '',
                'diseaseTreatment': commodity['diseaseTreatment'] ??
                    data['diseaseTreatment'] ??
                    '',
                'diseaseAttached': commodity['diseaseAttached'] ??
                    data['diseaseAttached'] ??
                    '',

                // ✅ ENVIRONMENTAL HAZARD FIELDS (Step 06)
                'hasEnvHazard':
                    commodity['hasEnvHazard'] ?? data['hasEnvHazard'] ?? false,
                'envHazards':
                    commodity['envHazards'] ?? data['envHazards'] ?? [],
                'envDate': commodity['envDate'] ?? data['envDate'] ?? '',
                'envDamageArea':
                    commodity['envDamageArea'] ?? data['envDamageArea'] ?? '',
                'envDamageHa':
                    commodity['envDamageHa'] ?? data['envDamageHa'] ?? '',
                'envTreatment':
                    commodity['envTreatment'] ?? data['envTreatment'] ?? '',
                'envAttached':
                    commodity['envAttached'] ?? data['envAttached'] ?? '',

                // ✅ HUMAN DAMAGE FIELDS (Step 06)
                'hasHumanDamage': commodity['hasHumanDamage'] ??
                    data['hasHumanDamage'] ??
                    false,
                'humanDamage':
                    commodity['humanDamage'] ?? data['humanDamage'] ?? '',
                'humanMortality':
                    commodity['humanMortality'] ?? data['humanMortality'] ?? '',
                'humanTreatment':
                    commodity['humanTreatment'] ?? data['humanTreatment'] ?? '',
                'humanAttached':
                    commodity['humanAttached'] ?? data['humanAttached'] ?? '',
              });
              break;
            case 'livestock':
              commodityData.addAll({
                'breed': commodity['breed'] ?? '',
                'inputsReceived': commodity['inputsReceived'] ?? [],
                'inputsPurchased': commodity['inputsPurchased'] ?? [],
                'farmgatePrices': commodity['farmgatePrices'] ?? [],
                'stocksReceived':
                    commodity['stocksReceived'] ?? data['stocksReceived'] ?? '',
                'dateReceived':
                    commodity['dateReceived'] ?? data['dateReceived'] ?? '',
                'maleStocks':
                    commodity['maleStocks'] ?? data['maleStocks'] ?? '',
                'femaleStocks':
                    commodity['femaleStocks'] ?? data['femaleStocks'] ?? '',
                'maleToFemaleRatio': commodity['maleToFemaleRatio'] ??
                    data['maleToFemaleRatio'] ??
                    '',
                'ageUponReceipt':
                    commodity['ageUponReceipt'] ?? data['ageUponReceipt'] ?? '',
                'avgWeightUponReceipt': commodity['avgWeightUponReceipt'] ??
                    data['avgWeightUponReceipt'] ??
                    '',
                'meatProduced':
                    commodity['meatProduced'] ?? data['meatProduced'] ?? '',
                'pregnantStocks':
                    commodity['pregnantStocks'] ?? data['pregnantStocks'] ?? '',
                'housingType':
                    commodity['housingType'] ?? data['housingType'] ?? '',
                'farmOwnership':
                    commodity['farmOwnership'] ?? data['farmOwnership'] ?? '',
                'farmOwnershipOther': commodity['farmOwnershipOther'] ??
                    data['farmOwnershipOther'] ??
                    '',
                'usufruct': commodity['usufruct'] ?? data['usufruct'] ?? '',
                'usufructRemarks': commodity['usufructRemarks'] ??
                    data['usufructRemarks'] ??
                    '',
                'healthActivities': commodity['healthActivities'] ??
                    data['healthActivities'] ??
                    '',
                'healthOthers':
                    commodity['healthOthers'] ?? data['healthOthers'] ?? '',
                'wasteManagement': commodity['wasteManagement'] ??
                    data['wasteManagement'] ??
                    '',
                'growOutPeriod':
                    commodity['growOutPeriod'] ?? data['growOutPeriod'] ?? '',
                'lactationPeriod': commodity['lactationPeriod'] ??
                    data['lactationPeriod'] ??
                    '',
                'dryPeriod': commodity['dryPeriod'] ?? data['dryPeriod'] ?? '',
                'producedOffspring': commodity['producedOffspring'] ??
                    data['producedOffspring'] ??
                    '',
                'offspringMale':
                    commodity['offspringMale'] ?? data['offspringMale'] ?? '',
                'offspringFemale': commodity['offspringFemale'] ??
                    data['offspringFemale'] ??
                    '',
                'offspringMFRatio': commodity['offspringMFRatio'] ??
                    data['offspringMFRatio'] ??
                    '',
                'mortalitiesAfterBirth': commodity['mortalitiesAfterBirth'] ??
                    data['mortalitiesAfterBirth'] ??
                    '',
                'remainingOffspring': commodity['remainingOffspring'] ??
                    data['remainingOffspring'] ??
                    '',
                'grazingArea':
                    commodity['grazingArea'] ?? data['grazingArea'] ?? '',
                'feeds': commodity['feeds'] ?? data['feeds'] ?? [],
                'waterSources':
                    commodity['waterSources'] ?? data['waterSources'] ?? [],
                'soldAsLiveweight': commodity['soldAsLiveweight'] ??
                    data['soldAsLiveweight'] ??
                    '',
                'soldAsLiveweightRemarks':
                    commodity['soldAsLiveweightRemarks'] ??
                        data['soldAsLiveweightRemarks'] ??
                        '',
                'avgMarketableWeight': commodity['avgMarketableWeight'] ??
                    data['avgMarketableWeight'] ??
                    '',
                'milkVolumeDaily': commodity['milkVolumeDaily'] ??
                    data['milkVolumeDaily'] ??
                    '',
                'farmgatePriceMilk': commodity['farmgatePriceMilk'] ??
                    data['farmgatePriceMilk'] ??
                    '',
                'milkUnit': commodity['milkUnit'] ?? data['milkUnit'] ?? '',
                'slaughteredCount': commodity['slaughteredCount'] ??
                    data['slaughteredCount'] ??
                    '',
                'slaughteredPrice': commodity['slaughteredPrice'] ??
                    data['slaughteredPrice'] ??
                    '',
                'postharvest':
                    commodity['postharvest'] ?? data['postharvest'] ?? '',
                'postharvestRemarks': commodity['postharvestRemarks'] ??
                    data['postharvestRemarks'] ??
                    '',
                'processing':
                    commodity['processing'] ?? data['processing'] ?? '',
                'processingRemarks': commodity['processingRemarks'] ??
                    data['processingRemarks'] ??
                    '',
              });
              break;
            case 'poultry':
              commodityData.addAll({
                'breed': commodity['breed'] ?? '',
                'inputsReceived': commodity['inputsReceived'] ?? [],
                'inputsPurchased': commodity['inputsPurchased'] ?? [],
                'farmgatePrices': commodity['farmgatePrices'] ?? [],
                'stocksReceived':
                    commodity['stocksReceived'] ?? data['stocksReceived'] ?? '',
                'dateReceived':
                    commodity['dateReceived'] ?? data['dateReceived'] ?? '',
                'ageUponReceipt':
                    commodity['ageUponReceipt'] ?? data['ageUponReceipt'] ?? '',
                'avgWeightUponReceipt': commodity['avgWeightUponReceipt'] ??
                    data['avgWeightUponReceipt'] ??
                    '',
                'totalProductiveCycle': commodity['totalProductiveCycle'] ??
                    data['totalProductiveCycle'] ??
                    '',
                'housingType':
                    commodity['housingType'] ?? data['housingType'] ?? '',
                'landOwnership':
                    commodity['landOwnership'] ?? data['landOwnership'] ?? '',
                'landOwnershipOther': commodity['landOwnershipOther'] ??
                    data['landOwnershipOther'] ??
                    '',
                'usufruct': commodity['usufruct'] ?? data['usufruct'] ?? '',
                'maleToFemaleRatio': commodity['maleToFemaleRatio'] ??
                    data['maleToFemaleRatio'] ??
                    '',
                'eggsProduced':
                    commodity['eggsProduced'] ?? data['eggsProduced'] ?? '',
                'fertilEggs':
                    commodity['fertilEggs'] ?? data['fertilEggs'] ?? '',
                'eggsIncubated':
                    commodity['eggsIncubated'] ?? data['eggsIncubated'] ?? '',
                'eggsHatched':
                    commodity['eggsHatched'] ?? data['eggsHatched'] ?? '',
                'hatchingRate':
                    commodity['hatchingRate'] ?? data['hatchingRate'] ?? '',
                'mortalitiesAfterHatch': commodity['mortalitiesAfterHatch'] ??
                    data['mortalitiesAfterHatch'] ??
                    '',
                'chicksSold':
                    commodity['chicksSold'] ?? data['chicksSold'] ?? '',
                'eggsSold': commodity['eggsSold'] ?? data['eggsSold'] ?? '',
                'harvestedBirds':
                    commodity['harvestedBirds'] ?? data['harvestedBirds'] ?? '',
                'totalWeightHarvested': commodity['totalWeightHarvested'] ??
                    data['totalWeightHarvested'] ??
                    '',
                'avgDailyGain':
                    commodity['avgDailyGain'] ?? data['avgDailyGain'] ?? '',
                'harvestRecovery': commodity['harvestRecovery'] ??
                    data['harvestRecovery'] ??
                    '',
                'avgLiveWeight':
                    commodity['avgLiveWeight'] ?? data['avgLiveWeight'] ?? '',
                'feedConversionRatio': commodity['feedConversionRatio'] ??
                    data['feedConversionRatio'] ??
                    '',
                'avgAgeHarvested': commodity['avgAgeHarvested'] ??
                    data['avgAgeHarvested'] ??
                    '',
                'broilerPerformanceIndex':
                    commodity['broilerPerformanceIndex'] ??
                        data['broilerPerformanceIndex'] ??
                        '',
                'rangingAge':
                    commodity['rangingAge'] ?? data['rangingAge'] ?? '',
                'totalEggsHarvested': commodity['totalEggsHarvested'] ??
                    data['totalEggsHarvested'] ??
                    '',
                'avgHarvestRate':
                    commodity['avgHarvestRate'] ?? data['avgHarvestRate'] ?? '',
                'weeklyHenDayEggProduction':
                    commodity['weeklyHenDayEggProduction'] ??
                        data['weeklyHenDayEggProduction'] ??
                        '',
                'weeklyHDEPFile':
                    commodity['weeklyHDEPFile'] ?? data['weeklyHDEPFile'] ?? '',
                'daysUnderMolting': commodity['daysUnderMolting'] ??
                    data['daysUnderMolting'] ??
                    '',
                'feedType': commodity['feedType'] ?? data['feedType'] ?? '',
                'totalFeedConsumed': commodity['totalFeedConsumed'] ??
                    data['totalFeedConsumed'] ??
                    '',
                'feedPerDay':
                    commodity['feedPerDay'] ?? data['feedPerDay'] ?? '',
                'waterSources':
                    commodity['waterSources'] ?? data['waterSources'] ?? [],
                'sacksManureProduced': commodity['sacksManureProduced'] ??
                    data['sacksManureProduced'] ??
                    '',
                'sacksManureSold': commodity['sacksManureSold'] ??
                    data['sacksManureSold'] ??
                    '',
                'sacksManureUsed': commodity['sacksManureUsed'] ??
                    data['sacksManureUsed'] ??
                    '',
                'manurePricePerSack': commodity['manurePricePerSack'] ??
                    data['manurePricePerSack'] ??
                    '',
                'hasPest': commodity['hasPest'] ?? data['hasPest'] ?? false,
                'pestOccurrence':
                    commodity['pestOccurrence'] ?? data['pestOccurrence'] ?? '',
                'pestDate': commodity['pestDate'] ?? data['pestDate'] ?? '',
                'pestMortality':
                    commodity['pestMortality'] ?? data['pestMortality'] ?? '',
                'hasDisease':
                    commodity['hasDisease'] ?? data['hasDisease'] ?? false,
                'diseaseOccurrence': commodity['diseaseOccurrence'] ??
                    data['diseaseOccurrence'] ??
                    '',
                'diseaseDate':
                    commodity['diseaseDate'] ?? data['diseaseDate'] ?? '',
                'diseaseMortality': commodity['diseaseMortality'] ??
                    data['diseaseMortality'] ??
                    '',
                'hasEnvHazard':
                    commodity['hasEnvHazard'] ?? data['hasEnvHazard'] ?? false,
                'envOccurrence':
                    commodity['envOccurrence'] ?? data['envOccurrence'] ?? '',
                'envDate': commodity['envDate'] ?? data['envDate'] ?? '',
                'envMortality':
                    commodity['envMortality'] ?? data['envMortality'] ?? '',
                'hasHumanInduced': commodity['hasHumanInduced'] ??
                    data['hasHumanInduced'] ??
                    false,
                'humanOccurrence': commodity['humanOccurrence'] ??
                    data['humanOccurrence'] ??
                    '',
                'humanDate': commodity['humanDate'] ?? data['humanDate'] ?? '',
                'humanMortality':
                    commodity['humanMortality'] ?? data['humanMortality'] ?? '',
                'treatment': commodity['treatment'] ?? data['treatment'] ?? '',
                'attachedReport':
                    commodity['attachedReport'] ?? data['attachedReport'] ?? '',
                'totalMortalities': commodity['totalMortalities'] ??
                    data['totalMortalities'] ??
                    '',
                'rejectsCulled':
                    commodity['rejectsCulled'] ?? data['rejectsCulled'] ?? '',
                'remainingStocks': commodity['remainingStocks'] ??
                    data['remainingStocks'] ??
                    '',
              });
              break;
            default:
              commodityData.addAll({
                'typeOfCrop': commodity['typeOfCrop'] ?? '',
                'variety': commodity['variety'] ?? '',
                'breed': commodity['breed'] ?? '',
                'inputsReceived': commodity['inputsReceived'] ?? [],
                'inputsPurchased': commodity['inputsPurchased'] ?? [],
                'farmgatePrices': commodity['farmgatePrices'] ?? {},
              });
          }

          // ✅ COLLECTIVE GLOBAL COMMODITY ID - using globally tracked number
          final currentNumber = globalNextNumber + i;
          final commodityId =
              '${typePrefix}_${currentNumber.toString().padLeft(3, '0')}';

          commodityData['commodityId'] = commodityId;
          commodity['commodityId'] = commodityId;

          await groupDocRef
              .collection('commodities')
              .doc(commodityId)
              .set(commodityData);
        }

        if (kDebugMode) {
          print('✅ COLLECTIVE STRUCTURE SAVED');
          print('   FCA: $fcaName');
          print(
              '   Production Type: $productionType → $detectedType ($typePrefix)');
          print('   Implementation: $implementationType');
          print('   Commodities: ${completedCommodities.length}');
        }

        return groupDocId;
      }

      // ✅ INDIVIDUAL/HYBRID: Save each farmer in members subcollection with their commodities
      print('📋 INDIVIDUAL/HYBRID PATH:');
      print('   membersByFarmerId keys: ${membersByFarmerId.keys.toList()}');
      print('   Total members to sync: ${membersByFarmerId.length}');

      for (final saadId in membersByFarmerId.keys) {
        try {
          print('🌾 Processing member: $saadId');
          final farmer = membersByFarmerId[saadId];
          if (farmer is Map<String, dynamic>) {
            final farmerName =
                (farmer['farmerName'] as String? ?? saadId).trim();
            final farmerSaadId = (farmer['saadIdNo'] as String? ?? '').trim();

            print('   Name: $farmerName | SAAD: $farmerSaadId');

            // LEVEL 2: Save PERSONAL DATA in members subcollection
            // NOTE: Only farmer's name and trainings - location is at FCA level
            final personalData = {
              'name': farmerName,
              'farmerName': farmerName,
              'saadIdNo': farmerSaadId,
              'trainings': farmer['trainings'] ?? [],
              'addedAt': FieldValue.serverTimestamp(),
            };

            final memberDocRef = groupDocRef.collection('members').doc(saadId);
            print('   ✍️ Writing personal data to members/$saadId');
            await memberDocRef.set(personalData, SetOptions(merge: true));
            print('   ✅ Personal data saved');

            // LEVEL 3: Save each farmer's COMMODITIES in commodities subcollection
            // Filter commodities that belong to this farmer
            // Match by either saadIdNo (if not empty) OR farmerName (if saadIdNo is empty)
            print(
                '   🔍 Filtering commodities for farmer: $farmerName (saadId: $farmerSaadId)');
            print(
                '      Total completedCommodities: ${completedCommodities.length}');

            final farmerCommodities = completedCommodities.where((c) {
              final commoditySaadId = (c['saadIdNo'] as String? ?? '').trim();
              final commodityFarmerName =
                  (c['farmerName'] as String? ?? '').trim();

              print(
                  '      - Checking commodity: farmerName="$commodityFarmerName" saadId="$commoditySaadId"');

              // Match if saadIdNo matches, OR if both are using farmerName as identifier
              if (farmerSaadId.isNotEmpty && commoditySaadId.isNotEmpty) {
                final matches = commoditySaadId == farmerSaadId;
                print('        → Match by saadId: $matches');
                return matches;
              } else if (farmerSaadId.isEmpty &&
                  commodityFarmerName.isNotEmpty) {
                // Both using farmerName as identifier
                final matches = commodityFarmerName == farmerName;
                print('        → Match by farmerName: $matches');
                return matches;
              }
              print('        → No match (both identifiers empty)');
              return false;
            }).toList();

            print(
                '   ✅ Matched ${farmerCommodities.length} commodities for $farmerName');

            // ✅ GLOBAL NUMBERING: Get starting number for this production type
            final startingId = CommodityIdService.generateCommodityId(
              productionType,
              completedCommodities, // Pass ALL commodities for global count
            );
            int startingNumber = CommodityIdService.getNumberFromId(startingId);

            for (int i = 0; i < farmerCommodities.length; i++) {
              final commodity = farmerCommodities[i];

              // 🔍 DEBUG: Log damage fields before sync
              print('   📦 Commodity $i fields:');
              print('      - hasPest: ${commodity['hasPest']}');
              print('      - pestOccurrence: ${commodity['pestOccurrence']}');
              print('      - pestDamageArea: ${commodity['pestDamageArea']}');
              print('      - pestDamageHa: ${commodity['pestDamageHa']}');
              print('      - pestTreatment: ${commodity['pestTreatment']}');
              print('      - pestAttached: ${commodity['pestAttached']}');

              final commodityData = <String, dynamic>{
                'saadIdNo': saadId,
                'farmerName': farmerName,
                'recordedAt': FieldValue.serverTimestamp(),
              };
              switch (productionType.toLowerCase()) {
                case 'crop':
                  commodityData.addAll({
                    'typeOfCrop': commodity['typeOfCrop'] ?? '',
                    'variety': commodity['variety'] ?? '',
                    'inputsReceived': commodity['inputsReceived'] ?? [],
                    'inputsPurchased': commodity['inputsPurchased'] ?? [],
                    'farmgatePrices': commodity['farmgatePrices'] ?? {},
                    'totalCostPurchased': commodity['totalCostPurchased'] ?? '',
                    'qtyVsArea': commodity['qtyVsArea'] ?? '',
                    'croppingCycles': commodity['croppingCycles'] ?? '',
                    'qtyVsCycles': commodity['qtyVsCycles'] ?? '',
                    'peakVolume': commodity['peakVolume'] ?? '',
                    'peakMonth': commodity['peakMonth'] ?? '',
                    'volumesPerCycle': commodity['volumesPerCycle'] ?? [],
                    'farmgatePrice': commodity['farmgatePrice'] ?? '',
                    'totalLandArea': commodity['totalLandArea'] ??
                        data['totalLandArea'] ??
                        '',
                    'landOwnership': commodity['landOwnership'] ??
                        data['landOwnership'] ??
                        '',
                    'landOwnershipOther': commodity['landOwnershipOther'] ??
                        data['landOwnershipOther'] ??
                        '',
                    'usufructAgreement': commodity['usufructAgreement'] ??
                        data['usufructAgreement'] ??
                        '',
                    'landRemarks':
                        commodity['landRemarks'] ?? data['landRemarks'] ?? [],
                    'machineryType': commodity['machineryType'] ??
                        data['machineryType'] ??
                        '',
                    'machineryOther': commodity['machineryOther'] ??
                        data['machineryOther'] ??
                        '',
                    'machineryRemarks': commodity['machineryRemarks'] ??
                        data['machineryRemarks'] ??
                        [],
                    'landPrepCostPerCycle': commodity['landPrepCostPerCycle'] ??
                        data['landPrepCostPerCycle'] ??
                        [],
                    'landPrepStartDate': commodity['landPrepStartDate'] ??
                        data['landPrepStartDate'] ??
                        '',
                    'landPrepDays':
                        commodity['landPrepDays'] ?? data['landPrepDays'] ?? '',
                    'sourceOfWater': commodity['sourceOfWater'] ??
                        data['sourceOfWater'] ??
                        '',
                    'plantingDate':
                        commodity['plantingDate'] ?? data['plantingDate'] ?? '',
                    'seedAmount':
                        commodity['seedAmount'] ?? data['seedAmount'] ?? '',
                    'seedUnit': commodity['seedUnit'] ?? data['seedUnit'] ?? '',
                    'germinationRate': commodity['germinationRate'] ??
                        data['germinationRate'] ??
                        '',
                    'goodGermination': commodity['goodGermination'] ??
                        data['goodGermination'] ??
                        '',
                    'germinationReason': commodity['germinationReason'] ??
                        data['germinationReason'] ??
                        '',
                    'fertilizerType': commodity['fertilizerType'] ??
                        data['fertilizerType'] ??
                        '',
                    'organicSource': commodity['organicSource'] ??
                        data['organicSource'] ??
                        '',
                    'organicBagsSAAD': commodity['organicBagsSAAD'] ??
                        data['organicBagsSAAD'] ??
                        '',
                    'organicBagsCommercial':
                        commodity['organicBagsCommercial'] ??
                            data['organicBagsCommercial'] ??
                            '',
                    'organicTotalCost': commodity['organicTotalCost'] ??
                        data['organicTotalCost'] ??
                        '',
                    'organicBagsCycle': commodity['organicBagsCycle'] ??
                        data['organicBagsCycle'] ??
                        [],
                    'organicFrequency': commodity['organicFrequency'] ??
                        data['organicFrequency'] ??
                        '',
                    'inorganicType': commodity['inorganicType'] ??
                        data['inorganicType'] ??
                        '',
                    'inorganicBagsSAAD': commodity['inorganicBagsSAAD'] ??
                        data['inorganicBagsSAAD'] ??
                        '',
                    'inorganicMeasure': commodity['inorganicMeasure'] ??
                        data['inorganicMeasure'] ??
                        '',
                    'inorganicTotalCost': commodity['inorganicTotalCost'] ??
                        data['inorganicTotalCost'] ??
                        '',
                    'inorganicBagsCycle': commodity['inorganicBagsCycle'] ??
                        data['inorganicBagsCycle'] ??
                        [],
                    'inorganicFrequency': commodity['inorganicFrequency'] ??
                        data['inorganicFrequency'] ??
                        '',
                    'pesticideRequirement': commodity['pesticideRequirement'] ??
                        data['pesticideRequirement'] ??
                        '',
                    'landAreaCycles': commodity['landAreaCycles'] ??
                        data['landAreaCycles'] ??
                        [],
                    'dateHarvestCycles': commodity['dateHarvestCycles'] ??
                        data['dateHarvestCycles'] ??
                        [],
                    'quantityCycles': commodity['quantityCycles'] ??
                        data['quantityCycles'] ??
                        [],
                    'avgHarvestPerHa': commodity['avgHarvestPerHa'] ??
                        data['avgHarvestPerHa'] ??
                        '',
                    'harvestCostCycles': commodity['harvestCostCycles'] ??
                        data['harvestCostCycles'] ??
                        [],
                    'foodConsumptionPct': commodity['foodConsumptionPct'] ??
                        data['foodConsumptionPct'] ??
                        '',
                    'postharvestRemarks': commodity['postharvestRemarks'] ??
                        data['postharvestRemarks'] ??
                        [],
                    'processingRemarks': commodity['processingRemarks'] ??
                        data['processingRemarks'] ??
                        [],

                    // ✅ PEST DAMAGE FIELDS (Step 06) - NOW INCLUDED FOR SYNC
                    'hasPest': commodity['hasPest'] ?? data['hasPest'] ?? false,
                    'pestOccurrence': commodity['pestOccurrence'] ??
                        data['pestOccurrence'] ??
                        '',
                    'pestDate': commodity['pestDate'] ?? data['pestDate'] ?? '',
                    'pestDamageArea': commodity['pestDamageArea'] ??
                        data['pestDamageArea'] ??
                        '',
                    'pestDamageHa':
                        commodity['pestDamageHa'] ?? data['pestDamageHa'] ?? '',
                    'pestTreatment': commodity['pestTreatment'] ??
                        data['pestTreatment'] ??
                        '',
                    'pestAttached':
                        commodity['pestAttached'] ?? data['pestAttached'] ?? '',

                    // ✅ DISEASE DAMAGE FIELDS (Step 06)
                    'hasDisease':
                        commodity['hasDisease'] ?? data['hasDisease'] ?? false,
                    'diseaseOccurrence': commodity['diseaseOccurrence'] ??
                        data['diseaseOccurrence'] ??
                        '',
                    'diseaseDate':
                        commodity['diseaseDate'] ?? data['diseaseDate'] ?? '',
                    'diseaseDamageArea': commodity['diseaseDamageArea'] ??
                        data['diseaseDamageArea'] ??
                        '',
                    'diseaseDamageHa': commodity['diseaseDamageHa'] ??
                        data['diseaseDamageHa'] ??
                        '',
                    'diseaseTreatment': commodity['diseaseTreatment'] ??
                        data['diseaseTreatment'] ??
                        '',
                    'diseaseAttached': commodity['diseaseAttached'] ??
                        data['diseaseAttached'] ??
                        '',

                    // ✅ ENVIRONMENTAL HAZARD FIELDS (Step 06)
                    'hasEnvHazard': commodity['hasEnvHazard'] ??
                        data['hasEnvHazard'] ??
                        false,
                    'envHazards':
                        commodity['envHazards'] ?? data['envHazards'] ?? [],
                    'envDate': commodity['envDate'] ?? data['envDate'] ?? '',
                    'envDamageArea': commodity['envDamageArea'] ??
                        data['envDamageArea'] ??
                        '',
                    'envDamageHa':
                        commodity['envDamageHa'] ?? data['envDamageHa'] ?? '',
                    'envTreatment':
                        commodity['envTreatment'] ?? data['envTreatment'] ?? '',
                    'envAttached':
                        commodity['envAttached'] ?? data['envAttached'] ?? '',

                    // ✅ HUMAN DAMAGE FIELDS (Step 06)
                    'hasHumanDamage': commodity['hasHumanDamage'] ??
                        data['hasHumanDamage'] ??
                        false,
                    'humanDamage':
                        commodity['humanDamage'] ?? data['humanDamage'] ?? '',
                    'humanMortality': commodity['humanMortality'] ??
                        data['humanMortality'] ??
                        '',
                    'humanTreatment': commodity['humanTreatment'] ??
                        data['humanTreatment'] ??
                        '',
                    'humanAttached': commodity['humanAttached'] ??
                        data['humanAttached'] ??
                        '',
                  });

                  // 🔍 DEBUG: Log what's being sent to Firebase
                  print('      ✅ Syncing crop commodity to Firebase:');
                  print('         - hasPest: ${commodityData['hasPest']}');
                  print(
                      '         - pestOccurrence: ${commodityData['pestOccurrence']}');
                  print(
                      '         - pestDamageArea: ${commodityData['pestDamageArea']}');
                  print(
                      '         - pestDamageHa: ${commodityData['pestDamageHa']}');
                  print(
                      '         - pestTreatment: ${commodityData['pestTreatment']}');

                  break;
                case 'livestock':
                  commodityData.addAll({
                    'breed': commodity['breed'] ?? '',
                    'inputsReceived': commodity['inputsReceived'] ?? [],
                    'inputsPurchased': commodity['inputsPurchased'] ?? [],
                    'farmgatePrices': commodity['farmgatePrices'] ?? [],
                    'stocksReceived': commodity['stocksReceived'] ??
                        data['stocksReceived'] ??
                        '',
                    'dateReceived':
                        commodity['dateReceived'] ?? data['dateReceived'] ?? '',
                    'maleStocks':
                        commodity['maleStocks'] ?? data['maleStocks'] ?? '',
                    'femaleStocks':
                        commodity['femaleStocks'] ?? data['femaleStocks'] ?? '',
                    'maleToFemaleRatio': commodity['maleToFemaleRatio'] ??
                        data['maleToFemaleRatio'] ??
                        '',
                    'ageUponReceipt': commodity['ageUponReceipt'] ??
                        data['ageUponReceipt'] ??
                        '',
                    'avgWeightUponReceipt': commodity['avgWeightUponReceipt'] ??
                        data['avgWeightUponReceipt'] ??
                        '',
                    'meatProduced':
                        commodity['meatProduced'] ?? data['meatProduced'] ?? '',
                    'pregnantStocks': commodity['pregnantStocks'] ??
                        data['pregnantStocks'] ??
                        '',
                    'housingType':
                        commodity['housingType'] ?? data['housingType'] ?? '',
                    'farmOwnership': commodity['farmOwnership'] ??
                        data['farmOwnership'] ??
                        '',
                    'farmOwnershipOther': commodity['farmOwnershipOther'] ??
                        data['farmOwnershipOther'] ??
                        '',
                    'usufruct': commodity['usufruct'] ?? data['usufruct'] ?? '',
                    'usufructRemarks': commodity['usufructRemarks'] ??
                        data['usufructRemarks'] ??
                        '',
                    'healthActivities': commodity['healthActivities'] ??
                        data['healthActivities'] ??
                        '',
                    'healthOthers':
                        commodity['healthOthers'] ?? data['healthOthers'] ?? '',
                    'wasteManagement': commodity['wasteManagement'] ??
                        data['wasteManagement'] ??
                        '',
                    'growOutPeriod': commodity['growOutPeriod'] ??
                        data['growOutPeriod'] ??
                        '',
                    'lactationPeriod': commodity['lactationPeriod'] ??
                        data['lactationPeriod'] ??
                        '',
                    'dryPeriod':
                        commodity['dryPeriod'] ?? data['dryPeriod'] ?? '',
                    'producedOffspring': commodity['producedOffspring'] ??
                        data['producedOffspring'] ??
                        '',
                    'offspringMale': commodity['offspringMale'] ??
                        data['offspringMale'] ??
                        '',
                    'offspringFemale': commodity['offspringFemale'] ??
                        data['offspringFemale'] ??
                        '',
                    'offspringMFRatio': commodity['offspringMFRatio'] ??
                        data['offspringMFRatio'] ??
                        '',
                    'mortalitiesAfterBirth':
                        commodity['mortalitiesAfterBirth'] ??
                            data['mortalitiesAfterBirth'] ??
                            '',
                    'remainingOffspring': commodity['remainingOffspring'] ??
                        data['remainingOffspring'] ??
                        '',
                    'grazingArea':
                        commodity['grazingArea'] ?? data['grazingArea'] ?? '',
                    'feeds': commodity['feeds'] ?? data['feeds'] ?? [],
                    'waterSources':
                        commodity['waterSources'] ?? data['waterSources'] ?? [],
                    'soldAsLiveweight': commodity['soldAsLiveweight'] ??
                        data['soldAsLiveweight'] ??
                        '',
                    'soldAsLiveweightRemarks':
                        commodity['soldAsLiveweightRemarks'] ??
                            data['soldAsLiveweightRemarks'] ??
                            '',
                    'avgMarketableWeight': commodity['avgMarketableWeight'] ??
                        data['avgMarketableWeight'] ??
                        '',
                    'milkVolumeDaily': commodity['milkVolumeDaily'] ??
                        data['milkVolumeDaily'] ??
                        '',
                    'farmgatePriceMilk': commodity['farmgatePriceMilk'] ??
                        data['farmgatePriceMilk'] ??
                        '',
                    'milkUnit': commodity['milkUnit'] ?? data['milkUnit'] ?? '',
                    'slaughteredCount': commodity['slaughteredCount'] ??
                        data['slaughteredCount'] ??
                        '',
                    'slaughteredPrice': commodity['slaughteredPrice'] ??
                        data['slaughteredPrice'] ??
                        '',
                    'postharvest':
                        commodity['postharvest'] ?? data['postharvest'] ?? '',
                    'postharvestRemarks': commodity['postharvestRemarks'] ??
                        data['postharvestRemarks'] ??
                        '',
                    'processing':
                        commodity['processing'] ?? data['processing'] ?? '',
                    'processingRemarks': commodity['processingRemarks'] ??
                        data['processingRemarks'] ??
                        '',
                  });
                  break;
                case 'poultry':
                  commodityData.addAll({
                    'breed': commodity['breed'] ?? '',
                    'inputsReceived': commodity['inputsReceived'] ?? [],
                    'inputsPurchased': commodity['inputsPurchased'] ?? [],
                    'farmgatePrices': commodity['farmgatePrices'] ?? [],
                    'stocksReceived': commodity['stocksReceived'] ??
                        data['stocksReceived'] ??
                        '',
                    'dateReceived':
                        commodity['dateReceived'] ?? data['dateReceived'] ?? '',
                    'ageUponReceipt': commodity['ageUponReceipt'] ??
                        data['ageUponReceipt'] ??
                        '',
                    'avgWeightUponReceipt': commodity['avgWeightUponReceipt'] ??
                        data['avgWeightUponReceipt'] ??
                        '',
                    'totalProductiveCycle': commodity['totalProductiveCycle'] ??
                        data['totalProductiveCycle'] ??
                        '',
                    'housingType':
                        commodity['housingType'] ?? data['housingType'] ?? '',
                    'landOwnership': commodity['landOwnership'] ??
                        data['landOwnership'] ??
                        '',
                    'landOwnershipOther': commodity['landOwnershipOther'] ??
                        data['landOwnershipOther'] ??
                        '',
                    'usufruct': commodity['usufruct'] ?? data['usufruct'] ?? '',
                    'maleToFemaleRatio': commodity['maleToFemaleRatio'] ??
                        data['maleToFemaleRatio'] ??
                        '',
                    'eggsProduced':
                        commodity['eggsProduced'] ?? data['eggsProduced'] ?? '',
                    'fertilEggs':
                        commodity['fertilEggs'] ?? data['fertilEggs'] ?? '',
                    'eggsIncubated': commodity['eggsIncubated'] ??
                        data['eggsIncubated'] ??
                        '',
                    'eggsHatched':
                        commodity['eggsHatched'] ?? data['eggsHatched'] ?? '',
                    'hatchingRate':
                        commodity['hatchingRate'] ?? data['hatchingRate'] ?? '',
                    'mortalitiesAfterHatch':
                        commodity['mortalitiesAfterHatch'] ??
                            data['mortalitiesAfterHatch'] ??
                            '',
                    'chicksSold':
                        commodity['chicksSold'] ?? data['chicksSold'] ?? '',
                    'eggsSold': commodity['eggsSold'] ?? data['eggsSold'] ?? '',
                    'harvestedBirds': commodity['harvestedBirds'] ??
                        data['harvestedBirds'] ??
                        '',
                    'totalWeightHarvested': commodity['totalWeightHarvested'] ??
                        data['totalWeightHarvested'] ??
                        '',
                    'avgDailyGain':
                        commodity['avgDailyGain'] ?? data['avgDailyGain'] ?? '',
                    'harvestRecovery': commodity['harvestRecovery'] ??
                        data['harvestRecovery'] ??
                        '',
                    'avgLiveWeight': commodity['avgLiveWeight'] ??
                        data['avgLiveWeight'] ??
                        '',
                    'feedConversionRatio': commodity['feedConversionRatio'] ??
                        data['feedConversionRatio'] ??
                        '',
                    'avgAgeHarvested': commodity['avgAgeHarvested'] ??
                        data['avgAgeHarvested'] ??
                        '',
                    'broilerPerformanceIndex':
                        commodity['broilerPerformanceIndex'] ??
                            data['broilerPerformanceIndex'] ??
                            '',
                    'rangingAge':
                        commodity['rangingAge'] ?? data['rangingAge'] ?? '',
                    'totalEggsHarvested': commodity['totalEggsHarvested'] ??
                        data['totalEggsHarvested'] ??
                        '',
                    'avgHarvestRate': commodity['avgHarvestRate'] ??
                        data['avgHarvestRate'] ??
                        '',
                    'weeklyHenDayEggProduction':
                        commodity['weeklyHenDayEggProduction'] ??
                            data['weeklyHenDayEggProduction'] ??
                            '',
                    'weeklyHDEPFile': commodity['weeklyHDEPFile'] ??
                        data['weeklyHDEPFile'] ??
                        '',
                    'daysUnderMolting': commodity['daysUnderMolting'] ??
                        data['daysUnderMolting'] ??
                        '',
                    'feedType': commodity['feedType'] ?? data['feedType'] ?? '',
                    'totalFeedConsumed': commodity['totalFeedConsumed'] ??
                        data['totalFeedConsumed'] ??
                        '',
                    'feedPerDay':
                        commodity['feedPerDay'] ?? data['feedPerDay'] ?? '',
                    'waterSources':
                        commodity['waterSources'] ?? data['waterSources'] ?? [],
                    'sacksManureProduced': commodity['sacksManureProduced'] ??
                        data['sacksManureProduced'] ??
                        '',
                    'sacksManureSold': commodity['sacksManureSold'] ??
                        data['sacksManureSold'] ??
                        '',
                    'sacksManureUsed': commodity['sacksManureUsed'] ??
                        data['sacksManureUsed'] ??
                        '',
                    'manurePricePerSack': commodity['manurePricePerSack'] ??
                        data['manurePricePerSack'] ??
                        '',
                    'hasPest': commodity['hasPest'] ?? data['hasPest'] ?? false,
                    'pestOccurrence': commodity['pestOccurrence'] ??
                        data['pestOccurrence'] ??
                        '',
                    'pestDate': commodity['pestDate'] ?? data['pestDate'] ?? '',
                    'pestMortality': commodity['pestMortality'] ??
                        data['pestMortality'] ??
                        '',
                    'hasDisease':
                        commodity['hasDisease'] ?? data['hasDisease'] ?? false,
                    'diseaseOccurrence': commodity['diseaseOccurrence'] ??
                        data['diseaseOccurrence'] ??
                        '',
                    'diseaseDate':
                        commodity['diseaseDate'] ?? data['diseaseDate'] ?? '',
                    'diseaseMortality': commodity['diseaseMortality'] ??
                        data['diseaseMortality'] ??
                        '',
                    'hasEnvHazard': commodity['hasEnvHazard'] ??
                        data['hasEnvHazard'] ??
                        false,
                    'envOccurrence': commodity['envOccurrence'] ??
                        data['envOccurrence'] ??
                        '',
                    'envDate': commodity['envDate'] ?? data['envDate'] ?? '',
                    'envMortality':
                        commodity['envMortality'] ?? data['envMortality'] ?? '',
                    'hasHumanInduced': commodity['hasHumanInduced'] ??
                        data['hasHumanInduced'] ??
                        false,
                    'humanOccurrence': commodity['humanOccurrence'] ??
                        data['humanOccurrence'] ??
                        '',
                    'humanDate':
                        commodity['humanDate'] ?? data['humanDate'] ?? '',
                    'humanMortality': commodity['humanMortality'] ??
                        data['humanMortality'] ??
                        '',
                    'treatment':
                        commodity['treatment'] ?? data['treatment'] ?? '',
                    'attachedReport': commodity['attachedReport'] ??
                        data['attachedReport'] ??
                        '',
                    'totalMortalities': commodity['totalMortalities'] ??
                        data['totalMortalities'] ??
                        '',
                    'rejectsCulled': commodity['rejectsCulled'] ??
                        data['rejectsCulled'] ??
                        '',
                    'remainingStocks': commodity['remainingStocks'] ??
                        data['remainingStocks'] ??
                        '',
                  });
                  break;
                default:
                  commodityData.addAll({
                    'typeOfCrop': commodity['typeOfCrop'] ?? '',
                    'variety': commodity['variety'] ?? '',
                    'breed': commodity['breed'] ?? '',
                    'inputsReceived': commodity['inputsReceived'] ?? [],
                    'inputsPurchased': commodity['inputsPurchased'] ?? [],
                    'farmgatePrices': commodity['farmgatePrices'] ?? {},
                  });
              }

              // ✅ GLOBAL COMMODITY ID: Sequential numbering across all farmers
              final currentNumber = startingNumber + i;
              final commodityId =
                  '${typePrefix}_${currentNumber.toString().padLeft(3, '0')}';

              commodityData['commodityId'] = commodityId;

              // ✅ Update completedCommodities array so next farmer's count is accurate
              commodity['commodityId'] = commodityId;

              print('   📤 Writing commodity $commodityId to Firebase');
              await memberDocRef
                  .collection('commodities')
                  .doc(commodityId)
                  .set(commodityData);
              print('   ✅ Commodity $commodityId saved');
            }
            print('   ✅ All commodities saved for member: $farmerName');
          }
        } catch (e) {
          print('❌ ERROR processing member $saadId: $e');
          print('   Stack trace: ${StackTrace.current}');
          rethrow;
        }
      }
      print('✅ All members processed successfully');

      if (kDebugMode) {
        print('✅ 3-LEVEL HIERARCHICAL STRUCTURE SAVED');
        print('   FCA: $fcaName');
        print(
            '   Production Type: $productionType → $detectedType ($typePrefix)');
        print('   Implementation: $implementationType');
        print('   Members: ${membersByFarmerId.length}');
        for (final saadId in membersByFarmerId.keys) {
          final memberCommodities = completedCommodities
              .where((c) => (c['saadIdNo'] as String? ?? '') == saadId)
              .length;
          print(
              '     - ${membersByFarmerId[saadId]['farmerName']}: $memberCommodities commodity/ies');
        }
      }

      print('🎉 savePendingRecord COMPLETED SUCCESSFULLY');
      return groupDocId;
    } catch (e) {
      print('❌❌❌ savePendingRecord FAILED: $e');
      print('   Error type: ${e.runtimeType}');
      print('   Stack: ${StackTrace.current}');
      rethrow;
    }
  }

  /// Fetch pending records with 3-level hierarchy (FCA → Members → Commodities)
  Future<List<Map<String, dynamic>>> fetchPendingRecords({
    String? createdBy,
    int limit = 200,
  }) async {
    Query<Map<String, dynamic>> query =
        _firestore.collection(_pendingCollection);

    if (createdBy != null && createdBy.isNotEmpty) {
      query = query.where('createdBy', isEqualTo: createdBy);
    }

    final snapshot = await query
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .get(const GetOptions(source: Source.server));

    final records = <Map<String, dynamic>>[];

    for (final doc in snapshot.docs) {
      final data = {
        ...doc.data(),
        'id': doc.id,
        'documentPath': doc.reference.path
      };

      // ✅ LEVEL 2: Fetch all members with their commodities
      try {
        final membersSnapshot = await doc.reference.collection('members').get();
        print(
            '🔍 fetchPendingRecords: Found ${membersSnapshot.docs.length} members');
        if (membersSnapshot.docs.isNotEmpty) {
          // Build membersByFarmerId map
          final membersByFarmerId = <String, dynamic>{};
          final members = <Map<String, dynamic>>[];

          int memberIndex = 0;
          for (final memberDoc in membersSnapshot.docs) {
            memberIndex++;
            final memberData = memberDoc.data();
            final saadId = memberDoc.id;
            print(
                '🔍 fetchPendingRecords - Member #$memberIndex: saadId=$saadId');

            if (saadId.isNotEmpty) {
              // ✅ LEVEL 3: Fetch commodities for this member
              print('   🔍 Fetching commodities for saadId=$saadId...');
              final commoditiesSnapshot =
                  await memberDoc.reference.collection('commodities').get();

              print(
                  '   ✅ Got ${commoditiesSnapshot.docs.length} commodities for saadId=$saadId');
              final commodities = <Map<String, dynamic>>[];
              for (final commodityDoc in commoditiesSnapshot.docs) {
                final commodityData = {
                  'id': commodityDoc.id,
                  ...commodityDoc.data()
                };

                // 🔍 DEBUG: Log damage fields from Firebase
                print('🔍 fetchPendingRecords - Member commodity:');
                print('   - commodityId: ${commodityData['commodityId']}');
                print('   - hasPest: ${commodityData['hasPest']}');
                print(
                    '   - pestOccurrence: ${commodityData['pestOccurrence']}');
                print(
                    '   - pestDamageArea: ${commodityData['pestDamageArea']}');
                print('   - pestDamageHa: ${commodityData['pestDamageHa']}');
                print('   - pestTreatment: ${commodityData['pestTreatment']}');

                commodities.add(commodityData);
              }

              // Normalize member name for display and compatibility with older records
              memberData['name'] = (memberData['name'] as String?)?.trim() ??
                  (memberData['farmerName'] as String?)?.trim() ??
                  '';

              // Add commodities to member data
              memberData['commodities'] = commodities;
              print(
                  '   ✅ Added ${commodities.length} commodities to memberData[saadId=$saadId]');

              membersByFarmerId[saadId] = memberData;
              members.add({'id': memberDoc.id, ...memberData});
            }
          }

          if (membersByFarmerId.isNotEmpty) {
            // Only include the hierarchical map for group records.
            print(
                '✅ fetchPendingRecords: Adding membersByFarmerId with ${membersByFarmerId.length} members');
            data['membersByFarmerId'] = membersByFarmerId;
          }
        } else {
          // Fallback for older individual records saved with a root-level commodities collection
          final rootCommoditiesSnapshot =
              await doc.reference.collection('commodities').get();
          if (rootCommoditiesSnapshot.docs.isNotEmpty) {
            final rootCommodities = <Map<String, dynamic>>[];
            for (final commodityDoc in rootCommoditiesSnapshot.docs) {
              final commodityData = {
                'id': commodityDoc.id,
                ...commodityDoc.data()
              };

              // 🔍 DEBUG: Log damage fields from Firebase
              print('🔍 fetchPendingRecords - Root commodity:');
              print('   - commodityId: ${commodityData['commodityId']}');
              print('   - hasPest: ${commodityData['hasPest']}');
              print('   - pestOccurrence: ${commodityData['pestOccurrence']}');
              print('   - pestDamageArea: ${commodityData['pestDamageArea']}');
              print('   - pestDamageHa: ${commodityData['pestDamageHa']}');
              print('   - pestTreatment: ${commodityData['pestTreatment']}');

              rootCommodities.add(commodityData);
            }
            data['commodities'] = rootCommodities;
          }
        }
      } catch (e) {
        if (kDebugMode) print('Error fetching members: $e');
      }

      records.add(data);
    }

    return records;
  }

  /// Fetch approved records with 3-level hierarchy (FCA → Members → Commodities)
  Future<List<Map<String, dynamic>>> fetchApprovedRecords({
    String? createdBy,
    int limit = 200,
  }) async {
    Query<Map<String, dynamic>> query =
        _firestore.collection(_approvedCollection);

    if (createdBy != null && createdBy.isNotEmpty) {
      query = query.where('createdBy', isEqualTo: createdBy);
    }

    final snapshot = await query
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .get(const GetOptions(source: Source.server));

    final records = <Map<String, dynamic>>[];

    for (final doc in snapshot.docs) {
      final data = {
        ...doc.data(),
        'id': doc.id,
        'documentPath': doc.reference.path
      };

      // ✅ LEVEL 2: Fetch all members with their commodities
      try {
        final membersSnapshot = await doc.reference.collection('members').get();
        if (membersSnapshot.docs.isNotEmpty) {
          // Build membersByFarmerId map
          final membersByFarmerId = <String, dynamic>{};
          final members = <Map<String, dynamic>>[];

          for (final memberDoc in membersSnapshot.docs) {
            final memberData = memberDoc.data();
            final saadId = memberDoc.id;

            if (saadId.isNotEmpty) {
              // ✅ LEVEL 3: Fetch commodities for this member
              final commoditiesSnapshot =
                  await memberDoc.reference.collection('commodities').get();

              final commodities = <Map<String, dynamic>>[];
              for (final commodityDoc in commoditiesSnapshot.docs) {
                commodities
                    .add({'id': commodityDoc.id, ...commodityDoc.data()});
              }

              // Normalize member name for display and compatibility with older records
              memberData['name'] = (memberData['name'] as String?)?.trim() ??
                  (memberData['farmerName'] as String?)?.trim() ??
                  '';

              // Add commodities to member data
              memberData['commodities'] = commodities;

              membersByFarmerId[saadId] = memberData;
              members.add({'id': memberDoc.id, ...memberData});
            }
          }

          if (membersByFarmerId.isNotEmpty) {
            // Only include the hierarchical map for group records.
            data['membersByFarmerId'] = membersByFarmerId;
          }
        } else {
          // Fallback for older individual records saved with a root-level commodities collection
          final rootCommoditiesSnapshot =
              await doc.reference.collection('commodities').get();
          if (rootCommoditiesSnapshot.docs.isNotEmpty) {
            final rootCommodities = <Map<String, dynamic>>[];
            for (final commodityDoc in rootCommoditiesSnapshot.docs) {
              rootCommodities
                  .add({'id': commodityDoc.id, ...commodityDoc.data()});
            }
            data['commodities'] = rootCommodities;
          }
        }
      } catch (e) {
        if (kDebugMode) print('Error fetching members: $e');
      }

      records.add(data);
    }

    return records;
  }

  /// Approve a pending record - move to approved_monitoring with 3-level hierarchy
  /// Only moderator/admin can approve
  Future<void> approveRecord({
    required String recordId,
    required bool isModerator,
    required bool isAdmin,
  }) async {
    if (!isModerator && !isAdmin) {
      throw Exception('Only moderators and admins can approve records');
    }

    try {
      final pendingDocRef =
          _firestore.collection(_pendingCollection).doc(recordId);
      final pendingDoc = await pendingDocRef.get();

      if (!pendingDoc.exists) {
        throw Exception('Record not found');
      }

      // ✅ LEVEL 1: Get project background data
      final data = pendingDoc.data() ?? {};

      // Create record in approved collection with same FCA document
      final approvedDocRef =
          _firestore.collection(_approvedCollection).doc(recordId);

      await approvedDocRef.set({
        ...data,
        'approvalStatus': 'approved',
        'approvedBy': _auth.currentUser?.uid,
        'approvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // ✅ LEVEL 2 & 3: Copy all members and their commodities
      final membersSnapshot = await pendingDocRef.collection('members').get();

      for (final memberDoc in membersSnapshot.docs) {
        final memberData = memberDoc.data();
        final saadId = memberDoc.id;

        // Copy member personal data
        final approvedMemberRef =
            approvedDocRef.collection('members').doc(saadId);
        await approvedMemberRef.set(memberData);

        // Copy commodities for this member
        final commoditiesSnapshot =
            await memberDoc.reference.collection('commodities').get();

        for (final commodityDoc in commoditiesSnapshot.docs) {
          final commodityData = commodityDoc.data();
          await approvedMemberRef
              .collection('commodities')
              .doc(commodityDoc.id)
              .set(commodityData);
        }

        // Delete commodities from pending
        for (final commodityDoc in commoditiesSnapshot.docs) {
          await commodityDoc.reference.delete();
        }
      }

      // If this pending record used the older individual fallback format,
      // copy root-level commodities as well.
      final rootCommoditiesSnapshot =
          await pendingDocRef.collection('commodities').get();
      for (final commodityDoc in rootCommoditiesSnapshot.docs) {
        final commodityData = commodityDoc.data();
        await approvedDocRef
            .collection('commodities')
            .doc(commodityDoc.id)
            .set(commodityData);
      }

      // Delete root-level commodities from pending
      for (final commodityDoc in rootCommoditiesSnapshot.docs) {
        await commodityDoc.reference.delete();
      }

      // Delete all members from pending
      for (final memberDoc in membersSnapshot.docs) {
        await memberDoc.reference.delete();
      }

      // Delete the main pending FCA document
      await pendingDocRef.delete();

      if (kDebugMode) {
        print('✅ Record approved with 3-level hierarchy: $recordId');
        print(
            '   FCA + ${membersSnapshot.docs.length} members moved to approved_monitoring');
      }
    } catch (e) {
      if (kDebugMode) print('Error approving record: $e');
      rethrow;
    }
  }

  /// Decline a pending record - delete from pending with 3-level hierarchy
  /// Only moderator/admin can decline
  Future<void> declineRecord({
    required String recordId,
    required bool isModerator,
    required bool isAdmin,
  }) async {
    if (!isModerator && !isAdmin) {
      throw Exception('Only moderators and admins can decline records');
    }

    try {
      final pendingDocRef =
          _firestore.collection(_pendingCollection).doc(recordId);

      // ✅ Delete all nested commodities first
      final membersSnapshot = await pendingDocRef.collection('members').get();

      for (final memberDoc in membersSnapshot.docs) {
        // Delete commodities for this member
        final commoditiesSnapshot =
            await memberDoc.reference.collection('commodities').get();
        for (final commodityDoc in commoditiesSnapshot.docs) {
          await commodityDoc.reference.delete();
        }

        // Delete the member document
        await memberDoc.reference.delete();
      }

      // Delete any root-level commodities from the older individual record shape.
      final rootCommoditiesSnapshot =
          await pendingDocRef.collection('commodities').get();
      for (final commodityDoc in rootCommoditiesSnapshot.docs) {
        await commodityDoc.reference.delete();
      }

      // Delete the main FCA document
      await pendingDocRef.delete();

      if (kDebugMode) {
        print(
            '✅ Record declined and deleted with 3-level hierarchy: $recordId');
        print('   FCA + ${membersSnapshot.docs.length} members removed');
      }
    } catch (e) {
      if (kDebugMode) print('Error declining record: $e');
      rethrow;
    }
  }
}
