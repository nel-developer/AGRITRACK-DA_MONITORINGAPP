import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/da_colors.dart';
import '../../widgets/crop_form_shell.dart';
import '../../services/pending_draft_service.dart';
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
      'postharvestRemarks': w.postharvestRemarks,
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

      // ✅ CRITICAL: Build membersByFarmerId map for ALL record types
      // (both group and individual with single farmer)
      // This ensures member records are properly displayed
      final members = jsonData['members'] as List? ?? [];
      final commodities = jsonData['completedCommodities'] as List? ?? [];
      final farmerName = (jsonData['farmerName'] as String? ?? '').trim();
      final saadIdNo = (jsonData['saadIdNo'] as String? ?? '').trim();

      Map<String, dynamic> membersByFarmerId = {};

      // Case 1: Group record with multiple farmers in members list
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
              // Filter commodities for this farmer
              final farmerCommodities = commodities.where((comm) {
                if (comm is! Map<String, dynamic>) return false;
                final commName = (comm['farmerName'] as String? ?? '').trim();
                final commSaadId = (comm['saadIdNo'] as String? ?? '').trim();
                return commName == memberName || commSaadId == memberSaadId;
              }).toList();

              membersByFarmerId[memberId] = {
                'name': memberName,
                'farmerName': memberName,
                'saadIdNo': memberSaadId,
                'completedCommodities': farmerCommodities,
              };
            }
          }
        }
        print(
            '✅ Built membersByFarmerId for group: ${membersByFarmerId.keys.toList()}');
      }
      // Case 2: Collective record with no farmers, store data directly at root level
      else if (w.implementationType?.toLowerCase() == 'collective' &&
          commodities.isNotEmpty) {
        // For collective records, store commodities directly at root level, not in membersByFarmerId
        jsonData['completedCommodities'] = commodities;
        jsonData['trainings'] =
            w.trainings; // Store trainings at root level too
        print(
            '✅ Stored collective data directly at root level: ${commodities.length} commodities, ${w.trainings.length} trainings');
      }
      // Case 3: Individual record with single farmer (no members list)
      else if (farmerName.isNotEmpty && commodities.isNotEmpty) {
        final memberId = saadIdNo.isNotEmpty ? saadIdNo : farmerName;
        membersByFarmerId[memberId] = {
          'name': farmerName,
          'farmerName': farmerName,
          'saadIdNo': saadIdNo,
          'completedCommodities': commodities,
          'trainings':
              w.trainings, // ✅ Individual farmers have their own trainings
        };
        print('✅ Built membersByFarmerId for individual: $memberId');
      }

      if (membersByFarmerId.isNotEmpty) {
        jsonData['membersByFarmerId'] = membersByFarmerId;
        // Only clear root level commodities for non-collective records
        if (w.implementationType?.toLowerCase() != 'collective') {
          jsonData['completedCommodities'] = [];
        }
      }

      print('🔥 About to call saveDraft:');
      print('   implementationType: ${w.implementationType}');
      print('   members: ${jsonData['members']}');
      print(
          '   membersByFarmerId: ${(jsonData['membersByFarmerId'] as Map?)?.keys.toList()}');
      print('   farmerName: ${jsonData['farmerName']}');
      print('   fcaName: ${jsonData['fcaName']}');
      print(
          '   completedCommodities count: ${(jsonData['completedCommodities'] as List?)?.length ?? 0}');

      await PendingDraftService.instance.saveDraft(
        productionType: 'crop',
        implementationType: w.implementationType ?? 'collective',
        data: jsonData,
        source: 'unsync',
      );
      _didSaveDraft = true;

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

  Future<void> _handleBack() async {
    if (!_didSaveDraft && _photoPath.isNotEmpty) {
      await _deletePhotoSilently(_photoPath);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _fillSampleData() {
    setState(() {
      w.reportingPeriod = '2026 Q2';
      w.fcaName = 'Test Group';
      w.region = 'Region 1';
      w.province = 'Province A';
      w.municipality = 'Municipality X';
      w.barangay = 'Barangay Y';
      w.projectTitle = 'Sample Crop Monitoring';
      w.primaryIntervention = 'Crop Production';
      w.primaryInterventionOther = 'Integrated cropping';
      w.supportInterventions = ['Improved Seeds', 'Training', 'Soil Testing'];
      w.saadIdNo = 'SAAD12345';
      w.farmerName = 'Juan dela Cruz';
      w.members = [
        {'name': 'Juan dela Cruz', 'saadIdNo': 'SAAD12345'},
      ];
      w.typeOfCrop = 'Maize';
      w.variety = 'Yellow';
      w.inputsReceived = [
        InputReceived()
          ..name = 'Fertilizer'
          ..quantity = '2 bags',
      ];
      w.inputsPurchased = [
        InputPurchased()
          ..name = 'Pesticide'
          ..quantity = '1 bottle'
          ..cost = '500',
      ];
      w.totalCostPurchased = '500';
      w.qtyVsArea = '200kg/ha';
      w.croppingCycles = '2';
      w.qtyVsCycles = '100kg';
      w.peakVolume = '250kg';
      w.peakMonth = 'June';
      w.volumesPerCycle = ['120kg', '130kg'];
      w.farmgatePrice = '18';
      w.totalLandArea = '1.5';
      w.landOwnership = 'Owned';
      w.landOwnershipOther = '';
      w.usufructAgreement = 'None';
      w.landRemarks = ['Well tilled', 'Good soil'];
      w.machineryType = 'Hand Tractor';
      w.machineryOther = '';
      w.machineryRemarks = ['Used for tillage'];
      w.landPrepCostPerCycle = ['1500', '1600'];
      w.landPrepStartDate = '2026-04-10';
      w.landPrepDays = '5';
      w.sourceOfWater = 'Irrigation canal';
      w.plantingDate = '2026-04-15';
      w.seedAmount = '10';
      w.seedUnit = 'kg';
      w.germinationRate = '90%';
      w.goodGermination = 'Yes';
      w.germinationReason = 'Excellent seed quality';
      w.fertilizerType = 'NPK';
      w.organicSource = 'Compost';
      w.organicBagsSAAD = '2';
      w.organicBagsCommercial = '1';
      w.organicTotalCost = '1200';
      w.organicBagsCycle = '2';
      w.organicFrequency = 'Every 30 days';
      w.inorganicType = 'Urea';
      w.inorganicBagsSAAD = '3';
      w.inorganicMeasure = '2 bags';
      w.inorganicTotalCost = '900';
      w.inorganicBagsCycle = ['30', '60'];
      w.inorganicFrequency = 'Every two weeks';
      w.pesticideRequirement = 'Yes';
      w.landAreaCycles = ['0.75', '0.75'];
      w.dateHarvestCycles = ['2026-08-01', '2026-08-15'];
      w.quantityCycles = ['120kg', '130kg'];
      w.avgHarvestPerHa = '220kg';
      w.harvestCostCycles = ['600', '650'];
      w.foodConsumptionPct = '10%';
      w.postharvestFile = '';
      w.postharvestRemarks = ['Drying under shade'];
      w.processingFile = '';
      w.processingRemarks = ['Shelling manually'];
      w.hasPest = true;
      w.pestOccurrence = 'Locusts';
      w.pestDate = '2026-05-10';
      w.pestDamageArea = '0.2';
      w.pestDamageHa = '0.1';
      w.pestTreatment = 'Insecticide spray';
      w.pestAttached = '';
      w.hasDisease = true;
      w.diseaseOccurrence = 'Leaf blight';
      w.diseaseDate = '2026-05-12';
      w.diseaseDamageArea = '0.1';
      w.diseaseDamageHa = '0.05';
      w.diseaseTreatment = 'Fungicide';
      w.diseaseAttached = '';
      w.hasEnvHazard = true;
      w.envHazards = ['Flood risk'];
      w.envDate = '2026-05-05';
      w.envDamageArea = '0.05';
      w.envDamageHa = '0.02';
      w.envTreatment = 'Drainage ditches';
      w.envAttached = '';
      w.hasHumanDamage = true;
      w.humanDamage = 'Foot injury';
      w.humanMortality = '0';
      w.humanTreatment = 'First aid';
      w.humanAttached = '';
      _trainings.clear();
      _trainings.add(TrainingEntry()
        ..name = 'Crop Management Training'
        ..date = '2026-05-01'
        ..attendees = '15');
    });
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
          if (kDebugMode)
            TextButton(
              onPressed: _fillSampleData,
              child: Text('Fill sample data',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: DAColors.greenMid)),
            ),
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
