import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/da_colors.dart';
import '../../routes/app_routes.dart';
import 'livestock_step_wrapper.dart';
import '../../widgets/crop_form_shell.dart';
import '../../widgets/crop_field.dart';
import '../../widgets/crop_dropdown.dart';

class LivestockStep3ProductionInformation extends StatefulWidget {
  const LivestockStep3ProductionInformation({super.key, required this.wrapper});
  final LivestockStepWrapper wrapper;

  @override
  State<LivestockStep3ProductionInformation> createState() =>
      _LivestockStep3State();
}

class _LivestockStep3State extends State<LivestockStep3ProductionInformation> {
  LivestockStepWrapper get w => widget.wrapper;

  // ── Fields ───────────────────────────────────────────────────
  String _stocksReceived = '';
  String _dateReceived = '';
  String _maleStocks = '';
  String _femaleStocks = '';
  String _maleToFemaleRatio = '';
  String _ageUponReceipt = '';
  String _avgWeightUponReceipt = '';
  String _pregnantStocks = '';
  String? _housingType;
  String? _farmOwnership;
  String _farmOwnershipOther = '';
  String? _usufruct; // Y / N
  String _usufructRemarks = '';
  bool _showUsufructRemarks = false;
  String? _healthActivities;
  String _healthOthers = '';
  String _wasteManagement = '';

  bool get _isFattener => w.purposeMeat;
  bool get _isDairy => w.purposeDairy;
  bool get _isBreeding => w.purposeBreeding;

  static const _housingOptions = [
    'Confinement',
    'Semi-confinement',
    'Free range',
    'Pasture-based',
    'Communal',
    'Others',
  ];

  static const _ownershipOptions = [
    'Owned',
    'Rented',
    'Others',
  ];

  static const _yesNo = ['Yes', 'No'];

  static const _healthOptions = [
    'Deworming',
    'Spraying for parasite control',
    'Vaccination',
    'Vitamin supplementation',
    'Hoof trimming',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _stocksReceived = w.stocksReceived;
    _dateReceived = w.dateReceived;
    _maleStocks = w.maleStocks;
    _femaleStocks = w.femaleStocks;
    _maleToFemaleRatio = w.maleToFemaleRatio;
    _ageUponReceipt = w.ageUponReceipt;
    _avgWeightUponReceipt = w.avgWeightUponReceipt;
    _pregnantStocks = w.pregnantStocks;
    _housingType = w.housingType;
    _farmOwnership = w.farmOwnership;
    _farmOwnershipOther = w.farmOwnershipOther;
    _usufruct = w.usufruct;
    _usufructRemarks = w.usufructRemarks;
    _showUsufructRemarks = _usufruct == 'Yes';
    _healthActivities = w.healthActivities;
    _healthOthers = w.healthOthers;
    _wasteManagement = w.wasteManagement;
  }

