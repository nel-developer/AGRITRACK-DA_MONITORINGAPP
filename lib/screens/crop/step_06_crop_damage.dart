import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/da_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/crop_form_shell.dart';
import '../../widgets/crop_field.dart';
import 'crop_step_wrapper.dart';

class CropStep6CropDamage extends StatefulWidget {
  const CropStep6CropDamage({super.key, required this.wrapper});
  final CropStepWrapper wrapper;

  @override
  State<CropStep6CropDamage> createState() => _CropStep6State();
}

class _CropStep6State extends State<CropStep6CropDamage> {
  CropStepWrapper get w => widget.wrapper;

  // Checklist toggles
  bool _hasPest        = false;
  bool _hasDisease     = false;
  bool _hasEnvHazard   = false;
  bool _hasHumanDamage = false;

  // Pest
  String _pestOccurrence    = '';
  String _pestDate          = '';
  String _pestDamageArea    = '';
  String _pestDamageHa      = '';
  String _pestTreatment     = '';
  String _pestAttached      = '';

  // Disease
  String _diseaseOccurrence = '';
  String _diseaseDate       = '';
  String _diseaseDamageArea = '';
  String _diseaseDamageHa   = '';
  String _diseaseTreatment  = '';
  String _diseaseAttached   = '';

  // Environmental hazard
  final List<String> _envHazards = [''];
  String _envDate               = '';
  String _envDamageArea         = '';
  String _envDamageHa           = '';
  String _envTreatment          = '';
  String _envAttached           = '';

  // Human-induced
  String _humanDamage     = '';
  String _humanMortality  = '';
  String _humanTreatment  = '';
  String _humanAttached   = '';

  void _next() {
    w.hasPest          = _hasPest;
    w.pestOccurrence   = _pestOccurrence;
    w.pestDate         = _pestDate;
    w.pestDamageArea   = _pestDamageArea;
    w.pestDamageHa     = _pestDamageHa;
    w.pestTreatment    = _pestTreatment;
    w.pestAttached     = _pestAttached;

    w.hasDisease         = _hasDisease;
    w.diseaseOccurrence  = _diseaseOccurrence;
    w.diseaseDate        = _diseaseDate;
    w.diseaseDamageArea  = _diseaseDamageArea;
    w.diseaseDamageHa    = _diseaseDamageHa;
    w.diseaseTreatment   = _diseaseTreatment;
    w.diseaseAttached    = _diseaseAttached;

    w.hasEnvHazard = _hasEnvHazard;
    w.envHazards   = List.from(_envHazards);
    w.envDate      = _envDate;
    w.envDamageArea = _envDamageArea;
    w.envDamageHa  = _envDamageHa;
    w.envTreatment = _envTreatment;
    w.envAttached  = _envAttached;

    w.hasHumanDamage = _hasHumanDamage;
    w.humanDamage    = _humanDamage;
    w.humanMortality = _humanMortality;
    w.humanTreatment = _humanTreatment;
    w.humanAttached  = _humanAttached;

    Navigator.of(context).pushNamed(AppRoutes.cropStep7, arguments: w);
  }

