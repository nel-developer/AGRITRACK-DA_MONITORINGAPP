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

  // Pest
  String _pestOccurrence  = '';
  String _pestDate        = '';
  String _pestMortality   = '';

  // Disease
  String _diseaseOccurrence = '';
  String _diseaseDate       = '';
  String _diseaseMortality  = '';

  // Environmental
  String _envOccurrence   = '';
  String _envDate         = '';
  String _envMortality    = '';

  // Human-induced
  String _humanOccurrence = '';
  String _humanDate       = '';
  String _humanMortality  = '';

  // Shared
  String _treatment        = '';
  String _attachedReport   = '';
  String _totalMortalities = '';
  String _rejectsCulled    = '';
  String _remainingStocks  = '';

  void _next() {
    w.pestOccurrence    = _pestOccurrence;
    w.pestDate          = _pestDate;
    w.pestMortality     = _pestMortality;
    w.diseaseOccurrence = _diseaseOccurrence;
    w.diseaseDate       = _diseaseDate;
    w.diseaseMortality  = _diseaseMortality;
    w.envOccurrence     = _envOccurrence;
    w.envDate           = _envDate;
    w.envMortality      = _envMortality;
    w.humanDate         = _humanDate;
    w.humanMortality    = _humanMortality;
    w.treatment         = _treatment;
    w.attachedReport    = _attachedReport;
    w.totalMortalities  = _totalMortalities;
    w.rejectsCulled     = _rejectsCulled;
    w.remainingStocks   = _remainingStocks;
    Navigator.of(context).pushNamed(AppRoutes.poultryStep5, arguments: w);
  }

  Widget _lbl(String t) => Text(t,
    style: GoogleFonts.poppins(
        fontSize: 14, fontWeight: FontWeight.w700, color: DAColors.textDark));

  Widget _field({
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

  Widget _dateField(String value, ValueChanged<String> onChanged) =>
    GestureDetector(
      onTap: () async {
        final p = await showDatePicker(
          context: context, initialDate: DateTime.now(),
          firstDate: DateTime(2020), lastDate: DateTime(2035),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.light(primary: DAColors.greenMid)),
            child: child!));
        if (p != null) onChanged(
            '${p.year}-${p.month.toString().padLeft(2,'0')}-${p.day.toString().padLeft(2,'0')}');
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDDDDDD), width: 1.5)),
        child: Row(children: [
          Expanded(child: Text(value.isEmpty ? 'Choose Date' : value,
            style: GoogleFonts.poppins(fontSize: 14,
                color: value.isEmpty ? DAColors.textMuted : DAColors.textDark))),
          const Icon(Icons.calendar_month_rounded,
              color: DAColors.greenMid, size: 22),
        ]),
      ),
    );

  Widget _divider() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 16),
    child: Divider(color: Color(0xFFEEEEEE), thickness: 1.5));

  @override
  Widget build(BuildContext context) => CropFormShell(
    formTitle:    'POULTRY PRODUCTION',
    formSubtitle: 'Poultry Production Monitoring Form',
    currentStep:  3,
    totalSteps:   7,
    onNext:       _next,
    child:        _buildForm(),
  );

  Widget _buildForm() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      Text('Poultry Mortality Information',
        style: GoogleFonts.poppins(
            fontSize: 22, fontWeight: FontWeight.w800, color: DAColors.textDark)),
      const SizedBox(height: 24),

      // ── Pest ─────────────────────────────────────────────────
      _lbl('Pest Occurrence'),
      const SizedBox(height: 8),
      _field(hint: 'Enter Ocurrence', initial: _pestOccurrence,
          onChanged: (v) => _pestOccurrence = v),
      const SizedBox(height: 16),

      _lbl('Date of Pest/Parasite Occurrence'),
      const SizedBox(height: 8),
      _dateField(_pestDate, (v) => setState(() => _pestDate = v)),
      const SizedBox(height: 16),

      _lbl('Number of poultry mortality (Pest/Parasite)'),
      const SizedBox(height: 8),
      _field(hint: 'Enter', initial: _pestMortality,
        kb: TextInputType.number,
        fmt: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (v) => _pestMortality = v),

      _divider(),

      // ── Disease ───────────────────────────────────────────────
      _lbl('Disease Occurrence'),
      const SizedBox(height: 8),
      _field(hint: 'Enter', initial: _diseaseOccurrence,
          onChanged: (v) => _diseaseOccurrence = v),
      const SizedBox(height: 16),

      _lbl('Date of Disease Occurrence'),
      const SizedBox(height: 8),
      _field(hint: 'Enter Ocurrence', initial: _diseaseDate,
          onChanged: (v) => _diseaseDate = v),
      const SizedBox(height: 16),

      _lbl('Number of poultry mortality (Disease)'),
      const SizedBox(height: 8),
      _field(hint: 'Enter', initial: _diseaseMortality,
        kb: TextInputType.number,
        fmt: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (v) => _diseaseMortality = v),

      _divider(),

      // ── Environmental ─────────────────────────────────────────
      _lbl('Environmental hazard affecting the poultry production'),
      const SizedBox(height: 8),
      _field(hint: 'Enter', initial: _envOccurrence,
          onChanged: (v) => _envOccurrence = v),
      const SizedBox(height: 16),

      _lbl('Date of occurrence (specific date/calendar period affected)'),
      const SizedBox(height: 8),
      _dateField(_envDate, (v) => setState(() => _envDate = v)),
      const SizedBox(height: 16),

      _lbl('Number of poultry mortality (Environmental)'),
      const SizedBox(height: 8),
      _field(hint: 'Enter', initial: _envMortality,
        kb: TextInputType.number,
        fmt: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (v) => _envMortality = v),

      _divider(),

      // ── Human-induced ─────────────────────────────────────────
      _lbl('Human-induced mortality'),
      const SizedBox(height: 8),
      _field(hint: 'Enter', initial: _humanOccurrence,
          onChanged: (v) => _humanOccurrence = v),
      const SizedBox(height: 16),

      _lbl('Date of occurrence (specific date/calendar period affected) (Human-induced)'),
      const SizedBox(height: 8),
      _dateField(_humanDate, (v) => setState(() => _humanDate = v)),
      const SizedBox(height: 16),

      _lbl('Number of poultry mortality (Human-induced)'),
      const SizedBox(height: 8),
      _field(hint: 'Enter', initial: _humanMortality,
        kb: TextInputType.number,
        fmt: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (v) => _humanMortality = v),

      _divider(),

      // ── Shared bottom fields ──────────────────────────────────
      _lbl('Treatment provided/ Action Taken'),
      const SizedBox(height: 8),
      _field(hint: 'Enter', initial: _treatment,
          onChanged: (v) => _treatment = v),
      const SizedBox(height: 16),

      _lbl('(Attached mortality/monitoring/incident report)'),
      const SizedBox(height: 8),
      _field(hint: 'Enter', initial: _attachedReport,
          onChanged: (v) => _attachedReport = v),
      const SizedBox(height: 16),

      _lbl('Total number of mortalities'),
      const SizedBox(height: 8),
      _field(hint: 'Enter', initial: _totalMortalities,
        kb: TextInputType.number,
        fmt: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (v) => _totalMortalities = v),
      const SizedBox(height: 16),

      _lbl('Number of rejects/culled (indicate number of culled sold)'),
      const SizedBox(height: 8),
      _field(hint: 'Enter', initial: _rejectsCulled,
          onChanged: (v) => _rejectsCulled = v),
      const SizedBox(height: 16),

      _lbl('Number of remaining stocks (as of writing)'),
      const SizedBox(height: 8),
      _field(hint: 'Enter', initial: _remainingStocks,
        kb: TextInputType.number,
        fmt: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (v) => _remainingStocks = v),

      const SizedBox(height: 32),
    ]);
  }
}