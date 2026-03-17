import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/da_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/crop_form_shell.dart';
import '../../widgets/crop_field.dart';
import '../../widgets/crop_dropdown.dart';
import 'crop_step_wrapper.dart';

class CropStep4Fertilization extends StatefulWidget {
  const CropStep4Fertilization({super.key, required this.wrapper});
  final CropStepWrapper wrapper;

  @override
  State<CropStep4Fertilization> createState() => _CropStep4State();
}

class _CropStep4State extends State<CropStep4Fertilization> {
  CropStepWrapper get w => widget.wrapper;

  String? _fertilizerType;

  // Organic
  String? _organicSource;
  String  _organicBagsSAAD  = '';
  String  _organicBagsComm  = '';
  String  _organicTotalCost = '';
  String  _organicBagsCycle = '';
  String  _organicFrequency = '';

  // Inorganic
  String  _inorganicType      = '';
  String  _inorganicBagsSAAD  = '';
  String  _inorganicMeasure   = '';
  String  _inorganicTotalCost = '';
  final List<String> _inorganicBagsCycle = [''];
  String  _inorganicFrequency = '';

  // Pesticide
  String  _pesticideReq = '';

  static const _fertilizerOptions  = ['Organic', 'Inorganic', 'Both'];
  static const _organicSourceOptions = ['Commercial', 'Produced by FCA'];

  bool get _showOrganic   => _fertilizerType == 'Organic'   || _fertilizerType == 'Both';
  bool get _showInorganic => _fertilizerType == 'Inorganic' || _fertilizerType == 'Both';

  void _next() {
    w.fertilizerType        = _fertilizerType;
    w.organicSource         = _organicSource;
    w.organicBagsSAAD       = _organicBagsSAAD;
    w.organicBagsCommercial = _organicBagsComm;
    w.organicTotalCost      = _organicTotalCost;
    w.organicBagsCycle      = _organicBagsCycle;
    w.organicFrequency      = _organicFrequency;
    w.inorganicType         = _inorganicType;
    w.inorganicBagsSAAD     = _inorganicBagsSAAD;
    w.inorganicMeasure      = _inorganicMeasure;
    w.inorganicTotalCost    = _inorganicTotalCost;
    w.inorganicBagsCycle    = List.from(_inorganicBagsCycle);
    w.inorganicFrequency    = _inorganicFrequency;
    w.pesticideRequirement  = _pesticideReq;
    Navigator.of(context).pushNamed(AppRoutes.cropStep5, arguments: w);
  }

  Widget _sectionHeader(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Text(t, style: GoogleFonts.poppins(
        fontSize: 16, fontWeight: FontWeight.w800, color: DAColors.greenMid)),
  );

  Widget _label(String t) => Text(t,
    style: GoogleFonts.poppins(
        fontSize: 14, fontWeight: FontWeight.w700, color: DAColors.textDark));

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

  @override
  Widget build(BuildContext context) {
    return CropFormShell(currentStep: 3, onNext: _next, child: _buildForm());
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fertilization requirement',
          style: GoogleFonts.poppins(
              fontSize: 22, fontWeight: FontWeight.w800, color: DAColors.textDark)),
        const SizedBox(height: 24),

        CropDropdown(
          label: 'Types of fertilizers applied (organic, inorganic or both)',
          hint: 'Choose', value: _fertilizerType, items: _fertilizerOptions,
          onChanged: (v) => setState(() => _fertilizerType = v),
        ),
        const SizedBox(height: 24),

        // ════ ORGANIC ═════════════════════════════════════════════
        if (_showOrganic) ...[
          _sectionHeader('Organic Fertilizers'),

          CropDropdown(
            label: 'Indicate if organic fertilizer is commercial or produced by FCA',
            hint: 'Choose', value: _organicSource, items: _organicSourceOptions,
            onChanged: (v) => setState(() => _organicSource = v),
          ),
          const SizedBox(height: 20),

          CropField(label: 'Number of bags/kg received from SAAD',
            hint: 'Enter No. of bags', initialValue: _organicBagsSAAD,
            keyboardType: TextInputType.number, onChanged: (v) => _organicBagsSAAD = v),
          const SizedBox(height: 20),

          if (_organicSource == 'Commercial') ...[
            CropField(label: 'Number of bags/kg received from commercial',
              hint: 'Enter No. of bags', initialValue: _organicBagsComm,
              keyboardType: TextInputType.number, onChanged: (v) => _organicBagsComm = v),
            const SizedBox(height: 20),
          ],

          CropField(label: 'Total cost of organic fertilizer purchased (based on FCA records)',
            hint: 'Enter the Total cost', initialValue: _organicTotalCost,
            keyboardType: TextInputType.number, onChanged: (v) => _organicTotalCost = v),
          const SizedBox(height: 20),

          CropField(label: 'Total bags used per cropping cycle',
            hint: 'Enter the Total Bags', initialValue: _organicBagsCycle,
            keyboardType: TextInputType.number, onChanged: (v) => _organicBagsCycle = v),
          const SizedBox(height: 20),

          CropField(label: 'Frequency of application from date of planting',
            hint: 'Enter', initialValue: _organicFrequency,
            onChanged: (v) => _organicFrequency = v),
          const SizedBox(height: 28),
        ],

        // ════ INORGANIC ═══════════════════════════════════════════
        if (_showInorganic) ...[
          _sectionHeader('Inorganic Fertilizer'),

          CropField(label: 'Indicate types of inorganic fertilizer used',
            hint: 'Enter', initialValue: _inorganicType,
            onChanged: (v) => _inorganicType = v),
          const SizedBox(height: 20),

          _label('Number of bags/kg received from SAAD (per type)'),
          const SizedBox(height: 8),
          _bareField(hint: 'Enter the no. of bags', initial: _inorganicBagsSAAD,
              onChanged: (v) => _inorganicBagsSAAD = v, kb: TextInputType.number),
          const SizedBox(height: 8),
          _bareField(hint: 'Type of Measurement', initial: _inorganicMeasure,
              onChanged: (v) => _inorganicMeasure = v),
          const SizedBox(height: 20),

          CropField(label: 'Total cost of inorganic fertilizer purchased (based on FCA records)',
            hint: 'Enter', initialValue: _inorganicTotalCost,
            keyboardType: TextInputType.number, onChanged: (v) => _inorganicTotalCost = v),
          const SizedBox(height: 20),

          _label('Total bags used per cropping cycle (per type)'),
          const SizedBox(height: 10),
          ..._inorganicBagsCycle.asMap().entries.map((e) {
            final i = e.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Expanded(child: _bareField(hint: 'Enter', initial: _inorganicBagsCycle[i],
                    onChanged: (v) => _inorganicBagsCycle[i] = v, kb: TextInputType.number)),
                if (i > 0) ...[
                  const SizedBox(width: 8),
                  _removeBtn(() => setState(() => _inorganicBagsCycle.removeAt(i))),
                ],
              ]),
            );
          }),
          _addBtn('Add Cycle', () => setState(() => _inorganicBagsCycle.add(''))),
          const SizedBox(height: 20),

          CropField(label: 'Frequency of application from date of planting (per type)',
            hint: 'Enter', initialValue: _inorganicFrequency,
            onChanged: (v) => _inorganicFrequency = v),
          const SizedBox(height: 28),
        ],

        // ════ PESTICIDE — always shown ════════════════════════════
        CropField(label: 'Insert pesticide requirement', hint: 'Enter',
          initialValue: _pesticideReq, onChanged: (v) => _pesticideReq = v),

        const SizedBox(height: 32),
      ],
    );
  }
}