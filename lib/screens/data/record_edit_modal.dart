import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/da_colors.dart';
import '../../widgets/record_card.dart';
import '../../widgets/crop_dropdown.dart';

class RecordEditModal extends StatefulWidget {
  const RecordEditModal({super.key, required this.record});
  final RecordModel record;

  @override
  State<RecordEditModal> createState() => _RecordEditModalState();
}

class _RecordEditModalState extends State<RecordEditModal> {

  String get _type => widget.record.productionType.toLowerCase();

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final botPad  = MediaQuery.of(context).padding.bottom;

    return Container(
      height: screenH * 0.92,
      decoration: const BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(children: [

        // Green header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 8, 14),
          decoration: const BoxDecoration(color: DAColors.greenDark),
          child: Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Edit Record',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 22, color: Colors.white, letterSpacing: 2)),
                Text(widget.record.name,
                  style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.white.withOpacity(0.85),
                    fontStyle: FontStyle.italic)),
              ],
            )),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded, color: Colors.white)),
          ]),
        ),

        // Form body
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: _type == 'crop'
                ? _CropEditForm()
                : _type == 'livestock'
                    ? _LivestockEditForm()
                    : _PoultryEditForm(),
          ),
        ),

        // Save button
        Container(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + botPad),
          decoration: BoxDecoration(
            color:  Colors.white,
            border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1))),
          child: SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Changes saved!',
                    style: GoogleFonts.poppins(fontSize: 13)),
                  backgroundColor: DAColors.greenMid,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: DAColors.greenMid,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50))),
              child: Text('Save Changes',
                style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w700,
                  color: Colors.white)),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Shared form helpers ───────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 12),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(10)),
      alignment: Alignment.center,
      child: Text(title,
        style: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w700,
          color: DAColors.textDark)),
    ),
  );
}

InputDecoration _fieldDeco(String hint) => InputDecoration(
  hintText:  hint,
  hintStyle: GoogleFonts.poppins(fontSize: 14, color: DAColors.textMuted),
  filled: true, fillColor: Colors.white,
  isDense: true,
  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFDDDDDD), width: 1.5)),
  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFDDDDDD), width: 1.5)),
  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: DAColors.greenMid, width: 2.0)),
);

Widget _lbl(String t) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: Text(t, style: GoogleFonts.poppins(
    fontSize: 14, fontWeight: FontWeight.w700, color: DAColors.textDark)));

Widget _field(String hint, String initial, {TextInputType kb = TextInputType.text}) =>
  TextFormField(
    initialValue: initial,
    keyboardType: kb,
    style: GoogleFonts.poppins(fontSize: 14, color: DAColors.textDark),
    decoration: _fieldDeco(hint),
  );

Widget _row2(String l1, String v1, String l2, String v2, {TextInputType kb = TextInputType.text}) =>
  Row(children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _lbl(l1), _field(l1, v1, kb: kb),
    ])),
    const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _lbl(l2), _field(l2, v2, kb: kb),
    ])),
  ]);

Widget _gap() => const SizedBox(height: 16);

// ── CROP edit form ────────────────────────────────────────────────
class _CropEditForm extends StatefulWidget {
  @override
  State<_CropEditForm> createState() => _CropEditFormState();
}

class _CropEditFormState extends State<_CropEditForm> {
  String? _primaryIntervention = 'Any Fruit';
  String? _fertilizerType      = 'Organic';
  String? _landOwnership       = 'Owned';

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      // ── Project Background ──────────────────────────────────
      const _SectionHeader(title: 'Project Background'),
      _row2('Reporting Period', '2026', 'FCA Name', 'Maharlika FCA'),
      _gap(),
      _row2('Region', 'Region IV-A (CALABARZON)', 'Province', 'Batangas'),
      _gap(),
      _row2('Municipality', 'Cuenca', 'Barangay', 'Bungahan'),
      _gap(),
      _lbl('Project Title'),
      _field('Enter Project Title', 'SAAD 2026 Crop Production'),
      _gap(),
      CropDropdown(label: 'Primary Intervention Provided', hint: 'Choose',
        value: _primaryIntervention,
        items: const ['Any Fruit', 'Any Vegetables', 'Coconut', 'Others'],
        onChanged: (v) => setState(() => _primaryIntervention = v)),
      _gap(),
      _lbl('Support Intervention Provided'),
      _field('Enter support intervention', 'Fertilizers'),

