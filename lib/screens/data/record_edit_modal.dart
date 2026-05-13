import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/pending_draft_service.dart';
import '../../theme/da_colors.dart';
import '../../widgets/record_card.dart';
import '../../widgets/crop_dropdown.dart';

class RecordEditModal extends StatefulWidget {
  const RecordEditModal({
    super.key,
    required this.record,
    this.isMemberEditOnly = false,
    this.isGroup = false,
  });
  final RecordModel record;
  final bool
      isMemberEditOnly; // true = farmer can only edit their own commodity data
  final bool isGroup; // true = editing group/FCA record

  @override
  State<RecordEditModal> createState() => _RecordEditModalState();
}

class _RecordEditModalState extends State<RecordEditModal> {
  final _formKey = GlobalKey<_DynamicEditFormState>();

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final botPad = MediaQuery.of(context).padding.bottom;

    return Container(
      height: screenH * 0.92,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(children: [
        // Green header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 8, 14),
          decoration: const BoxDecoration(color: DAColors.greenDark),
          child: Row(children: [
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Edit Record',
                    style: GoogleFonts.bebasNeue(
                        fontSize: 22, color: Colors.white, letterSpacing: 2)),
                Text(widget.record.name,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.85),
                        fontStyle: FontStyle.italic)),
              ],
            )),
            IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white)),
          ]),
        ),

        // Form body
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: _DynamicEditForm(
              key: _formKey,
              record: widget.record,
              isMemberEditOnly: widget.isMemberEditOnly,
              isGroup: widget.isGroup,
            ),
          ),
        ),

        // Save button
        Container(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + botPad),
          decoration: BoxDecoration(
              color: Colors.white,
              border:
                  Border(top: BorderSide(color: Colors.grey[200]!, width: 1))),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => _formKey.currentState?.saveChanges(),
              style: ElevatedButton.styleFrom(
                  backgroundColor: DAColors.greenMid,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50))),
              child: Text('Save Changes',
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Shared form helpers ───────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
              color: const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(10)),
          alignment: Alignment.center,
          child: Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: DAColors.textDark)),
        ),
      );
}

InputDecoration _fieldDeco(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(fontSize: 14, color: DAColors.textMuted),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDDDDDD), width: 1.5)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDDDDDD), width: 1.5)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: DAColors.greenMid, width: 2.0)),
    );

Widget _lbl(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t,
        style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: DAColors.textDark)));

Widget _field(String hint, String initial,
        {TextInputType kb = TextInputType.text}) =>
    TextFormField(
      initialValue: initial,
      keyboardType: kb,
      style: GoogleFonts.poppins(fontSize: 14, color: DAColors.textDark),
      decoration: _fieldDeco(hint),
    );

Widget _row2(String l1, String v1, String l2, String v2,
        {TextInputType kb = TextInputType.text}) =>
    Row(children: [
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _lbl(l1),
        _field(l1, v1, kb: kb),
      ])),
      const SizedBox(width: 12),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _lbl(l2),
        _field(l2, v2, kb: kb),
      ])),
    ]);

Widget _gap() => const SizedBox(height: 16);

class _DynamicEditForm extends StatefulWidget {
  const _DynamicEditForm({
    super.key,
    required this.record,
    this.isMemberEditOnly = false,
    this.isGroup = false,
  });

  final RecordModel record;
  final bool
      isMemberEditOnly; // true = farmer can only edit their own commodity data
  final bool isGroup; // true = editing group/FCA record

  @override
  State<_DynamicEditForm> createState() => _DynamicEditFormState();
}

class _DynamicEditFormState extends State<_DynamicEditForm> {
  late final Map<String, dynamic> _originalData;
  late final Map<String, TextEditingController> _controllers;
  late final Map<String, TextEditingController> _itemControllers;
  late final List<Map<String, dynamic>> _originalCommodityItems;
  late final bool _isCollective;
  late final String _commodityListKey;
  late final List<String> _commodityFieldKeys;
  late int _selectedCommodityIndex;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _originalData = Map<String, dynamic>.from(
        widget.record.data ?? const <String, dynamic>{});

    final type = widget.record.productionType.toLowerCase();
    _isCollective = widget.record.implType.toLowerCase() == 'collective' ||
        _originalData['implementationType']?.toString().toLowerCase() ==
            'collective';
    _commodityListKey =
        type == 'crop' ? 'completedCommodities' : 'completedBatches';
    _commodityFieldKeys = _commodityFieldsForType(type);

