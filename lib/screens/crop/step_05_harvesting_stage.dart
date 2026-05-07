import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/da_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/crop_form_shell.dart';
import '../../widgets/crop_field.dart';
import 'crop_step_wrapper.dart';

class CropStep5HarvestingStage extends StatefulWidget {
  const CropStep5HarvestingStage({super.key, required this.wrapper});
  final CropStepWrapper wrapper;

  @override
  State<CropStep5HarvestingStage> createState() => _CropStep5State();
}

class _CropStep5State extends State<CropStep5HarvestingStage> {
  CropStepWrapper get w => widget.wrapper;

  // Dynamic lists (per cropping cycle)
  final List<String> _landAreaCycles = [''];
  final List<String> _dateHarvestCycles = [''];
  final List<String> _quantityCycles = [''];
  final List<String> _harvestCostCycles = [''];

  // Single-value fields
  String _avgHarvestPerHa = '';
  String _foodConsumptionPct = '';

  @override
  void initState() {
    super.initState();
    _avgHarvestPerHa = w.avgHarvestPerHa;
    _foodConsumptionPct = w.foodConsumptionPct;
    _landAreaCycles
      ..clear()
      ..addAll(w.landAreaCycles.isEmpty
          ? ['']
          : List<String>.from(w.landAreaCycles));
    _dateHarvestCycles
      ..clear()
      ..addAll(w.dateHarvestCycles.isEmpty
          ? ['']
          : List<String>.from(w.dateHarvestCycles));
    _quantityCycles
      ..clear()
      ..addAll(w.quantityCycles.isEmpty
          ? ['']
          : List<String>.from(w.quantityCycles));
    _harvestCostCycles
      ..clear()
      ..addAll(w.harvestCostCycles.isEmpty
          ? ['']
          : List<String>.from(w.harvestCostCycles));
  }

  void _next() {
    w.landAreaCycles = List.from(_landAreaCycles);
    w.dateHarvestCycles = List.from(_dateHarvestCycles);
    w.quantityCycles = List.from(_quantityCycles);
    w.avgHarvestPerHa = _avgHarvestPerHa;
    w.harvestCostCycles = List.from(_harvestCostCycles);
    w.foodConsumptionPct = _foodConsumptionPct;
    Navigator.of(context).pushNamed(AppRoutes.cropStep6, arguments: w);
  }

  // ── Helpers ───────────────────────────────────────────────────
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

  Widget _dateCycleField({
    required String value,
    required ValueChanged<String> onChanged,
  }) =>
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDDDDDD), width: 1.5)),
          child: Row(children: [
            Expanded(
                child: Text(value.isEmpty ? 'Enter Date Harvested' : value,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: value.isEmpty
                            ? DAColors.textMuted
                            : DAColors.textDark))),
            const Icon(Icons.calendar_month_rounded,
                color: DAColors.greenMid, size: 22),
          ]),
        ),
      );

  Widget _attachField({
    required String value,
    required ValueChanged<String> onChanged,
  }) =>
      GestureDetector(
        onTap: () async {
          // Simulate file pick — in real app use file_picker package
          onChanged('document_attached.pdf');
          setState(() {});
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDDDDDD), width: 1.5)),
          child: Row(children: [
            Expanded(
                child: Text(value.isEmpty ? 'Attach File' : value,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: value.isEmpty
                            ? DAColors.textMuted
                            : DAColors.greenMid))),
            const Icon(Icons.attach_file_rounded,
                color: DAColors.greenMid, size: 22),
          ]),
        ),
      );

  Widget _cycleList({
    required String sectionLabel,
    required List<String> list,
    required String addLabel,
    required String fieldHint,
    TextInputType kb = TextInputType.text,
  }) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label(sectionLabel),
        const SizedBox(height: 10),
        ...list.asMap().entries.map((e) {
          final i = e.key;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Expanded(
                  child: _bareField(
                      hint: fieldHint,
                      initial: list[i],
                      onChanged: (v) => list[i] = v,
                      kb: kb)),
              if (i > 0) ...[
                const SizedBox(width: 8),
                _removeBtn(() => setState(() => list.removeAt(i))),
              ],
            ]),
          );
        }),
        _addBtn(addLabel, () => setState(() => list.add(''))),
      ]);

  Widget _dateCycleList({
    required String sectionLabel,
    required List<String> list,
  }) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label(sectionLabel),
        const SizedBox(height: 10),
        ...list.asMap().entries.map((e) {
          final i = e.key;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Expanded(
                  child: _dateCycleField(
                      value: list[i],
                      onChanged: (v) => setState(() => list[i] = v))),
              if (i > 0) ...[
                const SizedBox(width: 8),
                _removeBtn(() => setState(() => list.removeAt(i))),
              ],
            ]),
          );
        }),
        _addBtn('Add Cycle', () => setState(() => list.add(''))),
      ]);

  Widget _remarksList(List<String> list) =>
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
        _addBtn('Add Remarks', () => setState(() => list.add(''))),
      ]);

  @override
  Widget build(BuildContext context) {
    return CropFormShell(currentStep: 4, onNext: _next, child: _buildForm());
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Harvesting stage',
            style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: DAColors.textDark)),
        const SizedBox(height: 24),
        _cycleList(
            sectionLabel: 'Total land area harvested (per cropping cycle)',
            list: _landAreaCycles,
            addLabel: 'Add Cycle',
            fieldHint: 'Enter land area harvested',
            kb: TextInputType.number),
        const SizedBox(height: 20),
        _dateCycleList(
            sectionLabel: 'Date Harvested (per cropping cycle)',
            list: _dateHarvestCycles),
        const SizedBox(height: 20),
        _cycleList(
            sectionLabel: 'Total harvest quantity (in kg or tons)',
            list: _quantityCycles,
            addLabel: 'Add Cycle',
            fieldHint: 'Total harvested in kg',
            kb: TextInputType.number),
        const SizedBox(height: 20),
        CropField(
            label: 'Average harvest per hectare',
            hint: 'Enter Average Hectare',
            initialValue: _avgHarvestPerHa,
            keyboardType: TextInputType.number,
            onChanged: (v) => _avgHarvestPerHa = v),
        const SizedBox(height: 20),
        _cycleList(
            sectionLabel:
                'Total cost of harvesting activities per cropping cycle (based on FCA records)',
            list: _harvestCostCycles,
            addLabel: 'Add Cycle',
            fieldHint: 'Enter the total cost',
            kb: TextInputType.number),
        const SizedBox(height: 20),
        CropField(
            label: 'Percentage of harvest goes for food consumption',
            hint: 'Enter percentage',
            initialValue: _foodConsumptionPct,
            keyboardType: TextInputType.number,
            onChanged: (v) => _foodConsumptionPct = v),
        const SizedBox(height: 20),
        const SizedBox(height: 32),
      ],
    );
  }
}
