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
  const LivestockStep5HarvestingInformation({super.key, required this.wrapper});
  final LivestockStepWrapper wrapper;

  @override
  State<LivestockStep5HarvestingInformation> createState() =>
      _LivestockStep5State();
}

class _LivestockStep5State extends State<LivestockStep5HarvestingInformation> {
  LivestockStepWrapper get w => widget.wrapper;

  // ── Production information (from Step 3) ──────────────────
  // Fattener
  String _growOutPeriod = '';
  // Dairy
  String _lactationPeriod = '';
  String _dryPeriod = '';
  // Breeding
  String _producedOffspring = '';
  String _offspringMale = '';
  String _offspringFemale = '';
  String _offspringMFRatio = '';
  String _mortalitiesAfterBirth = '';
  String _remainingOffspring = '';

  // ── Harvesting information ────────────────────────────────
  // Fattener
  String? _soldAsLiveweight;
  String _soldAsLiveweightRemarks = '';
  String _avgMarketableWeight = '';

  // Dairy
  String _milkVolumeDaily = '';
  String _farmgatePriceMilk = '';
  String _milkUnit = '';

  // Breeder
  String _slaughteredCount = '';
  String _slaughteredPrice = '';

  bool get _isFattener => w.purposeMeat;
  bool get _isDairy => w.purposeDairy;
  bool get _isBreeder => w.purposeBreeding;

  static const _yesNo = ['Yes', 'No'];

  @override
  void initState() {
    super.initState();
    // Production info
    _growOutPeriod = w.growOutPeriod;
    _lactationPeriod = w.lactationPeriod;
    _dryPeriod = w.dryPeriod;
    _producedOffspring = w.producedOffspring;
    _offspringMale = w.offspringMale;
    _offspringFemale = w.offspringFemale;
    _offspringMFRatio = w.offspringMFRatio;
    _mortalitiesAfterBirth = w.mortalitiesAfterBirth;
    _remainingOffspring = w.remainingOffspring;
    // Harvesting info
    _soldAsLiveweight = w.soldAsLiveweight;
    _soldAsLiveweightRemarks = w.soldAsLiveweightRemarks;
    _avgMarketableWeight = w.avgMarketableWeight;
    _milkVolumeDaily = w.milkVolumeDaily;
    _farmgatePriceMilk = w.farmgatePriceMilk;
    _milkUnit = w.milkUnit;
    _slaughteredCount = w.slaughteredCount;
    _slaughteredPrice = w.slaughteredPrice;
  }