    _originalCommodityItems = (_originalData[_commodityListKey] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList() ??
        [];

    _selectedCommodityIndex = 0;
    _itemControllers = {};
    final shouldCreateItemControllers = _originalCommodityItems.isNotEmpty &&
        (_isCollective || !widget.isGroup);
    if (shouldCreateItemControllers) {
      for (var itemIndex = 0;
          itemIndex < _originalCommodityItems.length;
          itemIndex++) {
        final item = _originalCommodityItems[itemIndex];
        for (final field in _commodityFieldKeys) {
          _itemControllers['${type}_${itemIndex}_$field'] =
              TextEditingController(text: item[field]?.toString() ?? '');
        }
      }
    }

    var editableKeys = _editableKeysForType(type);
    const backgroundKeys = {
      'reportingPeriod',
      'fcaName',
      'region',
      'province',
      'municipality',
      'barangay',
      'projectTitle',
      'primaryIntervention',
    };

    // Farmer editing their own record: show commodity keys only
    if (widget.isMemberEditOnly && !widget.isGroup) {
      editableKeys =
          editableKeys.where((key) => !backgroundKeys.contains(key)).toList();
    }
    // Group record or collective: show background keys only
    else if (widget.isGroup || _isCollective) {
      editableKeys = editableKeys.where(backgroundKeys.contains).toList();
    }

    _controllers = {
      for (final key in editableKeys)
        key: TextEditingController(text: _readInitialValue(key)),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final controller in _itemControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _readInitialValue(String key) {
    if (key == 'trainingsSummary') {
      final trainings = (_originalData['trainings'] as List?) ?? const [];
      return trainings.map((item) {
        final row = Map<String, dynamic>.from(item as Map);
        return [
          row['name']?.toString() ?? '',
          row['date']?.toString() ?? '',
          row['attendees']?.toString() ?? '',
        ].where((part) => part.isNotEmpty).join(' | ');
      }).join('\n');
    }
    if (key == 'inputsReceived' || key == 'inputsPurchased') {
      final inputs = (_originalData[key] as List?) ?? const [];
      if (inputs.isEmpty) return '(None recorded)';
      return inputs.map((item) {
        final row = Map<String, dynamic>.from(item as Map);
        final inputName = row['inputName']?.toString() ?? 'Input';
        final quantity = row['quantity']?.toString() ?? '';
        final cost = row['cost']?.toString() ?? '';
        return [
          inputName,
          if (quantity.isNotEmpty) '$quantity qty',
          if (cost.isNotEmpty) '₱$cost'
        ].where((part) => part.isNotEmpty).join(' • ');
      }).join('\n');
    }
    final value = _originalData[key];
    if (value == null) return '';
    if (value is List) return value.join(', ');
    return value.toString();
  }

  List<String> _editableKeysForType(String type) {
    switch (type) {
      case 'crop':
        return const [
          'reportingPeriod',
          'fcaName',
          'region',
          'province',
          'municipality',
          'barangay',
          'projectTitle',
          'primaryIntervention',
          'supportInterventions',
          'farmerName',
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
          // Fertilization fields
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
          // Harvesting fields
          'landAreaCycles',
          'dateHarvestCycles',
          'quantityCycles',
          'avgHarvestPerHa',
          'harvestCostCycles',
          'foodConsumptionPct',
          // Crop damage fields
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
          'trainingsSummary',
        ];
      case 'livestock':
        return const [
          'fcaName',
          'region',
          'province',
          'municipality',
          'barangay',
          'projectTitle',
          'primaryIntervention',
          'supportInterventions',
          'farmerName',
          'breed',
          'stocksReceived',
          'dateReceived',
          'maleStocks',
          'femaleStocks',
          'avgWeightUponReceipt',
          'housingType',
          'grazingArea',
          'avgMarketableWeight',
          'milkVolumeDaily',
          'trainingsSummary',
        ];
      default:
        return const [
          'reportingPeriod',
          'fcaName',
          'region',
          'province',
          'municipality',
          'barangay',
          'projectTitle',
          'primaryIntervention',
          'supportInterventions',
          'farmerName',
          'breed',
          'stocksReceived',
          'dateReceived',
          'ageUponReceipt',
          'avgWeightUponReceipt',
          'housingType',
          'harvestedBirds',
          'totalWeightHarvested',
          'totalEggsHarvested',
          'feedType',
          'totalFeedConsumed',
          'sacksManureProduced',
          'trainingsSummary',
        ];
    }
  }

  List<String> _filterOutCommodityFields(
      List<String> keys, String productionType) {
    // Define commodity fields for each type that should be removed from group edits
    const cropCommodityFields = {
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
    };

    const livestockCommodityFields = {
      'breed',
      'stocksReceived',
      'dateReceived',
      'maleStocks',
      'femaleStocks',
      'avgWeightUponReceipt',
      'housingType',
      'grazingArea',
      'avgMarketableWeight',
      'milkVolumeDaily',
    };

    const poultryCommodityFields = {
      'breed',
      'stocksReceived',
      'dateReceived',
      'ageUponReceipt',
      'avgWeightUponReceipt',
      'housingType',
      'harvestedBirds',
      'totalWeightHarvested',
      'totalEggsHarvested',
      'feedType',
      'totalFeedConsumed',
      'sacksManureProduced',
    };

    final commodityFieldsToRemove = productionType == 'crop'
        ? cropCommodityFields
        : productionType == 'livestock'
            ? livestockCommodityFields
            : poultryCommodityFields;

    return keys.where((key) => !commodityFieldsToRemove.contains(key)).toList();
  }

  List<String> _commodityFieldsForType(String productionType) {
    switch (productionType) {
      case 'crop':
        return const [
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
        ];
      case 'livestock':
        return const [
          'breed',
          'stocksReceived',
          'dateReceived',
          'maleStocks',
          'femaleStocks',
          'avgWeightUponReceipt',
          'housingType',
          'grazingArea',
          'avgMarketableWeight',
          'milkVolumeDaily',
        ];
      default:
        return const [
          'breed',
          'stocksReceived',
          'dateReceived',
          'ageUponReceipt',
          'avgWeightUponReceipt',
          'housingType',
          'harvestedBirds',
          'totalWeightHarvested',
          'totalEggsHarvested',
          'feedType',
          'totalFeedConsumed',
          'sacksManureProduced',
        ];
    }
  }

  String _labelFor(String key) {
    switch (key) {
      case 'fcaName':
        return 'FCA Name';
      case 'supportInterventions':
        return 'Support Interventions';
      case 'typeOfCrop':
        return 'Type of Crop';
      case 'farmgatePrice':
        return 'Farmgate Price';
      case 'qtyVsArea':
        return 'Quantity vs Area';
      case 'peakVolume':
        return 'Peak Volume';
      case 'inputsReceived':
        return 'Inputs Received from FCA';
      case 'inputsPurchased':
        return 'Inputs Purchased by Farmer';
      case 'totalLandArea':
        return 'Total Land Area';
      case 'landOwnership':
        return 'Land Ownership';
      case 'landOwnershipOther':
        return 'Land Ownership Other';
      case 'usufructAgreement':
        return 'Usufruct Agreement';
      case 'landRemarks':
        return 'Land Remarks';
      case 'machineryType':
        return 'Machinery Type';
      case 'machineryOther':
        return 'Machinery Other';
      case 'machineryRemarks':
        return 'Machinery Remarks';
      case 'landPrepCostPerCycle':
        return 'Land Prep Cost Per Cycle';
      case 'landPrepStartDate':
        return 'Land Prep Start Date';
      case 'landPrepDays':
        return 'Land Prep Days';
      case 'sourceOfWater':
        return 'Source of Water';
      case 'plantingDate':
        return 'Planting Date';
      case 'seedAmount':
        return 'Seed Amount';
      case 'seedUnit':
        return 'Seed Unit';
      case 'germinationRate':
        return 'Germination Rate';
      case 'goodGermination':
        return 'Good Germination';
      case 'germinationReason':
        return 'Germination Reason';
      case 'stocksReceived':
        return 'Stocks Received';
      case 'dateReceived':
        return 'Date Received';
      case 'maleStocks':
        return 'Male Stocks';
      case 'femaleStocks':
        return 'Female Stocks';
      case 'avgWeightUponReceipt':
        return 'Average Weight Upon Receipt';
      case 'housingType':
        return 'Housing Type';
      case 'grazingArea':
        return 'Grazing Area';
      case 'avgMarketableWeight':
        return 'Average Marketable Weight';
      case 'milkVolumeDaily':
        return 'Milk Volume Daily';
      case 'ageUponReceipt':
        return 'Age Upon Receipt';
      case 'harvestedBirds':
        return 'Harvested Birds';
      case 'totalWeightHarvested':
        return 'Total Weight Harvested';
      case 'totalEggsHarvested':
        return 'Total Eggs Harvested';
      case 'feedType':
        return 'Feed Type';
      case 'totalFeedConsumed':
        return 'Total Feed Consumed';
      case 'sacksManureProduced':
        return 'Sacks Manure Produced';
      case 'trainingsSummary':
        return 'Trainings';
      // Fertilization labels
      case 'fertilizerType':
        return 'Fertilizer Type';
      case 'organicSource':
        return 'Organic Source';
      case 'organicBagsSAAD':
        return 'Organic Bags (SAAD)';
      case 'organicBagsCommercial':
        return 'Organic Bags (Commercial)';
      case 'organicTotalCost':
        return 'Organic Total Cost';
      case 'organicBagsCycle':
        return 'Organic Bags Cycle';
      case 'organicFrequency':
        return 'Organic Frequency';
      case 'inorganicType':
        return 'Inorganic Type';
      case 'inorganicBagsSAAD':
        return 'Inorganic Bags (SAAD)';
      case 'inorganicMeasure':
        return 'Inorganic Measure';
      case 'inorganicTotalCost':
        return 'Inorganic Total Cost';
      case 'inorganicBagsCycle':
        return 'Inorganic Bags Cycle';
      case 'inorganicFrequency':
        return 'Inorganic Frequency';
      case 'pesticideRequirement':
        return 'Pesticide Requirement';
      // Harvesting labels
      case 'landAreaCycles':
        return 'Land Area Cycles';
      case 'dateHarvestCycles':
        return 'Date Harvest Cycles';
      case 'quantityCycles':
        return 'Quantity Cycles';
      case 'avgHarvestPerHa':
        return 'Avg Harvest per Ha';
      case 'harvestCostCycles':
        return 'Harvest Cost Cycles';
      case 'foodConsumptionPct':
        return 'Food Consumption %';

      // Crop damage labels
      case 'pestOccurrence':
        return 'Pest Occurrence';
      case 'pestDate':
        return 'Pest Date';
      case 'pestDamageArea':
        return 'Pest Damage Area';
      case 'pestDamageHa':
        return 'Pest Damage Ha';
      case 'pestTreatment':
        return 'Pest Treatment';
      case 'diseaseOccurrence':
        return 'Disease Occurrence';
      case 'diseaseDate':
        return 'Disease Date';
      case 'diseaseDamageArea':
        return 'Disease Damage Area';
      case 'diseaseDamageHa':
        return 'Disease Damage Ha';
      case 'diseaseTreatment':
        return 'Disease Treatment';
      case 'envHazards':
        return 'Env Hazards';
      case 'envDate':
        return 'Env Date';
      case 'envDamageArea':
        return 'Env Damage Area';
      case 'envDamageHa':
        return 'Env Damage Ha';
      case 'envTreatment':
        return 'Env Treatment';
      case 'humanDamage':
        return 'Human Damage';
      case 'humanMortality':
        return 'Human Mortality';
      case 'humanTreatment':
        return 'Human Treatment';
      default:
        return key
            .replaceAllMapped(
                RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
            .trim()
            .split(' ')
            .map((part) => part.isEmpty
                ? part
                : '${part[0].toUpperCase()}${part.substring(1)}')
            .join(' ');
    }
  }

  Future<void> saveChanges() async {
    setState(() => _isSaving = true);

    final updates = Map<String, dynamic>.from(_originalData);
    for (final entry in _controllers.entries) {
      if (entry.key == 'trainingsSummary') {
        final lines = entry.value.text
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList();
        updates['trainings'] = lines
            .map((line) => {'name': line, 'date': '', 'attendees': ''})
            .toList();
      } else if (entry.key == 'supportInterventions') {
        updates['supportInterventions'] = entry.value.text
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList();
      } else {
        updates[entry.key] = entry.value.text.trim();
      }
    }

    final shouldSaveItemControllers = _originalCommodityItems.isNotEmpty &&
        (_isCollective || !widget.isGroup);
    if (shouldSaveItemControllers) {
      final type = widget.record.productionType.toLowerCase();
      final updatedItems = <Map<String, dynamic>>[];
      for (var itemIndex = 0;
          itemIndex < _originalCommodityItems.length;
          itemIndex++) {
        final item =
            Map<String, dynamic>.from(_originalCommodityItems[itemIndex]);
        for (final field in _commodityFieldKeys) {
          final controller = _itemControllers['${type}_${itemIndex}_$field'];
          if (controller != null) {
            item[field] = controller.text.trim();
          }
        }
        updatedItems.add(item);
      }
      updates[_commodityListKey] = updatedItems;
    }

    try {
      if (widget.record.isLocal && widget.record.id != null) {
        await PendingDraftService.instance.updateDraft(
          localId: widget.record.id!,
          data: updates,
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Changes saved!',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor: DAColors.greenMid,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.record.productionType.toLowerCase();
    final allKeys = _editableKeysForType(type);
    const backgroundKeys = {
      'reportingPeriod',
      'fcaName',
      'region',
      'province',
      'municipality',
      'barangay',
      'projectTitle',
      'primaryIntervention',
      'supportInterventions',
    };

    // Farmer editing their own record: show commodity keys only
    final keys = widget.isMemberEditOnly && !widget.isGroup
        ? allKeys.where((key) => !backgroundKeys.contains(key)).toList()
        : widget.isGroup || _isCollective
            ? allKeys.where(backgroundKeys.contains).toList()
            : allKeys
                .where((key) => !_commodityFieldKeys.contains(key))
                .toList();

    // Show commodity section for: (collective OR farmer editing own record) AND has items
    final showCommoditySection = _originalCommodityItems.isNotEmpty &&
        (_isCollective || (widget.isMemberEditOnly && !widget.isGroup));

    if (type == 'crop') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (keys.isNotEmpty) _buildCropSections(keys),
          if (showCommoditySection) _buildCommodityEditorSection(type),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (keys.isNotEmpty) const _SectionHeader(title: 'Edit Record'),
        ...keys.map((key) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _lbl(_labelFor(key)),
                  TextFormField(
                    controller: _controllers[key],
                    enabled: !_isSaving,
                    maxLines: key == 'trainingsSummary' ? 4 : 1,
                    style: GoogleFonts.poppins(
                        fontSize: 14, color: DAColors.textDark),
                    decoration: _fieldDeco('Enter ${_labelFor(key)}'),
                  ),
                ],
              ),
            )),
        if (showCommoditySection) _buildCommodityEditorSection(type),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCommodityEditorSection(String type) {
    final title = type == 'crop' ? 'Commodity Items' : 'Batch Items';
    final itemLabel = type == 'crop' ? 'Commodity' : 'Batch';

    if (_originalCommodityItems.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.isMemberEditOnly) const SizedBox(height: 8),
          _SectionHeader(title: title),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              'No ${type == 'crop' ? 'commodities' : 'batches'} available to edit.',
              style:
                  GoogleFonts.poppins(fontSize: 13, color: DAColors.textMuted),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _SectionHeader(title: title),
        // Commodity selector dropdown
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _lbl('Select $itemLabel to Edit'),
              DropdownButtonFormField<int>(
                initialValue: _selectedCommodityIndex,
                items: _originalCommodityItems.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  final displayText = type == 'crop'
                      ? '${item['typeOfCrop']?.toString().trim() ?? 'Commodity'} · ${item['variety']?.toString().trim() ?? ''}'
                      : '${item['breed']?.toString().trim() ?? 'Batch'} ${idx + 1}';
                  return DropdownMenuItem(
                    value: idx,
                    child: Text(
                      displayText,
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedCommodityIndex = val);
                  }
                },
                decoration: _fieldDeco('Choose $itemLabel'),
              ),
            ],
          ),
        ),
        // Show only selected commodity
        if (_selectedCommodityIndex < _originalCommodityItems.length)
          type == 'crop'
              ? Column(
                  children:
                      _buildCropItemSections(type, _selectedCommodityIndex))
              : Column(
                  children:
                      _buildGenericItemFields(type, _selectedCommodityIndex)),
      ],
    );
  }

  List<Widget> _buildCropItemSections(String type, int index) {
    final sections = [
      {
        'title': 'Commodity Information',
        'keys': [
          'typeOfCrop',
          'variety',
          'farmgatePrice',
          'totalCostPurchased',
          'qtyVsArea',
          'croppingCycles',
          'peakVolume',
          'inputsReceived',
          'inputsPurchased',
        ]
      },
      {
        'title': 'Planting Stage',
        'keys': [
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
        ]
      },
      {
        'title': 'Fertilization Requirement',
        'keys': [
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
        ]
      },
      {
        'title': 'Harvesting Stage',
        'keys': [
          'landAreaCycles',
          'dateHarvestCycles',
          'quantityCycles',
          'avgHarvestPerHa',
          'harvestCostCycles',
          'foodConsumptionPct',
          'postharvestRemarks',
          'processingRemarks',
        ]
      },
      {
        'title': 'Crop Damage Information',
        'keys': [
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
      },
    ];

    return sections.expand<Widget>((section) {
      final sectionKeys = (section['keys'] as List<String>)
          .where((key) => _commodityFieldKeys.contains(key))
          .toList();
      if (sectionKeys.isEmpty) return const <Widget>[];

      return [
        const SizedBox(height: 12),
        _SectionHeader(title: section['title'] as String),
        ...sectionKeys.map((field) => _buildItemField(type, index, field)),
      ];
    }).toList();
  }

  List<Widget> _buildGenericItemFields(String type, int index) {
    return _commodityFieldKeys
        .map((field) => _buildItemField(type, index, field))
        .toList();
  }

  Widget _buildItemField(String type, int index, String field) {
    final fieldKey = '${type}_${index}_$field';
    final isInputField =
        field == 'inputsReceived' || field == 'inputsPurchased';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _lbl(_labelFor(field)),
          if (isInputField)
            // Display inputs as read-only since they're complex structures
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _itemControllers[fieldKey]?.text ?? '(None recorded)',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: DAColors.textMuted,
                  height: 1.5,
                ),
              ),
            )
          else
            TextFormField(
              controller: _itemControllers[fieldKey],
              enabled: !_isSaving,
              maxLines: 1,
              style:
                  GoogleFonts.poppins(fontSize: 14, color: DAColors.textDark),
              decoration: _fieldDeco('Enter ${_labelFor(field)}'),
            ),
        ],
      ),
    );
  }

  Widget _buildCropSections(List<String> keys) {
    final sections = [
      {
        'title': 'Project Background',
        'keys': [
          'reportingPeriod',
          'fcaName',
          'region',
          'province',
          'municipality',
          'barangay',
          'projectTitle',
          'primaryIntervention',
          'supportInterventions',
        ]
      },
      {
        'title': 'Farmer Information',
        'keys': ['farmerName']
      },
      {
        'title': 'Commodity Information',
        'keys': [
          'typeOfCrop',
          'variety',
          'farmgatePrice',
          'totalCostPurchased',
          'qtyVsArea',
          'croppingCycles',
          'peakVolume',
        ]
      },
      {
        'title': 'Planting Stage',
        'keys': [
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
        ]
      },
      {
        'title': 'Fertilization Requirement',
        'keys': [
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
        ]
      },
      {
        'title': 'Harvesting Stage',
        'keys': [
          'landAreaCycles',
          'dateHarvestCycles',
          'quantityCycles',
          'avgHarvestPerHa',
          'harvestCostCycles',
          'foodConsumptionPct',
          'postharvestRemarks',
          'processingRemarks',
        ]
      },
      {
        'title': 'Crop Damage Information',
        'keys': [
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
      },
      {
        'title': 'Trainings Attended',
        'keys': ['trainingsSummary']
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...sections.map((section) {
          final sectionKeys = (section['keys'] as List<String>)
              .where((key) => keys.contains(key))
              .toList();
          if (sectionKeys.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(title: section['title'] as String),
              ...sectionKeys.map((key) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _lbl(_labelFor(key)),
                        TextFormField(
                          controller: _controllers[key],
                          enabled: !_isSaving,
                          maxLines: key == 'trainingsSummary' ? 4 : 1,
                          style: GoogleFonts.poppins(
                              fontSize: 14, color: DAColors.textDark),
                          decoration: _fieldDeco('Enter ${_labelFor(key)}'),
                        ),
                      ],
                    ),
                  )),
            ],
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ── CROP edit form ────────────────────────────────────────────────
class _CropEditForm extends StatefulWidget {
  @override
  State<_CropEditForm> createState() => _CropEditFormState();
}

class _CropEditFormState extends State<_CropEditForm> {
  String? _primaryIntervention = 'Any Fruit';
  String? _fertilizerType = 'Organic';
  String? _landOwnership = 'Owned';

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ── Project Background ──────────────────────────────────
      const _SectionHeader(title: 'Project Background'),
      _row2('Reporting Period', '2026', 'FCA Name', 'Maharlika FCA'),
      _gap(),
      _row2('Region', 'Region IV-A (CALABARZON)', 'Province', 'Batangas'),
      _gap(),
      _row2('Municipality', 'Cuenca', 'Barangay', 'Bungahan'),
      _gap(),
      _lbl('Project Title'),
      _field('Enter Project Title', 'SAAD 2026 Crop Production'),
      _gap(),
      CropDropdown(
          label: 'Primary Intervention Provided',
          hint: 'Choose',
          value: _primaryIntervention,
          items: const ['Any Fruit', 'Any Vegetables', 'Coconut', 'Others'],
          onChanged: (v) => setState(() => _primaryIntervention = v)),
      _gap(),
      _lbl('Support Intervention Provided'),
      _field('Enter support intervention', 'Fertilizers'),

      // ── Commodity Information ───────────────────────────────
      const _SectionHeader(title: 'Commodity Information'),
      _row2('Name of Farmer', 'Juan Dela Cruz', 'Type of Crop', 'Banana'),
      _gap(),
      _row2('Variety', 'Lakatan', 'Farmgate Price (₱/kg)', '25',
          kb: TextInputType.number),
      _gap(),
      _lbl('Total Cost of Inputs Purchased'),
      _field('Enter total cost', '2500', kb: TextInputType.number),
      _gap(),
      _row2('Cropping Cycles/Year', '2', 'Peak Volume', '500 kg',
          kb: TextInputType.number),

      // ── Planting Stage ──────────────────────────────────────
      const _SectionHeader(title: 'Planting Stage'),
      _row2('Total Land Area (ha)', '1.5', 'Source of Water', 'Rainfall',
          kb: TextInputType.number),
      _gap(),
      CropDropdown(
          label: 'Land Ownership',
          hint: 'Choose',
          value: _landOwnership,
          items: const ['Owned', 'Rented', 'Shared', 'Others'],
          onChanged: (v) => setState(() => _landOwnership = v)),
      _gap(),
      _row2('Planting Date', '2026-01-10', 'Seed Amount (kg)', '50',
          kb: TextInputType.number),
      _gap(),
      _row2('Germination Rate (%)', '85', 'Land Prep Days', '7',
          kb: TextInputType.number),

      // ── Fertilization ───────────────────────────────────────
      const _SectionHeader(title: 'Fertilization'),
      CropDropdown(
          label: 'Fertilizer Type',
          hint: 'Choose',
          value: _fertilizerType,
          items: const ['Organic', 'Inorganic', 'Both'],
          onChanged: (v) => setState(() => _fertilizerType = v)),
      _gap(),
      _row2('Bags from SAAD', '10', 'Total Cost (₱)', '2500',
          kb: TextInputType.number),
      _gap(),
      _lbl('Pesticide Requirement'),
      _field('Enter', 'Malathion 50EC'),

      // ── Harvesting Stage ────────────────────────────────────
      const _SectionHeader(title: 'Harvesting Stage'),
      _row2('Total Harvested (kg)', '500', 'Avg Harvest/ha', '333',
          kb: TextInputType.number),
      _gap(),
      _row2('Food Consumption (%)', '10', 'Harvest Cost (₱)', '1000',
          kb: TextInputType.number),

      // ── Crop Damage ─────────────────────────────────────────
      const _SectionHeader(title: 'Crop Damage'),
      _row2('Damage Area', '0.5 ha', 'Damage (ha)', '0.5',
          kb: TextInputType.number),
      _gap(),
      _lbl('Treatment / Action Taken'),
      _field('Enter treatment', 'Applied pesticide'),

      // ── Trainings ───────────────────────────────────────────
      const _SectionHeader(title: 'Trainings Attended'),
      _lbl('Training (include date and no. of farmers)'),
      _field(
          'Enter training', 'Crop Production Seminar — Jan 2026, 25 farmers'),

      const SizedBox(height: 32),
    ]);
  }
}

