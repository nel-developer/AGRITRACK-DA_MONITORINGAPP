import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/da_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/crop_form_shell.dart';
import '../../widgets/crop_field.dart';
import '../../widgets/crop_dropdown.dart';
import 'poultry_step_wrapper.dart';

class _ChickSold {
  String count = '';
  String age = '';
}

class PoultryStep3ProductionInformation extends StatefulWidget {
  const PoultryStep3ProductionInformation({super.key, required this.wrapper});
  final PoultryStepWrapper wrapper;

  @override
  State<PoultryStep3ProductionInformation> createState() => _Step3State();
}

class _Step3State extends State<PoultryStep3ProductionInformation> {
  PoultryStepWrapper get w => widget.wrapper;

  // ── Common fields ─────────────────────────────────────────────
  String _stocksReceived = '';
  String _dateReceived = '';
  String _ageUponReceipt = '';
  String _avgWeightUponReceipt = '';
  String _totalProductiveCycle = '';
  String _housingType = '';
  String? _landOwnership;
  String _landOwnershipOther = '';
  String? _usufruct;

  // ── Breeding ──────────────────────────────────────────────────
  String _maleToFemaleRatio = '';
  String _eggsProduced = '';
  String _fertilEggs = '';
  String _eggsIncubated = '';
  String _eggsHatched = '';
  String _hatchingRate = '';
  String _mortalitiesAfterHatch = '';
  final List<_ChickSold> _chicksSold = [_ChickSold()];
  String _eggsSold = '';

  // ── Broiler/Meat ──────────────────────────────────────────────
  String _harvestedBirds = '';
  String _totalWeightHarvested = '';
  String _avgDailyGain = '';
  String _harvestRecovery = '';
  String _avgLiveWeight = '';
  String _feedConversionRatio = '';
  String _avgAgeHarvested = '';
  String _broilerPerformanceIndex = '';

  // ── Layer/Egg ─────────────────────────────────────────────────
  String _rangingAge = '';
  String _totalEggsHarvested = '';
  String _avgHarvestRate = '';
  String _weeklyHDEP = '';
  String _weeklyHDEPFile = '';
  String _daysUnderMolting = '';

  static const _ownershipOptions = ['Owned', 'Donated', 'Rented', 'Others'];
  static const _yesNo = ['Yes', 'No'];

  @override
  void initState() {
    super.initState();
    _stocksReceived = w.stocksReceived;
    _dateReceived = w.dateReceived;
    _ageUponReceipt = w.ageUponReceipt;
    _avgWeightUponReceipt = w.avgWeightUponReceipt;
    _totalProductiveCycle = w.totalProductiveCycle;
    _housingType = w.housingType ?? '';
    _landOwnership = w.landOwnership;
    _landOwnershipOther = w.landOwnershipOther;
    _usufruct = w.usufruct;
    _maleToFemaleRatio = w.maleToFemaleRatio;
    _eggsProduced = w.eggsProduced;
    _fertilEggs = w.fertilEggs;
    _eggsIncubated = w.eggsIncubated;
    _eggsHatched = w.eggsHatched;
    _hatchingRate = w.hatchingRate;
    _mortalitiesAfterHatch = w.mortalitiesAfterHatch;
    _eggsSold = w.eggsSold;
    _harvestedBirds = w.harvestedBirds;
    _totalWeightHarvested = w.totalWeightHarvested;
    _avgDailyGain = w.avgDailyGain;
    _harvestRecovery = w.harvestRecovery;
    _avgLiveWeight = w.avgLiveWeight;
    _feedConversionRatio = w.feedConversionRatio;
    _avgAgeHarvested = w.avgAgeHarvested;
    _broilerPerformanceIndex = w.broilerPerformanceIndex;
    _rangingAge = w.rangingAge;
    _totalEggsHarvested = w.totalEggsHarvested;
    _avgHarvestRate = w.avgHarvestRate;
    _weeklyHDEP = w.weeklyHenDayEggProduction;
    _weeklyHDEPFile = w.weeklyHDEPFile;
    _daysUnderMolting = w.daysUnderMolting;
    _chicksSold
      ..clear()
      ..addAll(_parseChicksSold(w.chicksSold));
  }

