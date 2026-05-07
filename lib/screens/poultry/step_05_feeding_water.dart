import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/da_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/crop_form_shell.dart';
import '../../widgets/crop_dropdown.dart';
import '../../widgets/crop_field.dart';
import 'poultry_step_wrapper.dart';

class PoultryStep5FeedingWater extends StatefulWidget {
  const PoultryStep5FeedingWater({super.key, required this.wrapper});
  final PoultryStepWrapper wrapper;

  @override
  State<PoultryStep5FeedingWater> createState() => _Step5State();
}

class _Step5State extends State<PoultryStep5FeedingWater> {
  PoultryStepWrapper get w => widget.wrapper;

  String? _feedType;
  String _totalFeedConsumed = '';
  String _feedPerDay = '';
  String? _waterSource;

  static const _feedOptions = [
    'Booster',
    'Grower',
    'Finisher',
    'Laying pellet',
    'Laying crumble',
    'Laying mash',
    'Others',
  ];

  static const _waterOptions = [
    'Tap water',
    'Well water',
    'River/Stream',
    'Rainwater',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _feedType = w.feedType.isEmpty ? null : w.feedType;
    _totalFeedConsumed = w.totalFeedConsumed;
    _feedPerDay = w.feedPerDay;
    _waterSource = w.waterSources.isNotEmpty ? w.waterSources.first : null;
  }

  void _next() {
    w.feedType = _feedType ?? '';
    w.totalFeedConsumed = _totalFeedConsumed;
    w.feedPerDay = _feedPerDay;
    w.waterSources = _waterSource != null ? [_waterSource!] : [];
    Navigator.of(context).pushNamed(AppRoutes.poultryStep6, arguments: w);
  }

  @override
  Widget build(BuildContext context) => CropFormShell(
        formTitle: 'POULTRY PRODUCTION',
        formSubtitle: 'Poultry Production Monitoring Form',
        currentStep: 4,
        totalSteps: 7,
        onNext: _next,
        child: _buildForm(),
      );

  Widget _buildForm() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Feeding and Water Management',
          style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: DAColors.textDark)),
      const SizedBox(height: 24),
      CropDropdown(
        label: 'Type of feed used',
        hint: 'Choose the type of feed used',
        value: _feedType,
        items: _feedOptions,
        onChanged: (v) => setState(() => _feedType = v),
      ),
      const SizedBox(height: 20),
      CropField(
        label: 'Total feed consumed (kg)',
        hint: 'Enter',
        initialValue: _totalFeedConsumed,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
        onChanged: (v) => _totalFeedConsumed = v,
      ),
      const SizedBox(height: 20),
      CropField(
        label: 'Feed per day (g/hd)',
        hint: 'Enter',
        initialValue: _feedPerDay,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
        onChanged: (v) => _feedPerDay = v,
      ),
      const SizedBox(height: 20),
      CropDropdown(
        label: 'Source/s of water',
        hint: 'Choose the Source/s of water',
        value: _waterSource,
        items: _waterOptions,
        onChanged: (v) => setState(() => _waterSource = v),
      ),
      const SizedBox(height: 32),
    ]);
  }
}
