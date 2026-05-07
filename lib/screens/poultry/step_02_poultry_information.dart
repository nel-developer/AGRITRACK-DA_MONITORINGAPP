import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/approved_farmer.dart';
import '../../theme/da_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/approved_farmer_picker_field.dart';
import '../../widgets/crop_form_shell.dart';
import '../../widgets/crop_field.dart';
import 'poultry_step_wrapper.dart';

class PoultryStep2PoultryInformation extends StatefulWidget {
  const PoultryStep2PoultryInformation({super.key, required this.wrapper});
  final PoultryStepWrapper wrapper;

  @override
  State<PoultryStep2PoultryInformation> createState() => _PoultryStep2State();
}

class _PoultryStep2State extends State<PoultryStep2PoultryInformation> {
  PoultryStepWrapper get w => widget.wrapper;

  late final TextEditingController _farmerNameController;

  String _farmerName = '';
  String _breed = '';

  final List<PoultryInputReceived> _inputsReceived = [PoultryInputReceived()];
  final List<PoultryInputPurchased> _inputsPurchased = [
    PoultryInputPurchased()
  ];
  String _farmgatePrice = '';

  // Show editable name field when:
  //   (a) explicitly adding a new farmer (isAddFarmer), or
  //   (b) fresh individual/hybrid start with no name yet
  //   (c) collective records should NOT show farmer name field
  bool get _showFarmerName =>
      w.isAddFarmer ||
      ((w.implementationType == 'individual' ||
              w.implementationType == 'hybrid') &&
          w.farmerName.isEmpty);

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
    _breed = w.breed;
    _farmgatePrice = w.farmgatePrices.isNotEmpty ? w.farmgatePrices.first : '';
    _inputsReceived
      ..clear()
      ..addAll(
        (w.inputsReceived.isEmpty ? [PoultryInputReceived()] : w.inputsReceived)
            .map((item) {
          final copy = PoultryInputReceived();
          copy.name = item.name;
          copy.quantity = item.quantity;
          return copy;
        }),
      );
    _inputsPurchased
      ..clear()
      ..addAll(
        (w.inputsPurchased.isEmpty
                ? [PoultryInputPurchased()]
                : w.inputsPurchased)
            .map((item) {
          final copy = PoultryInputPurchased();
          copy.name = item.name;
          copy.quantity = item.quantity;
          copy.cost = item.cost;
          return copy;
        }),
      );
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
        // For collectives, just add to members with minimal data
        final name = [farmer.firstName, farmer.middleName, farmer.surname]
            .where((part) => part.trim().isNotEmpty)
            .join(' ')
            .trim();
        final existing = w.members.firstWhere(
          (member) => (member['saadIdNo'] as String? ?? '') == farmer.saadIdNo,
          orElse: () => {},
        );
        if (existing.isEmpty) {
          w.members.add({
            'name': name,
            'saadIdNo': farmer.saadIdNo,
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
        // Don't set _selectedApprovedFarmerLabel for collectives
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

  void _next() {
    // Handle farmer name for individual/hybrid implementation types only
    if (_farmerName.isNotEmpty &&
        w.implementationType?.toLowerCase() != 'collective') {
      if (w.implementationType?.toLowerCase() == 'hybrid') {
        // For hybrid, add the manually entered farmer to members
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
      } else {
        // For individual
        w.farmerName = _farmerName;
        // If adding a farmer to existing group (isAddFarmer), preserve and add to members
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
        } else {
          // Fresh individual start - replace members with just this farmer
          w.members.clear();
          w.members.add({
            'name': _farmerName,
            'saadIdNo': w.saadIdNo.isNotEmpty ? w.saadIdNo : _farmerName,
          });
        }
      }
    }

    // For collective records, ensure farmerName stays empty
    if (w.implementationType?.toLowerCase() == 'collective') {
      w.farmerName = '';
      w.saadIdNo = '';
      w.approvedFarmerProfile = {};
    }

    w.breed = _breed;
    w.inputsReceived = _inputsReceived;
    w.inputsPurchased = _inputsPurchased;
    w.farmgatePrices = _farmgatePrice.trim().isEmpty ? [] : [_farmgatePrice];
    // Members are already updated via ApprovedFarmerPickerField, don't overwrite
    Navigator.of(context).pushNamed(AppRoutes.poultryStep3, arguments: w);
  }

  // ── Helpers ───────────────────────────────────────────────────
  Widget _label(String t) => Text(t,
      style: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w700, color: DAColors.textDark));

  Widget _subLabel(String t) => Text(t,
      style: GoogleFonts.poppins(
          fontSize: 13, fontWeight: FontWeight.w600, color: DAColors.textDark));

  Widget _rawField({
    required String hint,
    required ValueChanged<String> onChanged,
    String? initial,
    TextInputType kb = TextInputType.text,
    List<TextInputFormatter>? fmt,
  }) =>
      TextFormField(
        initialValue: initial,
        onChanged: onChanged,
        keyboardType: kb,
        inputFormatters: fmt,
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
        ),
      );

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
  Widget build(BuildContext context) => CropFormShell(
        formTitle: 'POULTRY PRODUCTION',
        formSubtitle: 'Poultry Production Monitoring Form',
        currentStep: 1,
        totalSteps: 7,
        onNext: _next,
        child: _buildForm(),
      );

