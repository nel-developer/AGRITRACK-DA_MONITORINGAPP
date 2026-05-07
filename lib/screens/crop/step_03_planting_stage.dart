import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/da_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/crop_form_shell.dart';
import '../../widgets/crop_field.dart';
import '../../widgets/crop_dropdown.dart';
import 'crop_step_wrapper.dart';

class CropStep3PlantingStage extends StatefulWidget {
  const CropStep3PlantingStage({super.key, required this.wrapper});
  final CropStepWrapper wrapper;

  @override
  State<CropStep3PlantingStage> createState() => _CropStep3State();
}

class _CropStep3State extends State<CropStep3PlantingStage> {
  CropStepWrapper get w => widget.wrapper;

  String _totalLandArea = '';
  String? _landOwnership;
  String _landOwnershipOther = '';
  String? _usufructAgreement;
  final List<String> _landRemarks = [];

  String? _machineryType;
  String _machineryOther = '';
  final List<String> _machineryRemarks = [];

  final List<String> _landPrepCosts = [''];

  String _landPrepStartDate = '';
  String _landPrepDays = '';
  String _sourceOfWater = '';
  String _plantingDate = '';
  String _seedAmount = '';
  String _seedUnit = '';
  String _germinationRate = '';
  String? _goodGermination;
  String _germinationReason = '';

  static const _ownershipOptions = ['Owned', 'Rented', 'Shared', 'Others'];
  static const _ynOptions = ['Yes', 'No'];
  static const _machineryOptions = [
    'Animal-drawn',
    'Hand tractor',
    'Four-wheel tractor',
    'Power tiller',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _totalLandArea = w.totalLandArea;
    _landOwnership = w.landOwnership;
    _landOwnershipOther = w.landOwnershipOther;
    _usufructAgreement = w.usufructAgreement;
    _machineryType = w.machineryType;
    _machineryOther = w.machineryOther;
    _landPrepStartDate = w.landPrepStartDate;
    _landPrepDays = w.landPrepDays;
    _sourceOfWater = w.sourceOfWater;
    _plantingDate = w.plantingDate;
    _seedAmount = w.seedAmount;
    _seedUnit = w.seedUnit;
    _germinationRate = w.germinationRate;
    _goodGermination = w.goodGermination;
    _germinationReason = w.germinationReason;
    _landRemarks
      ..clear()
      ..addAll(w.landRemarks);
    _machineryRemarks
      ..clear()
      ..addAll(w.machineryRemarks);
    _landPrepCosts
      ..clear()
      ..addAll(w.landPrepCostPerCycle.isEmpty
          ? ['']
          : List<String>.from(w.landPrepCostPerCycle));
  }

  void _next() {
    w.totalLandArea = _totalLandArea;
    w.landOwnership = _landOwnership;
    w.landOwnershipOther = _landOwnershipOther;
    w.usufructAgreement = _usufructAgreement;
    w.landRemarks = List.from(_landRemarks);
    w.machineryType = _machineryType;
    w.machineryOther = _machineryOther;
    w.machineryRemarks = List.from(_machineryRemarks);
    w.landPrepCostPerCycle = List.from(_landPrepCosts);
    w.landPrepStartDate = _landPrepStartDate;
    w.landPrepDays = _landPrepDays;
    w.sourceOfWater = _sourceOfWater;
    w.plantingDate = _plantingDate;
    w.seedAmount = _seedAmount;
    w.seedUnit = _seedUnit;
    w.germinationRate = _germinationRate;
    w.goodGermination = _goodGermination;
    w.germinationReason = _germinationReason;
    Navigator.of(context).pushNamed(AppRoutes.cropStep4, arguments: w);
  }