      // ── Commodity Information ───────────────────────────────
      const _SectionHeader(title: 'Commodity Information'),
      _row2('Name of Farmer', 'Juan Dela Cruz', 'Type of Crop', 'Banana'),
      _gap(),
      _row2('Variety', 'Lakatan', 'Farmgate Price (₱/kg)', '25',
          kb: TextInputType.number),
      _gap(),
      _lbl('Total Cost of Inputs Purchased'),
      _field('Enter total cost', '2500', kb: TextInputType.number),
      _gap(),
      _row2('Cropping Cycles/Year', '2', 'Peak Volume', '500 kg',
          kb: TextInputType.number),

      // ── Planting Stage ──────────────────────────────────────
      const _SectionHeader(title: 'Planting Stage'),
      _row2('Total Land Area (ha)', '1.5', 'Source of Water', 'Rainfall',
          kb: TextInputType.number),
      _gap(),
      CropDropdown(label: 'Land Ownership', hint: 'Choose',
        value: _landOwnership,
        items: const ['Owned', 'Rented', 'Shared', 'Others'],
        onChanged: (v) => setState(() => _landOwnership = v)),
      _gap(),
      _row2('Planting Date', '2026-01-10', 'Seed Amount (kg)', '50',
          kb: TextInputType.number),
      _gap(),
      _row2('Germination Rate (%)', '85', 'Land Prep Days', '7',
          kb: TextInputType.number),

      // ── Fertilization ───────────────────────────────────────
      const _SectionHeader(title: 'Fertilization'),
      CropDropdown(label: 'Fertilizer Type', hint: 'Choose',
        value: _fertilizerType,
        items: const ['Organic', 'Inorganic', 'Both'],
        onChanged: (v) => setState(() => _fertilizerType = v)),
      _gap(),
      _row2('Bags from SAAD', '10', 'Total Cost (₱)', '2500',
          kb: TextInputType.number),
      _gap(),
      _lbl('Pesticide Requirement'),
      _field('Enter', 'Malathion 50EC'),

      // ── Harvesting Stage ────────────────────────────────────
      const _SectionHeader(title: 'Harvesting Stage'),
      _row2('Total Harvested (kg)', '500', 'Avg Harvest/ha', '333',
          kb: TextInputType.number),
      _gap(),
      _row2('Food Consumption (%)', '10', 'Harvest Cost (₱)', '1000',
          kb: TextInputType.number),

      // ── Crop Damage ─────────────────────────────────────────
      const _SectionHeader(title: 'Crop Damage'),
      _row2('Damage Area', '0.5 ha', 'Damage (ha)', '0.5',
          kb: TextInputType.number),
      _gap(),
      _lbl('Treatment / Action Taken'),
      _field('Enter treatment', 'Applied pesticide'),

      // ── Trainings ───────────────────────────────────────────
      const _SectionHeader(title: 'Trainings Attended'),
      _lbl('Training (include date and no. of farmers)'),
      _field('Enter training', 'Crop Production Seminar — Jan 2026, 25 farmers'),

      const SizedBox(height: 32),
    ]);
  }
}

// ── LIVESTOCK edit form ───────────────────────────────────────────
class _LivestockEditForm extends StatefulWidget {
  @override
  State<_LivestockEditForm> createState() => _LivestockEditFormState();
}

class _LivestockEditFormState extends State<_LivestockEditForm> {
  String? _primaryIntervention = 'Goat';
  String? _housingType         = 'Semi-confinement';
  String? _landOwnership       = 'Owned';

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      // ── Project Background ──────────────────────────────────
      const _SectionHeader(title: 'Project Background'),
      _row2('FCA Name', 'Maharlika FCA', 'Region', 'Region IV-A (CALABARZON)'),
      _gap(),
      _row2('Municipality', 'Cuenca', 'Barangay', 'Bungahan'),
      _gap(),
      _lbl('Project Title'),
      _field('Enter Project Title', 'SAAD 2026 Livestock Production'),
      _gap(),
      CropDropdown(label: 'Primary Intervention Provided', hint: 'Choose',
        value: _primaryIntervention,
        items: const ['Carabao', 'Goat', 'Swine', 'Cattle', 'Others'],
        onChanged: (v) => setState(() => _primaryIntervention = v)),
      _gap(),
      _lbl('Support Intervention Provided'),
      _field('Enter support intervention', 'Veterinary supplies'),

