import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/da_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/crop_form_shell.dart';
import 'livestock_step_wrapper.dart';
import 'livestock_monitoring_summary_screen.dart';

class LivestockStep7Trainings extends StatefulWidget {
  const LivestockStep7Trainings({super.key, required this.wrapper});
  final LivestockStepWrapper wrapper;

  @override
  State<LivestockStep7Trainings> createState() => _LivestockStep7State();
}

class _LivestockStep7State extends State<LivestockStep7Trainings> {
  LivestockStepWrapper get w => widget.wrapper;

  final List<TrainingEntry> _trainings = [TrainingEntry()];
  String _photoPath = '';

  void _save() {
    w.trainings = List<TrainingEntry>.from(_trainings);
    w.farmPhoto = _photoPath;

    final isIndividual = w.implementationType == 'individual';
    final isHybrid     = w.implementationType == 'hybrid';

    if (isIndividual || isHybrid) {
      _showModal();
    } else {
      // Collective — go home
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
    }
  }

  void _showModal() {
    final record = LivestockMonitoringRecord(
      farmerName:  w.farmerName,
      breed:       w.breed ?? '',
      completedAt: DateTime.now(),
    );

    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          24, 20, 24,
          MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(50)))),
            const SizedBox(height: 20),

            Text('Record Saved!',
              style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.w800,
                color: DAColors.textDark)),
            const SizedBox(height: 6),
            Text('What would you like to do next?',
              style: GoogleFonts.poppins(
                fontSize: 13, color: DAColors.textMuted)),
            const SizedBox(height: 20),

            // Add Another Batch
            _ModalOption(
              icon:     Icons.pets_rounded,
              title:    'Add Another Batch',
              subtitle: 'Same farmer, monitor a new batch',
              color:    DAColors.greenMid,
              onTap: () {
                Navigator.pop(context);
                final next = LivestockStepWrapper()
                  ..fcaName              = w.fcaName
                  ..region               = w.region
                  ..province             = w.province
                  ..municipality         = w.municipality
                  ..barangay             = w.barangay
                  ..projectTitle         = w.projectTitle
                  ..primaryIntervention  = w.primaryIntervention
                  ..supportInterventions = List.from(w.supportInterventions)
                  ..purposeBreeding      = w.purposeBreeding
                  ..purposeMeat          = w.purposeMeat
                  ..purposeDairy         = w.purposeDairy
                  ..implementationType   = w.implementationType
                  ..farmerName           = w.farmerName;
                Navigator.of(context).pushNamed(
                    AppRoutes.livestockStep2, arguments: next);
              },
            ),
            const SizedBox(height: 12),

            // Add Another Farmer → Summary Screen
            _ModalOption(
              icon:     Icons.person_add_rounded,
              title:    'Add Another Farmer',
              subtitle: 'View summary and monitor more farmers',
              color:    DAColors.amber,
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => LivestockMonitoringSummaryScreen(
                      wrapper:          w,
                      completedRecords: [record],
                    ),
                  ),
                  (route) => route.settings.name == '/home',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _addBtn(String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Row(children: [
      Container(width: 28, height: 28,
        decoration: const BoxDecoration(
            color: DAColors.greenMid, shape: BoxShape.circle),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 18)),
      const SizedBox(width: 8),
      Text(label, style: GoogleFonts.poppins(
          fontSize: 13, fontWeight: FontWeight.w600, color: DAColors.greenMid)),
    ]));

  Widget _removeBtn(VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(width: 32, height: 32,
      decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
      child: Icon(Icons.close_rounded, color: Colors.red.shade400, size: 18)));

  Widget _bareField({required String hint, required ValueChanged<String> onChanged, String? initial}) =>
    TextFormField(initialValue: initial, onChanged: onChanged,
      style: GoogleFonts.poppins(fontSize: 14, color: DAColors.textDark),
      decoration: InputDecoration(hintText: hint,
        hintStyle: GoogleFonts.poppins(fontSize: 14, color: DAColors.textMuted),
        filled: true, fillColor: Colors.white, isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDDDDDD), width: 1.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDDDDDD), width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: DAColors.greenMid, width: 2.0))));

  @override
  Widget build(BuildContext context) => CropFormShell(
    formTitle:    'LIVESTOCK PRODUCTION',
    formSubtitle: 'Livestock Production Monitoring Form',
    currentStep:  6,
    totalSteps:   7,
    nextLabel:    'Submit',
    onNext:       _save,
    child:        _buildForm(),
  );

  Widget _buildForm() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Trainings Attended',
        style: GoogleFonts.poppins(
            fontSize: 22, fontWeight: FontWeight.w800, color: DAColors.textDark)),
      const SizedBox(height: 24),

      Text('Trainings Attended',
        style: GoogleFonts.poppins(
            fontSize: 14, fontWeight: FontWeight.w700, color: DAColors.textDark)),
      const SizedBox(height: 12),

      ..._trainings.asMap().entries.map((e) {
        final i = e.key;
        final t = e.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 1.2)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text('Training \${i + 1}',
                  style: GoogleFonts.poppins(fontSize: 13,
                      fontWeight: FontWeight.w700, color: DAColors.greenMid))),
                if (i > 0) _removeBtn(() => setState(() => _trainings.removeAt(i))),
              ]),
              const SizedBox(height: 10),
              Text('Name of Training', style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w600, color: DAColors.textDark)),
              const SizedBox(height: 6),
              _bareField(hint: 'Enter training name', initial: t.name,
                  onChanged: (v) => t.name = v),
              const SizedBox(height: 10),
              Text('Date', style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w600, color: DAColors.textDark)),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () async {
                  final p = await showDatePicker(
                    context: context, initialDate: DateTime.now(),
                    firstDate: DateTime(2020), lastDate: DateTime(2030),
                    builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(
                      colorScheme: const ColorScheme.light(primary: DAColors.greenMid)),
                      child: child!));
                  if (p != null) {
                    final y = p.year.toString();
                    final mo = p.month.toString().padLeft(2, '0');
                    final dy = p.day.toString().padLeft(2, '0');
                    setState(() => t.date = '\$y-\$mo-\$dy');
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFDDDDDD), width: 1.5)),
                  child: Row(children: [
                    Expanded(child: Text(t.date.isEmpty ? 'Choose Date' : t.date,
                      style: GoogleFonts.poppins(fontSize: 14,
                        color: t.date.isEmpty ? DAColors.textMuted : DAColors.textDark))),
                    const Icon(Icons.calendar_month_rounded, color: DAColors.greenMid, size: 22),
                  ]),
                ),
              ),
              const SizedBox(height: 10),
              Text('Number of Attendees', style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w600, color: DAColors.textDark)),
              const SizedBox(height: 6),
              TextFormField(
                initialValue: t.attendees,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (v) => t.attendees = v,
                style: GoogleFonts.poppins(fontSize: 14, color: DAColors.textDark),
                decoration: InputDecoration(
                  hintText: 'Enter number of attendees',
                  hintStyle: GoogleFonts.poppins(fontSize: 14, color: DAColors.textMuted),
                  filled: true, fillColor: Colors.white, isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFDDDDDD), width: 1.5)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFDDDDDD), width: 1.5)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: DAColors.greenMid, width: 2.0))),
              ),
            ]),
          ),
        );
      }),

      _addBtn('Add Training', () => setState(() => _trainings.add(TrainingEntry()))),
      const SizedBox(height: 28),

      Text('Picture of the Farm',
        style: GoogleFonts.poppins(
            fontSize: 14, fontWeight: FontWeight.w700, color: DAColors.textDark)),
      const SizedBox(height: 10),

      if (_photoPath.isNotEmpty) ...[
        Stack(children: [
          ClipRRect(borderRadius: BorderRadius.circular(14),
            child: Container(width: double.infinity, height: 180,
              color: DAColors.greenLight.withOpacity(0.2),
              child: const Icon(Icons.image_rounded, size: 64, color: DAColors.greenMid))),
          Positioned(top: 8, right: 8,
            child: GestureDetector(onTap: () => setState(() => _photoPath = ''),
              child: Container(width: 32, height: 32,
                decoration: BoxDecoration(color: Colors.red.shade400, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 18)))),
        ]),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => setState(() => _photoPath = 'farm_photo.jpg'),
          child: Container(width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: DAColors.greenMid.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: DAColors.greenMid, width: 1.5)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.camera_alt_outlined, color: DAColors.greenMid, size: 22),
              const SizedBox(width: 8),
              Text('Retake Photo', style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w600, color: DAColors.greenMid)),
            ]))),
      ] else
        GestureDetector(
          onTap: () => setState(() => _photoPath = 'farm_photo.jpg'),
          child: Container(width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: DAColors.greenMid,
              borderRadius: BorderRadius.circular(16)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Padding(padding: const EdgeInsets.only(left: 24),
                child: Text('Take Photo', style: GoogleFonts.bebasNeue(
                    fontSize: 24, color: Colors.white, letterSpacing: 1))),
              const Padding(padding: EdgeInsets.only(right: 24),
                child: Icon(Icons.camera_alt_outlined, color: Colors.white, size: 32)),
            ]))),

      const SizedBox(height: 32),
    ]);
  }
}

class _ModalOption extends StatelessWidget {
  const _ModalOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
  final IconData     icon;
  final String       title;
  final String       subtitle;
  final Color        color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1.5)),
      child: Row(children: [
        Container(width: 44, height: 44,
          decoration: BoxDecoration(
            color:        color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22)),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.poppins(
              fontSize: 14, fontWeight: FontWeight.w700,
              color: DAColors.textDark)),
            const SizedBox(height: 2),
            Text(subtitle, style: GoogleFonts.poppins(
              fontSize: 12, color: DAColors.textMuted)),
          ],
        )),
        Icon(Icons.chevron_right_rounded, color: color, size: 22),
      ]),
    ),
  );
}