// ── LIVESTOCK edit form ───────────────────────────────────────────
class _LivestockEditForm extends StatefulWidget {
  @override
  State<_LivestockEditForm> createState() => _LivestockEditFormState();
}

class _LivestockEditFormState extends State<_LivestockEditForm> {
  String? _primaryIntervention = 'Goat';
  String? _housingType = 'Semi-confinement';
  String? _landOwnership = 'Owned';

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ── Project Background ──────────────────────────────────
      const _SectionHeader(title: 'Project Background'),
      _row2('FCA Name', 'Maharlika FCA', 'Region', 'Region IV-A (CALABARZON)'),
      _gap(),
      _row2('Municipality', 'Cuenca', 'Barangay', 'Bungahan'),
      _gap(),
      _lbl('Project Title'),
      _field('Enter Project Title', 'SAAD 2026 Livestock Production'),
      _gap(),
      CropDropdown(
          label: 'Primary Intervention Provided',
          hint: 'Choose',
          value: _primaryIntervention,
          items: const ['Carabao', 'Goat', 'Swine', 'Cattle', 'Others'],
          onChanged: (v) => setState(() => _primaryIntervention = v)),
      _gap(),
      _lbl('Support Intervention Provided'),
      _field('Enter support intervention', 'Veterinary supplies'),

