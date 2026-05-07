import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service to handle saving profiling records to Firestore
///
/// Collection structure:
/// profiler/profiling/{productionType}/{implementationType}/{recordId}
///
/// Examples:
/// - profiler/profiling/crop_production/collective/{recordId}
/// - profiler/profiling/livestock_production/individual/{recordId}
/// - profiler/profiling/poultry_production/hybrid/{recordId}
class ProfilingService {
  static final ProfilingService _instance = ProfilingService._internal();

  factory ProfilingService() {
    return _instance;
  }

  ProfilingService._internal();

  static ProfilingService get instance => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Save a profiling record to Firestore
  ///
  /// [productionType]: 'crop', 'livestock', or 'poultry'
  /// [implementationType]: 'collective', 'individual', or 'hybrid'
  /// [data]: The profiling data as a Map
  ///
  /// Returns the document ID of the saved record
  Future<String> saveProfiling({
    required String productionType,
    required String implementationType,
    required Map<String, dynamic> data,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Map production type to collection name
      final productionKey = _mapProductionType(productionType);

      // Add profiling metadata
      final profilingData = {
        ...data,
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'productionType': productionType,
        'implementationType': implementationType,
        'reviewStatus': data['reviewStatus'] ?? 'pending',
      };

      // Use a batch to create subcollection document
      final batch = _firestore.batch();

      // Ensure the parent document exists
      final parentRef = _firestore
          .collection('profiler')
          .doc('profiling')
          .collection(productionKey)
          .doc(implementationType);

      // Create or update implementation type document with profiling records
      final recordsCollection = parentRef.collection('records');
      final newRecordRef = recordsCollection.doc();

      batch.set(newRecordRef, profilingData);

      await batch.commit();

      if (kDebugMode) {
        print('Profiling record saved: ${newRecordRef.id}');
      }

      return newRecordRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving profiling: $e');
      }
      rethrow;
    }
  }

  /// Save a profiling record with automatic ID generation
  /// This saves to: profiler/profiling/{productionType}/{implementationType}/records/{autoId}
  Future<String> saveProfilingWithAutoId({
    required String productionType,
    required String implementationType,
    required Map<String, dynamic> data,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final productionKey = _mapProductionType(productionType);

      final profilingData = {
        ...data,
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'productionType': productionType,
        'implementationType': implementationType,
        'reviewStatus': data['reviewStatus'] ?? 'pending',
      };

      // Reference to the records subcollection
      final recordsCollection = _firestore
          .collection('profiler')
          .doc('profiling')
          .collection(productionKey)
          .doc(implementationType)
          .collection('records');

      // Add document with auto-generated ID
      final docRef = await recordsCollection.add(profilingData);

      if (kDebugMode) {
        print('Profiling record saved with auto ID: ${docRef.id}');
      }

      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving profiling with auto ID: $e');
      }
      rethrow;
    }
  }

  /// Fetch all profiling records for a production type and implementation type
  Stream<List<Map<String, dynamic>>> getProfilingRecords({
    required String productionType,
    required String implementationType,
  }) {
    try {
      final productionKey = _mapProductionType(productionType);

      return _firestore
          .collection('profiler')
          .doc('profiling')
          .collection(productionKey)
          .doc(implementationType)
          .collection('records')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => {...doc.data(), 'id': doc.id})
              .toList());
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching profiling records: $e');
      }
      rethrow;
    }
  }

  /// Map user-friendly production type to Firestore collection name
  String _mapProductionType(String productionType) {
    switch (productionType.toLowerCase()) {
      case 'crop':
        return 'crop_production';
      case 'livestock':
        return 'livestock_production';
      case 'poultry':
        return 'poultry_production';
      default:
        throw Exception('Unknown production type: $productionType');
    }
  }

  /// Delete a profiling record
  Future<void> deleteProfilingRecord({
    required String productionType,
    required String implementationType,
    required String recordId,
  }) async {
    try {
      final productionKey = _mapProductionType(productionType);

      await _firestore
          .collection('profiler')
          .doc('profiling')
          .collection(productionKey)
          .doc(implementationType)
          .collection('records')
          .doc(recordId)
          .delete();

      if (kDebugMode) {
        print('Profiling record deleted: $recordId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting profiling record: $e');
      }
      rethrow;
    }
  }

  /// Update a profiling record
  Future<void> updateProfilingRecord({
    required String productionType,
    required String implementationType,
    required String recordId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final productionKey = _mapProductionType(productionType);

      final updateData = {
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('profiler')
          .doc('profiling')
          .collection(productionKey)
          .doc(implementationType)
          .collection('records')
          .doc(recordId)
          .update(updateData);

      if (kDebugMode) {
        print('Profiling record updated: $recordId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating profiling record: $e');
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchReviewRecords({
    String? createdBy,
    int limit = 200,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collectionGroup('records');

      if (createdBy != null && createdBy.isNotEmpty) {
        query = query.where('createdBy', isEqualTo: createdBy);
      }

      query = query.limit(limit);

      final snapshot = await query.get(const GetOptions(source: Source.server));

      return snapshot.docs
          .map((doc) => {
                ...doc.data(),
                'id': doc.id,
                'documentPath': doc.reference.path,
              })
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching review records: $e');
      }
      rethrow;
    }
  }

  Future<void> updateReviewStatus({
    required String documentPath,
    required String reviewStatus,
  }) async {
    try {
      final user = _auth.currentUser;
      await _firestore.doc(documentPath).update({
        'reviewStatus': reviewStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': user?.uid,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error updating review status: $e');
      }
      rethrow;
    }
  }

  Future<void> updateRecordByDocumentPath({
    required String documentPath,
    required Map<String, dynamic> updates,
  }) async {
    try {
      await _firestore.doc(documentPath).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error updating record by path: $e');
      }
      rethrow;
    }
  }
}