  Widget _label(String t) => Text(t,
      style: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w700, color: DAColors.textDark));

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
        ]),
      );

  Widget _removeBtn(VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: Colors.red.shade50, shape: BoxShape.circle),
            child: Icon(Icons.close_rounded,
                color: Colors.red.shade400, size: 18)),
      );

  Widget _bareField({
    required String hint,
    required ValueChanged<String> onChanged,
    String? initial,
    TextInputType kb = TextInputType.text,
  }) =>
      TextFormField(
        initialValue: initial,
        onChanged: onChanged,
        keyboardType: kb,
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

  Widget _dateField({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label(label),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2035),
              builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                      colorScheme:
                          const ColorScheme.light(primary: DAColors.greenMid)),
                  child: child!),
            );
            if (picked != null) {
              onChanged(
                  '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFDDDDDD), width: 1.5)),
            child: Row(children: [
              Expanded(
                  child: Text(value.isEmpty ? 'Choose Date' : value,
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: value.isEmpty
                              ? DAColors.textMuted
                              : DAColors.textDark))),
              const Icon(Icons.calendar_month_rounded,
                  color: DAColors.greenMid, size: 22),
            ]),
          ),
        ),
      ]);

  Widget _remarksList(List<String> list, String addLabel) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ...list.asMap().entries.map((e) {
          final i = e.key;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Expanded(
                  child: _bareField(
                      hint: 'Enter Remark',
                      initial: list[i],
                      onChanged: (v) => setState(() => list[i] = v))),
              const SizedBox(width: 8),
              _removeBtn(() => setState(() => list.removeAt(i))),
            ]),
          );
        }),
        _addBtn(addLabel, () => setState(() => list.add(''))),
      ]);

  @override
  Widget build(BuildContext context) {
    return CropFormShell(currentStep: 2, onNext: _next, child: _buildForm());
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Planting to growing stage',
            style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: DAColors.textDark)),
        const SizedBox(height: 24),
        CropField(
            label: 'Total land area planted',
            hint: 'Enter Total land area planted',
            initialValue: _totalLandArea,
            keyboardType: TextInputType.number,
            onChanged: (v) => _totalLandArea = v),
        const SizedBox(height: 20),
        CropDropdown(
          label: 'Land ownership',
          hint: 'Choose',
          value: _landOwnership,
          items: _ownershipOptions,
          onChanged: (v) => setState(() {
            _landOwnership = v;
            if (v != 'Others') _landOwnershipOther = '';
            if (v == 'Owned') _usufructAgreement = null;
          }),
        ),
        const SizedBox(height: 12),
        CropField(
            label: 'Others, specify',
            hint: 'Enter',
            initialValue: _landOwnershipOther,
            enabled: _landOwnership == 'Others',
            onChanged: (v) => _landOwnershipOther = v),
        const SizedBox(height: 12),
        CropDropdown(
          label: 'If not owned, with usufruct/land used agreement (Y/N)',
          hint: 'Choose',
          value: _usufructAgreement,
          items: _ynOptions,
          enabled: _landOwnership != null && _landOwnership != 'Owned',
          onChanged: (v) => setState(() => _usufructAgreement = v),
        ),
        const SizedBox(height: 12),
        _remarksList(_landRemarks, 'Add Remarks'),
        const SizedBox(height: 20),
        CropDropdown(
          label: 'Types of animals or machinery used for land preparation',
          hint: 'Choose',
          value: _machineryType,
          items: _machineryOptions,
          onChanged: (v) => setState(() {
            _machineryType = v;
            if (v != 'Others') _machineryOther = '';
          }),
        ),
        const SizedBox(height: 12),
        CropField(
            label: 'Others, specify',
            hint: 'Enter',
            initialValue: _machineryOther,
            enabled: _machineryType == 'Others',
            onChanged: (v) => _machineryOther = v),
        const SizedBox(height: 12),
        _remarksList(_machineryRemarks, 'Add Remarks'),
        const SizedBox(height: 20),
        _label('Total cost of land preparation activities per cropping cycle'),
        const SizedBox(height: 10),
        ..._landPrepCosts.asMap().entries.map((e) {
          final i = e.key;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Expanded(
                  child: _bareField(
                      hint: 'Enter Cost',
                      initial: _landPrepCosts[i],
                      onChanged: (v) => _landPrepCosts[i] = v,
                      kb: TextInputType.number)),
              if (i > 0) ...[
                const SizedBox(width: 8),
                _removeBtn(() => setState(() => _landPrepCosts.removeAt(i))),
              ],
            ]),
          );
        }),
        _addBtn('Add Cycle', () => setState(() => _landPrepCosts.add(''))),
        const SizedBox(height: 20),
        _dateField(
            label: 'Start date of Land Preparation',
            value: _landPrepStartDate,
            onChanged: (v) => setState(() => _landPrepStartDate = v)),
        const SizedBox(height: 20),
        CropField(
            label: 'Total number of days for land preparation',
            hint: 'Enter no. of days',
            initialValue: _landPrepDays,
            keyboardType: TextInputType.number,
            onChanged: (v) => _landPrepDays = v),
        const SizedBox(height: 20),
        CropField(
            label: 'Source of water',
            hint: 'Enter the Source of Water',
            initialValue: _sourceOfWater,
            onChanged: (v) => _sourceOfWater = v),
        const SizedBox(height: 20),
        _dateField(
            label: 'Date of planting/transplanting',
            value: _plantingDate,
            onChanged: (v) => setState(() => _plantingDate = v)),
        const SizedBox(height: 20),
        _label('Amount of seeds/seedlings/planting materials planted'),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
              child: _bareField(
                  hint: 'Enter Amount',
                  initial: _seedAmount,
                  onChanged: (v) => _seedAmount = v,
                  kb: TextInputType.number)),
          const SizedBox(width: 10),
          Expanded(
              child: _bareField(
                  hint: 'Enter Unit',
                  initial: _seedUnit,
                  onChanged: (v) => _seedUnit = v)),
        ]),
        const SizedBox(height: 20),
        CropField(
            label: 'Germination rate (based on specifications)',
            hint: 'Enter Rate',
            initialValue: _germinationRate,
            keyboardType: TextInputType.number,
            onChanged: (v) => _germinationRate = v),
        const SizedBox(height: 20),
        CropDropdown(
          label: 'Good germination based on the FCA (Y/N)',
          hint: 'Choose Y/N',
          value: _goodGermination,
          items: _ynOptions,
          onChanged: (v) => setState(() {
            _goodGermination = v;
            if (v == 'Yes') _germinationReason = '';
          }),
        ),
        const SizedBox(height: 12),
        CropField(
            label: 'If no, indicate the probable reason',
            hint: 'Enter the reason',
            initialValue: _germinationReason,
            enabled: _goodGermination == 'No',
            onChanged: (v) => _germinationReason = v),
        const SizedBox(height: 32),
      ],
    );
  }
}