      // ── Livestock Information ───────────────────────────────
      const _SectionHeader(title: 'Livestock Information'),
      _row2('Name of Farmer', 'Juan Dela Cruz', 'Breed', 'Anglo-Nubian'),
      _gap(),
      _lbl('Farmgate Price (₱/head)'),
      _field('Enter price', '3500', kb: TextInputType.number),

      // ── Production Information ──────────────────────────────
      const _SectionHeader(title: 'Production Information'),
      _row2('Stocks Received', '10', 'Date Received', '2026-01-05'),
      _gap(),
      _row2('Male Stocks', '3', 'Female Stocks', '7', kb: TextInputType.number),
      _gap(),
      _row2('M:F Ratio', '3:7', 'Age Upon Receipt (months)', '6'),
      _gap(),
      _row2('Avg Weight (kg)', '15', 'Pregnant Stocks', '2',
          kb: TextInputType.number),
      _gap(),
      CropDropdown(
          label: 'Type of Housing/Confinement',
          hint: 'Choose',
          value: _housingType,
          items: const [
            'Confinement',
            'Semi-confinement',
            'Free range',
            'Pasture-based',
            'Communal',
            'Others'
          ],
          onChanged: (v) => setState(() => _housingType = v)),
      _gap(),
      CropDropdown(
          label: 'Farm Ownership',
          hint: 'Choose',
          value: _landOwnership,
          items: const ['Owned', 'Rented', 'Others'],
          onChanged: (v) => setState(() => _landOwnership = v)),
      _gap(),
      _lbl('Waste Management Practices'),
      _field('Enter', 'Composting'),

