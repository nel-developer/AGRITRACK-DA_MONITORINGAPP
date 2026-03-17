import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/da_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/crop_form_shell.dart';
import '../../widgets/crop_field.dart';
import '../../widgets/crop_dropdown.dart';
import 'poultry_step_wrapper.dart';

class PoultryStep1ProjectBackground extends StatefulWidget {
  const PoultryStep1ProjectBackground({super.key, required this.controller});
  final PoultryStepWrapper controller;

  @override
  State<PoultryStep1ProjectBackground> createState() => _PoultryStep1State();
}

class _PoultryStep1State extends State<PoultryStep1ProjectBackground> {
  PoultryStepWrapper get c => widget.controller;

  final List<String> _supportInterventions = [''];

  static const _regions = ['Region IV-A (CALABARZON)'];

  static const _provinces = {
    'Region IV-A (CALABARZON)': [
      'Batangas', 'Cavite', 'Laguna', 'Quezon', 'Rizal',
    ],
  };

  static const _municipalities = {
    'Batangas': ['Agoncillo','Alitagtag','Balayan','Balete','Batangas City','Bauan','Calaca','Calatagan','Cuenca','Ibaan','Laurel','Lemery','Lian','Lipa City','Lobo','Mabini','Malvar','Mataas na Kahoy','Nasugbu','Padre Garcia','Rosario','San Jose','San Juan','San Luis','San Nicolas','San Pascual','Santa Teresita','Santo Tomas','Taal','Talisay','Tanauan City','Taysan','Tingloy','Tuy'],
    'Cavite': ['Alfonso','Amadeo','Bacoor City','Carmona','Cavite City','Dasmariñas City','General Emilio Aguinaldo','General Mariano Alvarez','General Trias City','Imus City','Indang','Kawit','Magallanes','Maragondon','Mendez','Naic','Noveleta','Rosario','Silang','Tagaytay City','Tanza','Ternate','Trece Martires City'],
    'Laguna': ['Alaminos','Bay','Biñan City','Cabuyao City','Calamba City','Calauan','Cavinti','Famy','Kalayaan','Liliw','Los Baños','Luisiana','Lumban','Mabitac','Magdalena','Majayjay','Nagcarlan','Paete','Pagsanjan','Pakil','Pangil','Pila','Rizal','San Pablo City','San Pedro City','Santa Cruz','Santa Maria','Santa Rosa City','Siniloan','Victoria'],
    'Quezon': ['Agdangan','Alabat','Atimonan','Buenavista','Burdeos','Calauag','Candelaria','Catanauan','Dolores','General Luna','General Nakar','Guinayangan','Gumaca','Infanta','Jomalig','Lopez','Lucban','Lucena City','Macalelon','Mauban','Mulanay','Padre Burgos','Pagbilao','Panukulan','Patnanungan','Perez','Pitogo','Plaridel','Polillo','Quezon','Real','Sampaloc','San Andres','San Antonio','San Francisco','San Narciso','Sariaya','Tagkawayan','Tayabas City','Tiaong','Unisan'],
    'Rizal': ['Angono','Antipolo City','Baras','Binangonan','Cainta','Cardona','Jala-Jala','Morong','Pililla','Rodriguez','San Mateo','Taytay','Teresa','Tanay'],
  };

