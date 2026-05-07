import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import '../../services/pending_draft_service.dart';
import '../../theme/da_colors.dart';
import '../../routes/app_routes.dart';
import 'livestock_step_wrapper.dart';

// ── Record model ──────────────────────────────────────────────────
class LivestockMonitoringRecord {
  final String farmerName;
  final String breed;
  final DateTime completedAt;

  const LivestockMonitoringRecord({
    required this.farmerName,
    required this.breed,
    required this.completedAt,
  });
}

// ── Member model ──────────────────────────────────────────────────
class LivestockMember {
  final String name;
  bool monitored;
  LivestockMember({required this.name, this.monitored = false});
}

class LivestockMonitoringSummaryScreen extends StatefulWidget {
  const LivestockMonitoringSummaryScreen({
    super.key,
    required this.wrapper,
    required this.completedRecords,
    this.members,
  });

  final LivestockStepWrapper wrapper;
  final List<LivestockMonitoringRecord> completedRecords;
  final List<LivestockMember>? members;

  @override
  State<LivestockMonitoringSummaryScreen> createState() =>
      _LivestockMonitoringSummaryScreenState();
}

class _LivestockMonitoringSummaryScreenState
    extends State<LivestockMonitoringSummaryScreen> {
  @override
  void initState() {
    super.initState();
    _loadExistingCollectiveData();
  }

  // ✅ Helper: Load existing collective data for display
  Future<void> _loadExistingCollectiveData() async {
    if (widget.wrapper.implementationType?.toLowerCase() != 'collective') {
      return;
    }

    final existingDraft = await _loadExistingGroupDraft();
    if (existingDraft != null) {
      final batches = existingDraft['completedBatches'] as List? ?? [];
      if (batches.isNotEmpty) {
        setState(() {
          widget.wrapper.completedBatches.clear();
          widget.wrapper.completedBatches.addAll(
              batches.map((c) => Map<String, dynamic>.from(c)).toList());
        });
      }
    }
  }

  // ✅ Helper: Load existing group draft to preserve other farmers
  Future<Map<String, dynamic>?> _loadExistingGroupDraft() async {
    final allDrafts = await PendingDraftService.instance.getPendingDrafts();

    for (final draft in allDrafts) {
      final draftProductionType =
          (draft['productionType'] as String? ?? '').trim().toLowerCase();
      final draftImplementationType =
          (draft['implementationType'] as String? ?? '').trim().toLowerCase();
      final wrapperImplementationType =
          widget.wrapper.implementationType?.trim().toLowerCase() ?? '';

      if (draftProductionType != 'livestock' ||
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

  Future<void> _done() async {
    try {
      // ✅ Accumulate current batch if it has data
      if (widget.wrapper.breed != null && widget.wrapper.breed!.isNotEmpty) {
        widget.wrapper.completedBatches.add({
          'farmerName': widget.wrapper.farmerName,
          'saadIdNo': widget.wrapper.saadIdNo,
          'breed': widget.wrapper.breed,
          'inputsReceived': widget.wrapper.inputsReceived
              .map((item) => item.toJson())
              .toList(),
          'inputsPurchased': widget.wrapper.inputsPurchased
              .map((item) => item.toJson())
              .toList(),
          'farmgatePrices': widget.wrapper.farmgatePrices,
          'stocksReceived': widget.wrapper.stocksReceived,
          'dateReceived': widget.wrapper.dateReceived,
          'maleStocks': widget.wrapper.maleStocks,
          'femaleStocks': widget.wrapper.femaleStocks,
          'maleToFemaleRatio': widget.wrapper.maleToFemaleRatio,
        });
      }

      // ✅ Load existing group draft to preserve other farmers when building a group
      final shouldMergeExistingDraft =
          widget.wrapper.implementationType != 'individual' ||
              widget.wrapper.isAddFarmer ||
              widget.wrapper.members.isNotEmpty;
      final existingDraft =
          shouldMergeExistingDraft ? await _loadExistingGroupDraft() : null;

      // ✅ Get/create membersByFarmerId map
      Map<String, dynamic> membersByFarmerId = {};
      if (existingDraft != null && existingDraft['membersByFarmerId'] != null) {
        membersByFarmerId = Map<String, dynamic>.from(
            existingDraft['membersByFarmerId'] as Map);
      }

      final trainingsData =
          widget.wrapper.trainings.map((t) => t.toJson()).toList();

      if (widget.wrapper.implementationType == 'individual') {
        // Individual: Only current farmer
        final saadId = widget.wrapper.saadIdNo.trim();
        final farmerName = widget.wrapper.farmerName.trim();
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
        // ✅ CRITICAL: Only add current farmer, preserve all others from draft
        final saadId = widget.wrapper.saadIdNo.trim();
        final farmerName = widget.wrapper.farmerName.trim();
        final farmerId = saadId.isNotEmpty ? saadId : farmerName;

        if (farmerId.isNotEmpty) {
          // ✅ FIX: Only add current farmer if new, otherwise preserve existing data
          if (!membersByFarmerId.containsKey(farmerId)) {
            print('🆕 Adding NEW farmer to group: $farmerName ($farmerId)');
            membersByFarmerId[farmerId] = {
              'farmerName': farmerName,
              'saadIdNo': saadId,
              'trainings': trainingsData,
              'addedDate': DateTime.now().toIso8601String(),
            };
          } else {
            // ✅ Farmer already exists - ONLY update trainings if new data provided
            print('📝 Updating EXISTING farmer: $farmerName ($farmerId)');
            final existing =
                membersByFarmerId[farmerId] as Map<String, dynamic>;
            // Merge trainings: combine old and new (avoiding duplicates by object comparison)
            final oldTrainings = (existing['trainings'] as List?) ?? [];
            final mergedTrainings = <Map<String, dynamic>>[
              ...oldTrainings.cast<Map<String, dynamic>>(),
            ];
            // Add new trainings if not already present
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

      print('💾 === SAVING LIVESTOCK RECORD ===');
      print('   Production Type: livestock');
      print('   Implementation Type: ${widget.wrapper.implementationType}');
      print('   FCA Name: ${dataToSave['fcaName']}');
      print('   Total Farmers: ${membersByFarmerId.length}');
      print('   Farmers: ${membersByFarmerId.keys.toList()}');

      await PendingDraftService.instance.saveDraft(
        productionType: 'livestock',
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

  late final List<LivestockMember> _members = widget.members ?? [];

  // Only for individual/hybrid — saves current farmer first, then adds new one
  Future<void> _addAnotherFarmer() async {
    // ✅ Load existing draft FIRST to get saved completedBatches and membersByFarmerId
    final existingDraft = await _loadExistingGroupDraft();

    // ✅ Start with existing batches and members from saved draft
    final existingBatches =
        existingDraft != null && existingDraft['completedBatches'] != null
            ? List<Map<String, dynamic>>.from(
                existingDraft['completedBatches'] as List)
            : <Map<String, dynamic>>[];

    Map<String, dynamic> membersByFarmerId = {};
    if (existingDraft != null && existingDraft['membersByFarmerId'] != null) {
      membersByFarmerId =
          Map<String, dynamic>.from(existingDraft['membersByFarmerId'] as Map);
    }

    // CRITICAL: Before saving, accumulate CURRENT farmer's batch data
    // This ensures all farmers stay in ONE group record (no duplicates)
    if (widget.wrapper.farmerName.isNotEmpty &&
        widget.wrapper.breed != null &&
        widget.wrapper.breed!.isNotEmpty) {
      existingBatches.add({
        'farmerName': widget.wrapper.farmerName,
        'saadIdNo': widget.wrapper.saadIdNo,
        'breed': widget.wrapper.breed,
        'inputsReceived':
            widget.wrapper.inputsReceived.map((item) => item.toJson()).toList(),
        'inputsPurchased': widget.wrapper.inputsPurchased
            .map((item) => item.toJson())
            .toList(),
        'farmgatePrices': widget.wrapper.farmgatePrices,
        'stocksReceived': widget.wrapper.stocksReceived,
        'dateReceived': widget.wrapper.dateReceived,
        'maleStocks': widget.wrapper.maleStocks,
        'femaleStocks': widget.wrapper.femaleStocks,
        'maleToFemaleRatio': widget.wrapper.maleToFemaleRatio,
      });
    }

    // ✅ UNIQUE FARMER ID LOCK - Each farmer keyed by SAAD ID
    final farmerId = widget.wrapper.saadIdNo.trim();
    if (farmerId.isEmpty) {
      throw Exception('ERROR: Farmer must have SAAD ID before saving');
    }

    // ✅ ATOMIC MERGE - Add/update ONLY this farmer by SAAD ID
    membersByFarmerId[farmerId] = {
      'name': widget.wrapper.farmerName,
      'saadIdNo': farmerId,
      'addedDate': DateTime.now().toIso8601String(),
      'status': 'active',
    };

    // ✅ Clear farmerName for group records
    if (membersByFarmerId.isNotEmpty) {
      widget.wrapper.farmerName = '';
    }

    // ✅ SAVE - Include membersByFarmerId map and ALL accumulated batches (safe, no overwrites)
    final dataToSave = widget.wrapper.toJson();
    dataToSave['membersByFarmerId'] = membersByFarmerId;
    dataToSave['completedBatches'] =
        existingBatches; // ✅ Use accumulated batches, not wrapper's
    // Update members list to include all farmers for local folder saving
    dataToSave['members'] = membersByFarmerId.entries.map((entry) {
      final farmerData = entry.value as Map<String, dynamic>;
      return {
        'name': farmerData['name'] ?? farmerData['farmerName'] ?? '',
        'saadIdNo': entry.key,
      };
    }).toList();

    await PendingDraftService.instance.saveDraft(
      productionType: 'livestock',
      implementationType: widget.wrapper.implementationType ?? '',
      data: dataToSave,
    );

    if (!mounted) return;

    // Create new wrapper for next farmer with group info preserved
    // Batch fields are cleared for new farmer entry
    final next = LivestockStepWrapper()
      ..reportingPeriod = widget.wrapper.reportingPeriod
      ..fcaName = widget.wrapper.fcaName
      ..region = widget.wrapper.region
      ..province = widget.wrapper.province
      ..municipality = widget.wrapper.municipality
      ..barangay = widget.wrapper.barangay
      ..projectTitle = widget.wrapper.projectTitle
      ..primaryIntervention = widget.wrapper.primaryIntervention
      ..supportInterventions = List.from(widget.wrapper.supportInterventions)
      ..members = membersByFarmerId.entries.map((entry) {
        final farmerData = entry.value as Map<String, dynamic>;
        return {
          'name': farmerData['name'] ?? farmerData['farmerName'] ?? '',
          'saadIdNo': entry.key,
        };
      }).toList()
      ..completedBatches =
          existingBatches // ✅ Pass accumulated batches to next screen
      ..purposeBreeding = widget.wrapper.purposeBreeding
      ..purposeMeat = widget.wrapper.purposeMeat
      ..purposeDairy = widget.wrapper.purposeDairy
      ..implementationType = widget.wrapper.implementationType
      ..isAddFarmer = true;

    // Navigate to Step 2 to add new farmer's batch data
    Navigator.of(context)
        .pushNamed(AppRoutes.livestockStep2, arguments: next)
        .then((result) {
      if (result is LivestockStepWrapper && mounted) {
        // Update the wrapper with the returned data
        widget.wrapper.completedBatches = result.completedBatches;
        widget.wrapper.members = result.members;
        setState(() {}); // Refresh the UI to show the new farmer
      }
    });
  }

  String _saadIdForMember(String farmerName) {
    final match = widget.wrapper.members.firstWhere(
      (member) =>
          (member['name'] as String? ?? '').trim().toLowerCase() ==
          farmerName.trim().toLowerCase(),
      orElse: () => {},
    );
    return (match['saadIdNo'] as String? ?? '').trim();
  }

  void _monitorMember(LivestockMember member) {
    final farmerSaadId = _saadIdForMember(member.name);

    final next = LivestockStepWrapper()
      ..reportingPeriod = widget.wrapper.reportingPeriod
      ..fcaName = widget.wrapper.fcaName
      ..region = widget.wrapper.region
      ..province = widget.wrapper.province
      ..municipality = widget.wrapper.municipality
      ..barangay = widget.wrapper.barangay
      ..projectTitle = widget.wrapper.projectTitle
      ..primaryIntervention = widget.wrapper.primaryIntervention
      ..supportInterventions = List.from(widget.wrapper.supportInterventions)
      ..purposeBreeding = widget.wrapper.purposeBreeding
      ..purposeMeat = widget.wrapper.purposeMeat
      ..purposeDairy = widget.wrapper.purposeDairy
      ..implementationType = 'individual'
      ..farmerName = member.name
      ..saadIdNo = farmerSaadId;
    Navigator.of(context)
        .pushNamed(AppRoutes.livestockStep2, arguments: next)
        .then((_) => setState(() => member.monitored = true));
  }

  void _addBatchForMember(LivestockMember member) async {
    final farmerSaadId = _saadIdForMember(member.name);

    // CRITICAL: Before navigating, accumulate current batch data
    // This prevents overwrites when adding another batch for same farmer
    if (widget.wrapper.breed != null && widget.wrapper.breed!.isNotEmpty) {
      widget.wrapper.completedBatches.add({
        'farmerName': member.name,
        'saadIdNo': farmerSaadId,
        'breed': widget.wrapper.breed,
        'inputsReceived':
            widget.wrapper.inputsReceived.map((item) => item.toJson()).toList(),
        'inputsPurchased': widget.wrapper.inputsPurchased
            .map((item) => item.toJson())
            .toList(),
        'farmgatePrices': widget.wrapper.farmgatePrices,
        'stocksReceived': widget.wrapper.stocksReceived,
        'dateReceived': widget.wrapper.dateReceived,
        'maleStocks': widget.wrapper.maleStocks,
        'femaleStocks': widget.wrapper.femaleStocks,
        'maleToFemaleRatio': widget.wrapper.maleToFemaleRatio,
      });
    }

    if (!mounted) return;

    final next = LivestockStepWrapper()
      ..reportingPeriod = widget.wrapper.reportingPeriod
      ..fcaName = widget.wrapper.fcaName
      ..region = widget.wrapper.region
      ..province = widget.wrapper.province
      ..municipality = widget.wrapper.municipality
      ..barangay = widget.wrapper.barangay
      ..projectTitle = widget.wrapper.projectTitle
      ..primaryIntervention = widget.wrapper.primaryIntervention
      ..supportInterventions = List.from(widget.wrapper.supportInterventions)
      ..completedBatches = List.from(widget.wrapper.completedBatches)
      ..purposeBreeding = widget.wrapper.purposeBreeding
      ..purposeMeat = widget.wrapper.purposeMeat
      ..purposeDairy = widget.wrapper.purposeDairy
      ..implementationType = 'individual'
      ..farmerName = member.name
      ..saadIdNo = farmerSaadId
      ..members = List.from(widget.wrapper.members);

    // Navigate and wait for return
    final updatedWrapper = await Navigator.of(context)
            .pushNamed(AppRoutes.livestockStep2, arguments: next)
        as LivestockStepWrapper?;

    if (!mounted) return;

    // ✅ If returned with data, update the wrapper with new batch data
    if (updatedWrapper != null) {
      widget.wrapper.completedBatches = updatedWrapper.completedBatches;
      widget.wrapper.members = List.from(updatedWrapper.members);
      // Clear current batch fields for next entry
      widget.wrapper.breed = '';
      widget.wrapper.stocksReceived = '';
      widget.wrapper.dateReceived = '';
      widget.wrapper.maleStocks = '';
      widget.wrapper.femaleStocks = '';
      widget.wrapper.maleToFemaleRatio = '';
      setState(() => member.monitored = true);
    }
  }

  Future<void> _addBatchForGroup() async {
    // CRITICAL: Before navigating, accumulate current batch data
    // This prevents overwrites when adding another batch
    if (widget.wrapper.breed != null && widget.wrapper.breed!.isNotEmpty) {
      // ✅ For collective groups: Assign to ALL farmers in the group
      // This ensures commodities get assigned to each farmer when syncing to Firebase
      for (final member in widget.wrapper.members) {
        final memberName = (member['name'] as String? ?? '').trim();
        final memberSaadId = (member['saadIdNo'] as String? ?? '').trim();
        if (memberName.isNotEmpty) {
          widget.wrapper.completedBatches.add({
            'breed': widget.wrapper.breed,
            'farmerName': memberName,
            'saadIdNo': memberSaadId.isNotEmpty ? memberSaadId : memberName,
            'inputsReceived': widget.wrapper.inputsReceived
                .map((item) => item.toJson())
                .toList(),
            'inputsPurchased': widget.wrapper.inputsPurchased
                .map((item) => item.toJson())
                .toList(),
            'farmgatePrices': widget.wrapper.farmgatePrices,
            'stocksReceived': widget.wrapper.stocksReceived,
            'dateReceived': widget.wrapper.dateReceived,
            'maleStocks': widget.wrapper.maleStocks,
            'femaleStocks': widget.wrapper.femaleStocks,
            'maleToFemaleRatio': widget.wrapper.maleToFemaleRatio,
          });
        }
      }
    }

    // CRITICAL: Build membersByFarmerId BEFORE saving to ensure sync to Firebase
    Map<String, dynamic> membersByFarmerId = {};
    for (final member in widget.wrapper.members) {
      final memberName = (member['name'] as String? ?? '').trim();
      final memberSaadId = (member['saadIdNo'] as String? ?? '').trim();
      if (memberName.isNotEmpty) {
        final memberId = memberSaadId.isNotEmpty ? memberSaadId : memberName;
        membersByFarmerId[memberId] = {
          'farmerName': memberName,
          'saadIdNo': memberSaadId,
          'addedDate': DateTime.now().toIso8601String(),
        };
      }
    }

    final dataToSave = widget.wrapper.toJson();
    dataToSave['membersByFarmerId'] = membersByFarmerId;

    // CRITICAL: Save current state to prevent data loss
    // This ensures the commodity data is persisted before navigating
    await PendingDraftService.instance.saveDraft(
      productionType: 'livestock',
      implementationType: widget.wrapper.implementationType ?? '',
      data: dataToSave,
    );

    if (!mounted) return;

    final next = LivestockStepWrapper()
      ..reportingPeriod = widget.wrapper.reportingPeriod
      ..fcaName = widget.wrapper.fcaName
      ..region = widget.wrapper.region
      ..province = widget.wrapper.province
      ..municipality = widget.wrapper.municipality
      ..barangay = widget.wrapper.barangay
      ..projectTitle = widget.wrapper.projectTitle
      ..primaryIntervention = widget.wrapper.primaryIntervention
      ..supportInterventions = List.from(widget.wrapper.supportInterventions)
      ..completedBatches = List.from(widget.wrapper.completedBatches)
      ..purposeBreeding = widget.wrapper.purposeBreeding
      ..purposeMeat = widget.wrapper.purposeMeat
      ..purposeDairy = widget.wrapper.purposeDairy
      ..implementationType = widget.wrapper.implementationType
      ..members = List.from(widget.wrapper.members);
    Navigator.of(context).pushNamed(AppRoutes.livestockStep2, arguments: next);
  }

  void _showGroupDetailsDialog(LivestockStepWrapper wrapper) {
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
              // ── GROUP BACKGROUND DATA ONLY (no batch info) ──
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
              _buildDetailRow('Members',
                  '${_members.length} member${_members.length != 1 ? 's' : ''}'),
              const SizedBox(height: 16),
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
                color: DAColors.textMuted,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value.isEmpty ? '—' : value,
            style: GoogleFonts.poppins(
                fontSize: 12, color: DAColors.textDark, height: 1.4)),
      ],
    );
  }

  Widget _buildCommodityDetails(Map<String, dynamic> commodity) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            SizedBox(
                width: 120,
                child: _buildDetailRow('Breed', commodity['breed'] ?? '')),
            SizedBox(
                width: 120,
                child: _buildDetailRow(
                    'Stocks Received', commodity['stocksReceived'] ?? '')),
            SizedBox(
                width: 120,
                child: _buildDetailRow(
                    'Date Received', commodity['dateReceived'] ?? '')),
            SizedBox(
                width: 120,
                child: _buildDetailRow(
                    'Male Stocks', commodity['maleStocks'] ?? '')),
            SizedBox(
                width: 120,
                child: _buildDetailRow(
                    'Female Stocks', commodity['femaleStocks'] ?? '')),
            SizedBox(
                width: 120,
                child: _buildDetailRow(
                    'Housing Type', commodity['housingType'] ?? '')),
            SizedBox(
                width: 120,
                child: _buildDetailRow(
                    'Grazing Area', commodity['grazingArea'] ?? '')),
            SizedBox(
                width: 120,
                child: _buildDetailRow('Avg Marketable Weight',
                    commodity['avgMarketableWeight'] ?? '')),
            SizedBox(
                width: 120,
                child: _buildDetailRow(
                    'Milk Volume Daily', commodity['milkVolumeDaily'] ?? '')),
          ],
        ),
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
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── Add Another Farmer (individual / hybrid only) ─
              ...(w.implementationType != 'collective'
                  ? [
                      GestureDetector(
                        onTap: _addAnotherFarmer,
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
                                Text('Add Another Farmer',
                                    style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: DAColors.textDark)),
                                const SizedBox(height: 2),
                                Text('Monitor a new farmer',
                                    style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: DAColors.textMuted)),
                              ],
                            )),
                            const Icon(Icons.chevron_right_rounded,
                                color: DAColors.amber, size: 24),
                          ]),
                        ),
                      ),
                    ]
                  : []),
              const SizedBox(height: 24),

              // ── Group / FCA card ──────────────────────────────
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
                          Text(w.fcaName.isEmpty ? '—' : w.fcaName,
                              style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: DAColors.textDark)),
                          const SizedBox(height: 2),
                          Text(
                              [
                                if (w.primaryIntervention != null)
                                  w.primaryIntervention!,
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

                    // Add Another Batch for group
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: Color(0xFFF0F0F0)),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _addBatchForGroup,
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
                        Text('Add Another Batch',
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
              // ── Members ───────────────────────────────────────
              ...(w.implementationType != 'collective'
                  ? [
                      const SizedBox(height: 24),
                      Text('Members',
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: DAColors.textDark)),
                      const SizedBox(height: 10),
                      ..._members.map((m) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _MemberCard(
                              member: m,
                              onMonitor: () => _monitorMember(m),
                              onAddBatch: () => _addBatchForMember(m),
                            ),
                          )),
                    ]
                  : [
                      const SizedBox(height: 24),
                      Text('Batches',
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: DAColors.textDark)),
                      const SizedBox(height: 10),
                      if (w.completedBatches.isEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: DAColors.border.withOpacity(0.75),
                                width: 1.2),
                          ),
                          child: Text(
                            'No batches have been added yet. Tap "Add Another Batch" to start.',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: DAColors.textMuted,
                                height: 1.5),
                          ),
                        ),
                      ] else
                        ...w.completedBatches.asMap().entries.map((entry) {
                          final index = entry.key + 1;
                          final batch = entry.value;
                          final breed = batch['breed'] as String? ?? '';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ExpansionTile(
                              key: ValueKey('batch_$index'),
                              title: Text('Batch $index',
                                  style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: DAColors.textDark)),
                              subtitle: Text(
                                breed.isEmpty ? 'No breed specified' : breed,
                                style: GoogleFonts.poppins(
                                    fontSize: 12, color: DAColors.textMuted),
                              ),
                              trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: DAColors.pending.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(50)),
                                  child: Text('Completed',
                                      style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: DAColors.pending))),
                              childrenPadding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              children: [
                                _buildCommodityDetails(batch),
                              ],
                            ),
                          );
                        }),
                    ]),
            ]),
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
                        borderRadius: BorderRadius.circular(50))),
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
    required this.onAddBatch,
  });
  final LivestockMember member;
  final VoidCallback onMonitor;
  final VoidCallback onAddBatch;

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
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onAddBatch,
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
              Text('Add Another Batch',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: DAColors.greenMid)),
            ]),
          ),
        ]),
      );
}