  // ── Helpers ───────────────────────────────────────────────────
  Widget _label(String t, {bool italic = false}) => Text(t,
    style: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: italic ? FontWeight.w500 : FontWeight.w700,
      fontStyle:  italic ? FontStyle.italic : FontStyle.normal,
      color: DAColors.textDark));

  Widget _addBtn(String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Row(children: [
      Container(width: 28, height: 28,
        decoration: const BoxDecoration(color: DAColors.greenMid, shape: BoxShape.circle),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 18)),
      const SizedBox(width: 8),
      Text(label, style: GoogleFonts.poppins(
          fontSize: 13, fontWeight: FontWeight.w600, color: DAColors.greenMid)),
    ]),
  );

  Widget _removeBtn(VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(width: 32, height: 32,
      decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
      child: Icon(Icons.close_rounded, color: Colors.red.shade400, size: 18)),
  );

  Widget _bareField({
    required String hint, required ValueChanged<String> onChanged,
    String? initial, TextInputType kb = TextInputType.text,
  }) =>
    TextFormField(
      initialValue: initial, onChanged: onChanged, keyboardType: kb,
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

  Widget _dateField({
    required String value, required ValueChanged<String> onChanged,
    String hint = 'Choose Date',
  }) =>
    GestureDetector(
      onTap: () async {
        final p = await showDatePicker(
          context: context, initialDate: DateTime.now(),
          firstDate: DateTime(2020), lastDate: DateTime(2035),
          builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.light(primary: DAColors.greenMid)),
              child: child!),
        );
        if (p != null) {
          onChanged('${p.year}-${p.month.toString().padLeft(2,'0')}-${p.day.toString().padLeft(2,'0')}');
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDDDDDD), width: 1.5)),
        child: Row(children: [
          Expanded(child: Text(value.isEmpty ? hint : value,
            style: GoogleFonts.poppins(fontSize: 14,
                color: value.isEmpty ? DAColors.textMuted : DAColors.textDark))),
          const Icon(Icons.calendar_month_rounded, color: DAColors.greenMid, size: 22),
        ]),
      ),
    );

  Widget _checkRow(String label, bool value, ValueChanged<bool?> onChanged) =>
    InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Container(width: 22, height: 22,
            decoration: BoxDecoration(
              color: value ? DAColors.greenMid : Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                  color: value ? DAColors.greenMid : const Color(0xFFBBBBBB),
                  width: 1.5)),
            child: value
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                : null),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: GoogleFonts.poppins(
              fontSize: 14, fontWeight: FontWeight.w600, color: DAColors.textDark))),
        ]),
      ),
    );

  Widget _sectionDivider() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 4),
    child: Divider(color: Color(0xFFEEEEEE), thickness: 1.5));

  List<Widget> _damageAreaHa({
    required String area, required ValueChanged<String> onAreaChanged,
    required String ha,   required ValueChanged<String> onHaChanged,
  }) =>
    [
      CropField(label: 'Estimated crop damage (area)', hint: 'Enter area',
        initialValue: area, keyboardType: TextInputType.number, onChanged: onAreaChanged),
      const SizedBox(height: 14),
      CropField(label: 'Estimated crop damage (ha)', hint: 'Enter hectare',
        initialValue: ha, keyboardType: TextInputType.number, onChanged: onHaChanged),
    ];

  List<Widget> _treatmentAttached({
    required String treatment, required ValueChanged<String> onTreatmentChanged,
    required String attached,  required ValueChanged<String> onAttachedChanged,
  }) =>
    [
      CropField(label: 'Treatment provided/Action taken', hint: 'Enter',
        initialValue: treatment, onChanged: onTreatmentChanged),
      const SizedBox(height: 14),
      _label('(Attached incident/monitoring/mortality report and reporting period)',
          italic: true),
      const SizedBox(height: 8),
      _bareField(hint: 'Enter Ocurrence', initial: attached, onChanged: onAttachedChanged),
    ];

  @override
  Widget build(BuildContext context) {
    return CropFormShell(currentStep: 5, onNext: _next, child: _buildForm());
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Crop Damage Information',
          style: GoogleFonts.poppins(
              fontSize: 22, fontWeight: FontWeight.w800, color: DAColors.textDark)),
        const SizedBox(height: 16),

        // ── Checklist ──────────────────────────────────────────
        Text('Check List', style: GoogleFonts.poppins(
            fontSize: 15, fontWeight: FontWeight.w700, color: DAColors.textDark)),
        const SizedBox(height: 8),
        _checkRow('Pest Occurrence', _hasPest,
            (v) => setState(() => _hasPest = v ?? false)),
        _checkRow('Disease Occurrence', _hasDisease,
            (v) => setState(() => _hasDisease = v ?? false)),
        // *** FIXED: was "livestock production" — now "crop production" ***
        _checkRow('Environmental hazard affecting the crop production',
            _hasEnvHazard,
            (v) => setState(() => _hasEnvHazard = v ?? false)),
        _checkRow('Human-induced damage', _hasHumanDamage,
            (v) => setState(() => _hasHumanDamage = v ?? false)),
        const SizedBox(height: 20),

        // ════ PEST ═══════════════════════════════════════════════
        if (_hasPest) ...[
          Text('Pest Occurrence', style: GoogleFonts.poppins(
              fontSize: 15, fontWeight: FontWeight.w700, color: DAColors.textDark)),
          const SizedBox(height: 12),
          _bareField(hint: 'Enter Ocurrence', initial: _pestOccurrence,
              onChanged: (v) => _pestOccurrence = v),
          const SizedBox(height: 14),
          _label('Date when pest occurrence was first observed'),
          const SizedBox(height: 8),
          _dateField(value: _pestDate,
              onChanged: (v) => setState(() => _pestDate = v)),
          const SizedBox(height: 14),
          ..._damageAreaHa(
            area: _pestDamageArea, onAreaChanged: (v) => _pestDamageArea = v,
            ha:   _pestDamageHa,   onHaChanged:   (v) => _pestDamageHa   = v),
          const SizedBox(height: 14),
          ..._treatmentAttached(
            treatment: _pestTreatment, onTreatmentChanged: (v) => _pestTreatment = v,
            attached:  _pestAttached,  onAttachedChanged:  (v) => _pestAttached  = v),
          _sectionDivider(),
        ],

        // ════ DISEASE ════════════════════════════════════════════
        if (_hasDisease) ...[
          Text('Disease Occurrence', style: GoogleFonts.poppins(
              fontSize: 15, fontWeight: FontWeight.w700, color: DAColors.textDark)),
          const SizedBox(height: 12),
          _bareField(hint: 'Enter Ocurrence', initial: _diseaseOccurrence,
              onChanged: (v) => _diseaseOccurrence = v),
          const SizedBox(height: 14),
          _label('Date when disease occurrence was first observed'),
          const SizedBox(height: 8),
          _dateField(value: _diseaseDate, hint: 'Enter Date',
              onChanged: (v) => setState(() => _diseaseDate = v)),
          const SizedBox(height: 14),
          ..._damageAreaHa(
            area: _diseaseDamageArea, onAreaChanged: (v) => _diseaseDamageArea = v,
            ha:   _diseaseDamageHa,   onHaChanged:   (v) => _diseaseDamageHa   = v),
          const SizedBox(height: 14),
          ..._treatmentAttached(
            treatment: _diseaseTreatment, onTreatmentChanged: (v) => _diseaseTreatment = v,
            attached:  _diseaseAttached,  onAttachedChanged:  (v) => _diseaseAttached  = v),
          _sectionDivider(),
        ],

        // ════ ENVIRONMENTAL HAZARD ═══════════════════════════════
        if (_hasEnvHazard) ...[
          Text('Environmental hazard affecting the crop production (enumerate per hazard)',
            style: GoogleFonts.poppins(
                fontSize: 15, fontWeight: FontWeight.w700, color: DAColors.textDark)),
          const SizedBox(height: 12),

          ..._envHazards.asMap().entries.map((e) {
            final i = e.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Expanded(child: _bareField(hint: 'Enter Ocurrence',
                    initial: _envHazards[i], onChanged: (v) => _envHazards[i] = v)),
                if (i > 0) ...[
                  const SizedBox(width: 8),
                  _removeBtn(() => setState(() => _envHazards.removeAt(i))),
                ],
              ]),
            );
          }),
          _addBtn('Add Remarks', () => setState(() => _envHazards.add(''))),
          const SizedBox(height: 14),

          _label('Date of Occurrence'),
          const SizedBox(height: 8),
          _dateField(value: _envDate, hint: 'Enter',
              onChanged: (v) => setState(() => _envDate = v)),
          const SizedBox(height: 14),
          ..._damageAreaHa(
            area: _envDamageArea, onAreaChanged: (v) => _envDamageArea = v,
            ha:   _envDamageHa,   onHaChanged:   (v) => _envDamageHa   = v),
          const SizedBox(height: 14),
          ..._treatmentAttached(
            treatment: _envTreatment, onTreatmentChanged: (v) => _envTreatment = v,
            attached:  _envAttached,  onAttachedChanged:  (v) => _envAttached  = v),
          _sectionDivider(),
        ],

        // ════ HUMAN-INDUCED ══════════════════════════════════════
        if (_hasHumanDamage) ...[
          Text('Human-induced damage', style: GoogleFonts.poppins(
              fontSize: 15, fontWeight: FontWeight.w700, color: DAColors.textDark)),
          const SizedBox(height: 12),
          _bareField(hint: 'Enter', initial: _humanDamage,
              onChanged: (v) => _humanDamage = v),
          const SizedBox(height: 14),
          CropField(label: 'Number of mortality (Human-induced)', hint: 'Enter',
            initialValue: _humanMortality, keyboardType: TextInputType.number,
            onChanged: (v) => _humanMortality = v),
          const SizedBox(height: 14),
          ..._treatmentAttached(
            treatment: _humanTreatment, onTreatmentChanged: (v) => _humanTreatment = v,
            attached:  _humanAttached,  onAttachedChanged:  (v) => _humanAttached  = v),
          const SizedBox(height: 8),
        ],

        if (!_hasPest && !_hasDisease && !_hasEnvHazard && !_hasHumanDamage)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Text('Select at least one damage type from the checklist above.',
              style: GoogleFonts.poppins(fontSize: 13,
                  fontStyle: FontStyle.italic, color: DAColors.textMuted)),
          ),

        const SizedBox(height: 32),
      ],
    );
  }
}