      // ── Water and Feeding ───────────────────────────────────
      const _SectionHeader(title: 'Water and Feeding'),
      _lbl('Grazing Area (per head, with unit)'),
      _field('Enter', '0.5 ha/head'),
      _gap(),
      _lbl('Source/s of Water'),
      _field('Enter', 'Well water'),

      // ── Harvesting Information ──────────────────────────────
      const _SectionHeader(title: 'Harvesting Information'),
      _row2('Avg Marketable Weight (kg)', '25', 'Slaughtered Count', '5',
          kb: TextInputType.number),

      // ── Mortality Information ───────────────────────────────
      const _SectionHeader(title: 'Mortality Information'),
      _row2('Pest Mortality', '0', 'Disease Mortality', '1',
          kb: TextInputType.number),
      _gap(),
      _row2('Env. Mortality', '0', 'Human-induced Mortality', '0',
          kb: TextInputType.number),
      _gap(),
      _row2('Total Mortalities', '1', 'Remaining Stocks', '9',
          kb: TextInputType.number),
      _gap(),
      _lbl('Treatment / Action Taken'),
      _field('Enter treatment', 'Veterinary consultation'),

      // ── Trainings ───────────────────────────────────────────
      const _SectionHeader(title: 'Trainings Attended'),
      _lbl('Training (include date and no. of farmers)'),
      _field('Enter training',
          'Livestock Production Seminar — Feb 2026, 20 farmers'),