      // ── Livestock Information ───────────────────────────────
      const _SectionHeader(title: 'Livestock Information'),
      _row2('Name of Farmer', 'Juan Dela Cruz', 'Breed', 'Anglo-Nubian'),
      _gap(),
      _lbl('Farmgate Price (₱/head)'),
      _field('Enter price', '3500', kb: TextInputType.number),

      // ── Production Information ──────────────────────────────
      const _SectionHeader(title: 'Production Information'),
      _row2('Stocks Received', '10', 'Date Received', '2026-01-05'),
      _gap(),
      _row2('Male Stocks', '3', 'Female Stocks', '7', kb: TextInputType.number),
      _gap(),
      _row2('M:F Ratio', '3:7', 'Age Upon Receipt (months)', '6'),
      _gap(),
      _row2('Avg Weight (kg)', '15', 'Pregnant Stocks', '2',
          kb: TextInputType.number),
      _gap(),
      CropDropdown(label: 'Type of Housing/Confinement', hint: 'Choose',
        value: _housingType,
        items: const ['Confinement','Semi-confinement','Free range','Pasture-based','Communal','Others'],
        onChanged: (v) => setState(() => _housingType = v)),
      _gap(),
      CropDropdown(label: 'Farm Ownership', hint: 'Choose',
        value: _landOwnership,
        items: const ['Owned', 'Rented', 'Others'],
        onChanged: (v) => setState(() => _landOwnership = v)),
      _gap(),
      _lbl('Waste Management Practices'),
      _field('Enter', 'Composting'),

      // ── Water and Feeding ───────────────────────────────────
      const _SectionHeader(title: 'Water and Feeding'),
      _lbl('Grazing Area (per head, with unit)'),
      _field('Enter', '0.5 ha/head'),
      _gap(),
      _lbl('Source/s of Water'),
      _field('Enter', 'Well water'),

      // ── Harvesting Information ──────────────────────────────
      const _SectionHeader(title: 'Harvesting Information'),
      _row2('Avg Marketable Weight (kg)', '25', 'Slaughtered Count', '5',
          kb: TextInputType.number),

      // ── Mortality Information ───────────────────────────────
      const _SectionHeader(title: 'Mortality Information'),
      _row2('Pest Mortality', '0', 'Disease Mortality', '1',
          kb: TextInputType.number),
      _gap(),
      _row2('Env. Mortality', '0', 'Human-induced Mortality', '0',
          kb: TextInputType.number),
      _gap(),
      _row2('Total Mortalities', '1', 'Remaining Stocks', '9',
          kb: TextInputType.number),
      _gap(),
      _lbl('Treatment / Action Taken'),
      _field('Enter treatment', 'Veterinary consultation'),

      // ── Trainings ───────────────────────────────────────────
      const _SectionHeader(title: 'Trainings Attended'),
      _lbl('Training (include date and no. of farmers)'),
      _field('Enter training', 'Livestock Production Seminar — Feb 2026, 20 farmers'),

      const SizedBox(height: 32),
    ]);
  }
}

// ── POULTRY edit form ─────────────────────────────────────────────
class _PoultryEditForm extends StatefulWidget {
  @override
  State<_PoultryEditForm> createState() => _PoultryEditFormState();
}

class _PoultryEditFormState extends State<_PoultryEditForm> {
  String? _primaryIntervention = 'Chicken';
  String? _purpose             = 'Meat / Broiler';
  String? _housingType         = 'Confinement';
  String? _landOwnership       = 'Owned';
  String? _feedType            = 'Finisher';

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      // ── Project Background ──────────────────────────────────
      const _SectionHeader(title: 'Project Background'),
      _row2('Reporting Period', '2026', 'FCA Name', 'Maharlika FCA'),
      _gap(),
      _row2('Region', 'Region IV-A (CALABARZON)', 'Province', 'Batangas'),
      _gap(),
      _row2('Municipality', 'Cuenca', 'Barangay', 'Bungahan'),
      _gap(),
      _lbl('Project Title'),
      _field('Enter Project Title', 'SAAD 2026 Poultry Production'),
      _gap(),
      CropDropdown(label: 'Primary Intervention Provided', hint: 'Choose',
        value: _primaryIntervention,
        items: const ['Chicken', 'Others'],
        onChanged: (v) => setState(() => _primaryIntervention = v)),
      _gap(),
      _lbl('Support Intervention Provided'),
      _field('Enter support intervention', 'Feeds, Vitamins'),
      _gap(),
      CropDropdown(label: 'Purpose of Production', hint: 'Choose',
        value: _purpose,
        items: const ['Breeding', 'Meat / Broiler', 'Egg / Layer'],
        onChanged: (v) => setState(() => _purpose = v)),

