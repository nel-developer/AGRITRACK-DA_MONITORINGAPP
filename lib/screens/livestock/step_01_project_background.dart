import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/da_colors.dart';
import '../../routes/app_routes.dart';
import 'livestock_step_wrapper.dart';
import '../../widgets/crop_form_shell.dart';
import '../../widgets/crop_field.dart';
import '../../widgets/crop_dropdown.dart';

class LivestockStep1ProjectBackground extends StatefulWidget {
  const LivestockStep1ProjectBackground({super.key, required this.controller});
  final LivestockStepWrapper controller;

  @override
  State<LivestockStep1ProjectBackground> createState() =>
      _LivestockStep1ProjectBackgroundState();
}

class _LivestockStep1ProjectBackgroundState
    extends State<LivestockStep1ProjectBackground> {
  LivestockStepWrapper get c => widget.controller;
  static const bool _testingAllowEmptyFields = true;

  // ── Generate reporting period years (last 3 years + next 2 years) ──
  List<String> _getReportingPeriodYears() {
    final now = DateTime.now();
    final currentYear = now.year;
    final years = <String>[];
    for (int i = currentYear - 3; i <= currentYear + 2; i++) {
      years.add(i.toString());
    }
    return years;
  }

  final List<String> _supportInterventions = [''];

  static const _regions = ['Region IV-A (CALABARZON)'];

  static const _provinces = {
    'Region IV-A (CALABARZON)': [
      'Batangas',
      'Cavite',
      'Laguna',
      'Quezon',
      'Rizal',
    ],
  };

  static const _municipalities = {
    'Batangas': [
      'Agoncillo',
      'Alitagtag',
      'Balayan',
      'Balete',
      'Batangas City',
      'Bauan',
      'Calaca',
      'Calatagan',
      'Cuenca',
      'Ibaan',
      'Laurel',
      'Lemery',
      'Lian',
      'Lipa City',
      'Lobo',
      'Mabini',
      'Malvar',
      'Mataas na Kahoy',
      'Nasugbu',
      'Padre Garcia',
      'Rosario',
      'San Jose',
      'San Juan',
      'San Luis',
      'San Nicolas',
      'San Pascual',
      'Santa Teresita',
      'Santo Tomas',
      'Taal',
      'Talisay',
      'Tanauan City',
      'Taysan',
      'Tingloy',
      'Tuy'
    ],
    'Cavite': [
      'Alfonso',
      'Amadeo',
      'Bacoor City',
      'Carmona',
      'Cavite City',
      'Dasmariñas City',
      'General Emilio Aguinaldo',
      'General Mariano Alvarez',
      'General Trias City',
      'Imus City',
      'Indang',
      'Kawit',
      'Magallanes',
      'Maragondon',
      'Mendez',
      'Naic',
      'Noveleta',
      'Rosario',
      'Silang',
      'Tagaytay City',
      'Tanza',
      'Ternate',
      'Trece Martires City'
    ],
    'Laguna': [
      'Alaminos',
      'Bay',
      'Biñan City',
      'Cabuyao City',
      'Calamba City',
      'Calauan',
      'Cavinti',
      'Famy',
      'Kalayaan',
      'Liliw',
      'Los Baños',
      'Luisiana',
      'Lumban',
      'Mabitac',
      'Magdalena',
      'Majayjay',
      'Nagcarlan',
      'Paete',
      'Pagsanjan',
      'Pakil',
      'Pangil',
      'Pila',
      'Rizal',
      'San Pablo City',
      'San Pedro City',
      'Santa Cruz',
      'Santa Maria',
      'Santa Rosa City',
      'Siniloan',
      'Victoria'
    ],
    'Quezon': [
      'Agdangan',
      'Alabat',
      'Atimonan',
      'Buenavista',
      'Burdeos',
      'Calauag',
      'Candelaria',
      'Catanauan',
      'Dolores',
      'General Luna',
      'General Nakar',
      'Guinayangan',
      'Gumaca',
      'Infanta',
      'Jomalig',
      'Lopez',
      'Lucban',
      'Lucena City',
      'Macalelon',
      'Mauban',
      'Mulanay',
      'Padre Burgos',
      'Pagbilao',
      'Panukulan',
      'Patnanungan',
      'Perez',
      'Pitogo',
      'Plaridel',
      'Polillo',
      'Quezon',
      'Real',
      'Sampaloc',
      'San Andres',
      'San Antonio',
      'San Francisco',
      'San Narciso',
      'Sariaya',
      'Tagkawayan',
      'Tayabas City',
      'Tiaong',
      'Unisan'
    ],
    'Rizal': [
      'Angono',
      'Antipolo City',
      'Baras',
      'Binangonan',
      'Cainta',
      'Cardona',
      'Jala-Jala',
      'Morong',
      'Pililla',
      'Rodriguez',
      'San Mateo',
      'Taytay',
      'Teresa',
      'Tanay'
    ],
  };

  static const _barangays = <String, List<String>>{
    'Batangas City': [
      'Balagtas',
      'Balete',
      'Banaba Center',
      'Banaba Ibaba',
      'Banaba Kanluran',
      'Banaba Silangan',
      'Bolbok',
      'Bukal',
      'Cumba',
      'Dela Paz',
      'Gulod Itaas',
      'Gulod Labac',
      'Haligue Kanluran',
      'Haligue Silangan',
      'Ilijan',
      'Kumba',
      'Kumintang Ibaba',
      'Kumintang Ilaya',
      'Libjo',
      'Liponpon',
      'Maapaz',
      'Mabacong',
      'Malagasang',
      'Malamig',
      'Manghinao Proper',
      'Pagkilatan',
      'Paharang Kanluran',
      'Paharang Silangan',
      'Pallocan Kanluran',
      'Pallocan Silangan',
      'Pinamucan Ibaba',
      'Pinamucan Proper',
      'Pinamucan Silangan',
      'Sampaga',
      'San Agapito',
      'San Agustin Kanluran',
      'San Agustin Silangan',
      'San Isidro',
      'San Jose Sico',
      'San Miguel',
      'San Pedro',
      'Simlong',
      'Sirang Lupa',
      'Sorosoro Ibaba',
      'Sorosoro Ilaya',
      'Sorosoro Karsada',
      'Sta. Clara',
      'Sta. Rita Aplaya',
      'Sta. Rita Karsada',
      'Sto. Domingo',
      'Sto. Niño',
      'Tabangao Ambulong',
      'Tabangao Aplaya',
      'Tabangao Dao',
      'Talahib Pandayan',
      'Talahib Payaba',
      'Talumpok Kanluran',
      'Talumpok Silangan',
      'Tingga Itaas',
      'Tingga Labac',
      'Tulo',
      'Wawa'
    ],
    'Antipolo City': [
      'Bagong Nayon',
      'Beverly Hills',
      'Calawis',
      'Cupang',
      'Dalig',
      'Dela Paz',
      'Evangelista',
      'Guinayang',
      'Mambugan',
      'Mayamot',
      'Muntingdilaw',
      'San Isidro',
      'San Jose',
      'San Juan',
      'San Luis',
      'San Roque',
      'Santa Cruz',
      'Santo Niño'
    ],
    'Lucena City': [
      'Barangay I (Pob.)',
      'Barangay II (Pob.)',
      'Barangay III (Pob.)',
      'Barangay IV (Pob.)',
      'Barangay V (Pob.)',
      'Barangay VI (Pob.)',
      'Barangay VII (Pob.)',
      'Barangay VIII (Pob.)',
      'Barangay IX (Pob.)',
      'Barangay X (Pob.)',
      'Barangay XI (Pob.)',
      'Bocohan',
      'Cotta',
      'Dalahican',
      'Domoit Kanluran',
      'Domoit Silangan',
      'Gulang-Gulang',
      'Ibabang Dupay',
      'Ibabang Iyam',
      'Ibabang Talim',
      'Ilayang Dupay',
      'Ilayang Iyam',
      'Ilayang Talim',
      'Isabang',
      'Market View',
      'Mayao Castillo',
      'Mayao Crossing',
      'Mayao Kanluran',
      'Mayao Parada',
      'Mayao Silangan',
      'Ransohan',
      'Salinas I',
      'Salinas II',
      'Salinas III',
      'Salinas IV',
      'Talao-Talao'
    ],
  };

  static const _primaryInterventions = [
    'Carabao',
    'Goat',
    'Swine',
    'Cattle',
    'Others',
  ];

  String _othersSpecify = '';

  bool _canProceed() {
    // Purpose of production required for ALL implementation types
    final purposeSelected =
        c.purposeBreeding || c.purposeMeat || c.purposeDairy;
    return c.fcaName.isNotEmpty &&
        c.region != null &&
        c.province != null &&
        c.municipality != null &&
        c.barangay != null &&
        c.projectTitle.isNotEmpty &&
        c.primaryIntervention != null &&
        purposeSelected;
  }

  void _next() {
    if (!_testingAllowEmptyFields && !_canProceed()) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please fill in all required fields.',
            style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    c.supportInterventions =
        _supportInterventions.where((s) => s.trim().isNotEmpty).toList();
    Navigator.of(context).pushNamed(AppRoutes.livestockStep2, arguments: c);
  }

  @override
  Widget build(BuildContext context) {
    return CropFormShell(
      formTitle: 'LIVESTOCK PRODUCTION',
      formSubtitle: 'Livestock Production Monitoring Form',
      currentStep: 0,
      onNext: _next,
      child: _buildForm(),
    );
  }

  Widget _buildForm() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('Project Background'),
      const SizedBox(height: 24),
      CropDropdown(
        label: 'Reporting Period',
        hint: 'Select Year',
        value: c.reportingPeriod.isNotEmpty ? c.reportingPeriod : null,
        items: _getReportingPeriodYears(),
        onChanged: (v) => setState(() => c.reportingPeriod = v ?? ''),
      ),
      const SizedBox(height: 20),
      CropField(
          label: 'FCA Name',
          hint: 'Enter FCA Name',
          initialValue: c.fcaName,
          onChanged: (v) => c.fcaName = v),
      const SizedBox(height: 20),
      CropDropdown(
          label: 'Region',
          hint: 'Choose Region',
          value: c.region,
          items: _regions,
          onChanged: (v) => setState(() {
                c.region = v;
                c.province = null;
                c.municipality = null;
                c.barangay = null;
              })),
      const SizedBox(height: 20),
      CropDropdown(
          label: 'Province',
          hint: 'Choose Province',
          value: c.province,
          items: c.region != null ? (_provinces[c.region!] ?? []) : [],
          enabled: c.region != null,
          onChanged: (v) => setState(() {
                c.province = v;
                c.municipality = null;
                c.barangay = null;
              })),
      const SizedBox(height: 20),
      CropDropdown(
          label: 'Municipality',
          hint: 'Choose Municipality',
          value: c.municipality,
          items: c.province != null ? (_municipalities[c.province!] ?? []) : [],
          enabled: c.province != null,
          onChanged: (v) => setState(() {
                c.municipality = v;
                c.barangay = null;
              })),
      const SizedBox(height: 20),
      CropDropdown(
          label: 'Barangay',
          hint: 'Choose Barangay',
          value: c.barangay,
          items: c.municipality != null
              ? (_barangays[c.municipality!] ??
                  ['Barangay 1', 'Barangay 2', 'Barangay 3'])
              : [],
          enabled: c.municipality != null,
          onChanged: (v) => setState(() => c.barangay = v)),
      const SizedBox(height: 20),
      CropField(
          label: 'Project Title',
          hint: 'Based on BEDs submission',
          initialValue: c.projectTitle,
          onChanged: (v) => c.projectTitle = v),
      const SizedBox(height: 20),
      CropDropdown(
          label: 'Primary Intervention Provided',
          hint: 'Choose livestock raised',
          value: c.primaryIntervention,
          items: _primaryInterventions,
          onChanged: (v) => setState(() => c.primaryIntervention = v)),
      if (c.primaryIntervention == 'Others') ...[
        const SizedBox(height: 12),
        CropField(
            label: 'Please specify',
            hint: 'Enter primary intervention',
            initialValue: _othersSpecify,
            onChanged: (v) => _othersSpecify = v),
      ],
      const SizedBox(height: 20),
      _buildLabel('Support Intervention Provided'),
      const SizedBox(height: 8),
      ..._supportInterventions.asMap().entries.map((entry) {
        final i = entry.key;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(
              child: SizedBox(
                height: 56,
                child: TextFormField(
                  initialValue: _supportInterventions[i],
                  onChanged: (v) => _supportInterventions[i] = v,
                  style: GoogleFonts.poppins(
                      fontSize: 14, color: DAColors.textDark),
                  decoration: InputDecoration(
                    hintText: 'Enter support intervention',
                    hintStyle: GoogleFonts.poppins(
                        fontSize: 14, color: DAColors.textMuted),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: false,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 16),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: Color(0xFFDDDDDD), width: 1.5)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: Color(0xFFDDDDDD), width: 1.5)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: DAColors.greenMid, width: 2.0)),
                  ),
                ),
              ),
            ),
            if (i > 0) ...[
              const SizedBox(width: 8),
              GestureDetector(
                  onTap: () =>
                      setState(() => _supportInterventions.removeAt(i)),
                  child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                          color: Colors.red.shade50, shape: BoxShape.circle),
                      child: Icon(Icons.close_rounded,
                          color: Colors.red.shade400, size: 16))),
            ] else
              const SizedBox(width: 40),
          ]),
        );
      }),
      GestureDetector(
        onTap: () => setState(() => _supportInterventions.add('')),
        child: Row(children: [
          Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                  color: DAColors.greenMid, shape: BoxShape.circle),
              child:
                  const Icon(Icons.add_rounded, color: Colors.white, size: 18)),
          const SizedBox(width: 8),
          Text('Add Another',
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: DAColors.greenMid)),
        ]),
      ),
      // Purpose fields shown for ALL production types (individual, collective, hybrid)
      const SizedBox(height: 28),
      _buildLabel('Purpose of Production'),
      const SizedBox(height: 12),
      _buildCheckbox(
          label: 'Breeding',
          value: c.purposeBreeding,
          onChanged: (v) => setState(() => c.purposeBreeding = v ?? false)),
      const SizedBox(height: 10),
      _buildCheckbox(
          label: 'Meat / Fattener',
          value: c.purposeMeat,
          onChanged: (v) => setState(() => c.purposeMeat = v ?? false)),
      const SizedBox(height: 10),
      _buildCheckbox(
          label: 'Dairy',
          value: c.purposeDairy,
          onChanged: (v) => setState(() => c.purposeDairy = v ?? false)),
      const SizedBox(height: 32),
    ]);
  }

  Widget _buildCheckbox(
          {required String label,
          required bool value,
          required ValueChanged<bool?> onChanged}) =>
      GestureDetector(
        onTap: () => onChanged(!value),
        child: Row(children: [
          AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                  color: value ? DAColors.greenMid : Colors.white,
                  border: Border.all(
                      color: value ? DAColors.greenMid : Colors.grey.shade400,
                      width: 1.8),
                  borderRadius: BorderRadius.circular(5)),
              child: value
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14)
                  : null),
          const SizedBox(width: 12),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: DAColors.textDark)),
        ]),
      );

  Widget _sectionTitle(String t) => Text(t,
      style: GoogleFonts.poppins(
          fontSize: 22, fontWeight: FontWeight.w800, color: DAColors.textDark));

  Widget _buildLabel(String t) => Text(t,
      style: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w700, color: DAColors.textDark));
}