      const SizedBox(height: 32),
    ]);
  }
}

// ── POULTRY edit form ─────────────────────────────────────────────
class _PoultryEditForm extends StatefulWidget {
  @override
  State<_PoultryEditForm> createState() => _PoultryEditFormState();
}

class _PoultryEditFormState extends State<_PoultryEditForm> {
  String? _primaryIntervention = 'Chicken';
  String? _purpose = 'Meat / Broiler';
  String? _housingType = 'Confinement';
  String? _landOwnership = 'Owned';
  String? _feedType = 'Finisher';

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ── Project Background ──────────────────────────────────
      const _SectionHeader(title: 'Project Background'),
      _row2('Reporting Period', '2026', 'FCA Name', 'Maharlika FCA'),
      _gap(),
      _row2('Region', 'Region IV-A (CALABARZON)', 'Province', 'Batangas'),
      _gap(),
      _row2('Municipality', 'Cuenca', 'Barangay', 'Bungahan'),
      _gap(),
      _lbl('Project Title'),
      _field('Enter Project Title', 'SAAD 2026 Poultry Production'),
      _gap(),
      CropDropdown(
          label: 'Primary Intervention Provided',
          hint: 'Choose',
          value: _primaryIntervention,
          items: const ['Chicken', 'Others'],
          onChanged: (v) => setState(() => _primaryIntervention = v)),
      _gap(),
      _lbl('Support Intervention Provided'),
      _field('Enter support intervention', 'Feeds, Vitamins'),
      _gap(),
      CropDropdown(
          label: 'Purpose of Production',
          hint: 'Choose',
          value: _purpose,
          items: const ['Breeding', 'Meat / Broiler', 'Egg / Layer'],
          onChanged: (v) => setState(() => _purpose = v)),

