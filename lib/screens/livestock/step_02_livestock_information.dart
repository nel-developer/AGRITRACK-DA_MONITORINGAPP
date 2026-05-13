import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/approved_farmer.dart';
import '../../theme/da_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/approved_farmer_picker_field.dart';
import 'livestock_step_wrapper.dart';
import '../../widgets/crop_form_shell.dart';
import '../../widgets/crop_dropdown.dart';
import '../../services/pending_draft_service.dart';

class LivestockStep2LivestockInformation extends StatefulWidget {
  const LivestockStep2LivestockInformation({super.key, required this.wrapper});
  final LivestockStepWrapper wrapper;

  @override
  State<LivestockStep2LivestockInformation> createState() =>
      _LivestockStep2State();
}

class _LivestockStep2State extends State<LivestockStep2LivestockInformation> {
  LivestockStepWrapper get w => widget.wrapper;

  late final TextEditingController _farmerNameController;

  // Local state
  String _farmerName = '';
  String? _breed;
  final List<LivestockInputReceived> _inputsReceived = [
    LivestockInputReceived()
  ];
  final List<LivestockInputPurchased> _inputsPurchased = [
    LivestockInputPurchased()
  ];
  final List<String> _farmgatePrices = [''];

  static const _breedOptions = [
    // Cattle
    'Brahman', 'Angus', 'Hereford', 'Simmental', 'Limousin',
    'Holstein', 'Brown Swiss', 'Jersey',
    // Carabao
    'Philippine Carabao', 'Murrah', 'Nili-Ravi',
    // Goat
    'Anglo-Nubian', 'Boer', 'Philippine Native', 'Saanen',
    // Sheep
    'Dorper', 'Katahdin', 'Philippine Native Sheep',
    // Swine
    'Landrace', 'Large White', 'Duroc', 'Hampshire', 'Philippine Native Pig',
    // Horse
    'Arabian', 'Thoroughbred', 'Philippine Native Horse',
    // Other
    'Crossbred', 'Native/Local', 'Others',
  ];

  @override
  void initState() {
    super.initState();

    // CRITICAL: For collectives, always ensure farmerName is cleared
    if (w.implementationType?.toLowerCase() == 'collective') {
      w.farmerName = '';
      _farmerName = '';
    } else {
      _farmerName = w.farmerName;
    }

    _farmerNameController = TextEditingController(text: _farmerName);

    // ✅ CRITICAL: When adding a new batch for the same farmer, clear breed and inputs
    if (w.isAddingNewCommodity) {
      _breed = null; // Clear breed for new batch
    } else {
      _breed = w.breed; // Load breed only on fresh start
    }

    // ✅ CRITICAL: When adding a new batch for the same farmer, clear old inputs
    // Only load inputs if they're empty (first time) - don't carry over from previous batch
    _inputsReceived
      ..clear()
      ..addAll(
        (w.isAddingNewCommodity || w.inputsReceived.isEmpty
                ? [LivestockInputReceived()]
                : w.inputsReceived)
            .map((item) {
          final copy = LivestockInputReceived();
          copy.name = item.name;
          copy.quantity = item.quantity;
          return copy;
        }),
      );
    _inputsPurchased
      ..clear()
      ..addAll(
        (w.isAddingNewCommodity || w.inputsPurchased.isEmpty
                ? [LivestockInputPurchased()]
                : w.inputsPurchased)
            .map((item) {
          final copy = LivestockInputPurchased();
          copy.name = item.name;
          copy.quantity = item.quantity;
          copy.cost = item.cost;
          return copy;
        }),
      );
    _farmgatePrices
      ..clear()
      ..addAll(w.isAddingNewCommodity || w.farmgatePrices.isEmpty
          ? ['']
          : List<String>.from(w.farmgatePrices));
  }

  @override
  void dispose() {
    _farmerNameController.dispose();
    super.dispose();
  }

  String? get _selectedApprovedFarmerLabel {
    if (w.saadIdNo.isEmpty) {
      return null;
    }
    return w.saadIdNo;
  }

  void _selectApprovedFarmer(ApprovedFarmer farmer) {
    setState(() {
      if (w.implementationType?.toLowerCase() == 'collective') {
        // For collectives, just add to members
        final existing = w.members.firstWhere(
          (member) => (member['saadIdNo'] as String? ?? '') == farmer.saadIdNo,
          orElse: () => {},
        );
        if (existing.isEmpty) {
          w.members.add({
            'name': farmer.fullName,
            'saadIdNo': farmer.saadIdNo,
            'municipality': farmer.municipality,
          });
        }
      } else {
        // For individual/hybrid, keep only the actively selected farmer
        _farmerName = [farmer.firstName, farmer.middleName, farmer.surname]
            .where((part) => part.trim().isNotEmpty)
            .join(' ')
            .trim();
        _farmerNameController.text = _farmerName;
        w.saadIdNo = farmer.saadIdNo;
        // Don't store full profile, only minimal data
        w.approvedFarmerProfile = {
          'saadIdNo': farmer.saadIdNo,
          'fullName': _farmerName,
        };
        // Region, province, barangay come from the group, not the farmer
        w.municipality =
            farmer.municipality.isEmpty ? w.municipality : farmer.municipality;
        w.members.clear();
        w.members.add({
          'name': _farmerName,
          'saadIdNo': farmer.saadIdNo,
        });
      }
    });
  }

