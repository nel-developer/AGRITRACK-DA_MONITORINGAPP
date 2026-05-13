import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/da_colors.dart';
import '../../widgets/record_card.dart';
import 'record_edit_modal.dart';
import 'approve_modal.dart';
import '../../services/pending_draft_service.dart';

class RecordViewModal extends StatelessWidget {
  const RecordViewModal({
    super.key,
    required this.record,
    this.memberName,
    this.isGroup = false,
    this.isMemberEditOnly = false,
    this.showEdit = false,
    this.showSync = false,
    this.showApprove = false,
    this.approveLocked = false,
    this.onSync,
    this.onApprove,
    this.onDecline,
    this.onMarkForSync,
    this.onKeepAsDraft,
  });

  final RecordModel record;
  final String? memberName; // null = collective view
  final bool isGroup; // true = group/FCA record view
  final bool
      isMemberEditOnly; // true = farmer can only edit their own commodity data
  final bool showEdit;
  final bool showSync;
  final bool showApprove;
  final bool approveLocked;
  final VoidCallback? onSync;
  final VoidCallback? onApprove;
  final VoidCallback? onDecline;
  final VoidCallback? onMarkForSync;
  final VoidCallback? onKeepAsDraft;

  void _openEdit(BuildContext context) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecordEditModal(
        record: record,
        isMemberEditOnly: isMemberEditOnly && memberName != null,
        isGroup: isGroup,
      ),
    );
  }

  void _openApprove(BuildContext context, bool isApprove) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ApproveModal(
        record: record,
        isApprove: isApprove,
        onConfirm: isApprove ? onApprove : onDecline,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final botPad = MediaQuery.of(context).padding.bottom;
    final type = record.productionType.toLowerCase();
    final data =
        Map<String, dynamic>.from(record.data ?? const <String, dynamic>{});

    return Container(
      height: screenH * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(children: [
        // Handle
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
              color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
          child: Row(children: [
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    isGroup
                        ? '${record.name} — Group Record'
                        : (memberName?.isNotEmpty == true
                            ? memberName!
                            : ((data['farmerName'] as String? ?? '')
                                    .trim()
                                    .isNotEmpty
                                ? (data['farmerName'] as String? ?? '').trim()
                                : record.name)),
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: DAColors.textDark)),
                const SizedBox(height: 2),
                Row(children: [
                  _TypeChip(label: record.productionType),
                  const SizedBox(width: 6),
                  _TypeChip(label: record.implType),
                ]),
              ],
            )),
            IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.grey)),
          ]),
        ),

        Divider(color: Colors.grey[200], height: 16),

        // Scrollable body
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: _DynamicRecordFields(
              type: type,
              data: data,
              recordName: record.name,
              memberName: memberName,
              isGroup: isGroup,
            ),
          ),
        ),

        // Footer buttons
        _buildFooter(context, botPad),
      ]),
    );
  }

  Widget _buildFooter(BuildContext context, double botPad) {
    final deco = BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
    );

    // ✅ For farmers viewing their own records: Show only Edit button
    if (isMemberEditOnly &&
        showEdit &&
        !showSync &&
        !showApprove &&
        !approveLocked) {
      return Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + botPad),
        decoration: deco,
        child: Row(children: [
          Expanded(
              child: _ActionBtn(
                  label: 'Edit',
                  color: const Color(0xFF1565C0),
                  onTap: () => _openEdit(context))),
        ]),
      );
    }

    // ✅ For regular viewing without sync: Show only Edit button
    if (showEdit && !showSync && !showApprove && !approveLocked) {
      return Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + botPad),
        decoration: deco,
        child: Row(children: [
          Expanded(
              child: _ActionBtn(
                  label: 'Edit',
                  color: const Color(0xFF1565C0),
                  onTap: () => _openEdit(context))),
        ]),
      );
    }

    if (showSync) {
      return Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + botPad),
        decoration: deco,
        child: Row(children: [
          Expanded(
              child: _ActionBtn(
                  label: 'Edit',
                  color: const Color(0xFF1565C0),
                  onTap: () => _openEdit(context))),
          const SizedBox(width: 16),
          Expanded(
              child: _ActionBtn(
                  label: 'Sync',
                  color: DAColors.greenMid,
                  onTap: () {
                    Navigator.pop(context);
                    onSync?.call();
                  })),
        ]),
      );
    }

    if (showApprove || approveLocked) {
      return Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + botPad),
        decoration: deco,
        child: Row(children: [
          Expanded(
              child: _LockedBtn(
                  label: 'Approve',
                  color: DAColors.greenMid,
                  locked: approveLocked,
                  lockMsg: 'Moderators only',
                  onTap: showApprove
                      ? (onApprove ?? () => _openApprove(context, true))
                      : null)),
          const SizedBox(width: 8),
          Expanded(
              child: _LockedBtn(
                  label: 'Edit',
                  color: const Color(0xFF1565C0),
                  locked: approveLocked,
                  lockMsg: 'Moderators only',
                  onTap: showApprove ? () => _openEdit(context) : null)),
          const SizedBox(width: 8),
          Expanded(
              child: _LockedBtn(
                  label: 'Decline',
                  color: Colors.red,
                  locked: approveLocked,
                  lockMsg: 'Moderators only',
                  onTap: showApprove
                      ? (onDecline ?? () => _openApprove(context, false))
                      : null)),
        ]),
      );
    }

    // For local pending/approved records
    if (record.status == 'pending' &&
        record.isLocal &&
        !showApprove &&
        !showSync &&
        !showEdit) {
      return Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + botPad),
        decoration: deco,
        child: Row(children: [
          Expanded(
              child: _ActionBtn(
                  label: 'Decline',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    onDecline?.call();
                  })),
          const SizedBox(width: 12),
          Expanded(
              child: _ActionBtn(
                  label: 'Approve',
                  color: DAColors.greenMid,
                  onTap: () {
                    Navigator.pop(context);
                    onApprove?.call();
                  })),
        ]),
      );
    }

    // Add unsynced actions if this is an unsynced record
    if (record.status == 'unsync') {
      return Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + botPad),
        decoration: deco,
        child: Row(
          children: [
            Expanded(
              child: Builder(
                builder: (context) => _ActionBtn(
                  label: 'Continue',
                  color: DAColors.greenMid,
                  onTap: () {
                    Navigator.pop(context);
                    if (record.productionType.toLowerCase() == 'poultry') {
                      Navigator.of(context).pushNamed(
                        '/poultry/stepper',
                        arguments: {
                          'draftData': record.data,
                          'draftId': record.id,
                          'resume': true,
                        },
                      );
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Builder(
                builder: (context) => _ActionBtn(
                  label: 'Edit',
                  color: const Color(0xFF1565C0),
                  onTap: () => _openEdit(context),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Builder(
                builder: (context) => _ActionBtn(
                  label: 'Delete',
                  color: Colors.red,
                  onTap: () {
                    // Use a workaround to call async code from onTap
                    Future<void>(() async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Draft'),
                          content: const Text(
                              'Are you sure you want to delete this draft? This action cannot be undone.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        String? draftId = record.id;
                        if (draftId == null || draftId.isEmpty) {
                          final dataLocalId = (record.data != null &&
                                  record.data is Map &&
                                  (record.data as Map).containsKey('localId'))
                              ? (record.data as Map)['localId']?.toString()
                              : null;
                          draftId = dataLocalId;
                        }
                        if (draftId != null && draftId.toString().isNotEmpty) {
                          try {
                            await PendingDraftService.instance
                                .deleteDraftByLocalId(draftId);
                            Navigator.pop(context); // Close modal after delete
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Failed to delete draft: $e')),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Draft ID missing, cannot delete.')),
                          );
                        }
                      }
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(height: botPad + 16);
  }
}

// ── Dynamic production fields ────────────────────────────────────

class _DynamicRecordFields extends StatelessWidget {
  const _DynamicRecordFields({
    required this.type,
    required this.data,
    required this.recordName,
    required this.memberName,
    this.isGroup = false,
  });

  final String type;
  final Map<String, dynamic> data;
  final String recordName;
  final String? memberName;
  final bool isGroup;

  @override
  Widget build(BuildContext context) {
    // 🔍 DEBUG: Show all fields in data map
    print('📊 RECORD VIEW MODAL DATA:');
    print('   - Keys in data: ${data.keys.toList()}');
    print('   - province: ${data["province"]}');
    print('   - municipality: ${data["municipality"]}');
    print('   - barangay: ${data["barangay"]}');
    print('   - primaryIntervention: ${data["primaryIntervention"]}');
    print('   - supportInterventions: ${data["supportInterventions"]}');
    
    final isCollective =
        data['implementationType']?.toString().toLowerCase() == 'collective';
    final shouldShowCommodities = (type == 'crop' && !isGroup) ||
        (type == 'crop' && isGroup && isCollective) ||
        (type == 'livestock' && !isGroup) ||
        (type == 'livestock' && isGroup && isCollective) ||
        (type == 'poultry' && !isGroup) ||
        (type == 'poultry' && isGroup && isCollective);

    if (shouldShowCommodities) {
      final commodities = _extractCommodityList();
      print(
          '🔍 _DynamicRecordFields: shouldShowCommodities=$shouldShowCommodities, type=$type, isGroup=$isGroup');
      print(
          '   - completedCommodities in data: ${data['completedCommodities'] != null}');
      print('   - extracted commodities count: ${commodities.length}');
      if (commodities.isNotEmpty) {
        for (int i = 0; i < commodities.length; i++) {
          final c = commodities[i];
          print('   - commodity[$i]: ${c['typeOfCrop']} ${c['variety']}');
        }
      }
      if (commodities.isNotEmpty) {
        final allSections = _sectionsForType(type);
        final commoditySections = allSections.length > 2
            ? allSections.sublist(1, allSections.length - 1)
            : allSections.skip(1).toList();
        final trainingSection =
            allSections.length > 1 ? allSections.last : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Always render project background first
            ..._buildProjectBackgroundSection(),
            const SizedBox(height: 16),
            ...commodities.asMap().entries.map((entry) {
              final index = entry.key;
              final commodity = entry.value;

              String subtitle = '';
              if (type == 'crop') {
                final cropType =
                    (commodity['typeOfCrop'] as String? ?? '').trim();
                final variety = (commodity['variety'] as String? ?? '').trim();
                subtitle = [
                  if (cropType.isNotEmpty) cropType,
                  if (variety.isNotEmpty) variety,
                ].join(' · ');
              } else if (type == 'livestock' || type == 'poultry') {
                final breed = (commodity['breed'] as String? ?? '').trim();
                subtitle = breed.isNotEmpty ? breed : 'Batch details';
              }

              final isBatch = type == 'livestock' || type == 'poultry';
              final commodityId = commodity['commodityId']?.toString() ?? '';
              final titleText = commodityId.isNotEmpty
                  ? '$commodityId ${isBatch ? '(Batch)' : '(Commodity)'}'
                  : (isBatch ? 'Batch ${index + 1}' : 'Commodity ${index + 1}');

              return ExpansionTile(
                key: ValueKey('${type}_tile_$index'),
                title: Text(titleText,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: DAColors.textDark)),
                subtitle: Text(
                  subtitle.isEmpty ? 'No details yet' : subtitle,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: DAColors.textMuted),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                children: commoditySections.expand<Widget>((section) {
                  // For group views, skip farmer-specific fields
                  final fieldsToShow = isGroup
                      ? section.fields
                          .where((field) => field.label != 'Name of Farmer')
                          .toList()
                      : section.fields;

                  final rows = fieldsToShow
                      .map((field) => _ResolvedField(
                          label: field.label,
                          value: _resolveFieldValue(field.key, commodity)))
                      .where((field) => field.value.isNotEmpty)
                      .toList();
                  if (rows.isEmpty) return const <Widget>[];

                  // ✅ Build GPS info if available
                  final gpsInfo = _buildGPSInfo(commodity);

                  return [
                    const SizedBox(height: 10),
                    _SectionHeader(title: section.title),
                    ..._buildFieldRows(rows),
                    if (gpsInfo.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ...gpsInfo,
                    ],
                  ];
                }).toList(),
              );
            }),
            if (trainingSection != null) ...[
              const SizedBox(height: 16),
              ..._buildOuterTrainingSection(trainingSection),
            ],
          ],
        );
      }
    }

    final sections = _sectionsForType(type);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections.map((section) {
        final resolved = section.fields
            .map((field) => _ResolvedField(
                label: field.label, value: _resolveFieldValue(field.key)))
            .toList();
        
        // 🔍 DEBUG: Log all field values to see what's being filtered
        print('📋 Section "${section.title}":');
        for (final field in resolved) {
          print('   ${field.label}: "${field.value}" (empty: ${field.value.isEmpty})');
        }
        
        final rows = resolved
            .where((field) => field.value.isNotEmpty)
            .toList();

        if (rows.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(title: section.title),
            ..._buildFieldRows(rows),
          ],
        );
      }).toList(),
    );
  }

  List<Widget> _buildProjectBackgroundSection() {
    final projectSections = _sectionsForType(type).take(1).toList();
    return projectSections.expand<Widget>((section) {
      final rows = section.fields
          .map((field) => _ResolvedField(
              label: field.label, value: _resolveFieldValue(field.key)))
          .where((field) => field.value.isNotEmpty)
          .toList();
      if (rows.isEmpty) return const <Widget>[];
      return [
        _SectionHeader(title: section.title),
        ..._buildFieldRows(rows),
      ];
    }).toList();
  }

  List<Widget> _buildOuterTrainingSection(_SectionDef trainingSection) {
    final rows = trainingSection.fields
        .map((field) => _ResolvedField(
            label: field.label, value: _resolveFieldValue(field.key)))
        .where((field) => field.value.isNotEmpty)
        .toList();
    if (rows.isEmpty) return const <Widget>[];
    return [
      _SectionHeader(title: trainingSection.title),
      ..._buildFieldRows(rows),
    ];
  }

  List<Map<String, dynamic>> _extractCommodityList() {
    final isCollective =
        data['implementationType']?.toString().toLowerCase() == 'collective';

    // For collective group records, show commodities stored at root level
    if (isGroup && isCollective) {
      final commodities = (data['completedCommodities'] as List?) ??
          (data['completedBatches'] as List?) ??
          const [];

      if (commodities.isNotEmpty) {
        return commodities
            .whereType<Map<String, dynamic>>()
            .map((commodity) => Map<String, dynamic>.from(commodity))
            .toList();
      }

      // Backward compatibility: If no commodities list, but data has commodity fields at root,
      // create a single commodity from the root data
      final hasCommodityData = type == 'crop'
          ? data.containsKey('typeOfCrop') || data.containsKey('variety')
          : data.containsKey('breed');

      if (hasCommodityData) {
        // Create a commodity map from the root data, excluding non-commodity fields
        final commodityKeys = type == 'crop'
            ? [
                'typeOfCrop',
                'variety',
                'farmgatePrice',
                'totalCostPurchased',
                'qtyVsArea',
                'croppingCycles',
                'peakVolume',
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
                'postharvestRemarks',
                'processingRemarks',
                'pestOccurrence',
                'pestDate',
                'pestDamageArea',
                'pestDamageHa',
                'pestTreatment',
                'diseaseOccurrence',
                'diseaseDate',
                'diseaseDamageArea',
                'diseaseDamageHa',
                'diseaseTreatment',
                'envHazards',
                'envDate',
                'envDamageArea',
                'envDamageHa',
                'envTreatment',
                'humanDamage',
                'humanMortality',
                'humanTreatment',
              ]
            : [
                'breed',
                'stocksReceived',
                'dateReceived',
                'ageUponReceipt',
                'avgWeightUponReceipt',
                'housingType',
                'grazingArea',
                'avgMarketableWeight',
                'milkVolumeDaily',
              ];

        final commodityData = <String, dynamic>{};
        for (final key in commodityKeys) {
          if (data.containsKey(key)) {
            commodityData[key] = data[key];
          }
        }

        if (commodityData.isNotEmpty) {
          return [commodityData];
        }
      }
    }

    // For individual farmer records (not group view), show commodities from root level
    if (!isGroup) {
      final commodities = (data['completedCommodities'] as List?) ??
          (data['completedBatches'] as List?) ??
          (data['commodities'] as List?) ??
          const [];

      if (commodities.isNotEmpty) {
        return commodities
            .whereType<Map<String, dynamic>>()
            .map((commodity) => Map<String, dynamic>.from(commodity))
            .toList();
      }

      // Backward compatibility: If no commodities list, but data has commodity fields at root,
      // create a single commodity from the root data
      final hasCommodityData = type == 'crop'
          ? data.containsKey('typeOfCrop') || data.containsKey('variety')
          : data.containsKey('breed');

      if (hasCommodityData) {
        // Create a commodity map from the root data, excluding non-commodity fields
        final commodityKeys = type == 'crop'
            ? [
                'typeOfCrop',
                'variety',
                'farmgatePrice',
                'totalCostPurchased',
                'qtyVsArea',
                'croppingCycles',
                'peakVolume',
                'peakMonth',
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
                'postharvestRemarks',
                'processingRemarks',
                'pestOccurrence',
                'pestDate',
                'pestDamageArea',
                'pestDamageHa',
                'pestTreatment',
                'diseaseOccurrence',
                'diseaseDate',
                'diseaseDamageArea',
                'diseaseDamageHa',
                'diseaseTreatment',
                'envHazards',
                'envDate',
                'envDamageArea',
                'envDamageHa',
                'envTreatment',
                'humanDamage',
                'humanMortality',
                'humanTreatment',
              ]
            : [
                'breed',
                'stocksReceived',
                'dateReceived',
                'ageUponReceipt',
                'avgWeightUponReceipt',
                'housingType',
                'grazingArea',
                'avgMarketableWeight',
                'milkVolumeDaily',
              ];

        final commodityData = <String, dynamic>{};
        for (final key in commodityKeys) {
          if (data.containsKey(key)) {
            commodityData[key] = data[key];
          }
        }

        if (commodityData.isNotEmpty) {
          return [commodityData];
        }
      }
    }

    // For individual and hybrid group records, do NOT show commodities at group level
    return const [];
  }

  String _resolveFieldValue(String key, [Map<String, dynamic>? override]) {
    final source = override ?? data;
    switch (key) {
      case 'recordName':
        return recordName;
      case 'fcaName':
        // For group records, use fcaName from data; for others use recordName
        if (isGroup && (source['fcaName'] as String? ?? '').isNotEmpty) {
          return source['fcaName'] as String;
        }
        return recordName;
      case 'memberName':
        if (memberName?.isNotEmpty == true) {
          return memberName!;
        }
        return (source['farmerName'] as String? ??
            data['farmerName'] as String? ??
            '');
      case 'membersList':
        // CRITICAL: Read from membersByFarmerId (safe map) first, fallback to members array (old)
        final membersByFarmerId = (source['membersByFarmerId'] as Map?) ?? {};
        if (membersByFarmerId.isNotEmpty) {
          final membersList = <String>[];
          for (final entry in membersByFarmerId.entries) {
            final farmerData = entry.value;
            if (farmerData is Map) {
              final name = farmerData['name']?.toString() ??
                  farmerData['farmerName']?.toString() ??
                  '';
              final saadIdNo = farmerData['saadIdNo']?.toString() ?? '';
              membersList.add(saadIdNo.isNotEmpty ? '$saadIdNo - $name' : name);
            }
          }
          return membersList.isEmpty
              ? 'No members recorded'
              : membersList.join('\n');
        }

        // Fallback to old members array for backward compatibility
        final members = (source['members'] as List?) ?? const [];
        if (members.isEmpty) return 'No members recorded';
        return members.map((member) {
          if (member is Map) {
            final name = member['name']?.toString() ??
                member['farmerName']?.toString() ??
                '';
            final saadIdNo = member['saadIdNo']?.toString() ?? '';
            return saadIdNo.isNotEmpty ? '$saadIdNo - $name' : name;
          }
          return member.toString();
        }).join('\n');
      case 'trainingsSummary':
        var trainings = (source['trainings'] as List?) ?? const [];
        if (trainings.isEmpty) {
          final isCollective =
              source['implementationType']?.toString().toLowerCase() ==
                  'collective';
          if (isCollective) {
            final membersByFarmerId =
                (source['membersByFarmerId'] as Map?) ?? {};
            for (final entry in membersByFarmerId.entries) {
              final memberData = entry.value;
              if (memberData is Map<String, dynamic>) {
                final memberTrainings =
                    (memberData['trainings'] as List?) ?? const [];
                if (memberTrainings.isNotEmpty) {
                  trainings = memberTrainings;
                  break;
                }
              }
            }
          }
        }

        if (trainings.isEmpty) return '';
        return trainings.map((item) {
          final row = Map<String, dynamic>.from(item as Map);
          final name = row['name']?.toString() ?? 'Training';
          final date = row['date']?.toString() ?? '';
          final attendees = row['attendees']?.toString() ?? '';
          return [
            name,
            if (date.isNotEmpty) date,
            if (attendees.isNotEmpty) '$attendees attendees'
          ].join(' • ');
        }).join('\n');
      case 'inputsReceived':
        final inputs = (source['inputsReceived'] as List?) ?? const [];
        if (inputs.isEmpty) return '';
        return inputs.map((item) {
          final row = Map<String, dynamic>.from(item as Map);
          final inputName = row['name']?.toString() ?? 'Input';
          final quantity = row['quantity']?.toString() ?? '';
          return [inputName, if (quantity.isNotEmpty) '$quantity qty']
              .join(' • ');
        }).join('\n');
      case 'inputsPurchased':
        final inputs = (source['inputsPurchased'] as List?) ?? const [];
        if (inputs.isEmpty) return '';
        return inputs.map((item) {
          final row = Map<String, dynamic>.from(item as Map);
          final inputName = row['name']?.toString() ?? 'Input';
          final quantity = row['quantity']?.toString() ?? '';
          final cost = row['cost']?.toString() ?? '';
          final month = row['month']?.toString() ?? '';
          return [
            inputName,
            if (quantity.isNotEmpty) '$quantity qty',
            if (cost.isNotEmpty) '₱$cost',
            if (month.isNotEmpty) month
          ].join(' • ');
        }).join('\n');
      default:
        return _stringifyValue(source[key]);
    }
  }

  List<Widget> _buildFieldRows(List<_ResolvedField> fields) {
    final widgets = <Widget>[];
    for (var index = 0; index < fields.length; index += 2) {
      if (index + 1 < fields.length) {
        widgets.add(_Row2(
          fields[index].label,
          fields[index].value,
          fields[index + 1].label,
          fields[index + 1].value,
        ));
      } else {
        widgets.add(_Row1(fields[index].label, fields[index].value));
      }
    }
    return widgets;
  }

  String _stringifyValue(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is num || value is bool) return value.toString();
    if (value is List) {
      return value
          .map(
              (item) => item is Map ? item.values.join(' • ') : item.toString())
          .join(', ');
    }
    if (value is Map) {
      return value.entries
          .map((entry) => '${entry.key}: ${entry.value}')
          .join(', ');
    }
    return value.toString();
  }

  // ✅ Build GPS information widget if available in commodity
  List<Widget> _buildGPSInfo(Map<String, dynamic> commodity) {
    final gpsData = commodity['photoGPS'] as Map?;
    if (gpsData == null) return [];

    final lat = (gpsData['latitude'] as num?)?.toDouble() ?? 0.0;
    final lon = (gpsData['longitude'] as num?)?.toDouble() ?? 0.0;
    final accuracy = (gpsData['accuracy'] as num?)?.toDouble() ?? 0.0;

    return [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Photo GPS Location',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Latitude:  $lat\nLongitude: $lon\nAccuracy: ±${accuracy.toStringAsFixed(1)}m',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey.shade700,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<_SectionDef> _sectionsForType(String type) {
    final isCollective =
        data['implementationType']?.toString().toLowerCase() == 'collective';

    // For group records, only show Project Background section
    if (isGroup && !isCollective) {
      return [
        const _SectionDef('Project Background', [
          _FieldDef('Reporting Period', 'reportingPeriod'),
          _FieldDef('FCA Name', 'fcaName'),
          _FieldDef('Region', 'region'),
          _FieldDef('Province', 'province'),
          _FieldDef('Municipality', 'municipality'),
          _FieldDef('Barangay', 'barangay'),
          _FieldDef('Project Title', 'projectTitle'),
          _FieldDef('Primary Intervention', 'primaryIntervention'),
          _FieldDef('Support Interventions', 'supportInterventions'),
        ]),
      ];
    }

    // For collective group records, always return all sections (commodities will be shown separately)
    // For individual records, return all sections as normal

    switch (type) {
      case 'crop':
        final commodityFields = <_FieldDef>[
          const _FieldDef('Type of Crop', 'typeOfCrop'),
          const _FieldDef('Variety', 'variety'),
          const _FieldDef('Farmgate Price', 'farmgatePrice'),
          const _FieldDef('Total Cost Purchased', 'totalCostPurchased'),
          const _FieldDef('Qty vs Area', 'qtyVsArea'),
          const _FieldDef('Cropping Cycles', 'croppingCycles'),
          const _FieldDef('Qty vs Cycles', 'qtyVsCycles'),
          const _FieldDef('Volumes Per Cycle', 'volumesPerCycle'),
          const _FieldDef('Peak Volume', 'peakVolume'),
          const _FieldDef('Peak Month', 'peakMonth'),
          const _FieldDef('Inputs Received from FCA', 'inputsReceived'),
          const _FieldDef('Inputs Purchased by Farmer', 'inputsPurchased'),
        ];
        if (!isCollective) {
          commodityFields.insert(
              0, const _FieldDef('Name of Farmer', 'memberName'));
        }

        final sections = [
          const _SectionDef('Project Background', [
            _FieldDef('Reporting Period', 'reportingPeriod'),
            _FieldDef('FCA Name', 'fcaName'),
            _FieldDef('Region', 'region'),
            _FieldDef('Province', 'province'),
            _FieldDef('Municipality', 'municipality'),
            _FieldDef('Barangay', 'barangay'),
            _FieldDef('Project Title', 'projectTitle'),
            _FieldDef('Primary Intervention', 'primaryIntervention'),
            _FieldDef('Support Interventions', 'supportInterventions'),
          ]),
          _SectionDef('Commodity Information', commodityFields),
        ];

        sections.addAll([
          const _SectionDef('Planting Stage', [
            _FieldDef('Total Land Area', 'totalLandArea'),
            _FieldDef('Land Ownership', 'landOwnership'),
            _FieldDef('Land Ownership Other', 'landOwnershipOther'),
            _FieldDef('Usufruct Agreement', 'usufructAgreement'),
            _FieldDef('Land Remarks', 'landRemarks'),
            _FieldDef('Machinery Type', 'machineryType'),
            _FieldDef('Machinery Other', 'machineryOther'),
            _FieldDef('Machinery Remarks', 'machineryRemarks'),
            _FieldDef('Land Prep Cost Per Cycle', 'landPrepCostPerCycle'),
            _FieldDef('Land Prep Start Date', 'landPrepStartDate'),
            _FieldDef('Land Prep Days', 'landPrepDays'),
            _FieldDef('Source of Water', 'sourceOfWater'),
            _FieldDef('Planting Date', 'plantingDate'),
            _FieldDef('Seed Amount', 'seedAmount'),
            _FieldDef('Seed Unit', 'seedUnit'),
            _FieldDef('Germination Rate', 'germinationRate'),
            _FieldDef('Good Germination', 'goodGermination'),
            _FieldDef('Germination Reason', 'germinationReason'),
          ]),
          const _SectionDef('Fertilization Requirement', [
            _FieldDef('Fertilizer Type', 'fertilizerType'),
            _FieldDef('Organic Source', 'organicSource'),
            _FieldDef('Organic Bags (SAAD)', 'organicBagsSAAD'),
            _FieldDef('Organic Bags (Commercial)', 'organicBagsCommercial'),
            _FieldDef('Organic Total Cost', 'organicTotalCost'),
            _FieldDef('Organic Bags Cycle', 'organicBagsCycle'),
            _FieldDef('Organic Frequency', 'organicFrequency'),
            _FieldDef('Inorganic Type', 'inorganicType'),
            _FieldDef('Inorganic Bags (SAAD)', 'inorganicBagsSAAD'),
            _FieldDef('Inorganic Measure', 'inorganicMeasure'),
            _FieldDef('Inorganic Total Cost', 'inorganicTotalCost'),
            _FieldDef('Inorganic Bags Cycle', 'inorganicBagsCycle'),
            _FieldDef('Inorganic Frequency', 'inorganicFrequency'),
            _FieldDef('Pesticide Requirement', 'pesticideRequirement'),
          ]),
          const _SectionDef('Harvesting Stage', [
            _FieldDef('Land Area Cycles', 'landAreaCycles'),
            _FieldDef('Date Harvest Cycles', 'dateHarvestCycles'),
            _FieldDef('Quantity Cycles', 'quantityCycles'),
            _FieldDef('Avg Harvest per Ha', 'avgHarvestPerHa'),
            _FieldDef('Harvest Cost Cycles', 'harvestCostCycles'),
            _FieldDef('Food Consumption %', 'foodConsumptionPct'),
            _FieldDef('Postharvest Remarks', 'postharvestRemarks'),
            _FieldDef('Processing Remarks', 'processingRemarks'),
          ]),
          const _SectionDef('Crop Damage Information', [
            _FieldDef('Pest Occurrence', 'pestOccurrence'),
            _FieldDef('Pest Date', 'pestDate'),
            _FieldDef('Pest Damage Area', 'pestDamageArea'),
            _FieldDef('Pest Damage Ha', 'pestDamageHa'),
            _FieldDef('Pest Treatment', 'pestTreatment'),
            _FieldDef('Disease Occurrence', 'diseaseOccurrence'),
            _FieldDef('Disease Date', 'diseaseDate'),
            _FieldDef('Disease Damage Area', 'diseaseDamageArea'),
            _FieldDef('Disease Damage Ha', 'diseaseDamageHa'),
            _FieldDef('Disease Treatment', 'diseaseTreatment'),
            _FieldDef('Env Hazards', 'envHazards'),
            _FieldDef('Env Date', 'envDate'),
            _FieldDef('Env Damage Area', 'envDamageArea'),
            _FieldDef('Env Damage Ha', 'envDamageHa'),
            _FieldDef('Env Treatment', 'envTreatment'),
            _FieldDef('Human Damage', 'humanDamage'),
            _FieldDef('Human Mortality', 'humanMortality'),
            _FieldDef('Human Treatment', 'humanTreatment'),
          ]),
          const _SectionDef('Trainings Attended', [
            _FieldDef('Training', 'trainingsSummary'),
          ]),
        ]);

        return sections;
      case 'livestock':
        final livestockFields = [
          const _FieldDef('Breed', 'breed'),
          const _FieldDef('Stocks Received', 'stocksReceived'),
          const _FieldDef('Date Received', 'dateReceived'),
          const _FieldDef('Male Stocks', 'maleStocks'),
          const _FieldDef('Female Stocks', 'femaleStocks'),
          const _FieldDef('Avg Weight Upon Receipt', 'avgWeightUponReceipt'),
          const _FieldDef('Housing Type', 'housingType'),
        ];
        if (!isCollective) {
          livestockFields.insert(
              0, const _FieldDef('Name of Farmer', 'memberName'));
        }

        return [
          const _SectionDef('Project Background', [
            _FieldDef('FCA Name', 'fcaName'),
            _FieldDef('Region', 'region'),
            _FieldDef('Province', 'province'),
            _FieldDef('Municipality', 'municipality'),
            _FieldDef('Barangay', 'barangay'),
            _FieldDef('Project Title', 'projectTitle'),
            _FieldDef('Primary Intervention', 'primaryIntervention'),
            _FieldDef('Support Interventions', 'supportInterventions'),
          ]),
          _SectionDef('Livestock Information', livestockFields),
          const _SectionDef('Harvesting Information', [
            _FieldDef('Grazing Area', 'grazingArea'),
            _FieldDef('Avg Marketable Weight', 'avgMarketableWeight'),
            _FieldDef('Milk Volume Daily', 'milkVolumeDaily'),
          ]),
          const _SectionDef('Trainings Attended', [
            _FieldDef('Training', 'trainingsSummary'),
          ]),
        ];
      default:
        final poultryFields = [
          const _FieldDef('Breed', 'breed'),
          const _FieldDef('Stocks Received', 'stocksReceived'),
          const _FieldDef('Date Received', 'dateReceived'),
          const _FieldDef('Age Upon Receipt', 'ageUponReceipt'),
          const _FieldDef('Avg Weight Upon Receipt', 'avgWeightUponReceipt'),
          const _FieldDef('Housing Type', 'housingType'),
        ];
        if (!isCollective) {
          poultryFields.insert(
              0, const _FieldDef('Name of Farmer', 'memberName'));
        }

        return [
          const _SectionDef('Project Background', [
            _FieldDef('Reporting Period', 'reportingPeriod'),
            _FieldDef('FCA Name', 'fcaName'),
            _FieldDef('Region', 'region'),
            _FieldDef('Province', 'province'),
            _FieldDef('Municipality', 'municipality'),
            _FieldDef('Barangay', 'barangay'),
            _FieldDef('Project Title', 'projectTitle'),
            _FieldDef('Primary Intervention', 'primaryIntervention'),
            _FieldDef('Support Interventions', 'supportInterventions'),
          ]),
          _SectionDef('Poultry Information', poultryFields),
          const _SectionDef('Production Information', [
            _FieldDef('Harvested Birds', 'harvestedBirds'),
            _FieldDef('Total Weight Harvested', 'totalWeightHarvested'),
            _FieldDef('Total Eggs Harvested', 'totalEggsHarvested'),
            _FieldDef('Feed Type', 'feedType'),
            _FieldDef('Total Feed Consumed', 'totalFeedConsumed'),
            _FieldDef('Sacks Manure Produced', 'sacksManureProduced'),
          ]),
          const _SectionDef('Trainings Attended', [
            _FieldDef('Training', 'trainingsSummary'),
          ]),
        ];
    }
  }
}

class _SectionDef {
  const _SectionDef(this.title, this.fields);
  final String title;
  final List<_FieldDef> fields;
}

class _FieldDef {
  const _FieldDef(this.label, this.key);
  final String label;
  final String key;
}

class _ResolvedField {
  const _ResolvedField({required this.label, required this.value});
  final String label;
  final String value;
}

// ── Shared field widgets ──────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
              color: const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(8)),
          alignment: Alignment.center,
          child: Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: DAColors.textDark)),
        ),
      );
}

