import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/approved_farmer.dart';
import '../services/approved_farmer_service.dart';
import '../theme/da_colors.dart';

class ApprovedFarmerPickerField extends StatefulWidget {
  const ApprovedFarmerPickerField({
    super.key,
    required this.onSelected,
    this.onCleared,
    this.selectedLabel,
    this.label = 'SAAD ID Number',
    this.hint = 'Select SAAD ID number',
  });

  final ValueChanged<ApprovedFarmer> onSelected;
  final VoidCallback? onCleared;
  final String? selectedLabel;
  final String label;
  final String hint;

  @override
  State<ApprovedFarmerPickerField> createState() =>
      _ApprovedFarmerPickerFieldState();
}

class _ApprovedFarmerPickerFieldState extends State<ApprovedFarmerPickerField> {
  List<ApprovedFarmer> _farmers = const <ApprovedFarmer>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFarmers();
  }

  Future<void> _loadFarmers() async {
    final farmers = await ApprovedFarmerService.instance.getApprovedFarmers();
    if (!mounted) return;
    setState(() {
      _farmers = farmers;
      _isLoading = false;
    });
  }

  Future<void> _openPicker() async {
    if (_isLoading) return;
    final selected = await showModalBottomSheet<ApprovedFarmer>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ApprovedFarmerPickerSheet(
        farmers: _farmers,
        selectedLabel: widget.selectedLabel,
      ),
    );

    if (selected != null) {
      widget.onSelected(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection =
        widget.selectedLabel != null && widget.selectedLabel!.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: DAColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _openPicker,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDDDDDD), width: 1.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _isLoading
                        ? 'Loading approved farmers...'
                        : (hasSelection ? widget.selectedLabel! : widget.hint),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color:
                          hasSelection ? DAColors.textDark : DAColors.textMuted,
                      fontWeight:
                          hasSelection ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ),
                if (hasSelection && widget.onCleared != null) ...[
                  GestureDetector(
                    onTap: widget.onCleared,
                    child: Icon(Icons.close_rounded,
                        color: Colors.red.shade400, size: 20),
                  ),
                  const SizedBox(width: 8),
                ],
                Icon(
                  _isLoading
                      ? Icons.sync_rounded
                      : Icons.arrow_drop_down_rounded,
                  color: DAColors.greenMid,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ApprovedFarmerPickerSheet extends StatefulWidget {
  const _ApprovedFarmerPickerSheet({
    required this.farmers,
    required this.selectedLabel,
  });

  final List<ApprovedFarmer> farmers;
  final String? selectedLabel;

  @override
  State<_ApprovedFarmerPickerSheet> createState() =>
      _ApprovedFarmerPickerSheetState();
}

class _ApprovedFarmerPickerSheetState
    extends State<_ApprovedFarmerPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.farmers.where((farmer) {
      if (_query.isEmpty) return true;
      return farmer.displayLabel.toLowerCase().contains(_query) ||
          farmer.municipality.toLowerCase().contains(_query);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFD0D0D0),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select SAAD ID Number',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: DAColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by SAAD ID, name, municipality',
                    hintStyle: GoogleFonts.poppins(
                        fontSize: 13, color: DAColors.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: DAColors.greenMid),
                    filled: true,
                    fillColor: const Color(0xFFF8F8F8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No approved farmers found.',
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: DAColors.textMuted),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final farmer = filtered[index];
                      final isSelected =
                          widget.selectedLabel == farmer.displayLabel;
                      final title = farmer.saadIdNo.isEmpty
                          ? farmer.displayLabel
                          : farmer.saadIdNo;
                      final subtitleParts = <String>[
                        farmer.fullName,
                        farmer.municipality
                      ].where((part) => part.trim().isNotEmpty).toList();
                      return ListTile(
                        onTap: () => Navigator.of(context).pop(farmer),
                        tileColor:
                            isSelected ? const Color(0xFFEAF6ED) : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isSelected
                                ? DAColors.greenMid
                                : const Color(0xFFE2E2E2),
                            width: 1.2,
                          ),
                        ),
                        title: Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: DAColors.textDark,
                          ),
                        ),
                        subtitle: subtitleParts.isEmpty
                            ? null
                            : Text(
                                subtitleParts.join(' | '),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: DAColors.textMuted,
                                ),
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
