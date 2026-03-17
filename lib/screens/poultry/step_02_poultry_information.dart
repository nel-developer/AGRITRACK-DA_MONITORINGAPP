import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/da_colors.dart';
import '../../routes/app_routes.dart';
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

  String _farmerName = '';
  String _breed      = '';

  final List<PoultryInputReceived>  _inputsReceived  = [PoultryInputReceived()];
  final List<PoultryInputPurchased> _inputsPurchased = [PoultryInputPurchased()];
  String _farmgatePrice = '';

  bool get _showFarmerName =>
      (w.implementationType == 'individual' || w.implementationType == 'hybrid')
      && w.farmerName.isEmpty;

  void _next() {
    w.farmerName     = _farmerName.isEmpty ? w.farmerName : _farmerName;
    w.breed          = _breed;
    w.inputsReceived  = _inputsReceived;
    w.inputsPurchased = _inputsPurchased;
    w.farmgatePrices  = _farmgatePrice.trim().isEmpty ? [] : [_farmgatePrice];
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
  }) => TextFormField(
    initialValue: initial, onChanged: onChanged,
    keyboardType: kb, inputFormatters: fmt,
    style: GoogleFonts.poppins(fontSize: 14, color: DAColors.textDark),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(fontSize: 14, color: DAColors.textMuted),
      filled: true, fillColor: Colors.white, isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDDDDDD), width: 1.5)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDDDDDD), width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: DAColors.greenMid, width: 2.0)),
    ),
  );

  Widget _addBtn(String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Row(children: [
      Container(width: 28, height: 28,
        decoration: const BoxDecoration(
            color: DAColors.greenMid, shape: BoxShape.circle),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 18)),
      const SizedBox(width: 8),
      Text(label, style: GoogleFonts.poppins(
          fontSize: 13, fontWeight: FontWeight.w600, color: DAColors.greenMid)),
    ]));

  Widget _removeBtn(VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(width: 32, height: 32,
      decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
      child: Icon(Icons.close_rounded, color: Colors.red.shade400, size: 18)));

  @override
  Widget build(BuildContext context) => CropFormShell(
    formTitle:    'POULTRY PRODUCTION',
    formSubtitle: 'Poultry Production Monitoring Form',
    currentStep:  1,
    totalSteps:   7,
    onNext:       _next,
    child:        _buildForm(),
  );

  Widget _buildForm() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      Text('Poultry Information',
        style: GoogleFonts.poppins(
            fontSize: 22, fontWeight: FontWeight.w800, color: DAColors.textDark)),
      const SizedBox(height: 24),

      // ── Name of Farmer ────────────────────────────────────────
      if (_showFarmerName) ...[
        CropField(
          label:        'Name of Farmer',
          hint:         'Enter Name',
          initialValue: _farmerName,
          onChanged:    (v) => _farmerName = v,
        ),
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
                fontSize: 14, color: DAColors.textDark,
                fontWeight: FontWeight.w500)),
        ),
        const SizedBox(height: 20),
      ],

      // ── Breed ─────────────────────────────────────────────────
      CropField(
        label:        'Breed',
        hint:         'Enter',
        initialValue: _breed,
        onChanged:    (v) => _breed = v,
      ),
      const SizedBox(height: 20),

      // ── Inputs received ───────────────────────────────────────
      _label('List of inputs (with quantity) received from the program'),
      const SizedBox(height: 10),
      ..._inputsReceived.asMap().entries.map((e) {
        final i    = e.key;
        final item = e.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: _rawField(
                hint:      'Enter Variety',
                initial:   item.name,
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
              hint:      'Enter Quantity',
              initial:   item.quantity,
              kb:        TextInputType.number,
              fmt:       [FilteringTextInputFormatter.digitsOnly],
              onChanged: (v) => item.quantity = v,
            ),
          ]),
        );
      }),
      _addBtn('Add Another Input',
          () => setState(() => _inputsReceived.add(PoultryInputReceived()))),
      const SizedBox(height: 20),

      // ── Inputs purchased ──────────────────────────────────────
      _label('List of inputs purchased by the FCA\n(indicate quantity and cost)'),
      const SizedBox(height: 10),
      ..._inputsPurchased.asMap().entries.map((e) {
        final i    = e.key;
        final item = e.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: _rawField(
                hint:      'Enter Name of the Input',
                initial:   item.name,
                onChanged: (v) => item.name = v,
              )),
              if (i > 0) ...[
                const SizedBox(width: 8),
                _removeBtn(() => setState(() => _inputsPurchased.removeAt(i))),
              ],
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _subLabel('Quantity'),
                  const SizedBox(height: 6),
                  _rawField(
                    hint:      'Enter Quantity',
                    initial:   item.quantity,
                    kb:        TextInputType.number,
                    fmt:       [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (v) => item.quantity = v,
                  ),
                ],
              )),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _subLabel('Cost'),
                  const SizedBox(height: 6),
                  _rawField(
                    hint:      'Enter Cost',
                    initial:   item.cost,
                    kb:        const TextInputType.numberWithOptions(decimal: true),
                    fmt:       [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
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
        hint:      'Total Cost',
        initial:   _farmgatePrice,
        kb:        const TextInputType.numberWithOptions(decimal: true),
        fmt:       [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
        onChanged: (v) => _farmgatePrice = v,
      ),

      const SizedBox(height: 32),
    ]);
  }
}