class _Row2 extends StatelessWidget {
  const _Row2(this.l1, this.v1, this.l2, this.v2);
  final String l1, v1, l2, v2;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _FieldItem(label: l1, value: v1)),
            Expanded(child: _FieldItem(label: l2, value: v2)),
          ],
        ),
      );
}

class _Row1 extends StatelessWidget {
  const _Row1(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _FieldItem(label: label, value: value),
      );
}

class _FieldItem extends StatelessWidget {
  const _FieldItem({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: DAColors.textDark)),
          Text(value,
              style:
                  GoogleFonts.poppins(fontSize: 12, color: DAColors.textMuted)),
        ],
      );
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: DAColors.greenLight.withOpacity(0.2),
          borderRadius: BorderRadius.circular(50)),
      child: Text(label,
          style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: DAColors.greenMid)));
}

// ── Action buttons ────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.label, required this.color, this.onTap});
  final String label;
  final Color color;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
          height: 48,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(50)),
          alignment: Alignment.center,
          child: Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white))));
}

class _LockedBtn extends StatelessWidget {
  const _LockedBtn(
      {required this.label,
      required this.color,
      required this.locked,
      required this.lockMsg,
      this.onTap});
  final String label;
  final Color color;
  final bool locked;
  final String lockMsg;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Stack(children: [
        _ActionBtn(label: label, color: color, onTap: onTap),
        if (locked)
          Positioned.fill(
              child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: Container(
              color: Colors.black.withOpacity(0.60),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_rounded,
                        color: Colors.white, size: 14),
                    const SizedBox(height: 2),
                    Text(lockMsg,
                        style: GoogleFonts.poppins(
                            fontSize: 8, color: Colors.white),
                        textAlign: TextAlign.center),
                  ]),
            ),
          )),
      ]);
}