  void _clearApprovedFarmer() {
    setState(() {
      w.saadIdNo = '';
      w.approvedFarmerProfile = {};
      if (w.implementationType?.toLowerCase() != 'collective') {
        w.members.clear();
      }
    });
  }

  Widget _approvedFarmerInfoCard() {
    final profile = Map<String, dynamic>.from(w.approvedFarmerProfile);
    if (profile.isEmpty) {
      return const SizedBox.shrink();
    }

    final rows = <MapEntry<String, String>>[
      MapEntry('Farmer Name', (profile['fullName'] as String? ?? '').trim()),
      MapEntry('Sex', (profile['sex'] as String? ?? '').trim()),
      MapEntry(
          'Date of Birth', (profile['dateOfBirth'] as String? ?? '').trim()),
      MapEntry('Spouse Name', (profile['spouseName'] as String? ?? '').trim()),
      MapEntry(
        'Address',
        [
          (profile['barangay'] as String? ?? '').trim(),
          (profile['municipality'] as String? ?? '').trim(),
          (profile['province'] as String? ?? '').trim(),
        ].where((part) => part.isNotEmpty).join(', '),
      ),
    ].where((entry) => entry.value.isNotEmpty).toList();

    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD9E8DB), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Information',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: DAColors.greenMid,
            ),
          ),
          const SizedBox(height: 10),
          ...rows.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: DAColors.textDark,
                    ),
                    children: [
                      TextSpan(
                        text: '${entry.key}: ',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: entry.value),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  void _next() async {
    // Handle adding new farmer to existing collective group
    if (w.isAddFarmer && w.implementationType?.toLowerCase() == 'collective') {
      // Add the new farmer to the members list
      final newSaadId = w.saadIdNo.trim();
      if (_farmerName.trim().isNotEmpty || newSaadId.isNotEmpty) {
        final existing = w.members.firstWhere(
          (member) {
            final memberSaad = (member['saadIdNo'] as String? ??
                    member['saadId'] as String? ??
                    '')
                .trim();
            if (newSaadId.isNotEmpty) {
              return memberSaad == newSaadId;
            }
            return (member['name'] as String? ?? '').trim().toLowerCase() ==
                _farmerName.trim().toLowerCase();
          },
          orElse: () => {},
        );
        if (existing.isEmpty) {
          w.members.add({
            'name': _farmerName.trim(),
            'saadIdNo': newSaadId,
          });
        }
      }

      // Set the batch data for this new farmer
      w.breed = _breed;
      w.inputsReceived = _inputsReceived;
      w.inputsPurchased = _inputsPurchased;
      w.farmgatePrices =
          _farmgatePrices.where((s) => s.trim().isNotEmpty).toList();

      // Add batch data for the new farmer
      if (w.breed != null && w.breed!.isNotEmpty) {
        w.completedBatches.add({
          'breed': w.breed,
          'farmerName': _farmerName.trim(),
          'saadIdNo': w.saadIdNo.trim().isNotEmpty
              ? w.saadIdNo.trim()
              : _farmerName.trim(),
          'inputsReceived':
              w.inputsReceived.map((item) => item.toJson()).toList(),
          'inputsPurchased':
              w.inputsPurchased.map((item) => item.toJson()).toList(),
          'farmgatePrices': w.farmgatePrices,
          'stocksReceived': w.stocksReceived,
          'dateReceived': w.dateReceived,
          'maleStocks': w.maleStocks,
          'femaleStocks': w.femaleStocks,
          'maleToFemaleRatio': w.maleToFemaleRatio,
        });
      }

      // Save the updated group data locally
      final dataToSave = w.toJson();
      Map<String, dynamic> membersByFarmerId = {};
      for (final member in w.members) {
        final memberName =
            (member['name'] as String? ?? member['farmerName'] as String? ?? '')
                .trim();
        final memberSaadId =
            (member['saadIdNo'] as String? ?? member['saadId'] as String? ?? '')
                .trim();
        if (memberName.isNotEmpty) {
          final memberId = memberSaadId.isNotEmpty ? memberSaadId : memberName;
          membersByFarmerId[memberId] = {
            'farmerName': memberName,
            'saadIdNo': memberSaadId,
            'addedDate': DateTime.now().toIso8601String(),
          };
        }
      }
      dataToSave['members'] = w.members;
      dataToSave['membersByFarmerId'] = membersByFarmerId;
      dataToSave['completedBatches'] = w.completedBatches ?? [];

      await PendingDraftService.instance.saveDraft(
        productionType: 'livestock',
        implementationType: w.implementationType ?? '',
        data: dataToSave,
      );

      // Return to summary screen with updated wrapper
      Navigator.of(context).pop(w);
      return;
    }

    // Set farmerName if manual entry provided
    if (_farmerName.isNotEmpty) {
      w.farmerName = _farmerName;
      // If adding a farmer to existing group, add to members
      if (w.isAddFarmer && w.members.isNotEmpty) {
        final existing = w.members.firstWhere(
          (member) => (member['name'] as String? ?? '') == _farmerName,
          orElse: () => {},
        );
        if (existing.isEmpty) {
          w.members.add({
            'name': _farmerName,
            'saadIdNo': w.saadIdNo.isNotEmpty ? w.saadIdNo : _farmerName,
          });
        }
      }
    }

    w.breed = _breed;
    w.inputsReceived = _inputsReceived;
    w.inputsPurchased = _inputsPurchased;
    w.farmgatePrices =
        _farmgatePrices.where((s) => s.trim().isNotEmpty).toList();
    // Members are already updated via ApprovedFarmerPickerField, don't overwrite

    Navigator.of(context).pushNamed(
      AppRoutes.livestockStep3,
      arguments: w,
    );
  }

  Widget _sectionBox(Widget child) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
        ),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    return CropFormShell(
      formTitle: 'LIVESTOCK PRODUCTION',
      formSubtitle: 'Livestock Production Monitoring Form',
      currentStep: 1,
      onNext: _next,
      child: _buildForm(),
    );
  }

  Widget _buildForm() {
    // Show editable name field when:
    //   (a) explicitly adding a new farmer (isAddFarmer), or
    //   (b) fresh individual/hybrid start with no name yet
    // When farmerName is already set (add-batch/add-commodity), hide the manual name field.
    final bool showFarmerName = w.isAddFarmer ||
        ((w.implementationType == 'individual' ||
                w.implementationType == 'hybrid') &&
            w.farmerName.isEmpty);

    // For individual/hybrid forms, keep the SAAD picker visible when a farmer has already been selected
    final bool showApprovedFarmerPicker =
        w.implementationType?.toLowerCase() != 'collective' &&
            (w.isAddFarmer || w.farmerName.isEmpty || w.saadIdNo.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Livestock Information'),
        const SizedBox(height: 24),

        // Name of Farmer / Group Members — only if individually managed and no name yet
        if (showApprovedFarmerPicker) ...[
          ApprovedFarmerPickerField(
            selectedLabel: _selectedApprovedFarmerLabel,
            onSelected: _selectApprovedFarmer,
            onCleared: _clearApprovedFarmer,
          ),
        ],
        if (showFarmerName) ...[
          if (w.approvedFarmerProfile.isNotEmpty) ...[
            const SizedBox(height: 12),
            _approvedFarmerInfoCard(),
          ],
          const SizedBox(height: 20),
          _buildLabel('Name of Farmer'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _farmerNameController,
            onChanged: (v) {
              _farmerName = v;
              if (_selectedApprovedFarmerLabel != null &&
                  v.trim() !=
                      (w.approvedFarmerProfile['fullName'] as String? ?? '')
                          .trim()) {
                _clearApprovedFarmer();
              }
            },
            style: GoogleFonts.poppins(fontSize: 14, color: DAColors.textDark),
            decoration: _rawDeco('Enter Name'),
          ),
          const SizedBox(height: 20),
        ],

        // Breed
        CropDropdown(
          label: 'Breed',
          hint: 'Choose',
          value: _breed,
          items: _breedOptions,
          onChanged: (v) => setState(() => _breed = v),
        ),
        const SizedBox(height: 20),

        // ── List of inputs received from SAAD ─────────────────
        _buildLabel('List of inputs received from SAAD'),
        const SizedBox(height: 8),
        ..._inputsReceived.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return _inputReceivedRow(i, item);
        }),
        _addAnotherBtn(
            onTap: () =>
                setState(() => _inputsReceived.add(LivestockInputReceived()))),
        const SizedBox(height: 20),

        // ── List of inputs purchased by the FCA ───────────────
        _buildLabel('List of inputs purchased by the FCA'),
        const SizedBox(height: 8),
        ..._inputsPurchased.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return _inputPurchasedRow(i, item);
        }),
        _addAnotherBtn(
            onTap: () => setState(
                () => _inputsPurchased.add(LivestockInputPurchased()))),
        const SizedBox(height: 20),

        // ── Farmgate price of each produce ────────────────────
        _buildLabel('Farmgate price of each produce'),
        const SizedBox(height: 8),
        ..._farmgatePrices.asMap().entries.map((entry) {
          final i = entry.key;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _farmgatePrices[i],
                    onChanged: (v) => _farmgatePrices[i] = v,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                    ],
                    style: GoogleFonts.poppins(
                        fontSize: 14, color: DAColors.textDark),
                    decoration: _rawDeco('Enter'),
                  ),
                ),
                if (i > 0) ...[
                  const SizedBox(width: 8),
                  _removeBtn(() => setState(() => _farmgatePrices.removeAt(i))),
                ] else
                  const SizedBox(width: 40),
              ],
            ),
          );
        }),
        _addAnotherBtn(onTap: () => setState(() => _farmgatePrices.add(''))),

        const SizedBox(height: 32),
      ],
    );
  }

  // ── Input received row: Name + Quantity ─────────────────────
  Widget _inputReceivedRow(int i, LivestockInputReceived item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFDDDDDD), width: 1.2),
          borderRadius: BorderRadius.circular(14),
          color: const Color(0xFFFAFAFA),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildLabel('Input ${i + 1}'),
                ),
                if (i > 0)
                  _removeBtn(() => setState(() => _inputsReceived.removeAt(i))),
              ],
            ),
            const SizedBox(height: 10),

            // Name
            _buildSubLabel('List of inputs received from SAAD'),
            const SizedBox(height: 6),
            TextFormField(
              initialValue: item.name,
              onChanged: (v) => item.name = v,
              style:
                  GoogleFonts.poppins(fontSize: 14, color: DAColors.textDark),
              decoration: _rawDeco('Enter'),
            ),
            const SizedBox(height: 10),

            // Quantity
            _buildSubLabel('Quantity'),
            const SizedBox(height: 6),
            TextFormField(
              initialValue: item.quantity,
              onChanged: (v) => item.quantity = v,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              style:
                  GoogleFonts.poppins(fontSize: 14, color: DAColors.textDark),
              decoration: _rawDeco('Enter'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Input purchased row: Name + Quantity + Cost ─────────────
  Widget _inputPurchasedRow(int i, LivestockInputPurchased item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFDDDDDD), width: 1.2),
          borderRadius: BorderRadius.circular(14),
          color: const Color(0xFFFAFAFA),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _buildLabel('Input ${i + 1}')),
                if (i > 0)
                  _removeBtn(
                      () => setState(() => _inputsPurchased.removeAt(i))),
              ],
            ),
            const SizedBox(height: 10),

            // Name
            _buildSubLabel('List of inputs purchased by the FCA'),
            const SizedBox(height: 6),
            TextFormField(
              initialValue: item.name,
              onChanged: (v) => item.name = v,
              style:
                  GoogleFonts.poppins(fontSize: 14, color: DAColors.textDark),
              decoration: _rawDeco('Enter'),
            ),
            const SizedBox(height: 10),

            // Quantity + Cost side by side
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSubLabel('Quantity'),
                      const SizedBox(height: 6),
                      TextFormField(
                        initialValue: item.quantity,
                        onChanged: (v) => item.quantity = v,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: DAColors.textDark),
                        decoration: _rawDeco('Enter'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSubLabel('Cost'),
                      const SizedBox(height: 6),
                      TextFormField(
                        initialValue: item.cost,
                        onChanged: (v) => item.cost = v,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                        ],
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: DAColors.textDark),
                        decoration: _rawDeco('Enter'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared raw InputDecoration (no label) ────────────────────
  InputDecoration _rawDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(fontSize: 14, color: DAColors.textMuted),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDDDDDD), width: 1.5)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDDDDDD), width: 1.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: DAColors.greenMid, width: 2.0)),
      );

  // ── Add Another button ───────────────────────────────────────
  Widget _addAnotherBtn({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: DAColors.greenMid,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          Text('Add Another',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: DAColors.greenMid,
              )),
        ],
      ),
    );
  }

  // ── Remove button ────────────────────────────────────────────
  Widget _removeBtn(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.close_rounded, color: Colors.red.shade400, size: 16),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: GoogleFonts.poppins(
          fontSize: 22, fontWeight: FontWeight.w800, color: DAColors.textDark));

  Widget _buildLabel(String t) => Text(t,
      style: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w700, color: DAColors.textDark));

  Widget _buildSubLabel(String t) => Text(t,
      style: GoogleFonts.poppins(
          fontSize: 13, fontWeight: FontWeight.w600, color: DAColors.textDark));
}
