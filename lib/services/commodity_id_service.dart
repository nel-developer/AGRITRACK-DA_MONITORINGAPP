/// Service for generating unique commodity/batch document IDs
class CommodityIdService {
  /// Generate a unique commodity ID based on production type and count
  ///
  /// Examples:
  /// - Crop: CROP-001, CROP-002, etc.
  /// - Poultry: POULTRY-001, POULTRY-002, etc.
  /// - Livestock: LIVESTOCK-001, LIVESTOCK-002, etc.
  static String generateCommodityId(
    String productionType,
    List<Map<String, dynamic>> existingCommodities,
  ) {
    final type = productionType.toUpperCase();
    final prefix = type == 'CROP'
        ? 'CROP'
        : type == 'POULTRY'
            ? 'POULTRY'
            : type == 'LIVESTOCK'
                ? 'LIVESTOCK'
                : type;

    // Count existing commodities with this prefix to determine next number
    int nextNumber = 1;
    for (final commodity in existingCommodities) {
      final existingId = commodity['commodityId']?.toString() ?? '';
      if (existingId.startsWith('$prefix-')) {
        try {
          final numberPart = existingId.split('-')[1];
          final number = int.tryParse(numberPart) ?? 0;
          if (number >= nextNumber) {
            nextNumber = number + 1;
          }
        } catch (e) {
          // Ignore parsing errors
        }
      }
    }

    return '$prefix-${nextNumber.toString().padLeft(3, '0')}';
  }

  /// Extract the numeric suffix from a commodity ID
  static int getNumberFromId(String commodityId) {
    try {
      final parts = commodityId.split('-');
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
    final regex = RegExp(r'^(CROP|POULTRY|LIVESTOCK)-\d{3}$');
    return regex.hasMatch(id);
  }
}
