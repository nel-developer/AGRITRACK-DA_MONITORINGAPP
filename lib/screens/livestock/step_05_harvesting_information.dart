import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/da_colors.dart';
import '../../routes/app_routes.dart';
import 'livestock_step_wrapper.dart';
import '../../widgets/crop_form_shell.dart';
import '../../widgets/crop_field.dart';
import '../../widgets/crop_dropdown.dart';

class LivestockStep5HarvestingInformation extends StatefulWidget {
  const LivestockStep5HarvestingInformation(
      {super.key, required this.wrapper});
  final LivestockStepWrapper wrapper;

  @override
  State<LivestockStep5HarvestingInformation> createState() =>
      _LivestockStep5State();
}

class _LivestockStep5State
    extends State<LivestockStep5HarvestingInformation> {
  LivestockStepWrapper get w => widget.wrapper;

  // Fattener
  String? _soldAsLiveweight;
  String  _soldAsLiveweightRemarks = '';
  String  _avgMarketableWeight     = '';

  // Dairy
  String _milkVolumeDaily   = '';
  String _farmgatePriceMilk = '';
  String _milkUnit          = '';

  // Breeder
  String _slaughteredCount = '';
  String _slaughteredPrice = '';

  // Postharvest / Processing
  String? _postharvest;
  String  _postharvestRemarks = '';
  String? _processing;
  String  _processingRemarks  = '';

  bool get _isFattener => w.purposeMeat;
  bool get _isDairy    => w.purposeDairy;
  bool get _isBreeder  => w.purposeBreeding;

  static const _yesNo = ['Yes', 'No'];

  void _next() {
    w.soldAsLiveweight         = _soldAsLiveweight;
    w.soldAsLiveweightRemarks  = _soldAsLiveweightRemarks;
    w.avgMarketableWeight      = _avgMarketableWeight;
    w.milkVolumeDaily          = _milkVolumeDaily;
    w.farmgatePriceMilk        = _farmgatePriceMilk;
    w.milkUnit                 = _milkUnit;
    w.slaughteredCount         = _slaughteredCount;
    w.slaughteredPrice         = _slaughteredPrice;
    w.postharvest              = _postharvest;
    w.postharvestRemarks       = _postharvestRemarks;
    w.processing               = _processing;
    w.processingRemarks        = _processingRemarks;

    Navigator.of(context).pushNamed(
      AppRoutes.livestockStep6,
      arguments: w,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CropFormShell(
      formTitle:    'LIVESTOCK PRODUCTION',
      formSubtitle: 'Livestock Production Monitoring Form',
      currentStep:  4,
      onNext:       _next,
      child:        _buildForm(),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        _sectionTitle('Harvesting Information'),
        const SizedBox(height: 24),

        // ── Fattener ─────────────────────────────────────────
        if (_isFattener) ...[
          _purposeLabel('Fattener'),
          const SizedBox(height: 12),

          CropDropdown(
            label:     'Sold as liveweight (Y/N)',
            hint:      'Choose',
            value:     _soldAsLiveweight,
            items:     _yesNo,
            onChanged: (v) => setState(() {
              _soldAsLiveweight = v;
              if (v == 'No') _soldAsLiveweightRemarks = '';
            }),
          ),
          if (_soldAsLiveweight != null) ...[
            const SizedBox(height: 8),
            _remarksToggle(
              remarks:   _soldAsLiveweightRemarks,
              onChanged: (v) => setState(
                  () => _soldAsLiveweightRemarks = v),
            ),
          ],
          const SizedBox(height: 16),

          CropField(
            label:        'Average marketable weight',
            hint:         'Enter',
            initialValue: _avgMarketableWeight,
            onChanged:    (v) => _avgMarketableWeight = v,
            keyboardType: const TextInputType.numberWithOptions(
                decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
          ),
          const SizedBox(height: 24),
        ],

        // ── Dairy ─────────────────────────────────────────────
        if (_isDairy) ...[
          _purposeLabel('Dairy'),
          const SizedBox(height: 12),

          CropField(
            label:        'Average volume of milk produced daily',
            hint:         'Enter',
            initialValue: _milkVolumeDaily,
            onChanged:    (v) => _milkVolumeDaily = v,
            keyboardType: const TextInputType.numberWithOptions(
                decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
          ),
          const SizedBox(height: 16),

          CropField(
            label:        'Farmgate price of milk in the area',
            hint:         'Enter',
            initialValue: _farmgatePriceMilk,
            onChanged:    (v) => _farmgatePriceMilk = v,
            keyboardType: const TextInputType.numberWithOptions(
                decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
          ),
          const SizedBox(height: 16),

          CropField(
            label:        'Unit',
            hint:         'Enter',
            initialValue: _milkUnit,
            onChanged:    (v) => _milkUnit = v,
          ),
          const SizedBox(height: 24),
        ],

        // ── Breeder ───────────────────────────────────────────
        if (_isBreeder) ...[
          _purposeLabel('Breeder'),
          const SizedBox(height: 12),

          CropField(
            label:        'Indicate number of slaughtered livestock',
            hint:         'Enter',
            initialValue: _slaughteredCount,
            onChanged:    (v) => _slaughteredCount = v,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 16),

          CropField(
            label:        'Indicate price of slaughtered livestock',
            hint:         'Enter',
            initialValue: _slaughteredPrice,
            onChanged:    (v) => _slaughteredPrice = v,
            keyboardType: const TextInputType.numberWithOptions(
                decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
          ),
          const SizedBox(height: 24),
        ],

        // ── Postharvest ───────────────────────────────────────
        _buildLabel('Underwent postharvest (Y/N)'),
        const SizedBox(height: 8),
        _attachFileField(
          hint:    'Attach File',
          value:   _postharvest ?? '',
          onTap:   () => _pickFile((v) => setState(
              () => _postharvest = v)),
        ),
        const SizedBox(height: 8),
        _remarksToggle(
          remarks:   _postharvestRemarks,
          onChanged: (v) => setState(() => _postharvestRemarks = v),
        ),
        const SizedBox(height: 16),

        // ── Processing ────────────────────────────────────────
        _buildLabel('Underwent processing (Y/N)'),
        const SizedBox(height: 8),
        _attachFileField(
          hint:  'Attach File',
          value: _processing ?? '',
          onTap: () => _pickFile((v) => setState(
              () => _processing = v)),
        ),
        const SizedBox(height: 8),
        _remarksToggle(
          remarks:   _processingRemarks,
          onChanged: (v) => setState(() => _processingRemarks = v),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  // ── File attach field ────────────────────────────────────────
  Widget _attachFileField({
    required String hint,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFFDDDDDD), width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value.isEmpty ? hint : value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: value.isEmpty
                      ? DAColors.textMuted
                      : DAColors.textDark,
                ),
              ),
            ),
            const Icon(Icons.attach_file_rounded,
                color: DAColors.greenMid, size: 22),
          ],
        ),
      ),
    );
  }

  // Placeholder file picker — replace with real file_picker later
  void _pickFile(ValueChanged<String> onPicked) {
    // TODO: integrate file_picker package
    onPicked('file_attached.jpg');
  }

  // ── Remarks toggle ───────────────────────────────────────────
  Widget _remarksToggle({
    required String remarks,
    required ValueChanged<String> onChanged,
  }) {
    if (remarks.trim().isNotEmpty) {
      return CropField(
        label:        'Remarks',
        hint:         'Enter remarks',
        initialValue: remarks,
        onChanged:    onChanged,
      );
    }
    return GestureDetector(
      onTap: () => onChanged(' '),
      child: Row(children: [
        Container(
          width: 28, height: 28,
          decoration: const BoxDecoration(
              color: DAColors.greenMid, shape: BoxShape.circle),
          child: const Icon(Icons.add_rounded,
              color: Colors.white, size: 18),
        ),
        const SizedBox(width: 8),
        Text('Add Remarks',
          style: GoogleFonts.poppins(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: DAColors.greenMid)),
      ]),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
    style: GoogleFonts.poppins(
      fontSize: 22, fontWeight: FontWeight.w800,
      color: DAColors.textDark));

  Widget _purposeLabel(String t) => Text(t,
    style: GoogleFonts.poppins(
      fontSize: 16, fontWeight: FontWeight.w700,
      color: DAColors.greenMid));

  Widget _buildLabel(String t) => Text(t,
    style: GoogleFonts.poppins(
      fontSize: 14, fontWeight: FontWeight.w700,
      color: DAColors.textDark));
}