  void _next() {
    // Production info
    w.growOutPeriod = _growOutPeriod;
    w.lactationPeriod = _lactationPeriod;
    w.dryPeriod = _dryPeriod;
    w.producedOffspring = _producedOffspring;
    w.offspringMale = _offspringMale;
    w.offspringFemale = _offspringFemale;
    w.offspringMFRatio = _offspringMFRatio;
    w.mortalitiesAfterBirth = _mortalitiesAfterBirth;
    w.remainingOffspring = _remainingOffspring;
    // Harvesting info
    w.soldAsLiveweight = _soldAsLiveweight;
    w.soldAsLiveweightRemarks = _soldAsLiveweightRemarks;
    w.avgMarketableWeight = _avgMarketableWeight;
    w.milkVolumeDaily = _milkVolumeDaily;
    w.farmgatePriceMilk = _farmgatePriceMilk;
    w.milkUnit = _milkUnit;
    w.slaughteredCount = _slaughteredCount;
    w.slaughteredPrice = _slaughteredPrice;

    Navigator.of(context).pushNamed(
      AppRoutes.livestockStep6,
      arguments: w,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CropFormShell(
      formTitle: 'LIVESTOCK PRODUCTION',
      formSubtitle: 'Livestock Production Monitoring Form',
      currentStep: 4,
      onNext: _next,
      child: _buildForm(),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Production & Harvesting Information'),
        const SizedBox(height: 24),

        // ── Purpose of Production ─────────────────────────────
        _buildLabel('Purpose of Production'),
        const SizedBox(height: 12),
        _buildCheckbox(
            label: 'Breeding',
            value: w.purposeBreeding,
            onChanged: (v) => setState(() => w.purposeBreeding = v ?? false)),
        const SizedBox(height: 10),
        _buildCheckbox(
            label: 'Meat / Fattener',
            value: w.purposeMeat,
            onChanged: (v) => setState(() => w.purposeMeat = v ?? false)),
        const SizedBox(height: 10),
        _buildCheckbox(
            label: 'Dairy',
            value: w.purposeDairy,
            onChanged: (v) => setState(() => w.purposeDairy = v ?? false)),
        const SizedBox(height: 32),

        // ── Fattener ─────────────────────────────────────────
        if (_isFattener) ...[
          _purposeLabel('Fattener'),
          const SizedBox(height: 12),
          _buildLabel('Identify actual grow-out period'),
          const SizedBox(height: 8),
          _dateField(
            hint: 'Enter Month',
            value: _growOutPeriod,
            onChanged: (v) => setState(() => _growOutPeriod = v),
          ),
          const SizedBox(height: 24),
          _buildLabel('Sold as liveweight (Y/N)'),
          const SizedBox(height: 8),
          CropDropdown(
            label: 'Sold as liveweight (Y/N)',
            hint: 'Choose',
            value: _soldAsLiveweight,
            items: _yesNo,
            onChanged: (v) => setState(() {
              _soldAsLiveweight = v;
              if (v == 'No') _soldAsLiveweightRemarks = '';
            }),
          ),
          if (_soldAsLiveweight != null) ...[
            const SizedBox(height: 8),
            _remarksToggle(
              remarks: _soldAsLiveweightRemarks,
              onChanged: (v) => setState(() => _soldAsLiveweightRemarks = v),
            ),
          ],
          const SizedBox(height: 16),
          CropField(
            label: 'Average marketable weight',
            hint: 'Enter',
            initialValue: _avgMarketableWeight,
            onChanged: (v) => _avgMarketableWeight = v,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
          _buildLabel('Identify lactation period'),
          const SizedBox(height: 8),
          _dateField(
            hint: 'Enter Month',
            value: _lactationPeriod,
            onChanged: (v) => setState(() => _lactationPeriod = v),
          ),
          const SizedBox(height: 16),
          _buildLabel('Identify dry period'),
          const SizedBox(height: 8),
          _dateField(
            hint: 'Enter Month',
            value: _dryPeriod,
            onChanged: (v) => setState(() => _dryPeriod = v),
          ),
          const SizedBox(height: 24),
          CropField(
            label: 'Average volume of milk produced daily',
            hint: 'Enter',
            initialValue: _milkVolumeDaily,
            onChanged: (v) => _milkVolumeDaily = v,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
          ),
          const SizedBox(height: 16),
          CropField(
            label: 'Farmgate price of milk in the area',
            hint: 'Enter',
            initialValue: _farmgatePriceMilk,
            onChanged: (v) => _farmgatePriceMilk = v,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
          ),
          const SizedBox(height: 16),
          CropField(
            label: 'Unit',
            hint: 'Enter',
            initialValue: _milkUnit,
            onChanged: (v) => _milkUnit = v,
          ),
          const SizedBox(height: 24),
        ],

        // ── Breeder ───────────────────────────────────────────
        if (_isBreeder) ...[
          _purposeLabel('Breeder'),
          const SizedBox(height: 12),
          _buildLabel('Number of produced offspring'),
          const SizedBox(height: 8),
          _dateField(
            hint: 'Enter',
            value: _producedOffspring,
            onChanged: (v) => setState(() => _producedOffspring = v),
          ),
          const SizedBox(height: 16),
          CropField(
            label: 'Male Stocks',
            hint: 'Enter',
            initialValue: _offspringMale,
            onChanged: (v) => _offspringMale = v,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 16),
          CropField(
            label: 'Female Stocks',
            hint: 'Enter',
            initialValue: _offspringFemale,
            onChanged: (v) => _offspringFemale = v,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 16),
          CropField(
            label: 'Male to Female Stocks Ratio',
            hint: 'Enter',
            initialValue: _offspringMFRatio,
            onChanged: (v) => _offspringMFRatio = v,
          ),
          const SizedBox(height: 16),
          CropField(
            label: 'Number of mortalities after birth',
            hint: 'Enter',
            initialValue: _mortalitiesAfterBirth,
            onChanged: (v) => _mortalitiesAfterBirth = v,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 16),
          _buildLabel('Indicate number of remaining offspring'),
          const SizedBox(height: 8),
          _dateField(
            hint: 'Enter',
            value: _remainingOffspring,
            onChanged: (v) => setState(() => _remainingOffspring = v),
          ),
          const SizedBox(height: 24),
          _buildLabel('Indicate number of slaughtered livestock'),
          const SizedBox(height: 8),
          CropField(
            label: 'Number of slaughtered livestock',
            hint: 'Enter',
            initialValue: _slaughteredCount,
            onChanged: (v) => _slaughteredCount = v,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 16),
          _buildLabel('Indicate price of slaughtered livestock'),
          const SizedBox(height: 8),
          CropField(
            label: 'Price of slaughtered livestock',
            hint: 'Enter',
            initialValue: _slaughteredPrice,
            onChanged: (v) => _slaughteredPrice = v,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
          ),
          const SizedBox(height: 24),
        ],

        const SizedBox(height: 32),
      ],
    );
  }

  // ── Date picker field ────────────────────────────────────────
  Widget _dateField({
    required String hint,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: now,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.light(
                primary: DAColors.greenMid,
                onPrimary: Colors.white,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) {
          final formatted =
              '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
          onChanged(formatted);
        }
      },
      child: AbsorbPointer(
        child: TextFormField(
          key: ValueKey(value),
          initialValue: value.isEmpty ? null : value,
          style: GoogleFonts.poppins(fontSize: 14, color: DAColors.textDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                GoogleFonts.poppins(fontSize: 14, color: DAColors.textMuted),
            suffixIcon: const Icon(Icons.calendar_month_rounded,
                color: DAColors.greenMid, size: 22),
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
        ),
      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDDDDDD), width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value.isEmpty ? hint : value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: value.isEmpty ? DAColors.textMuted : DAColors.textDark,
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
        label: 'Remarks',
        hint: 'Enter remarks',
        initialValue: remarks,
        onChanged: onChanged,
      );
    }
    return GestureDetector(
      onTap: () => onChanged(' '),
      child: Row(children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
              color: DAColors.greenMid, shape: BoxShape.circle),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 8),
        Text('Add Remarks',
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: DAColors.greenMid)),
      ]),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: GoogleFonts.poppins(
          fontSize: 22, fontWeight: FontWeight.w800, color: DAColors.textDark));

  Widget _purposeLabel(String t) => Text(t,
      style: GoogleFonts.poppins(
          fontSize: 16, fontWeight: FontWeight.w700, color: DAColors.greenMid));

  Widget _buildLabel(String t) => Text(t,
      style: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w700, color: DAColors.textDark));

  // ── Checkbox for purpose ──────────────────────────────────────
  Widget _buildCheckbox(
          {required String label,
          required bool value,
          required ValueChanged<bool?> onChanged}) =>
      GestureDetector(
        onTap: () => onChanged(!value),
        child: Row(children: [
          AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                  color: value ? DAColors.greenMid : Colors.white,
                  border: Border.all(
                      color: value ? DAColors.greenMid : Colors.grey.shade400,
                      width: 1.8),
                  borderRadius: BorderRadius.circular(5)),
              child: value
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14)
                  : null),
          const SizedBox(width: 12),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: DAColors.textDark)),
        ]),
      );
}
