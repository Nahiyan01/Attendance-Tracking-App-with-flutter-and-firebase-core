import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:attendence_app/models/tuition_model.dart';
import 'package:attendence_app/models/session_model.dart';

/// Service class for all Firestore operations related to tuitions.
/// This layer handles only data persistence logic, no UI logic.
class TuitionService {
  static final TuitionService _instance = TuitionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'tuitions';

  TuitionService._internal();

  /// Singleton pattern for TuitionService
  factory TuitionService() {
    return _instance;
  }

  // ============================================================================
  // TUITION CRUD OPERATIONS
  // ============================================================================

  /// Add a new tuition to Firestore
  /// Returns the ID of the newly created document
  Future<String> addTuition({
    required String name,
    required List<String> days,
    required int studentCount,
  }) async {
    try {
      final now = DateTime.now();
      print(
        '[TuitionService] Starting to add tuition: name=$name, days=$days, studentCount=$studentCount',
      );

      // Use a timeout to avoid indefinite waits when network/rules block the write.
      final docRef = await _firestore
          .collection(_collectionName)
          .add({
            'name': name,
            'days': days,
            'studentCount': studentCount,
            'sessionCount': 0,
            'createdAt': now,
            'lastUpdated': now,
          })
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print(
                '[TuitionService] TIMEOUT: Write operation took longer than 10 seconds',
              );
              throw Exception(
                'Timed out while adding tuition. Check network or Firestore rules.',
              );
            },
          );

      print(
        '[TuitionService] Tuition added successfully with ID: ${docRef.id}',
      );
      return docRef.id;
    } on FirebaseException catch (e) {
      print(
        '[TuitionService] FirebaseException: code=${e.code}, message=${e.message}',
      );
      // Surface Firebase-specific errors clearly
      throw Exception('Firestore error while adding tuition: ${e.message}');
    } catch (e) {
      print('[TuitionService] Unexpected error: $e');
      throw Exception('Failed to add tuition: $e');
    }
  }

  /// Get all tuitions from Firestore as a stream
  /// Useful for real-time updates in Provider
  Stream<List<TuitionModel>> getTuitionsStream() {
    try {
      return _firestore.collection(_collectionName).snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => TuitionModel.fromJson(doc.data(), doc.id))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to fetch tuitions: $e');
    }
  }

  /// Get a single tuition by ID
  Future<TuitionModel?> getTuitionById(String tuitionId) async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(tuitionId)
          .get();
      if (doc.exists) {
        return TuitionModel.fromJson(doc.data() ?? {}, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch tuition: $e');
    }
  }

  /// Update tuition details (name, days, student count)
  /// Preserves sessionCount and session history
  Future<void> updateTuition({
    required String tuitionId,
    String? name,
    List<String>? days,
    int? studentCount,
  }) async {
    try {
      final updateData = <String, dynamic>{'lastUpdated': DateTime.now()};

      if (name != null) updateData['name'] = name;
      if (days != null) updateData['days'] = days;
      if (studentCount != null) updateData['studentCount'] = studentCount;

      await _firestore
          .collection(_collectionName)
          .doc(tuitionId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to update tuition: $e');
    }
  }

  /// Delete a tuition and all its session history
  /// Uses batch write to ensure atomic deletion
  Future<void> deleteTuition(String tuitionId) async {
    try {
      final batch = _firestore.batch();

      // Delete all sessions in the subcollection
      final sessionsSnapshot = await _firestore
          .collection(_collectionName)
          .doc(tuitionId)
          .collection('sessions')
          .get();

      for (var doc in sessionsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete the tuition document itself
      batch.delete(_firestore.collection(_collectionName).doc(tuitionId));

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete tuition: $e');
    }
  }

  // ============================================================================
  // SESSION MANAGEMENT
  // ============================================================================

  /// Mark a new session (attendance taken)
  /// This is a critical operation:
  /// 1. Increment sessionCount in tuition document
  /// 2. Create a new session document with current date
  /// Uses transaction to ensure atomicity
  Future<void> markSession(String tuitionId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final tuitionRef = _firestore
            .collection(_collectionName)
            .doc(tuitionId);
        final tuitionDoc = await transaction.get(tuitionRef);

        if (!tuitionDoc.exists) {
          throw Exception('Tuition not found');
        }

        // Increment sessionCount
        final newSessionCount = (tuitionDoc['sessionCount'] as int? ?? 0) + 1;
        transaction.update(tuitionRef, {
          'sessionCount': newSessionCount,
          'lastUpdated': DateTime.now(),
        });

        // Create new session document in subcollection
        final now = DateTime.now();
        final sessionRef = tuitionRef
            .collection('sessions')
            .doc(); // Auto-generate ID
        transaction.set(sessionRef, {'date': now, 'createdAt': now});
      });
    } catch (e) {
      throw Exception('Failed to mark session: $e');
    }
  }

  /// Get all sessions for a tuition, ordered by date (newest first)
  Future<List<SessionModel>> getSessionHistory(String tuitionId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .doc(tuitionId)
          .collection('sessions')
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => SessionModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch session history: $e');
    }
  }

  /// Get session history as a stream for real-time updates
  Stream<List<SessionModel>> getSessionHistoryStream(String tuitionId) {
    try {
      return _firestore
          .collection(_collectionName)
          .doc(tuitionId)
          .collection('sessions')
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => SessionModel.fromJson(doc.data(), doc.id))
                .toList();
          });
    } catch (e) {
      throw Exception('Failed to fetch session history stream: $e');
    }
  }

  // ============================================================================
  // RESET FUNCTIONALITY
  // ============================================================================

  /// Reset a tuition: set sessionCount to 0 and delete all session history
  /// Uses batch write to ensure atomic reset
  Future<void> resetTuition(String tuitionId) async {
    try {
      final batch = _firestore.batch();

      // Delete all sessions
      final sessionsSnapshot = await _firestore
          .collection(_collectionName)
          .doc(tuitionId)
          .collection('sessions')
          .get();

      for (var doc in sessionsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Reset sessionCount to 0
      batch.update(_firestore.collection(_collectionName).doc(tuitionId), {
        'sessionCount': 0,
        'lastUpdated': DateTime.now(),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to reset tuition: $e');
    }
  }
}
