import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/approved_farmer.dart';
import '../../theme/da_colors.dart';
import '../../widgets/approved_farmer_picker_field.dart';
import '../../widgets/crop_form_shell.dart';
import '../../widgets/crop_field.dart';
import 'crop_step_wrapper.dart';
import '../../routes/app_routes.dart';

// Months list for month picker
const List<String> monthsList = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December'
];

// Crop types and their varieties mapping
const Map<String, List<String>> cropVarietiesMap = {
  'Maize': ['Yellow Dent', 'White Dent', 'Flint', 'Sweet Corn', 'Pop Corn'],
  'Rice': [
    'Long Grain',
    'Medium Grain',
    'Short Grain',
    'Aromatic',
    'Glutinous'
  ],
  'Wheat': [
    'Bread Wheat',
    'Durum Wheat',
    'Soft Wheat',
    'Spring Wheat',
    'Winter Wheat'
  ],
  'Beans': [
    'Black Beans',
    'Kidney Beans',
    'Pinto Beans',
    'Navy Beans',
    'Garbanzo'
  ],
  'Vegetables': [
    'Tomato',
    'Onion',
    'Cabbage',
    'Carrot',
    'Lettuce',
    'Pepper',
    'Cucumber',
    'Eggplant'
  ],
  'Root Crops': ['Potato', 'Sweet Potato', 'Cassava', 'Taro', 'Yam'],
  'Fruits': ['Banana', 'Mango', 'Coconut', 'Pineapple', 'Papaya', 'Avocado'],
  'Pulses': ['Lentils', 'Peas', 'Chickpeas', 'Pigeon Peas'],
  'Oilseeds': ['Sunflower', 'Canola', 'Soybean', 'Groundnut', 'Sesame'],
  'Cash Crops': ['Sugar Cane', 'Coffee', 'Cocoa', 'Tea', 'Tobacco'],
};

class CropStep2CommodityInformation extends StatefulWidget {
  const CropStep2CommodityInformation({super.key, required this.wrapper});
  final CropStepWrapper wrapper;

  @override
  State<CropStep2CommodityInformation> createState() => _CropStep2State();
}

class _CropStep2State extends State<CropStep2CommodityInformation> {
  CropStepWrapper get w => widget.wrapper;

  late final TextEditingController _farmerNameController;

  // Dynamic lists
  final List<InputReceived> _inputsReceived = [InputReceived()];
  final List<InputPurchased> _inputsPurchased = [InputPurchased()];
  final List<String> _volumesPerCycle = [''];

  // Single-value fields
  String _farmerName = '';
  String _typeOfCrop = '';
  String _variety = '';
  String _totalCostPurchased = '';
  String _qtyVsArea = '';
  String _croppingCycles = '';
  String _qtyVsCycles = '';
  String _peakVolume = '';
  String _peakMonth = '';
  String _farmgatePrice = '';

  // Show editable name field when:
  //   (a) explicitly adding a new farmer (isAddFarmer), or
  //   (b) fresh start with no name yet (individual, hybrid)
  //   (c) collective records should NOT show farmer name field
  bool get _showFarmerName =>
      w.isAddFarmer ||
      ((w.implementationType == 'individual' ||
              w.implementationType == 'hybrid') &&
          w.farmerName.isEmpty);

  @override
  void initState() {
    super.initState();

    print('🔍 Step02 initState:');
    print('   isAddFarmer: ${w.isAddFarmer}');
    print('   implementationType: ${w.implementationType}');
    print('   members count: ${w.members.length}');
    print('   members: ${w.members}');

    // For collective, use farmerName for the group entity name
    // For individual/hybrid, use farmerName as normal
    _farmerName = w.farmerName;

    _farmerNameController = TextEditingController(text: _farmerName);
    _typeOfCrop = w.typeOfCrop;
    _variety = w.variety;
    _totalCostPurchased = w.totalCostPurchased;
    _qtyVsArea = w.qtyVsArea;
    _croppingCycles = w.croppingCycles;
    _qtyVsCycles = w.qtyVsCycles;
    _peakVolume = w.peakVolume;
    _peakMonth = w.peakMonth;
    _farmgatePrice = w.farmgatePrice;

    _inputsReceived
      ..clear()
      ..addAll(
        (w.inputsReceived.isEmpty ? [InputReceived()] : w.inputsReceived)
            .map((item) {
          final copy = InputReceived();
          copy.name = item.name;
          copy.quantity = item.quantity;
          return copy;
        }),
      );

    _inputsPurchased
      ..clear()
      ..addAll(
        (w.inputsPurchased.isEmpty ? [InputPurchased()] : w.inputsPurchased)
            .map((item) {
          final copy = InputPurchased();
          copy.name = item.name;
          copy.quantity = item.quantity;
          copy.cost = item.cost;
          return copy;
        }),
      );

    _volumesPerCycle
      ..clear()
      ..addAll(w.volumesPerCycle.isEmpty
          ? ['']
          : List<String>.from(w.volumesPerCycle));
  }