      // ── Poultry Information ─────────────────────────────────
      const _SectionHeader(title: 'Poultry Information'),
      _row2('Name of Farmer', 'Juan Dela Cruz', 'Breed', 'Native Chicken'),
      _gap(),
      _lbl('Farmgate Price (₱/kg)'),
      _field('Enter price', '180', kb: TextInputType.number),

      // ── Production Information ──────────────────────────────
      const _SectionHeader(title: 'Production Information'),
      _row2('Stocks Received', '100', 'Date Received', '2026-01-10'),
      _gap(),
      _row2('Age Upon Receipt', '1 day old', 'Avg Weight (g)', '40'),
      _gap(),
      _row2('Total Productive Cycle', '56 days', '', ''),
      _gap(),
      CropDropdown(
          label: 'Type of Housing/Confinement',
          hint: 'Choose',
          value: _housingType,
          items: const [
            'Confinement',
            'Semi-confinement',
            'Free range',
            'Communal',
            'Others'
          ],
          onChanged: (v) => setState(() => _housingType = v)),
      _gap(),
      CropDropdown(
          label: 'Land Ownership',
          hint: 'Choose',
          value: _landOwnership,
          items: const ['Owned', 'Donated', 'Rented', 'Others'],
          onChanged: (v) => setState(() => _landOwnership = v)),
      _gap(),
      // Broiler fields
      _row2('Harvested Birds', '90', 'Total Weight Harvested (kg)', '180',
          kb: TextInputType.number),
      _gap(),
      _row2('ADG (g/day)', '22', 'Harvest Recovery (%)', '90',
          kb: TextInputType.number),
      _gap(),
      _row2('Avg Live Weight (kg)', '2', 'FCR (kg)', '2.5',
          kb: TextInputType.number),
      _gap(),
      _row2('Avg Age Harvested (days)', '56', 'BPI', '312',
          kb: TextInputType.number),

