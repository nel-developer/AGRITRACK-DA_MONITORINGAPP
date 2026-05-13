/// Service for generating unique commodity/batch document IDs
class CommodityIdService {
  /// Generate a unique commodity ID based on production type and count
  /// ✅ GLOBAL NUMBERING: IDs incremented globally across all farmers in group
  ///
  /// Examples:
  /// - Crop: crop_001, crop_002, etc.
  /// - Poultry: poultry_001, poultry_002, etc.
  /// - Livestock: livestock_001, livestock_002, etc.
  static String generateCommodityId(
    String productionType,
    List<Map<String, dynamic>> allGroupCommodities,
  ) {
    final type = productionType.toLowerCase().trim();
    final prefix = type == 'crop'
        ? 'crop'
        : type == 'poultry'
            ? 'poultry'
            : type == 'livestock'
                ? 'livestock'
                : 'unknown';

    // Count ALL existing commodities with this prefix globally in the group
    int nextNumber = 1;
    for (final commodity in allGroupCommodities) {
      final existingId = commodity['commodityId']?.toString() ?? '';
      if (existingId.startsWith('${prefix}_')) {
        try {
          final numberPart = existingId.split('_')[1];
          final number = int.tryParse(numberPart) ?? 0;
          if (number >= nextNumber) {
            nextNumber = number + 1;
          }
        } catch (e) {
          // Ignore parsing errors
        }
      }
    }

    return '${prefix}_${nextNumber.toString().padLeft(3, '0')}';
  }

  /// Extract the numeric suffix from a commodity ID
  static int getNumberFromId(String commodityId) {
    try {
      final parts = commodityId.split('_');
      if (parts.length == 2) {
        return int.parse(parts[1]);
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return 0;
  }

  /// Check if a commodity ID follows the correct format
  static bool isValidCommodityId(String id) {
    final regex = RegExp(r'^(crop|poultry|livestock)_\d{3}$');
    return regex.hasMatch(id);
  }
}