  static const _barangays = <String, List<String>>{
    'Batangas City': ['Balagtas','Balete','Banaba Center','Banaba Ibaba','Banaba Kanluran','Banaba Silangan','Bolbok','Bukal','Cumba','Dela Paz','Gulod Itaas','Gulod Labac','Haligue Kanluran','Haligue Silangan','Ilijan','Kumba','Kumintang Ibaba','Kumintang Ilaya','Libjo','Liponpon','Maapaz','Mabacong','Malagasang','Malamig','Manghinao Proper','Pagkilatan','Paharang Kanluran','Paharang Silangan','Pallocan Kanluran','Pallocan Silangan','Pinamucan Ibaba','Pinamucan Proper','Pinamucan Silangan','Sampaga','San Agapito','San Agustin Kanluran','San Agustin Silangan','San Isidro','San Jose Sico','San Miguel','San Pedro','Simlong','Sirang Lupa','Sorosoro Ibaba','Sorosoro Ilaya','Sorosoro Karsada','Sta. Clara','Sta. Rita Aplaya','Sta. Rita Karsada','Sto. Domingo','Sto. Niño','Tabangao Ambulong','Tabangao Aplaya','Tabangao Dao','Talahib Pandayan','Talahib Payaba','Talumpok Kanluran','Talumpok Silangan','Tingga Itaas','Tingga Labac','Tulo','Wawa'],
    'Antipolo City': ['Bagong Nayon','Beverly Hills','Calawis','Cupang','Dalig','Dela Paz','Evangelista','Guinayang','Mambugan','Mayamot','Muntingdilaw','San Isidro','San Jose','San Juan','San Luis','San Roque','Santa Cruz','Santo Niño'],
    'Lucena City': ['Barangay I (Pob.)','Barangay II (Pob.)','Barangay III (Pob.)','Barangay IV (Pob.)','Barangay V (Pob.)','Barangay VI (Pob.)','Barangay VII (Pob.)','Barangay VIII (Pob.)','Barangay IX (Pob.)','Barangay X (Pob.)','Barangay XI (Pob.)','Bocohan','Cotta','Dalahican','Domoit Kanluran','Domoit Silangan','Gulang-Gulang','Ibabang Dupay','Ibabang Iyam','Ibabang Talim','Ilayang Dupay','Ilayang Iyam','Ilayang Talim','Isabang','Market View','Mayao Castillo','Mayao Crossing','Mayao Kanluran','Mayao Parada','Mayao Silangan','Ransohan','Salinas I','Salinas II','Salinas III','Salinas IV','Talao-Talao'],
  };

  static const _primaryInterventions = [
    'Chicken',
    'Others',
  ];

  static const _purposeOptions = [
    'Breeding',
    'Meat / Broiler',
    'Egg / Layer',
  ];

  bool _canProceed() {
    return c.reportingPeriod.isNotEmpty &&
        c.fcaName.isNotEmpty &&
        c.region != null &&
        c.province != null &&
        c.municipality != null &&
        c.barangay != null &&
        c.projectTitle.isNotEmpty &&
        c.primaryIntervention != null &&
        (c.purposeBreeding || c.purposeMeat || c.purposeEgg);
  }

  // Map dropdown value → wrapper booleans
  String? get _purposeValue {
    if (c.purposeBreeding) return 'Breeding';
    if (c.purposeMeat)     return 'Meat / Broiler';
    if (c.purposeEgg)      return 'Egg / Layer';
    return null;
  }

  void _setPurpose(String? v) {
    setState(() {
      c.purposeBreeding = v == 'Breeding';
      c.purposeMeat     = v == 'Meat / Broiler';
      c.purposeEgg      = v == 'Egg / Layer';
    });
  }

  void _next() {
    if (!_canProceed()) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please fill in all required fields.',
            style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    c.supportInterventions = _supportInterventions
        .where((s) => s.trim().isNotEmpty)
        .toList();
    Navigator.of(context).pushNamed(AppRoutes.poultryStep2, arguments: c);
  }

