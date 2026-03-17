import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/da_colors.dart';
import '../../routes/app_routes.dart';
import 'livestock_step_wrapper.dart';
import '../../widgets/crop_form_shell.dart';
import '../../widgets/crop_field.dart';

class LivestockStep4WaterAndFeeding extends StatefulWidget {
  const LivestockStep4WaterAndFeeding({super.key, required this.wrapper});
  final LivestockStepWrapper wrapper;

  @override
  State<LivestockStep4WaterAndFeeding> createState() =>
      _LivestockStep4State();
}

class _LivestockStep4State extends State<LivestockStep4WaterAndFeeding> {
  LivestockStepWrapper get w => widget.wrapper;

  String _grazingArea = '';

  // Type of feeds — dynamic list (name + kg)
  final List<_FeedEntry> _feeds = [_FeedEntry()];

  // Source/s of water — dynamic list
  final List<String> _waterSources = [''];

  void _next() {
    w.grazingArea   = _grazingArea;
    w.feeds         = _feeds;
    w.waterSources  = _waterSources
        .where((s) => s.trim().isNotEmpty)
        .toList();

    Navigator.of(context).pushNamed(
      AppRoutes.livestockStep5,
      arguments: w,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CropFormShell(
      formTitle:    'LIVESTOCK PRODUCTION',
      formSubtitle: 'Livestock Production Monitoring Form',
      currentStep:  3,
      onNext:       _next,
      child:        _buildForm(),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        _sectionTitle('Water and Feeding Requirement'),
        const SizedBox(height: 24),

        // ── Grazing area ─────────────────────────────────────
        CropField(
          label:        'Average allotted grazing area (if applicable) per head, indicate unit',
          hint:         'Enter',
          initialValue: _grazingArea,
          onChanged:    (v) => _grazingArea = v,
        ),
        const SizedBox(height: 16),

        // ── Feeds — dynamic (type + kg) ──────────────────────
        _buildLabel('Type of feeds used (if applicable)'),
        const SizedBox(height: 8),
        ..._feeds.asMap().entries.map((e) => _feedRow(e.key, e.value)),
        _addAnotherBtn(
            onTap: () => setState(() => _feeds.add(_FeedEntry()))),
        const SizedBox(height: 16),

        // ── Water sources — dynamic ───────────────────────────
        _buildLabel('Source/s of water'),
        const SizedBox(height: 8),
        ..._waterSources.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _waterSources[e.key],
                  onChanged:    (v) => _waterSources[e.key] = v,
                  style: GoogleFonts.poppins(
                      fontSize: 14, color: DAColors.textDark),
                  decoration: _rawDeco('Enter'),
                ),
              ),
              if (e.key > 0) ...[
                const SizedBox(width: 8),
                _removeBtn(() => setState(
                    () => _waterSources.removeAt(e.key))),
              ] else
                const SizedBox(width: 40),
            ],
          ),
        )),
        _addAnotherBtn(
            onTap: () => setState(() => _waterSources.add(''))),

        const SizedBox(height: 32),
      ],
    );
  }

  // ── Feed row: type of feed + kg ──────────────────────────────
  Widget _feedRow(int i, _FeedEntry item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(
              color: const Color(0xFFDDDDDD), width: 1.2),
          borderRadius: BorderRadius.circular(14),
          color: const Color(0xFFFAFAFA),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _buildLabel('Feed ${i + 1}')),
                if (i > 0)
                  _removeBtn(
                      () => setState(() => _feeds.removeAt(i))),
              ],
            ),
            const SizedBox(height: 10),

            _buildSubLabel('Type of feeds used (if applicable)'),
            const SizedBox(height: 6),
            TextFormField(
              initialValue: item.type,
              onChanged:    (v) => item.type = v,
              style: GoogleFonts.poppins(
                  fontSize: 14, color: DAColors.textDark),
              decoration: _rawDeco('Enter'),
            ),
            const SizedBox(height: 10),

            _buildSubLabel('Total amount of feeds used per head (kg)'),
            const SizedBox(height: 6),
            TextFormField(
              initialValue:  item.kg,
              onChanged:     (v) => item.kg = v,
              keyboardType:  const TextInputType.numberWithOptions(
                  decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              style: GoogleFonts.poppins(
                  fontSize: 14, color: DAColors.textDark),
              decoration: _rawDeco('Enter'),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _rawDeco(String hint) => InputDecoration(
    hintText:  hint,
    hintStyle: GoogleFonts.poppins(
        fontSize: 14, color: DAColors.textMuted),
    filled:    true,
    fillColor: Colors.white,
    isDense:   true,
    contentPadding: const EdgeInsets.symmetric(
        horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
            color: Color(0xFFDDDDDD), width: 1.5)),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
            color: Color(0xFFDDDDDD), width: 1.5)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
            color: DAColors.greenMid, width: 2.0)),
  );

  Widget _addAnotherBtn({required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Row(children: [
          Container(
            width: 28, height: 28,
            decoration: const BoxDecoration(
                color: DAColors.greenMid, shape: BoxShape.circle),
            child: const Icon(Icons.add_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          Text('Add Another',
            style: GoogleFonts.poppins(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: DAColors.greenMid)),
        ]),
      );

  Widget _removeBtn(VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
          color: Colors.red.shade50, shape: BoxShape.circle),
      child: Icon(Icons.close_rounded,
          color: Colors.red.shade400, size: 16),
    ),
  );

  Widget _sectionTitle(String t) => Text(t,
    style: GoogleFonts.poppins(
      fontSize: 22, fontWeight: FontWeight.w800,
      color: DAColors.textDark));

  Widget _buildLabel(String t) => Text(t,
    style: GoogleFonts.poppins(
      fontSize: 14, fontWeight: FontWeight.w700,
      color: DAColors.textDark));

  Widget _buildSubLabel(String t) => Text(t,
    style: GoogleFonts.poppins(
      fontSize: 13, fontWeight: FontWeight.w600,
      color: DAColors.textDark));
}

class _FeedEntry {
  String type = '';
  String kg   = '';
}