  void _next() {
    w.stocksReceived = _stocksReceived;
    w.dateReceived = _dateReceived;
    w.ageUponReceipt = _ageUponReceipt;
    w.avgWeightUponReceipt = _avgWeightUponReceipt;
    w.totalProductiveCycle = _totalProductiveCycle;
    w.housingType = _housingType.isEmpty ? null : _housingType;
    w.landOwnership = _landOwnership;
    w.landOwnershipOther = _landOwnershipOther;
    w.usufruct = _usufruct;
    // Breeding
    w.maleToFemaleRatio = _maleToFemaleRatio;
    w.eggsProduced = _eggsProduced;
    w.fertilEggs = _fertilEggs;
    w.eggsIncubated = _eggsIncubated;
    w.eggsHatched = _eggsHatched;
    w.hatchingRate = _hatchingRate;
    w.mortalitiesAfterHatch = _mortalitiesAfterHatch;
    w.chicksSold =
        _chicksSold.map((c) => '${c.count} (age: ${c.age})').join(', ');
    w.eggsSold = _eggsSold;
    // Broiler
    w.harvestedBirds = _harvestedBirds;
    w.totalWeightHarvested = _totalWeightHarvested;
    w.avgDailyGain = _avgDailyGain;
    w.harvestRecovery = _harvestRecovery;
    w.avgLiveWeight = _avgLiveWeight;
    w.feedConversionRatio = _feedConversionRatio;
    w.avgAgeHarvested = _avgAgeHarvested;
    w.broilerPerformanceIndex = _broilerPerformanceIndex;
    // Layer
    w.rangingAge = _rangingAge;
    w.totalEggsHarvested = _totalEggsHarvested;
    w.avgHarvestRate = _avgHarvestRate;
    w.weeklyHenDayEggProduction = _weeklyHDEP;
    w.weeklyHDEPFile = _weeklyHDEPFile;
    w.daysUnderMolting = _daysUnderMolting;

    Navigator.of(context).pushNamed(AppRoutes.poultryStep4, arguments: w);
  }