  @override
  void dispose() {
    _farmerNameController.dispose();
    super.dispose();
  }

  String? get _selectedApprovedFarmerLabel {
    if (w.saadIdNo.isEmpty) {
      return null;
    }
    return w.saadIdNo;
  }

  void _selectApprovedFarmer(ApprovedFarmer farmer) {
    if (w.implementationType?.toLowerCase() == 'collective') {
      // Collective has no farmers or SAAD IDs, so ignore approved farmer selection.
      return;
    }

    setState(() {
      // For individual/hybrid, keep only the actively selected farmer
      _farmerName = [farmer.firstName, farmer.middleName, farmer.surname]
          .where((part) => part.trim().isNotEmpty)
          .join(' ')
          .trim();
      _farmerNameController.text = _farmerName;
      w.saadIdNo = farmer.saadIdNo;
      // Don't store full profile, only minimal data
      w.approvedFarmerProfile = {
        'saadIdNo': farmer.saadIdNo,
        'fullName': _farmerName,
      };
      w.members.clear();
      w.members.add({
        'name': _farmerName,
        'saadIdNo': farmer.saadIdNo,
      });
    });
  }

  void _clearApprovedFarmer() {
    setState(() {
      w.saadIdNo = '';
      w.approvedFarmerProfile = {};
      if (w.implementationType?.toLowerCase() != 'collective') {
        w.members.clear();
      }
    });
  }

