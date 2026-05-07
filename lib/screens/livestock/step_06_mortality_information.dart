import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/da_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/crop_form_shell.dart';
import 'livestock_step_wrapper.dart';

class LivestockStep6Mortality extends StatefulWidget {
  const LivestockStep6Mortality({super.key, required this.wrapper});
  final LivestockStepWrapper wrapper;

  @override
  State<LivestockStep6Mortality> createState() => _LivestockStep6State();
}

class _LivestockStep6State extends State<LivestockStep6Mortality> {
  LivestockStepWrapper get w => widget.wrapper;

  bool _hasPest = false;
  bool _hasDisease = false;
  bool _hasEnvHazard = false;
  bool _hasHuman = false;

  String _pestOccurrence = '',
      _pestDate = '',
      _pestMortality = '',
      _pestTreatment = '',
      _pestAttached = '';
  String _diseaseOccurrence = '',
      _diseaseDate = '',
      _diseaseMortality = '',
      _diseaseTreatment = '',
      _diseaseAttached = '';
  String _envOccurrence = '',
      _envDate = '',
      _envMortality = '',
      _envTreatment = '',
      _envAttached = '';
  String _humanOccurrence = '',
      _humanDate = '',
      _humanMortality = '',
      _humanRemainingStocks = '',
      _humanTreatment = '',
      _humanAttached = '';

  @override
  void initState() {
    super.initState();
    _hasPest = w.hasPest;
    _hasDisease = w.hasDisease;
    _hasEnvHazard = w.hasEnvHazard;
    _hasHuman = w.hasHumanInduced;
    _pestOccurrence = w.pestOccurrence;
    _pestDate = w.pestDate;
    _pestMortality = w.pestMortality;
    _pestTreatment = w.pestTreatment;
    _pestAttached = w.pestAttached;
    _diseaseOccurrence = w.diseaseOccurrence;
    _diseaseDate = w.diseaseDate;
    _diseaseMortality = w.diseaseMortality;
    _diseaseTreatment = w.diseaseTreatment;
    _diseaseAttached = w.diseaseAttached;
    _envOccurrence = w.envOccurrence;
    _envDate = w.envDate;
    _envMortality = w.envMortality;
    _envTreatment = w.envTreatment;
    _envAttached = w.envAttached;
    _humanOccurrence = w.humanOccurrence;
    _humanDate = w.humanDate;
    _humanMortality = w.humanMortality;
    _humanRemainingStocks = w.humanRemainingStocks;
    _humanTreatment = w.humanTreatment;
    _humanAttached = w.humanAttached;
  }