  @override
  Widget build(BuildContext context) {
    final implLabel = _implLabel(c.implementationType);
    return CropFormShell(
      formTitle:          'POULTRY PRODUCTION',
      formSubtitle:       implLabel,
      currentStep:        0,
      totalSteps:         7,
      onNext:             _next,
      child:              _buildForm(),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        _sectionTitle('Project Background'),
        const SizedBox(height: 24),

        CropField(
          label: 'Reporting Period',
          hint:  'e.g. 2026',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          initialValue: c.reportingPeriod,
          onChanged: (v) => c.reportingPeriod = v,
        ),
        const SizedBox(height: 20),

        CropField(
          label: 'FCA Name',
          hint:  'Enter FCA Name',
          initialValue: c.fcaName,
          onChanged: (v) => c.fcaName = v,
        ),
        const SizedBox(height: 20),

        CropDropdown(
          label: 'Region',
          hint:  'Choose Region',
          value: c.region,
          items: _regions,
          onChanged: (v) => setState(() {
            c.region = v; c.province = null;
            c.municipality = null; c.barangay = null;
          }),
        ),
        const SizedBox(height: 20),

        CropDropdown(
          label:   'Province',
          hint:    'Choose Province',
          value:   c.province,
          items:   c.region != null ? (_provinces[c.region!] ?? []) : [],
          enabled: c.region != null,
          onChanged: (v) => setState(() {
            c.province = v; c.municipality = null; c.barangay = null;
          }),
        ),
        const SizedBox(height: 20),

        CropDropdown(
          label:   'Municipality',
          hint:    'Choose Municipality',
          value:   c.municipality,
          items:   c.province != null
              ? (_municipalities[c.province!] ?? []) : [],
          enabled: c.province != null,
          onChanged: (v) => setState(() {
            c.municipality = v; c.barangay = null;
          }),
        ),
        const SizedBox(height: 20),

        CropDropdown(
          label:   'Barangay',
          hint:    'Choose Barangay',
          value:   c.barangay,
          items:   c.municipality != null
              ? (_barangays[c.municipality!] ??
                  ['Barangay 1', 'Barangay 2', 'Barangay 3'])
              : [],
          enabled: c.municipality != null,
          onChanged: (v) => setState(() => c.barangay = v),
        ),
        const SizedBox(height: 20),

        CropField(
          label: 'Project Title',
          hint:  'Based on BEDs submission',
          initialValue: c.projectTitle,
          onChanged: (v) => c.projectTitle = v,
        ),
        const SizedBox(height: 20),

        CropDropdown(
          label: 'Primary Intervention Provided',
          hint:  'Choose',
          value: c.primaryIntervention,
          items: _primaryInterventions,
          onChanged: (v) => setState(() => c.primaryIntervention = v),
        ),
        if (c.primaryIntervention == 'Others') ...[
          const SizedBox(height: 12),
          CropField(
            label: 'Please specify',
            hint:  'Enter primary intervention',
            initialValue: '',
            onChanged: (v) {},
          ),
        ],
        const SizedBox(height: 20),

        // ── Support Interventions ─────────────────────────────
        _buildLabel('Support intervention provided'),
        const SizedBox(height: 8),
        ..._supportInterventions.asMap().entries.map((entry) {
          final i = entry.key;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: TextFormField(
                      initialValue: _supportInterventions[i],
                      onChanged:    (v) => _supportInterventions[i] = v,
                      style: GoogleFonts.poppins(
                          fontSize: 14, color: DAColors.textDark),
                      decoration: InputDecoration(
                        hintText:  'Enter support intervention',
                        hintStyle: GoogleFonts.poppins(
                            fontSize: 14, color: DAColors.textMuted),
                        filled: true, fillColor: Colors.white,
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
                    onTap: () => setState(
                        () => _supportInterventions.removeAt(i)),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          shape: BoxShape.circle),
                      child: Icon(Icons.close_rounded,
                          color: Colors.red.shade400, size: 16)),
                  ),
                ] else
                  const SizedBox(width: 40),
              ],
            ),
          );
        }),

        GestureDetector(
          onTap: () => setState(() => _supportInterventions.add('')),
          child: Row(children: [
            Container(width: 28, height: 28,
              decoration: const BoxDecoration(
                  color: DAColors.greenMid, shape: BoxShape.circle),
              child: const Icon(Icons.add_rounded,
                  color: Colors.white, size: 18)),
            const SizedBox(width: 8),
            Text('Add Another', style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: DAColors.greenMid)),
          ]),
        ),
        const SizedBox(height: 20),

        // ── Purpose of Production — dropdown ──────────────────
        CropDropdown(
          label:     'Purpose of Production',
          hint:      'Choose',
          value:     _purposeValue,
          items:     _purposeOptions,
          onChanged: _setPurpose,
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  String _implLabel(String? type) {
    switch (type) {
      case 'individual': return 'Individually Managed';
      case 'collective': return 'Collectively Managed';
      case 'hybrid':     return 'Hybrid';
      default:           return 'Poultry Production Monitoring Form';
    }
  }

  Widget _sectionTitle(String t) => Text(t,
    style: GoogleFonts.poppins(
        fontSize: 22, fontWeight: FontWeight.w800, color: DAColors.textDark));

  Widget _buildLabel(String t) => Text(t,
    style: GoogleFonts.poppins(
        fontSize: 14, fontWeight: FontWeight.w700, color: DAColors.textDark));
}