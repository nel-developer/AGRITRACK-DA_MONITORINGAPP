import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/da_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/crop_form_shell.dart';
import 'poultry_step_wrapper.dart';

class PoultryStep4MortalityInformation extends StatefulWidget {
  const PoultryStep4MortalityInformation({super.key, required this.wrapper});
  final PoultryStepWrapper wrapper;

  @override
  State<PoultryStep4MortalityInformation> createState() => _Step4State();
}

class _Step4State extends State<PoultryStep4MortalityInformation> {
  PoultryStepWrapper get w => widget.wrapper;

  bool _hasPest = false;
  bool _hasDisease = false;
  bool _hasEnvHazard = false;
  bool _hasHuman = false;

  // Pest
  String _pestOccurrence = '';
  String _pestDate = '';
  String _pestMortality = '';

  // Disease
  String _diseaseOccurrence = '';
  String _diseaseDate = '';
  String _diseaseMortality = '';

  // Environmental
  String _envOccurrence = '';
  String _envDate = '';
  String _envMortality = '';

  // Human-induced
  String _humanOccurrence = '';
  String _humanDate = '';
  String _humanMortality = '';

  // Shared (bottom, not in checkboxes)
  String _treatment = '';
  String _attachedReport = '';
  String _totalMortalities = '';
  String _rejectsCulled = '';
  String _remainingStocks = '';

  @override
  void initState() {
    super.initState();

    // ✅ CRITICAL: For collective viewing, load first commodity's data into wrapper
    if (w.implementationType?.toLowerCase() == 'collective' &&
        w.completedCommodities.isNotEmpty) {
      final firstCommodity =
          w.completedCommodities.first as Map<String, dynamic>;
      w.hasPest = firstCommodity['hasPest'] as bool? ?? false;
      w.pestOccurrence =
          (firstCommodity['pestOccurrence'] as String? ?? '').trim();
      w.pestDate = (firstCommodity['pestDate'] as String? ?? '').trim();
      w.pestMortality =
          (firstCommodity['pestMortality'] as String? ?? '').trim();
      w.hasDisease = firstCommodity['hasDisease'] as bool? ?? false;
      w.diseaseOccurrence =
          (firstCommodity['diseaseOccurrence'] as String? ?? '').trim();
      w.diseaseDate = (firstCommodity['diseaseDate'] as String? ?? '').trim();
      w.diseaseMortality =
          (firstCommodity['diseaseMortality'] as String? ?? '').trim();
      w.hasEnvHazard = firstCommodity['hasEnvHazard'] as bool? ?? false;
      w.envOccurrence =
          (firstCommodity['envOccurrence'] as String? ?? '').trim();
      w.envDate = (firstCommodity['envDate'] as String? ?? '').trim();
      w.envMortality = (firstCommodity['envMortality'] as String? ?? '').trim();
      w.hasHumanInduced = firstCommodity['hasHumanInduced'] as bool? ?? false;
      w.humanOccurrence =
          (firstCommodity['humanOccurrence'] as String? ?? '').trim();
      w.humanDate = (firstCommodity['humanDate'] as String? ?? '').trim();
      w.humanMortality =
          (firstCommodity['humanMortality'] as String? ?? '').trim();
      w.treatment = (firstCommodity['treatment'] as String? ?? '').trim();
      w.attachedReport =
          (firstCommodity['attachedReport'] as String? ?? '').trim();
      w.totalMortalities =
          (firstCommodity['totalMortalities'] as String? ?? '').trim();
      w.rejectsCulled =
          (firstCommodity['rejectsCulled'] as String? ?? '').trim();
      w.remainingStocks =
          (firstCommodity['remainingStocks'] as String? ?? '').trim();
      print(
          '✅ COLLECTIVE POULTRY VIEWING: Loaded mortality data from first commodity');
    }

    _hasPest = w.hasPest;
    _hasDisease = w.hasDisease;
    _hasEnvHazard = w.hasEnvHazard;
    _hasHuman = w.hasHumanInduced;
    _pestOccurrence = w.pestOccurrence;
    _pestDate = w.pestDate;
    _pestMortality = w.pestMortality;
    _diseaseOccurrence = w.diseaseOccurrence;
    _diseaseDate = w.diseaseDate;
    _diseaseMortality = w.diseaseMortality;
    _envOccurrence = w.envOccurrence;
    _envDate = w.envDate;
    _envMortality = w.envMortality;
    _humanOccurrence = w.humanOccurrence;
    _humanDate = w.humanDate;
    _humanMortality = w.humanMortality;
    _treatment = w.treatment;
    _attachedReport = w.attachedReport;
    _totalMortalities = w.totalMortalities;
    _rejectsCulled = w.rejectsCulled;
    _remainingStocks = w.remainingStocks;
  }