  Widget _buildForm() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Poultry Information',
          style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: DAColors.textDark)),
      const SizedBox(height: 24),

      // ── Name of Farmer / Group Members ────────────────────────────────────────
      if (_showFarmerName) ...[
        ApprovedFarmerPickerField(
          selectedLabel: _selectedApprovedFarmerLabel,
          onSelected: _selectApprovedFarmer,
          onCleared: _clearApprovedFarmer,
        ),
        if (w.approvedFarmerProfile.isNotEmpty) ...[
          const SizedBox(height: 12),
          _approvedFarmerInfoCard(),
        ],
        const SizedBox(height: 20),
        _label('Name of Farmer'),
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
          decoration: InputDecoration(
            hintText: 'Enter Name',
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
                  const BorderSide(color: Color(0xFFDDDDDD), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFFDDDDDD), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: DAColors.greenMid, width: 2.0),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ] else if (w.implementationType?.toLowerCase() == 'collective') ...[
        // For collectives, show group members section
        _label('Group Members'),
        const SizedBox(height: 10),
        _sectionBox(
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (w.members.isEmpty) ...[
            Text(
              'No members added yet',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: DAColors.textMuted,
              ),
            ),
            const SizedBox(height: 12),
          ] else ...[
            ...w.members.asMap().entries.map((e) {
              final i = e.key;
              final member = e.value;
              final name = member['name'] as String? ?? '';
              final saadIdNo = member['saadIdNo'] as String? ?? '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAF7),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: const Color(0xFFD9E8DB), width: 1),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: DAColors.textDark,
                              ),
                            ),
                            if (saadIdNo.isNotEmpty)
                              Text(
                                'SAAD ID: $saadIdNo',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: DAColors.textMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: Colors.red),
                        onPressed: () => setState(() => w.members.removeAt(i)),
                        tooltip: 'Remove member',
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
          ],
        ])),
        const SizedBox(height: 20),
      ] else if (w.farmerName.isNotEmpty) ...[
        _label('Name of Farmer'),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDDDDDD), width: 1.5)),
          child: Text(w.farmerName,
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: DAColors.textDark,
                  fontWeight: FontWeight.w500)),
        ),
        const SizedBox(height: 20),
      ],

      // ── Breed ─────────────────────────────────────────────────
      CropField(
        label: 'Breed',
        hint: 'Enter',
        initialValue: _breed,
        onChanged: (v) => _breed = v,
      ),
      const SizedBox(height: 20),

      // ── Inputs received ───────────────────────────────────────
      _label('List of inputs (with quantity) received from the program'),
      const SizedBox(height: 10),
      ..._inputsReceived.asMap().entries.map((e) {
        final i = e.key;
        final item = e.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                  child: _rawField(
                hint: 'Enter Variety',
                initial: item.name,
                onChanged: (v) => item.name = v,
              )),
              if (i > 0) ...[
                const SizedBox(width: 8),
                _removeBtn(() => setState(() => _inputsReceived.removeAt(i))),
              ],
            ]),
            const SizedBox(height: 8),
            _subLabel('Quantity'),
            const SizedBox(height: 6),
            _rawField(
              hint: 'Enter Quantity',
              initial: item.quantity,
              kb: TextInputType.number,
              fmt: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (v) => item.quantity = v,
            ),
          ]),
        );
      }),
      _addBtn('Add Another Input',
          () => setState(() => _inputsReceived.add(PoultryInputReceived()))),
      const SizedBox(height: 20),

      // ── Inputs purchased ──────────────────────────────────────
      _label(
          'List of inputs purchased by the FCA\n(indicate quantity and cost)'),
      const SizedBox(height: 10),
      ..._inputsPurchased.asMap().entries.map((e) {
        final i = e.key;
        final item = e.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                  child: _rawField(
                hint: 'Enter Name of the Input',
                initial: item.name,
                onChanged: (v) => item.name = v,
              )),
              if (i > 0) ...[
                const SizedBox(width: 8),
                _removeBtn(() => setState(() => _inputsPurchased.removeAt(i))),
              ],
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _subLabel('Quantity'),
                  const SizedBox(height: 6),
                  _rawField(
                    hint: 'Enter Quantity',
                    initial: item.quantity,
                    kb: TextInputType.number,
                    fmt: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (v) => item.quantity = v,
                  ),
                ],
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _subLabel('Cost'),
                  const SizedBox(height: 6),
                  _rawField(
                    hint: 'Enter Cost',
                    initial: item.cost,
                    kb: const TextInputType.numberWithOptions(decimal: true),
                    fmt: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                    onChanged: (v) => item.cost = v,
                  ),
                ],
              )),
            ]),
          ]),
        );
      }),
      _addBtn('Add Another Input',
          () => setState(() => _inputsPurchased.add(PoultryInputPurchased()))),
      const SizedBox(height: 20),

      // ── Farmgate price ────────────────────────────────────────
      _label('Farmgate price of each produce'),
      const SizedBox(height: 8),
      _rawField(
        hint: 'Total Cost',
        initial: _farmgatePrice,
        kb: const TextInputType.numberWithOptions(decimal: true),
        fmt: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
        onChanged: (v) => _farmgatePrice = v,
      ),

      const SizedBox(height: 32),
    ]);
  }
}
