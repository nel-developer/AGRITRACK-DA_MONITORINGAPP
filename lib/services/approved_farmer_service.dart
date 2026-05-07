import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/approved_farmer.dart';

class ApprovedFarmerService {
  ApprovedFarmerService._();

  static final ApprovedFarmerService instance = ApprovedFarmerService._();

  static const _cacheKey = 'approved_farmers_v1';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<ApprovedFarmer>> getApprovedFarmers({bool refresh = true}) async {
    final cached = await getCachedFarmers();
    if (!refresh) {
      return cached;
    }

    try {
      final remote = await syncApprovedFarmers();
      return remote.isEmpty ? cached : remote;
    } catch (_) {
      return cached;
    }
  }

  Future<List<ApprovedFarmer>> syncApprovedFarmers() async {
    final snapshot = await _firestore
        .collection('profiling_forms')
        .where('status', isEqualTo: 'Approved')
        .get(const GetOptions(source: Source.server));

    final deduped = <String, ApprovedFarmer>{};
    for (final doc in snapshot.docs) {
      final farmer = ApprovedFarmer.fromJson({
        'id': doc.id,
        ...doc.data(),
      });
      if (farmer.saadIdNo.isEmpty) {
        continue;
      }

      final existing = deduped[farmer.saadIdNo];
      if (existing == null || _isNewer(farmer.updatedAt, existing.updatedAt)) {
        deduped[farmer.saadIdNo] = farmer;
      }
    }

    final farmers = deduped.values.toList()
      ..sort((a, b) =>
          a.displayLabel.toLowerCase().compareTo(b.displayLabel.toLowerCase()));
    await _writeCache(farmers);
    return farmers;
  }

  Future<List<ApprovedFarmer>> getCachedFarmers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_cacheKey) ?? const <String>[];
    return raw
        .map((item) =>
            ApprovedFarmer.fromJson(jsonDecode(item) as Map<String, dynamic>))
        .toList();
  }

  bool _isNewer(String leftRaw, String rightRaw) {
    final left = DateTime.tryParse(leftRaw);
    final right = DateTime.tryParse(rightRaw);
    if (left == null) return false;
    if (right == null) return true;
    return left.isAfter(right);
  }

  Future<void> _writeCache(List<ApprovedFarmer> farmers) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _cacheKey,
      farmers.map((farmer) => jsonEncode(farmer.toJson())).toList(),
    );
  }
}