      // ── Poultry Information ─────────────────────────────────
      const _SectionHeader(title: 'Poultry Information'),
      _row2('Name of Farmer', 'Juan Dela Cruz', 'Breed', 'Native Chicken'),
      _gap(),
      _lbl('Farmgate Price (₱/kg)'),
      _field('Enter price', '180', kb: TextInputType.number),

      // ── Production Information ──────────────────────────────
      const _SectionHeader(title: 'Production Information'),
      _row2('Stocks Received', '100', 'Date Received', '2026-01-10'),
      _gap(),
      _row2('Age Upon Receipt', '1 day old', 'Avg Weight (g)', '40'),
      _gap(),
      _row2('Total Productive Cycle', '56 days', '', ''),
      _gap(),
      CropDropdown(label: 'Type of Housing/Confinement', hint: 'Choose',
        value: _housingType,
        items: const ['Confinement','Semi-confinement','Free range','Communal','Others'],
        onChanged: (v) => setState(() => _housingType = v)),
      _gap(),
      CropDropdown(label: 'Land Ownership', hint: 'Choose',
        value: _landOwnership,
        items: const ['Owned', 'Donated', 'Rented', 'Others'],
        onChanged: (v) => setState(() => _landOwnership = v)),
      _gap(),
      // Broiler fields
      _row2('Harvested Birds', '90', 'Total Weight Harvested (kg)', '180',
          kb: TextInputType.number),
      _gap(),
      _row2('ADG (g/day)', '22', 'Harvest Recovery (%)', '90',
          kb: TextInputType.number),
      _gap(),
      _row2('Avg Live Weight (kg)', '2', 'FCR (kg)', '2.5',
          kb: TextInputType.number),
      _gap(),
      _row2('Avg Age Harvested (days)', '56', 'BPI', '312',
          kb: TextInputType.number),

      // ── Mortality Information ───────────────────────────────
      const _SectionHeader(title: 'Mortality Information'),
      _row2('Pest Mortality', '0', 'Disease Mortality', '2',
          kb: TextInputType.number),
      _gap(),
      _row2('Env. Mortality', '0', 'Human-induced Mortality', '0',
          kb: TextInputType.number),
      _gap(),
      _row2('Total Mortalities', '2', 'Remaining Stocks', '98',
          kb: TextInputType.number),
      _gap(),
      _row2('Rejects/Culled', '0', 'Culled Sold', '0',
          kb: TextInputType.number),
      _gap(),
      _lbl('Treatment / Action Taken'),
      _field('Enter treatment', 'Biosecurity measures applied'),

      // ── Feeding and Water ───────────────────────────────────
      const _SectionHeader(title: 'Feeding and Water Management'),
      CropDropdown(label: 'Type of Feed Used', hint: 'Choose',
        value: _feedType,
        items: const ['Booster','Grower','Finisher','Laying pellet','Laying crumble','Laying mash','Others'],
        onChanged: (v) => setState(() => _feedType = v)),
      _gap(),
      _row2('Total Feed Consumed (kg)', '250', 'Feed per Day (g/hd)', '45',
          kb: TextInputType.number),
      _gap(),
      _lbl('Source/s of Water'),
      _field('Enter', 'Tap water'),

      // ── Waste Management ────────────────────────────────────
      const _SectionHeader(title: 'Waste Management'),
      _row2('Sacks Produced', '20', 'Sacks Sold', '15',
          kb: TextInputType.number),
      _gap(),
      _row2('Sacks Used', '5', 'Price per Sack (₱)', '80',
          kb: TextInputType.number),

      // ── Trainings ───────────────────────────────────────────
      const _SectionHeader(title: 'Trainings Attended'),
      _lbl('Training (include date and no. of farmers)'),
      _field('Enter training', 'Poultry Production Seminar — Jan 2026, 18 farmers'),

      const SizedBox(height: 32),
    ]);
  }
}