  void _next() {
    w.stocksReceived = _stocksReceived;
    w.dateReceived = _dateReceived;
    w.maleStocks = _maleStocks;
    w.femaleStocks = _femaleStocks;
    w.maleToFemaleRatio = _maleToFemaleRatio;
    w.ageUponReceipt = _ageUponReceipt;
    w.avgWeightUponReceipt = _avgWeightUponReceipt;
    w.pregnantStocks = _pregnantStocks;
    w.housingType = _housingType;
    w.farmOwnership = _farmOwnership;
    w.farmOwnershipOther = _farmOwnershipOther;
    w.usufruct = _usufruct;
    w.usufructRemarks = _usufructRemarks;
    w.healthActivities = _healthActivities;
    w.healthOthers = _healthOthers;
    w.wasteManagement = _wasteManagement;

    Navigator.of(context).pushNamed(
      AppRoutes.livestockStep4,
      arguments: w,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CropFormShell(
      formTitle: 'LIVESTOCK PRODUCTION',
      formSubtitle: 'Livestock Production Monitoring Form',
      currentStep: 2,
      onNext: _next,
      child: _buildForm(),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Production Information'),
        const SizedBox(height: 24),

        // ── Basic stock info ─────────────────────────────────
        CropField(
          label: 'No. of stocks/heads received',
          hint: 'Enter',
          initialValue: _stocksReceived,
          onChanged: (v) => _stocksReceived = v,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 16),

        // Date received — with calendar icon
        _buildLabel('Date received'),
        const SizedBox(height: 8),
        _dateField(
          hint: 'Enter',
          value: _dateReceived,
          onChanged: (v) => setState(() => _dateReceived = v),
        ),
        const SizedBox(height: 16),

        CropField(
          label: 'Male Stocks',
          hint: 'Enter',
          initialValue: _maleStocks,
          onChanged: (v) => _maleStocks = v,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 16),

        CropField(
          label: 'Female Stocks',
          hint: 'Enter',
          initialValue: _femaleStocks,
          onChanged: (v) => _femaleStocks = v,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 16),

        CropField(
          label: 'Male to Female Stocks Ratio',
          hint: 'Enter',
          initialValue: _maleToFemaleRatio,
          onChanged: (v) => _maleToFemaleRatio = v,
        ),
        const SizedBox(height: 16),

        CropField(
          label: 'Age of livestock upon receipt (months)',
          hint: 'Enter',
          initialValue: _ageUponReceipt,
          onChanged: (v) => _ageUponReceipt = v,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 16),

        CropField(
          label: 'Average weight upon receipt',
          hint: 'Enter',
          initialValue: _avgWeightUponReceipt,
          onChanged: (v) => _avgWeightUponReceipt = v,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
          ],
        ),
        const SizedBox(height: 16),

        CropField(
          label: 'Number of pregnant stocks, if any',
          hint: 'Enter',
          initialValue: _pregnantStocks,
          onChanged: (v) => _pregnantStocks = v,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 16),

        // ── Housing ──────────────────────────────────────────
        CropDropdown(
          label: 'Type of housing/confinement',
          hint: 'Enter',
          value: _housingType,
          items: _housingOptions,
          onChanged: (v) => setState(() => _housingType = v),
        ),
        const SizedBox(height: 16),

        // ── Farm ownership ───────────────────────────────────
        CropDropdown(
          label: 'Farm ownership',
          hint: 'Enter',
          value: _farmOwnership,
          items: _ownershipOptions,
          onChanged: (v) => setState(() {
            _farmOwnership = v;
            if (v != 'Others') _farmOwnershipOther = '';
          }),
        ),
        if (_farmOwnership == 'Others') ...[
          const SizedBox(height: 10),
          CropField(
            label: 'Please specify',
            hint: 'Enter',
            initialValue: _farmOwnershipOther,
            onChanged: (v) => _farmOwnershipOther = v,
          ),
        ],
        const SizedBox(height: 16),

        // ── Usufruct ─────────────────────────────────────────
        CropDropdown(
          label: 'With usufruct/Land Use Agreement (Y/N)',
          hint: 'Choose',
          value: _usufruct,
          items: _yesNo,
          onChanged: (v) => setState(() {
            _usufruct = v;
            _showUsufructRemarks = v == 'Yes';
            if (v == 'No') _usufructRemarks = '';
          }),
        ),
        if (_showUsufructRemarks) ...[
          const SizedBox(height: 8),
          _addRemarksBtn(),
        ],
        const SizedBox(height: 16),

        // ── Health activities ────────────────────────────────
        CropDropdown(
          label: 'Livestock health management activities',
          hint: 'Choose',
          value: _healthActivities,
          items: _healthOptions,
          onChanged: (v) => setState(() {
            _healthActivities = v;
            if (v != 'Others') _healthOthers = '';
          }),
        ),
        if (_healthActivities == 'Others') ...[
          const SizedBox(height: 10),
          CropField(
            label: 'Others',
            hint: 'Enter',
            initialValue: _healthOthers,
            onChanged: (v) => _healthOthers = v,
          ),
        ],
        const SizedBox(height: 16),

        // ── Waste management ─────────────────────────────────
        CropField(
          label: 'Waste management/disposal practices',
          hint: 'Enter',
          initialValue: _wasteManagement,
          onChanged: (v) => _wasteManagement = v,
        ),
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

  // ── Add Remarks button ───────────────────────────────────────
  Widget _addRemarksBtn() {
    if (_usufructRemarks.isNotEmpty) {
      return CropField(
        label: 'Remarks',
        hint: 'Enter remarks',
        initialValue: _usufructRemarks,
        onChanged: (v) => _usufructRemarks = v,
      );
    }
    return GestureDetector(
      onTap: () => setState(() => _usufructRemarks = ' '),
      child: Row(
        children: [
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
                color: DAColors.greenMid,
              )),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: GoogleFonts.poppins(
          fontSize: 22, fontWeight: FontWeight.w800, color: DAColors.textDark));

  Widget _purposeLabel(String t, Color color) => Text(t,
      style: GoogleFonts.poppins(
          fontSize: 16, fontWeight: FontWeight.w700, color: color));

  Widget _buildLabel(String t) => Text(t,
      style: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w700, color: DAColors.textDark));
}
