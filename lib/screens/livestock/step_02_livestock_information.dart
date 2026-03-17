import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/da_colors.dart';
import '../../routes/app_routes.dart';
import 'livestock_step_wrapper.dart';
import '../../widgets/crop_form_shell.dart';
import '../../widgets/crop_field.dart';
import '../../widgets/crop_dropdown.dart';

class LivestockStep2LivestockInformation extends StatefulWidget {
  const LivestockStep2LivestockInformation({super.key, required this.wrapper});
  final LivestockStepWrapper wrapper;

  @override
  State<LivestockStep2LivestockInformation> createState() =>
      _LivestockStep2State();
}

class _LivestockStep2State
    extends State<LivestockStep2LivestockInformation> {

  LivestockStepWrapper get w => widget.wrapper;

  // Local state
  String _farmerName = '';
  String? _breed;
  final List<LivestockInputReceived>  _inputsReceived  = [LivestockInputReceived()];
  final List<LivestockInputPurchased> _inputsPurchased = [LivestockInputPurchased()];
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
    'Landrace', 'Large White', 'Duroc', 'Hampshire', 'Philippine Native',
    // Horse
    'Arabian', 'Thoroughbred', 'Philippine Native Horse',
    // Other
    'Crossbred', 'Native/Local', 'Others',
  ];

  void _next() {
    w.farmerName     = _farmerName;
    w.breed          = _breed;
    w.inputsReceived  = _inputsReceived;
    w.inputsPurchased = _inputsPurchased;
    w.farmgatePrices  = _farmgatePrices
        .where((s) => s.trim().isNotEmpty)
        .toList();

    Navigator.of(context).pushNamed(
      AppRoutes.livestockStep3,
      arguments: w,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CropFormShell(
      formTitle:    'LIVESTOCK PRODUCTION',
      formSubtitle: 'Livestock Production Monitoring Form',
      currentStep: 1,
      child: _buildForm(),
      onNext: _next,
    );
  }

  Widget _buildForm() {
    // Show farmer name only if individually managed
    final isIndividual = w.implementationType == 'individual' || w.implementationType == 'hybrid';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        _sectionTitle('Livestock Information'),
        const SizedBox(height: 24),

        // Name of Farmer — only if individually managed
        if (isIndividual) ...[
          CropField(
            label:        'Name of Farmer',
            hint:         'Enter Name',
            initialValue: _farmerName,
            onChanged:    (v) => _farmerName = v,
          ),
          const SizedBox(height: 20),
        ],

        // Breed
        CropDropdown(
          label:     'Breed',
          hint:      'Choose',
          value:     _breed,
          items:     _breedOptions,
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
            onTap: () => setState(
                () => _inputsReceived.add(LivestockInputReceived()))),
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
                    initialValue:  _farmgatePrices[i],
                    onChanged:     (v) => _farmgatePrices[i] = v,
                    keyboardType:  const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[\d.]')),
                    ],
                    style: GoogleFonts.poppins(
                        fontSize: 14, color: DAColors.textDark),
                    decoration: _rawDeco('Enter'),
                  ),
                ),
                if (i > 0) ...[
                  const SizedBox(width: 8),
                  _removeBtn(
                      () => setState(() => _farmgatePrices.removeAt(i))),
                ] else
                  const SizedBox(width: 40),
              ],
            ),
          );
        }),
        _addAnotherBtn(
            onTap: () => setState(() => _farmgatePrices.add(''))),

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
              onChanged:    (v) => item.name = v,
              style: GoogleFonts.poppins(
                  fontSize: 14, color: DAColors.textDark),
              decoration: _rawDeco('Enter'),
            ),
            const SizedBox(height: 10),

            // Quantity
            _buildSubLabel('Quantity'),
            const SizedBox(height: 6),
            TextFormField(
              initialValue:  item.quantity,
              onChanged:     (v) => item.quantity = v,
              keyboardType:  TextInputType.number,
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
                  _removeBtn(() => setState(
                      () => _inputsPurchased.removeAt(i))),
              ],
            ),
            const SizedBox(height: 10),

            // Name
            _buildSubLabel('List of inputs purchased by the FCA'),
            const SizedBox(height: 6),
            TextFormField(
              initialValue: item.name,
              onChanged:    (v) => item.name = v,
              style: GoogleFonts.poppins(
                  fontSize: 14, color: DAColors.textDark),
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
                        initialValue:  item.quantity,
                        onChanged:     (v) => item.quantity = v,
                        keyboardType:  TextInputType.number,
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
                        initialValue:  item.cost,
                        onChanged:     (v) => item.cost = v,
                        keyboardType:  const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[\d.]')),
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
    hintText:  hint,
    hintStyle: GoogleFonts.poppins(
        fontSize: 14, color: DAColors.textMuted),
    filled:      true,
    fillColor:   Colors.white,
    isDense:     true,
    contentPadding: const EdgeInsets.symmetric(
        horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
            color: Color(0xFFDDDDDD), width: 1.5)),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
            color: Color(0xFFDDDDDD), width: 1.5)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
            color: DAColors.greenMid, width: 2.0)),
  );

  // ── Add Another button ───────────────────────────────────────
  Widget _addAnotherBtn({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: const BoxDecoration(
              color: DAColors.greenMid,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          Text('Add Another',
            style: GoogleFonts.poppins(
              fontSize:   13,
              fontWeight: FontWeight.w600,
              color:      DAColors.greenMid,
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
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.close_rounded,
            color: Colors.red.shade400, size: 16),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
    style: GoogleFonts.poppins(
      fontSize: 22, fontWeight: FontWeight.w800,
      color: DAColors.textDark));

  Widget _buildLabel(String t) => Text(t,
    style: GoogleFonts.poppins(
      fontSize: 14, fontWeight: FontWeight.w700,
      color: DAColors.textDark));

  Widget _buildSubLabel(String t) => Text(t,
    style: GoogleFonts.poppins(
      fontSize: 13, fontWeight: FontWeight.w600,
      color: DAColors.textDark));
}