  // ── Widgets ───────────────────────────────────────────────────
  Widget _lbl(String t) => Text(t,
      style: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w700, color: DAColors.textDark));

  Widget _purposeLbl(String t) => Text(t,
      style: GoogleFonts.poppins(
          fontSize: 15, fontWeight: FontWeight.w700, color: DAColors.greenMid));

  List<_ChickSold> _parseChicksSold(String raw) {
    if (raw.trim().isEmpty) {
      return [_ChickSold()];
    }

    final items = raw
        .split(RegExp(r'\s*,\s*'))
        .where((entry) => entry.trim().isNotEmpty)
        .map((entry) {
      final match =
          RegExp(r'^(.*?)\s*\(age:\s*(.*?)\)$').firstMatch(entry.trim());
      final chick = _ChickSold();
      if (match != null) {
        chick.count = match.group(1)?.trim() ?? '';
        chick.age = match.group(2)?.trim() ?? '';
      } else {
        chick.count = entry.trim();
      }
      return chick;
    }).toList();

    return items.isEmpty ? [_ChickSold()] : items;
  }

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

  Widget _dateField(String value, ValueChanged<String> onChanged) =>
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
                child: Text(value.isEmpty ? 'Enter' : value,
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

  Widget _attachField(String value, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
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

  Widget _remarksToggle(String remarks, ValueChanged<String> onChanged) {
    if (remarks.trim().isNotEmpty) {
      return _field(
          hint: 'Enter remarks', initial: remarks, onChanged: onChanged);
    }
    return GestureDetector(
      onTap: () => onChanged(' '),
      child: Row(children: [
        Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
                color: DAColors.greenMid, shape: BoxShape.circle),
            child:
                const Icon(Icons.add_rounded, color: Colors.white, size: 18)),
        const SizedBox(width: 8),
        Text('Add Remarks',
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: DAColors.greenMid)),
      ]),
    );
  }

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
      ]));

  Widget _removeBtn(VoidCallback onTap) => GestureDetector(
      onTap: onTap,
      child: Container(
          width: 32,
          height: 32,
          decoration:
              BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
          child:
              Icon(Icons.close_rounded, color: Colors.red.shade400, size: 18)));

  Widget _divider() => const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Divider(color: Color(0xFFEEEEEE), thickness: 1.5));

  @override
  Widget build(BuildContext context) => CropFormShell(
        formTitle: 'POULTRY PRODUCTION',
        formSubtitle: 'Poultry Production Monitoring Form',
        currentStep: 2,
        totalSteps: 7,
        onNext: _next,
        child: _buildForm(),
      );

  Widget _buildForm() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Production Information',
          style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: DAColors.textDark)),
      const SizedBox(height: 24),

      // ── Common fields ────────────────────────────────────────
      CropField(
          label: 'Number of stocks',
          hint: 'Enter',
          initialValue: _stocksReceived,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (v) => _stocksReceived = v),
      const SizedBox(height: 16),

      _lbl('Date received/purchased'),
      const SizedBox(height: 8),
      _dateField(_dateReceived, (v) => setState(() => _dateReceived = v)),
      const SizedBox(height: 16),

      CropField(
          label: 'Age of poultry upon receipt (Weeks)',
          hint: 'Enter',
          initialValue: _ageUponReceipt,
          onChanged: (v) => _ageUponReceipt = v),
      const SizedBox(height: 16),

      CropField(
          label: 'Average weight upon receipt',
          hint: 'Enter',
          initialValue: _avgWeightUponReceipt,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
          ],
          onChanged: (v) => _avgWeightUponReceipt = v),
      const SizedBox(height: 16),

      CropField(
          label: 'Total Productive cycle (Months)',
          hint: 'Enter',
          initialValue: _totalProductiveCycle,
          onChanged: (v) => _totalProductiveCycle = v),
      const SizedBox(height: 16),

      CropField(
          label: 'Type of housing/confinement',
          hint: 'Enter',
          initialValue: _housingType,
          onChanged: (v) => _housingType = v),
      const SizedBox(height: 16),

      CropDropdown(
          label: 'Land ownership',
          hint: 'Choose',
          value: _landOwnership,
          items: _ownershipOptions,
          onChanged: (v) => setState(() {
                _landOwnership = v;
                if (v != 'Others') _landOwnershipOther = '';
              })),
      if (_landOwnership == 'Others') ...[
        const SizedBox(height: 8),
        CropField(
            label: 'Please specify',
            hint: 'Enter',
            initialValue: _landOwnershipOther,
            onChanged: (v) => _landOwnershipOther = v),
      ],
      const SizedBox(height: 16),

      CropDropdown(
          label: 'With Usufruct/Land use agreement',
          hint: 'Choose',
          value: _usufruct,
          items: _yesNo,
          enabled: _landOwnership != null && _landOwnership != 'Owned',
          onChanged: (v) => setState(() => _usufruct = v)),
      const SizedBox(height: 24),

      // ════ FOR BREEDING PRODUCTION ════════════════════════════
      if (w.purposeBreeding) ...[
        _purposeLbl('For Breeding Production'),
        const SizedBox(height: 16),

        CropField(
            label: 'Male Stocks',
            hint: 'Enter',
            initialValue: '',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) {}),
        const SizedBox(height: 16),

        CropField(
            label: 'Female Stocks',
            hint: 'Enter',
            initialValue: '',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) {}),
        const SizedBox(height: 16),

        CropField(
            label: 'Ratio of Male to Female stocks',
            hint: 'Enter',
            initialValue: _maleToFemaleRatio,
            onChanged: (v) => _maleToFemaleRatio = v),
        const SizedBox(height: 16),

        CropField(
            label: 'Number of eggs produced',
            hint: 'Enter',
            initialValue: _eggsProduced,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) => _eggsProduced = v),
        const SizedBox(height: 16),

        CropField(
            label: 'Number of fertile eggs',
            hint: 'Enter',
            initialValue: _fertilEggs,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) => _fertilEggs = v),
        const SizedBox(height: 16),

        CropField(
            label: 'Number of eggs incubated',
            hint: 'Enter',
            initialValue: _eggsIncubated,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) => _eggsIncubated = v),
        const SizedBox(height: 16),

        CropField(
            label: 'Number of eggs hatched',
            hint: 'Enter',
            initialValue: _eggsHatched,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) => _eggsHatched = v),
        const SizedBox(height: 16),

        CropField(
            label: 'Hatching rate (%)',
            hint: 'Enter',
            initialValue: _hatchingRate,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
            ],
            onChanged: (v) => _hatchingRate = v),
        const SizedBox(height: 16),

        CropField(
            label: 'Number of mortality after hatch',
            hint: 'Enter',
            initialValue: _mortalitiesAfterHatch,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) => _mortalitiesAfterHatch = v),
        const SizedBox(height: 16),

        // Chicks sold — dynamic (count + age)
        _lbl('Number of chicks sold (include age)'),
        const SizedBox(height: 10),
        ..._chicksSold.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: _field(
                        hint: 'Enter',
                        initial: item.count,
                        kb: TextInputType.number,
                        fmt: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (v) => item.count = v)),
                if (i > 0) ...[
                  const SizedBox(width: 8),
                  _removeBtn(() => setState(() => _chicksSold.removeAt(i))),
                ],
              ]),
              const SizedBox(height: 8),
              _lbl('Age'),
              const SizedBox(height: 6),
              _field(
                  hint: 'Enter',
                  initial: item.age,
                  onChanged: (v) => item.age = v),
            ]),
          );
        }),
        _addBtn('Add Another Input',
            () => setState(() => _chicksSold.add(_ChickSold()))),
        const SizedBox(height: 16),

        CropField(
            label: 'Number of eggs sold',
            hint: 'Enter',
            initialValue: _eggsSold,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) => _eggsSold = v),
        const SizedBox(height: 16),

        if (w.purposeMeat || w.purposeEgg) _divider(),
      ],

      // ════ FOR BROILER/MEAT PRODUCTION ════════════════════════
      if (w.purposeMeat) ...[
        _purposeLbl('For Broiler/Meat Production'),
        const SizedBox(height: 16),
        CropField(
            label: 'Number of harvested birds',
            hint: 'Enter No. of harvested birds',
            initialValue: _harvestedBirds,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) => _harvestedBirds = v),
        const SizedBox(height: 16),
        CropField(
            label: 'Total weight harvested',
            hint: 'Enter Total weight harvested',
            initialValue: _totalWeightHarvested,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
            ],
            onChanged: (v) => _totalWeightHarvested = v),
        const SizedBox(height: 16),
        CropField(
            label: 'Average Daily Gain (grams)',
            hint: 'Enter Average Daily Gain',
            initialValue: _avgDailyGain,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
            ],
            onChanged: (v) => _avgDailyGain = v),
        const SizedBox(height: 16),
        CropField(
            label: 'Harvest Recovery (%)',
            hint: 'Enter Percentage of Harvest Recovery',
            initialValue: _harvestRecovery,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
            ],
            onChanged: (v) => _harvestRecovery = v),
        const SizedBox(height: 16),
        CropField(
            label: 'Average Live Weight (kg)',
            hint: 'Enter Average Live Weight',
            initialValue: _avgLiveWeight,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
            ],
            onChanged: (v) => _avgLiveWeight = v),
        const SizedBox(height: 16),
        CropField(
            label: 'Feed Conversion Ratio (kg)',
            hint: 'Enter Feed Conversion Ratio (kg)',
            initialValue: _feedConversionRatio,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
            ],
            onChanged: (v) => _feedConversionRatio = v),
        const SizedBox(height: 16),
        CropField(
            label: 'Average Age harvested (days)',
            hint: 'Enter Average Age harvested',
            initialValue: _avgAgeHarvested,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) => _avgAgeHarvested = v),
        const SizedBox(height: 16),
        CropField(
            label: 'Birds/Broiler Performance Index',
            hint: 'Enter Birds/Broiler Performance Index',
            initialValue: _broilerPerformanceIndex,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
            ],
            onChanged: (v) => _broilerPerformanceIndex = v),
        const SizedBox(height: 16),
        if (w.purposeEgg) _divider(),
      ],

      // ════ FOR LAYER/EGG PRODUCTION ═══════════════════════════
      if (w.purposeEgg) ...[
        _purposeLbl('For Layer/Egg Production'),
        const SizedBox(height: 16),
        CropField(
            label: 'Ranging Age (in weeks)',
            hint: 'Enter',
            initialValue: _rangingAge,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
            ],
            onChanged: (v) => _rangingAge = v),
        const SizedBox(height: 16),
        CropField(
            label: 'Total eggs harvested',
            hint: 'Enter',
            initialValue: _totalEggsHarvested,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) => _totalEggsHarvested = v),
        const SizedBox(height: 16),
        CropField(
            label: 'Average harvest rate (%)',
            hint: 'Enter',
            initialValue: _avgHarvestRate,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
            ],
            onChanged: (v) => _avgHarvestRate = v),
        const SizedBox(height: 16),
        CropField(
            label: 'Weekly % Hen-Day Egg Production',
            hint: 'Enter',
            initialValue: _weeklyHDEP,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
            ],
            onChanged: (v) => _weeklyHDEP = v),
        const SizedBox(height: 8),
        _lbl('Attach weekly HDEP line chart'),
        const SizedBox(height: 8),
        _attachField(_weeklyHDEPFile,
            () => setState(() => _weeklyHDEPFile = 'hdep_chart.pdf')),
        const SizedBox(height: 16),
        CropField(
            label: 'Number of days underwent or observed molting',
            hint: 'Enter',
            initialValue: _daysUnderMolting,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) => _daysUnderMolting = v),
        const SizedBox(height: 16),
      ],

      const SizedBox(height: 32),
    ]);
  }
}