      // ── Mortality Information ───────────────────────────────
      const _SectionHeader(title: 'Mortality Information'),
      _row2('Pest Mortality', '0', 'Disease Mortality', '2',
          kb: TextInputType.number),
      _gap(),
      _row2('Env. Mortality', '0', 'Human-induced Mortality', '0',
          kb: TextInputType.number),
      _gap(),
      _row2('Total Mortalities', '2', 'Remaining Stocks', '98',
          kb: TextInputType.number),
      _gap(),
      _row2('Rejects/Culled', '0', 'Culled Sold', '0',
          kb: TextInputType.number),
      _gap(),
      _lbl('Treatment / Action Taken'),
      _field('Enter treatment', 'Biosecurity measures applied'),

      // ── Feeding and Water ───────────────────────────────────
      const _SectionHeader(title: 'Feeding and Water Management'),
      CropDropdown(
          label: 'Type of Feed Used',
          hint: 'Choose',
          value: _feedType,
          items: const [
            'Booster',
            'Grower',
            'Finisher',
            'Laying pellet',
            'Laying crumble',
            'Laying mash',
            'Others'
          ],
          onChanged: (v) => setState(() => _feedType = v)),
      _gap(),
      _row2('Total Feed Consumed (kg)', '250', 'Feed per Day (g/hd)', '45',
          kb: TextInputType.number),
      _gap(),
      _lbl('Source/s of Water'),
      _field('Enter', 'Tap water'),

      // ── Waste Management ────────────────────────────────────
      const _SectionHeader(title: 'Waste Management'),
      _row2('Sacks Produced', '20', 'Sacks Sold', '15',
          kb: TextInputType.number),
      _gap(),
      _row2('Sacks Used', '5', 'Price per Sack (₱)', '80',
          kb: TextInputType.number),

      // ── Trainings ───────────────────────────────────────────
      const _SectionHeader(title: 'Trainings Attended'),
      _lbl('Training (include date and no. of farmers)'),
      _field('Enter training',
          'Poultry Production Seminar — Jan 2026, 18 farmers'),

      const SizedBox(height: 32),
    ]);
  }
}
