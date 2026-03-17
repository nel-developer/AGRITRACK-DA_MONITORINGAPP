  import 'package:flutter/material.dart';
  import 'package:flutter/services.dart';
  import 'package:google_fonts/google_fonts.dart';
  import '../../theme/da_colors.dart';
  import '../../widgets/crop_form_shell.dart';
  import '../../widgets/crop_field.dart';
  import 'crop_step_wrapper.dart';
  import '../../routes/app_routes.dart';

  class CropStep2CommodityInformation extends StatefulWidget {
    const CropStep2CommodityInformation({super.key, required this.wrapper});
    final CropStepWrapper wrapper;

    @override
    State<CropStep2CommodityInformation> createState() => _CropStep2State();
  }

  class _CropStep2State extends State<CropStep2CommodityInformation> {
    CropStepWrapper get w => widget.wrapper;

    // Dynamic lists
    final List<InputReceived>  _inputsReceived  = [InputReceived()];
    final List<InputPurchased> _inputsPurchased = [InputPurchased()];
    final List<String>         _volumesPerCycle = [''];

    // Single-value fields
    String _farmerName         = '';
    String _typeOfCrop         = '';
    String _variety            = '';
    String _totalCostPurchased = '';
    String _qtyVsArea          = '';
    String _croppingCycles     = '';
    String _qtyVsCycles        = '';
    String _peakVolume         = '';
    String _peakMonth          = '';
    String _farmgatePrice      = '';

    // farmerName shown only for individual or hybrid
    bool get _showFarmerName =>
        w.implementationType == 'individual' || w.implementationType == 'hybrid';

    void _next() {
      w.farmerName         = _farmerName;
      w.typeOfCrop         = _typeOfCrop;
      w.variety            = _variety;
      w.inputsReceived     = _inputsReceived;
      w.inputsPurchased    = _inputsPurchased;
      w.totalCostPurchased = _totalCostPurchased;
      w.qtyVsArea          = _qtyVsArea;
      w.croppingCycles     = _croppingCycles;
      w.qtyVsCycles        = _qtyVsCycles;
      w.peakVolume         = _peakVolume;
      w.peakMonth          = _peakMonth;
      w.volumesPerCycle    = _volumesPerCycle;
      w.farmgatePrice      = _farmgatePrice;

      Navigator.of(context).pushNamed(AppRoutes.cropStep3, arguments: w);
    }

    // ── Helpers ───────────────────────────────────────────────────
    Widget _addBtn(String label, VoidCallback onTap) => GestureDetector(
      onTap: onTap,
      child: Row(children: [
        Container(
          width: 28, height: 28,
          decoration: const BoxDecoration(
              color: DAColors.greenMid, shape: BoxShape.circle),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.poppins(
            fontSize: 13, fontWeight: FontWeight.w600, color: DAColors.greenMid)),
      ]),
    );

    Widget _removeBtn(VoidCallback onTap) => GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
        child: Icon(Icons.close_rounded, color: Colors.red.shade400, size: 18),
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
          hintStyle: GoogleFonts.poppins(fontSize: 14, color: DAColors.textMuted),
          prefixIcon: prefix != null
              ? Padding(
                  padding: const EdgeInsets.only(left: 16, right: 0),
                  child: Align(widthFactor: 1,
                      alignment: Alignment.centerLeft, child: prefix))
              : null,
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
      return CropFormShell(currentStep: 1, onNext: _next, child: _buildForm());
    }

    Widget _buildForm() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text('Commodity Information',
            style: GoogleFonts.poppins(
                fontSize: 22, fontWeight: FontWeight.w800, color: DAColors.textDark)),
          const SizedBox(height: 24),

          // ── Name of Farmer — only for individual / hybrid ─────────
          if (_showFarmerName) ...[
            CropField(
              label:        'Name of Farmer (if individually managed)',
              hint:         'Enter Farmer Name',
              initialValue: _farmerName,
              onChanged:    (v) => _farmerName = v,
            ),
            const SizedBox(height: 20),
          ],

          CropField(label: 'Type of Crop', hint: 'Enter Type of Crop',
            initialValue: _typeOfCrop, onChanged: (v) => _typeOfCrop = v),
          const SizedBox(height: 20),

          CropField(label: 'Variety', hint: 'Enter Variety',
            initialValue: _variety, onChanged: (v) => _variety = v),
          const SizedBox(height: 20),

          // ── Inputs received from program ──────────────────────────
          _label('List of inputs (with quantity) received from the program'),
          const SizedBox(height: 10),
          _sectionBox(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._inputsReceived.asMap().entries.map((e) {
                final i = e.key; final item = e.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: _inlineField(hint: 'Enter Name of the Input',
                          initial: item.name, onChanged: (v) => item.name = v)),
                      if (i > 0) ...[
                        const SizedBox(width: 8),
                        _removeBtn(() => setState(() => _inputsReceived.removeAt(i))),
                      ],
                    ]),
                    const SizedBox(height: 8),
                    _inlineField(hint: 'Enter Quantity', initial: item.quantity,
                        onChanged: (v) => item.quantity = v, kb: TextInputType.number),
                    if (i < _inputsReceived.length - 1)
                      const Padding(padding: EdgeInsets.only(top: 12),
                          child: Divider(height: 1, color: Color(0xFFEEEEEE))),
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
          _label('List of inputs purchased by the FCA\n(indicate quantity and cost)'),
          const SizedBox(height: 10),
          _sectionBox(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._inputsPurchased.asMap().entries.map((e) {
                final i = e.key; final item = e.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: _inlineField(hint: 'Enter Name of the Input',
                          initial: item.name, onChanged: (v) => item.name = v)),
                      if (i > 0) ...[
                        const SizedBox(width: 8),
                        _removeBtn(() => setState(() => _inputsPurchased.removeAt(i))),
                      ],
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Quantity', style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w600, color: DAColors.textDark)),
                        const SizedBox(height: 6),
                        _inlineField(hint: 'Enter Quantity', initial: item.quantity,
                            onChanged: (v) => item.quantity = v, kb: TextInputType.number),
                      ])),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Cost', style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w600, color: DAColors.textDark)),
                        const SizedBox(height: 6),
                        _inlineField(hint: 'Enter Cost', initial: item.cost,
                            onChanged: (v) => item.cost = v, kb: TextInputType.number),
                      ])),
                    ]),
                    if (i < _inputsPurchased.length - 1)
                      const Padding(padding: EdgeInsets.only(top: 12),
                          child: Divider(height: 1, color: Color(0xFFEEEEEE))),
                  ]),
                );
              }),
              const SizedBox(height: 4),
              _addBtn('Add Another Input',
                  () => setState(() => _inputsPurchased.add(InputPurchased()))),
            ],
          )),
          const SizedBox(height: 20),

          CropField(label: 'Total cost of inputs purchased', hint: 'Total Cost',
            initialValue: _totalCostPurchased, keyboardType: TextInputType.number,
            onChanged: (v) => _totalCostPurchased = v),
          const SizedBox(height: 20),

          CropField(label: 'Quantity received vis-à-vis area coverage', hint: 'Enter Quantity',
            initialValue: _qtyVsArea, keyboardType: TextInputType.number,
            onChanged: (v) => _qtyVsArea = v),
          const SizedBox(height: 20),

          CropField(label: 'Number of cropping cycles in a year', hint: 'Total Number',
            initialValue: _croppingCycles, keyboardType: TextInputType.number,
            onChanged: (v) => _croppingCycles = v),
          const SizedBox(height: 20),

          CropField(label: 'Quantity received vis-à-vis number of cropping cycles',
            hint: 'Total Number', initialValue: _qtyVsCycles, keyboardType: TextInputType.number,
            onChanged: (v) => _qtyVsCycles = v),
          const SizedBox(height: 20),

          // ── Peak volume + month ───────────────────────────────────
          _label('Observed peak volume of production and month occurred'),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _inlineField(hint: 'Enter Peak Volume', initial: _peakVolume,
                onChanged: (v) => setState(() => _peakVolume = v), kb: TextInputType.number)),
            const SizedBox(width: 10),
            Expanded(child: _inlineField(hint: 'Month Occurred', initial: _peakMonth,
                onChanged: (v) => setState(() => _peakMonth = v))),
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
                Expanded(child: _inlineField(
                  hint: 'Enter volume per cycle',
                  initial: _volumesPerCycle[i],
                  onChanged: (v) => _volumesPerCycle[i] = v,
                  kb: TextInputType.number,
                  prefix: Text('Cycle ${i + 1}:  ',
                    style: GoogleFonts.poppins(fontSize: 13,
                        fontWeight: FontWeight.w600, color: DAColors.textMuted)),
                )),
                if (i > 0) ...[
                  const SizedBox(width: 8),
                  _removeBtn(() => setState(() => _volumesPerCycle.removeAt(i))),
                ],
              ]),
            );
          }),
          _addBtn('Add Another Cycle', () => setState(() => _volumesPerCycle.add(''))),
          const SizedBox(height: 20),

          CropField(label: 'Farmgate price of produce in the area', hint: 'Enter Farmgate Price',
            initialValue: _farmgatePrice, keyboardType: TextInputType.number,
            onChanged: (v) => _farmgatePrice = v),

          const SizedBox(height: 32),
        ],
      );
    }
  }