  Widget _approvedFarmerInfoCard() {
    final profile = Map<String, dynamic>.from(w.approvedFarmerProfile);
    if (profile.isEmpty) {
      return const SizedBox.shrink();
    }

    final rows = <MapEntry<String, String>>[
      MapEntry('Farmer Name', (profile['fullName'] as String? ?? '').trim()),
      MapEntry('Sex', (profile['sex'] as String? ?? '').trim()),
      MapEntry(
          'Date of Birth', (profile['dateOfBirth'] as String? ?? '').trim()),
      MapEntry('Spouse Name', (profile['spouseName'] as String? ?? '').trim()),
      MapEntry(
        'Address',
        [
          (profile['barangay'] as String? ?? '').trim(),
          (profile['municipality'] as String? ?? '').trim(),
          (profile['province'] as String? ?? '').trim(),
        ].where((part) => part.isNotEmpty).join(', '),
      ),
    ].where((entry) => entry.value.isNotEmpty).toList();

    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD9E8DB), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Information',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: DAColors.greenMid,
            ),
          ),
          const SizedBox(height: 10),
          ...rows.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: DAColors.textDark,
                    ),
                    children: [
                      TextSpan(
                        text: '${entry.key}: ',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: entry.value),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  void _next() {
    // Handle farmer name for individual/hybrid implementation types only
    if (_farmerName.isNotEmpty &&
        w.implementationType?.toLowerCase() != 'collective') {
      if (w.implementationType?.toLowerCase() == 'hybrid') {
        // For hybrid, set the farmer name and add to members
        w.farmerName = _farmerName;
        final existing = w.members.firstWhere(
          (member) => (member['name'] as String? ?? '') == _farmerName,
          orElse: () => {},
        );
        if (existing.isEmpty) {
          w.members.add({
            'name': _farmerName,
            'saadIdNo': w.saadIdNo.isNotEmpty ? w.saadIdNo : _farmerName,
          });
        }
      } else {
        // For individual
        w.farmerName = _farmerName;
        // If adding a farmer to existing group (isAddFarmer), preserve and add to members
        if (w.isAddFarmer && w.members.isNotEmpty) {
          final existing = w.members.firstWhere(
            (member) => (member['name'] as String? ?? '') == _farmerName,
            orElse: () => {},
          );
          if (existing.isEmpty) {
            w.members.add({
              'name': _farmerName,
              'saadIdNo': w.saadIdNo.isNotEmpty ? w.saadIdNo : _farmerName,
            });
          }
        } else {
          // Fresh individual start - replace members with just this farmer
          w.members.clear();
          w.members.add({
            'name': _farmerName,
            'saadIdNo': w.saadIdNo.isNotEmpty ? w.saadIdNo : _farmerName,
          });
        }
      }
    }

    // For collective records, ensure farmerName stays empty
    if (w.implementationType?.toLowerCase() == 'collective') {
      w.farmerName = '';
      w.members.clear();
      w.saadIdNo = '';
      w.approvedFarmerProfile = {};
    } else {
      // For individual type
      w.farmerName = _farmerName;
      // If adding a farmer to existing group (isAddFarmer), preserve and add to members
      // This allows farmers to be merged under the same group
      if (w.isAddFarmer && w.members.isNotEmpty) {
        final existing = w.members.firstWhere(
          (member) => (member['name'] as String? ?? '') == _farmerName,
          orElse: () => {},
        );
        if (existing.isEmpty) {
          w.members.add({
            'name': _farmerName,
            'saadIdNo': w.saadIdNo.isNotEmpty ? w.saadIdNo : _farmerName,
          });
        }
      } else {
        // Fresh individual start - no members
        w.members.clear();
      }
    }

    w.typeOfCrop = _typeOfCrop;
    w.variety = _variety;
    w.inputsReceived = _inputsReceived;
    w.inputsPurchased = _inputsPurchased;
    w.totalCostPurchased = _totalCostPurchased;
    w.qtyVsArea = _qtyVsArea;
    w.croppingCycles = _croppingCycles;
    w.qtyVsCycles = _qtyVsCycles;
    w.peakVolume = _peakVolume;
    w.peakMonth = _peakMonth;
    w.volumesPerCycle = _volumesPerCycle;
    w.farmgatePrice = _farmgatePrice;
    // Members are already updated via ApprovedFarmerPickerField, don't overwrite

    Navigator.of(context).pushNamed(AppRoutes.cropStep3, arguments: w);
  }

  // ── Helpers ───────────────────────────────────────────────────
  Widget _addBtn(String label, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Row(children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
                color: DAColors.greenMid, shape: BoxShape.circle),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: DAColors.greenMid)),
        ]),
      );

  Widget _removeBtn(VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration:
              BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
          child:
              Icon(Icons.close_rounded, color: Colors.red.shade400, size: 18),
        ),
      );

  Widget _label(String t) => Text(t,
      style: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w700, color: DAColors.textDark));

  Widget _sectionBox(Widget child) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
        ),
        child: child,
      );

  Widget _inlineField({
    required String hint,
    required ValueChanged<String> onChanged,
    String? initial,
    TextInputType kb = TextInputType.text,
    Widget? prefix,
  }) =>
      TextFormField(
        initialValue: initial,
        onChanged: onChanged,
        keyboardType: kb,
        style: GoogleFonts.poppins(fontSize: 14, color: DAColors.textDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              GoogleFonts.poppins(fontSize: 14, color: DAColors.textMuted),
          prefixIcon: prefix != null
              ? Padding(
                  padding: const EdgeInsets.only(left: 16, right: 0),
                  child: Align(
                      widthFactor: 1,
                      alignment: Alignment.centerLeft,
                      child: prefix))
              : null,
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

  @override
  Widget build(BuildContext context) {
    return CropFormShell(currentStep: 1, onNext: _next, child: _buildForm());
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Commodity Information',
            style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: DAColors.textDark)),
        const SizedBox(height: 24),

        // ── Name of Farmer / Group Members ─────────────────────────────────────────
        if (_showFarmerName) ...[
          if (w.implementationType?.toLowerCase() != 'collective') ...[
            ApprovedFarmerPickerField(
              selectedLabel: _selectedApprovedFarmerLabel,
              onSelected: _selectApprovedFarmer,
              onCleared: _clearApprovedFarmer,
            ),
            if (w.approvedFarmerProfile.isNotEmpty) ...[
              const SizedBox(height: 12),
              _approvedFarmerInfoCard(),
            ],
            const SizedBox(height: 20),
          ],
          _label(w.implementationType?.toLowerCase() == 'collective'
              ? 'Name of Collective Group'
              : 'Name of Farmer (if individually managed)'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _farmerNameController,
            onChanged: (v) {
              _farmerName = v;
              if (_selectedApprovedFarmerLabel != null &&
                  v.trim() !=
                      (w.approvedFarmerProfile['fullName'] as String? ?? '')
                          .trim()) {
                _clearApprovedFarmer();
              }
            },
            style: GoogleFonts.poppins(fontSize: 14, color: DAColors.textDark),
            decoration: InputDecoration(
              hintText: 'Enter Farmer Name',
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
                    const BorderSide(color: Color(0xFFDDDDDD), width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: Color(0xFFDDDDDD), width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: DAColors.greenMid, width: 2.0),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ] else if (w.implementationType?.toLowerCase() == 'collective') ...[
          // For collectives, show commodity information directly (no members)
          const SizedBox(height: 20),
        ],

        // ── Type of Crop Dropdown ──────────────────────────────────
        _label('Type of Crop'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDDDDDD), width: 1.5),
          ),
          child: DropdownButton<String>(
            value: _typeOfCrop.isEmpty ? null : _typeOfCrop,
            isExpanded: true,
            underline: const SizedBox(),
            hint: Text('Select Type of Crop',
                style: GoogleFonts.poppins(
                    fontSize: 14, color: DAColors.textMuted)),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _typeOfCrop = newValue;
                  // Reset variety when crop type changes
                  _variety = '';
                });
              }
            },
            items: cropVarietiesMap.keys.map((String cropType) {
              return DropdownMenuItem<String>(
                value: cropType,
                child: Text(cropType,
                    style: GoogleFonts.poppins(
                        fontSize: 14, color: DAColors.textDark)),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),

        // ── Variety Dropdown (dependent on crop type) ──────────────
        _label('Variety'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _typeOfCrop.isEmpty
                  ? const Color(0xFFCCCCCC)
                  : const Color(0xFFDDDDDD),
              width: 1.5,
            ),
          ),
          child: DropdownButton<String>(
            value: _variety.isEmpty ? null : _variety,
            isExpanded: true,
            underline: const SizedBox(),
            hint: Text(
              _typeOfCrop.isEmpty ? 'Select crop type first' : 'Select Variety',
              style:
                  GoogleFonts.poppins(fontSize: 14, color: DAColors.textMuted),
            ),
            onChanged: _typeOfCrop.isEmpty
                ? null
                : (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _variety = newValue;
                      });
                    }
                  },
            items: _typeOfCrop.isEmpty
                ? []
                : (cropVarietiesMap[_typeOfCrop] ?? []).map((String variety) {
                    return DropdownMenuItem<String>(
                      value: variety,
                      child: Text(variety,
                          style: GoogleFonts.poppins(
                              fontSize: 14, color: DAColors.textDark)),
                    );
                  }).toList(),
          ),
        ),
        const SizedBox(height: 20),

        // ── Inputs received from program ──────────────────────────
        _label('List of inputs (with quantity) received from the program'),
        const SizedBox(height: 10),
        _sectionBox(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ..._inputsReceived.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: _inlineField(
                                hint: 'Enter Name of the Input',
                                initial: item.name,
                                onChanged: (v) => item.name = v)),
                        if (i > 0) ...[
                          const SizedBox(width: 8),
                          _removeBtn(() =>
                              setState(() => _inputsReceived.removeAt(i))),
                        ],
                      ]),
                      const SizedBox(height: 8),
                      _inlineField(
                          hint: 'Enter Quantity',
                          initial: item.quantity,
                          onChanged: (v) => item.quantity = v,
                          kb: TextInputType.number),
                      if (i < _inputsReceived.length - 1)
                        const Padding(
                            padding: EdgeInsets.only(top: 12),
                            child:
                                Divider(height: 1, color: Color(0xFFEEEEEE))),
                    ]),
              );
            }),
            const SizedBox(height: 4),
            _addBtn('Add Another Input',
                () => setState(() => _inputsReceived.add(InputReceived()))),
          ],
        )),
        const SizedBox(height: 20),

        // ── Inputs purchased by FCA ───────────────────────────────
        _label(
            'List of inputs purchased by the FCA\n(indicate quantity and cost)'),
        const SizedBox(height: 10),
        _sectionBox(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ..._inputsPurchased.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: _inlineField(
                                hint: 'Enter Name of the Input',
                                initial: item.name,
                                onChanged: (v) => item.name = v)),
                        if (i > 0) ...[
                          const SizedBox(width: 8),
                          _removeBtn(() =>
                              setState(() => _inputsPurchased.removeAt(i))),
                        ],
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text('Quantity',
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: DAColors.textDark)),
                              const SizedBox(height: 6),
                              _inlineField(
                                  hint: 'Enter Quantity',
                                  initial: item.quantity,
                                  onChanged: (v) => item.quantity = v,
                                  kb: TextInputType.number),
                            ])),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text('Cost',
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: DAColors.textDark)),
                              const SizedBox(height: 6),
                              _inlineField(
                                  hint: 'Enter Cost',
                                  initial: item.cost,
                                  onChanged: (v) => item.cost = v,
                                  kb: TextInputType.number),
                            ])),
                      ]),
                      if (i < _inputsPurchased.length - 1)
                        const Padding(
                            padding: EdgeInsets.only(top: 12),
                            child:
                                Divider(height: 1, color: Color(0xFFEEEEEE))),
                    ]),
              );
            }),
            const SizedBox(height: 4),
            _addBtn('Add Another Input',
                () => setState(() => _inputsPurchased.add(InputPurchased()))),
          ],
        )),
        const SizedBox(height: 20),

        CropField(
            label: 'Total cost of inputs purchased',
            hint: 'Total Cost',
            initialValue: _totalCostPurchased,
            keyboardType: TextInputType.number,
            onChanged: (v) => _totalCostPurchased = v),
        const SizedBox(height: 20),

        CropField(
            label: 'Quantity received vis-à-vis area coverage',
            hint: 'Enter Quantity',
            initialValue: _qtyVsArea,
            keyboardType: TextInputType.number,
            onChanged: (v) => _qtyVsArea = v),
        const SizedBox(height: 20),

        CropField(
            label: 'Number of cropping cycles in a year',
            hint: 'Total Number',
            initialValue: _croppingCycles,
            keyboardType: TextInputType.number,
            onChanged: (v) => _croppingCycles = v),
        const SizedBox(height: 20),

        CropField(
            label: 'Quantity received vis-à-vis number of cropping cycles',
            hint: 'Total Number',
            initialValue: _qtyVsCycles,
            keyboardType: TextInputType.number,
            onChanged: (v) => _qtyVsCycles = v),
        const SizedBox(height: 20),

        // ── Peak volume + month ───────────────────────────────────
        _label('Observed peak volume of production and month occurred'),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: _inlineField(
                  hint: 'Enter Peak Volume',
                  initial: _peakVolume,
                  onChanged: (v) => setState(() => _peakVolume = v),
                  kb: TextInputType.number)),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFDDDDDD), width: 1.5),
              ),
              child: DropdownButton<String>(
                value: _peakMonth.isEmpty ? null : _peakMonth,
                isExpanded: true,
                underline: const SizedBox(),
                hint: Text('Select Month',
                    style: GoogleFonts.poppins(
                        fontSize: 14, color: DAColors.textMuted)),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _peakMonth = newValue;
                    });
                  }
                },
                items: monthsList.map((String month) {
                  return DropdownMenuItem<String>(
                    value: month,
                    child: Text(month,
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: DAColors.textDark)),
                  );
                }).toList(),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 20),

        // ── Volume per cycle (dynamic) ────────────────────────────
        _label('Volume of production per cycle'),
        const SizedBox(height: 10),
        ..._volumesPerCycle.asMap().entries.map((e) {
          final i = e.key;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Expanded(
                  child: _inlineField(
                hint: 'Enter volume per cycle',
                initial: _volumesPerCycle[i],
                onChanged: (v) => _volumesPerCycle[i] = v,
                kb: TextInputType.number,
                prefix: Text('Cycle ${i + 1}:  ',
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: DAColors.textMuted)),
              )),
              if (i > 0) ...[
                const SizedBox(width: 8),
                _removeBtn(() => setState(() => _volumesPerCycle.removeAt(i))),
              ],
            ]),
          );
        }),
        _addBtn('Add Another Cycle',
            () => setState(() => _volumesPerCycle.add(''))),
        const SizedBox(height: 20),

        CropField(
            label: 'Farmgate price of produce in the area',
            hint: 'Enter Farmgate Price',
            initialValue: _farmgatePrice,
            keyboardType: TextInputType.number,
            onChanged: (v) => _farmgatePrice = v),

        const SizedBox(height: 32),
      ],
    );
  }
}
