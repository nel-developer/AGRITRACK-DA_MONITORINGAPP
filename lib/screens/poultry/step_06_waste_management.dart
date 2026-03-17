import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/da_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/crop_form_shell.dart';
import 'poultry_step_wrapper.dart';

class PoultryStep6WasteManagement extends StatefulWidget {
  const PoultryStep6WasteManagement({super.key, required this.wrapper});
  final PoultryStepWrapper wrapper;

  @override
  State<PoultryStep6WasteManagement> createState() => _Step6State();
}

class _Step6State extends State<PoultryStep6WasteManagement> {
  PoultryStepWrapper get w => widget.wrapper;

  String _sacksProduced  = '';
  String _sacksSold      = '';
  String _sacksUsed      = '';
  String _manurePrice    = '';

  void _next() {
    w.sacksManureProduced = _sacksProduced;
    w.sacksManureSold     = _sacksSold;
    w.sacksManureUsed     = _sacksUsed;
    w.manurePricePerSack  = _manurePrice;
    Navigator.of(context).pushNamed(AppRoutes.poultryStep7, arguments: w);
  }

  Widget _field({
    required String label,
    required String hint,
    required ValueChanged<String> onChanged,
    String? initial,
  }) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: GoogleFonts.poppins(
        fontSize: 14, fontWeight: FontWeight.w700, color: DAColors.textDark)),
    const SizedBox(height: 8),
    TextFormField(
      initialValue: initial, onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
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
    ),
  ]);

  @override
  Widget build(BuildContext context) => CropFormShell(
    formTitle:    'POULTRY PRODUCTION',
    formSubtitle: 'Poultry Production Monitoring Form',
    currentStep:  5,
    totalSteps:   7,
    onNext:       _next,
    child:        _buildForm(),
  );

  Widget _buildForm() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      Text('Waste Management',
        style: GoogleFonts.poppins(
            fontSize: 22, fontWeight: FontWeight.w800, color: DAColors.textDark)),
      const SizedBox(height: 24),

      _field(
        label: 'Total number of sacks of manure produced',
        hint:  'Enter the no. of sacks',
        initial: _sacksProduced,
        onChanged: (v) => _sacksProduced = v,
      ),
      const SizedBox(height: 20),

      _field(
        label: 'Total sacks of manure sold',
        hint:  'Enter',
        initial: _sacksSold,
        onChanged: (v) => _sacksSold = v,
      ),
      const SizedBox(height: 20),

      _field(
        label: 'Total sacks of manure used',
        hint:  'Enter the total of manure used',
        initial: _sacksUsed,
        onChanged: (v) => _sacksUsed = v,
      ),
      const SizedBox(height: 20),

      _field(
        label: 'Price of manure per sack',
        hint:  'Enter the price of manure per sack',
        initial: _manurePrice,
        onChanged: (v) => _manurePrice = v,
      ),

      const SizedBox(height: 32),
    ]);
  }
}