  void _next() {
    w.hasPest = _hasPest;
    w.pestOccurrence = _pestOccurrence;
    w.pestDate = _pestDate;
    w.pestMortality = _pestMortality;
    w.hasDisease = _hasDisease;
    w.diseaseOccurrence = _diseaseOccurrence;
    w.diseaseDate = _diseaseDate;
    w.diseaseMortality = _diseaseMortality;
    w.hasEnvHazard = _hasEnvHazard;
    w.envOccurrence = _envOccurrence;
    w.envDate = _envDate;
    w.envMortality = _envMortality;
    w.hasHumanInduced = _hasHuman;
    w.humanOccurrence = _humanOccurrence;
    w.humanDate = _humanDate;
    w.humanMortality = _humanMortality;
    w.treatment = _treatment;
    w.attachedReport = _attachedReport;
    w.totalMortalities = _totalMortalities;
    w.rejectsCulled = _rejectsCulled;
    w.remainingStocks = _remainingStocks;
    Navigator.of(context).pushNamed(AppRoutes.poultryStep5, arguments: w);
  }

  Widget _checkRow(String label, bool value, ValueChanged<bool?> cb) => InkWell(
      onTap: () => cb(!value),
      child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                    color: value ? DAColors.greenMid : Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                        color:
                            value ? DAColors.greenMid : const Color(0xFFBBBBBB),
                        width: 1.5)),
                child: value
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 16)
                    : null),
            const SizedBox(width: 10),
            Expanded(
                child: Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: DAColors.textDark))),
          ])));

  Widget _lbl(String t) => Text(t,
      style: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w700, color: DAColors.textDark));

  Widget _lblItalic(String t) => Text(t,
      style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontStyle: FontStyle.italic,
          color: DAColors.textDark));

  Widget _sectionTitle(String t) => Text(t,
      style: GoogleFonts.poppins(
          fontSize: 15, fontWeight: FontWeight.w700, color: DAColors.textDark));

  Widget _field({
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

  Widget _dateField({
    required String value,
    required ValueChanged<String> onChanged,
    String hint = 'Choose Date',
  }) =>
      GestureDetector(
        onTap: () async {
          final p = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2035),
              builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                      colorScheme:
                          const ColorScheme.light(primary: DAColors.greenMid)),
                  child: child!));
          if (p != null) {
            onChanged(
                '${p.year}-${p.month.toString().padLeft(2, '0')}-${p.day.toString().padLeft(2, '0')}');
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
                child: Text(value.isEmpty ? hint : value,
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

  Widget _divider() => const Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Divider(color: Color(0xFFEEEEEE), thickness: 1.5));

  @override
  Widget build(BuildContext context) => CropFormShell(
        formTitle: 'POULTRY PRODUCTION',
        formSubtitle: 'Poultry Production Monitoring Form',
        currentStep: 3,
        totalSteps: 7,
        onNext: _next,
        child: _buildForm(),
      );

  Widget _buildForm() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Poultry Mortality Information',
          style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: DAColors.textDark)),
      const SizedBox(height: 16),
      Text('Check List',
          style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: DAColors.textDark)),
      const SizedBox(height: 8),
      _checkRow('Pest/Parasite Occurrence', _hasPest,
          (v) => setState(() => _hasPest = v ?? false)),
      _checkRow('Disease Occurrence', _hasDisease,
          (v) => setState(() => _hasDisease = v ?? false)),
      _checkRow('Environmental hazard affecting the poultry production',
          _hasEnvHazard, (v) => setState(() => _hasEnvHazard = v ?? false)),
      _checkRow('Human-induced mortality', _hasHuman,
          (v) => setState(() => _hasHuman = v ?? false)),
      const SizedBox(height: 20),

      // ── PEST ──
      if (_hasPest) ...[
        _sectionTitle('Pest/Parasite Occurrence'),
        const SizedBox(height: 12),
        _field(
            hint: 'Enter Occurrence',
            initial: _pestOccurrence,
            onChanged: (v) => _pestOccurrence = v),
        const SizedBox(height: 14),
        _lbl('Date of Occurrence'),
        const SizedBox(height: 8),
        _dateField(
            value: _pestDate, onChanged: (v) => setState(() => _pestDate = v)),
        const SizedBox(height: 14),
        _lbl('Number of poultry mortality (Pest/Parasite)'),
        const SizedBox(height: 8),
        _field(
            hint: 'Enter',
            initial: _pestMortality,
            kb: TextInputType.number,
            fmt: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) => _pestMortality = v),
        _divider(),
      ],

      // ── DISEASE ──
      if (_hasDisease) ...[
        _sectionTitle('Disease Occurrence'),
        const SizedBox(height: 12),
        _field(
            hint: 'Enter Occurrence',
            initial: _diseaseOccurrence,
            onChanged: (v) => _diseaseOccurrence = v),
        const SizedBox(height: 14),
        _lbl('Date of Occurrence'),
        const SizedBox(height: 8),
        _dateField(
            value: _diseaseDate,
            onChanged: (v) => setState(() => _diseaseDate = v)),
        const SizedBox(height: 14),
        _lbl('Number of poultry mortality (Disease)'),
        const SizedBox(height: 8),
        _field(
            hint: 'Enter',
            initial: _diseaseMortality,
            kb: TextInputType.number,
            fmt: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) => _diseaseMortality = v),
        _divider(),
      ],

      // ── ENVIRONMENTAL ──
      if (_hasEnvHazard) ...[
        _sectionTitle('Environmental hazard affecting the poultry production'),
        const SizedBox(height: 12),
        _field(
            hint: 'Enter Occurrence',
            initial: _envOccurrence,
            onChanged: (v) => _envOccurrence = v),
        const SizedBox(height: 14),
        _lbl('Date of occurrence (specific date/calendar period affected)'),
        const SizedBox(height: 8),
        _dateField(
            value: _envDate, onChanged: (v) => setState(() => _envDate = v)),
        const SizedBox(height: 14),
        _lbl('Number of poultry mortality (Environmental)'),
        const SizedBox(height: 8),
        _field(
            hint: 'Enter',
            initial: _envMortality,
            kb: TextInputType.number,
            fmt: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) => _envMortality = v),
        _divider(),
      ],

      // ── HUMAN-INDUCED ──
      if (_hasHuman) ...[
        _sectionTitle('Human-induced mortality'),
        const SizedBox(height: 12),
        _field(
            hint: 'Enter Occurrence',
            initial: _humanOccurrence,
            onChanged: (v) => _humanOccurrence = v),
        const SizedBox(height: 14),
        _lbl('Date of occurrence (specific date/calendar period affected)'),
        const SizedBox(height: 8),
        _dateField(
            value: _humanDate,
            onChanged: (v) => setState(() => _humanDate = v)),
        const SizedBox(height: 14),
        _lbl('Number of poultry mortality (Human-induced)'),
        const SizedBox(height: 8),
        _field(
            hint: 'Enter',
            initial: _humanMortality,
            kb: TextInputType.number,
            fmt: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) => _humanMortality = v),
        const SizedBox(height: 8),
      ],

      if (!_hasPest && !_hasDisease && !_hasEnvHazard && !_hasHuman)
        Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Text(
                'Select at least one mortality type from the checklist above.',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: DAColors.textMuted))),

      const SizedBox(height: 20),

      // ── TREATMENT & SUMMARY (NOT IN CHECKBOXES - ALWAYS VISIBLE) ────────────────
      _lbl('Treatment provided / Action Taken'),
      const SizedBox(height: 8),
      _field(
          hint: 'Enter', initial: _treatment, onChanged: (v) => _treatment = v),
      const SizedBox(height: 14),

      _lblItalic('(Attached mortality/monitoring/incident report)'),
      const SizedBox(height: 8),
      _field(
          hint: 'Enter',
          initial: _attachedReport,
          onChanged: (v) => _attachedReport = v),
      const SizedBox(height: 14),

      _lbl('Total number of mortalities'),
      const SizedBox(height: 8),
      _field(
          hint: 'Enter',
          initial: _totalMortalities,
          kb: TextInputType.number,
          fmt: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (v) => _totalMortalities = v),
      const SizedBox(height: 14),

      _lbl('Number of rejects/culled (indicate number of culled sold)'),
      const SizedBox(height: 8),
      _field(
          hint: 'Enter',
          initial: _rejectsCulled,
          onChanged: (v) => _rejectsCulled = v),
      const SizedBox(height: 14),

      _lbl('Number of remaining stocks (as of writing)'),
      const SizedBox(height: 8),
      _field(
          hint: 'Enter',
          initial: _remainingStocks,
          kb: TextInputType.number,
          fmt: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (v) => _remainingStocks = v),

      const SizedBox(height: 32),
    ]);
  }
}