  void _next() {
    w.hasPest = _hasPest;
    w.pestOccurrence = _pestOccurrence;
    w.pestDate = _pestDate;
    w.pestMortality = _pestMortality;
    w.pestTreatment = _pestTreatment;
    w.pestAttached = _pestAttached;
    w.hasDisease = _hasDisease;
    w.diseaseOccurrence = _diseaseOccurrence;
    w.diseaseDate = _diseaseDate;
    w.diseaseMortality = _diseaseMortality;
    w.diseaseTreatment = _diseaseTreatment;
    w.diseaseAttached = _diseaseAttached;
    w.hasEnvHazard = _hasEnvHazard;
    w.envOccurrence = _envOccurrence;
    w.envDate = _envDate;
    w.envMortality = _envMortality;
    w.envTreatment = _envTreatment;
    w.envAttached = _envAttached;
    w.hasHumanInduced = _hasHuman;
    w.humanOccurrence = _humanOccurrence;
    w.humanDate = _humanDate;
    w.humanMortality = _humanMortality;
    w.humanRemainingStocks = _humanRemainingStocks;
    w.humanTreatment = _humanTreatment;
    w.humanAttached = _humanAttached;
    Navigator.of(context).pushNamed(AppRoutes.livestockStep7, arguments: w);
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

  Widget _field(
          {required String hint,
          required ValueChanged<String> onChanged,
          String? initial,
          TextInputType kb = TextInputType.text,
          List<TextInputFormatter>? fmt}) =>
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
                      const BorderSide(color: DAColors.greenMid, width: 2.0))));

  Widget _dateField(
          {required String value,
          required ValueChanged<String> onChanged,
          String hint = 'Choose Date'}) =>
      GestureDetector(
          onTap: () async {
            final p = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
                builder: (ctx, child) => Theme(
                    data: Theme.of(ctx).copyWith(
                        colorScheme: const ColorScheme.light(
                            primary: DAColors.greenMid)),
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
                  border:
                      Border.all(color: const Color(0xFFDDDDDD), width: 1.5)),
              child: Row(children: [
                Expanded(
                    child: Text(value.isEmpty ? hint : value,
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: value.isEmpty
                                ? DAColors.textMuted
                                : DAColors.textDark))),
                const Icon(Icons.calendar_month_rounded,
                    color: DAColors.greenMid, size: 22)
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
  Widget _divider() => const Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Divider(color: Color(0xFFEEEEEE), thickness: 1.5));

  List<Widget> _treatmentBlock(String treatment, ValueChanged<String> onT,
          String attached, ValueChanged<String> onA) =>
      [
        _lbl('Treatment provided/Action taken'),
        const SizedBox(height: 8),
        _field(hint: 'Enter', initial: treatment, onChanged: onT),
        const SizedBox(height: 14),
        _lblItalic(
            '(Attached incident/monitoring/mortality report and reporting period)'),
        const SizedBox(height: 8),
        _field(hint: 'Enter Ocurrence', initial: attached, onChanged: onA),
      ];

  @override
  Widget build(BuildContext context) => CropFormShell(
      formTitle: 'LIVESTOCK PRODUCTION',
      formSubtitle: 'Livestock Production Monitoring Form',
      currentStep: 5,
      onNext: _next,
      child: _buildForm());

  Widget _buildForm() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Livestock Mortality Information',
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
      _checkRow('Environmental hazard affecting the livestock production',
          _hasEnvHazard, (v) => setState(() => _hasEnvHazard = v ?? false)),
      _checkRow('Human-induced mortality', _hasHuman,
          (v) => setState(() => _hasHuman = v ?? false)),
      const SizedBox(height: 20),

      // ── PEST ──
      if (_hasPest) ...[
        _sectionTitle('Pest/Parasite Occurrence'),
        const SizedBox(height: 12),
        _field(
            hint: 'Enter Ocurrence',
            initial: _pestOccurrence,
            onChanged: (v) => _pestOccurrence = v),
        const SizedBox(height: 14),
        _lbl('Date of Occurrence'),
        const SizedBox(height: 8),
        _dateField(
            value: _pestDate, onChanged: (v) => setState(() => _pestDate = v)),
        const SizedBox(height: 14),
        _lbl('Number of livestock mortality (Pest/Parasite)'),
        const SizedBox(height: 8),
        _field(
            hint: 'Enter',
            initial: _pestMortality,
            kb: TextInputType.number,
            fmt: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) => _pestMortality = v),
        const SizedBox(height: 14),
        ..._treatmentBlock(_pestTreatment, (v) => _pestTreatment = v,
            _pestAttached, (v) => _pestAttached = v),
        _divider(),
      ],

      // ── DISEASE ──
      if (_hasDisease) ...[
        _sectionTitle('Disease Occurrence'),
        const SizedBox(height: 12),
        _field(
            hint: 'Enter Ocurrence',
            initial: _diseaseOccurrence,
            onChanged: (v) => _diseaseOccurrence = v),
        const SizedBox(height: 14),
        _lbl('Date of Occurrence'),
        const SizedBox(height: 8),
        _dateField(
            value: _diseaseDate,
            onChanged: (v) => setState(() => _diseaseDate = v)),
        const SizedBox(height: 14),
        _lbl('Number of livestock mortality (Disease)'),
        const SizedBox(height: 8),
        _field(
            hint: 'Enter',
            initial: _diseaseMortality,
            kb: TextInputType.number,
            fmt: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) => _diseaseMortality = v),
        const SizedBox(height: 14),
        ..._treatmentBlock(_diseaseTreatment, (v) => _diseaseTreatment = v,
            _diseaseAttached, (v) => _diseaseAttached = v),
        _divider(),
      ],

      // ── ENV HAZARD ──
      if (_hasEnvHazard) ...[
        _sectionTitle(
            'Environmental hazard affecting the livestock production'),
        const SizedBox(height: 12),
        _field(
            hint: 'Enter Ocurrence',
            initial: _envOccurrence,
            onChanged: (v) => _envOccurrence = v),
        const SizedBox(height: 14),
        _lbl('Date of occurrence (specific date/calendar period affected)'),
        const SizedBox(height: 8),
        _dateField(
            value: _envDate, onChanged: (v) => setState(() => _envDate = v)),
        const SizedBox(height: 14),
        _lbl('Number of livestock mortality (Environmental)'),
        const SizedBox(height: 8),
        _field(
            hint: 'Enter',
            initial: _envMortality,
            kb: TextInputType.number,
            fmt: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) => _envMortality = v),
        const SizedBox(height: 14),
        ..._treatmentBlock(_envTreatment, (v) => _envTreatment = v,
            _envAttached, (v) => _envAttached = v),
        _divider(),
      ],

      // ── HUMAN ──
      if (_hasHuman) ...[
        _sectionTitle('Human-induced mortality'),
        const SizedBox(height: 12),
        _field(
            hint: 'Enter Ocurrence',
            initial: _humanOccurrence,
            onChanged: (v) => _humanOccurrence = v),
        const SizedBox(height: 14),
        _lbl('Date of Occurrence'),
        const SizedBox(height: 8),
        _dateField(
            value: _humanDate,
            onChanged: (v) => setState(() => _humanDate = v)),
        const SizedBox(height: 14),
        _lbl('Number of livestock mortality (Human-induced)'),
        const SizedBox(height: 8),
        _field(
            hint: 'Enter',
            initial: _humanMortality,
            kb: TextInputType.number,
            fmt: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) => _humanMortality = v),
        const SizedBox(height: 14),
        _lbl('Number of remaining stocks (as of writing)'),
        const SizedBox(height: 8),
        _field(
            hint: 'Enter',
            initial: _humanRemainingStocks,
            kb: TextInputType.number,
            fmt: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) => _humanRemainingStocks = v),
        const SizedBox(height: 14),
        ..._treatmentBlock(_humanTreatment, (v) => _humanTreatment = v,
            _humanAttached, (v) => _humanAttached = v),
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

      const SizedBox(height: 32),
    ]);
  }
}
