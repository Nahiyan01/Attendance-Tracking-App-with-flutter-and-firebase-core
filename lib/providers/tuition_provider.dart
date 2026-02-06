import 'package:flutter/material.dart';
import 'package:attendence_app/models/tuition_model.dart';
import 'package:attendence_app/models/session_model.dart';
import 'package:attendence_app/services/tuition_service.dart';

/// Provider class that manages tuition business logic and state.
/// Acts as intermediary between Firestore service and UI layer.
class TuitionProvider extends ChangeNotifier {
  final TuitionService _tuitionService = TuitionService();

  // Loading states
  bool _isLoading = false;
  String? _errorMessage;

  // Tuition data
  List<TuitionModel> _tuitions = [];
  List<SessionModel> _sessionHistory = [];

  // Current selected tuition for detailed view
  TuitionModel? _selectedTuition;

  // ============================================================================
  // GETTERS
  // ============================================================================

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<TuitionModel> get tuitions => _tuitions;
  TuitionModel? get selectedTuition => _selectedTuition;
  List<SessionModel> get sessionHistory => _sessionHistory;

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  /// Initialize provider by listening to tuitions stream
  /// Call this once when app starts (in main.dart or initial screen)
  void initializeTuitions() {
    try {
      _tuitionService.getTuitionsStream().listen(
        (tuitions) {
          _tuitions = tuitions;
          _errorMessage = null;
          notifyListeners();
        },
        onError: (error) {
          _errorMessage = error.toString();
          notifyListeners();
        },
      );
    } catch (e) {
      _errorMessage = 'Failed to initialize tuitions: $e';
      notifyListeners();
    }
  }

  // ============================================================================
  // TUITION CRUD OPERATIONS
  // ============================================================================

  /// Add a new tuition
  /// Returns true if successful, false otherwise
  Future<bool> addTuition({
    required String name,
    required List<String> days,
    required int studentCount,
  }) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      // Validate inputs
      if (name.trim().isEmpty) {
        _errorMessage = 'Tuition name cannot be empty';
        _setLoading(false);
        return false;
      }

      if (days.isEmpty) {
        _errorMessage = 'Please select at least one day';
        _setLoading(false);
        return false;
      }

      if (studentCount <= 0) {
        _errorMessage = 'Number of students must be greater than 0';
        _setLoading(false);
        return false;
      }

      await _tuitionService.addTuition(
        name: name.trim(),
        days: days,
        studentCount: studentCount,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add tuition: $e';
      _setLoading(false);
      return false;
    }
  }

  /// Update an existing tuition
  /// Returns true if successful, false otherwise
  Future<bool> updateTuition({
    required String tuitionId,
    String? name,
    List<String>? days,
    int? studentCount,
  }) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      // Validate inputs if provided
      if (name != null && name.trim().isEmpty) {
        _errorMessage = 'Tuition name cannot be empty';
        _setLoading(false);
        return false;
      }

      if (days != null && days.isEmpty) {
        _errorMessage = 'Please select at least one day';
        _setLoading(false);
        return false;
      }

      if (studentCount != null && studentCount <= 0) {
        _errorMessage = 'Number of students must be greater than 0';
        _setLoading(false);
        return false;
      }

      await _tuitionService.updateTuition(
        tuitionId: tuitionId,
        name: name?.trim(),
        days: days,
        studentCount: studentCount,
      );

      // Update selected tuition if it's the one being edited
      if (_selectedTuition?.id == tuitionId) {
        _selectedTuition = _selectedTuition?.copyWith(
          name: name ?? _selectedTuition?.name,
          days: days ?? _selectedTuition?.days,
          studentCount: studentCount ?? _selectedTuition?.studentCount,
          lastUpdated: DateTime.now(),
        );
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update tuition: $e';
      _setLoading(false);
      return false;
    }
  }

  /// Delete a tuition and all its session history
  /// Returns true if successful, false otherwise
  Future<bool> deleteTuition(String tuitionId) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      await _tuitionService.deleteTuition(tuitionId);

      // Clear selected tuition if it's the one being deleted
      if (_selectedTuition?.id == tuitionId) {
        _selectedTuition = null;
        _sessionHistory = [];
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete tuition: $e';
      _setLoading(false);
      return false;
    }
  }

  // ============================================================================
  // SESSION MANAGEMENT
  // ============================================================================

  /// Mark a new session (attendance taken)
  /// Increments sessionCount and creates session record
  /// Returns true if successful, false otherwise
  Future<bool> markSession(String tuitionId) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      await _tuitionService.markSession(tuitionId);

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to mark session: $e';
      _setLoading(false);
      return false;
    }
  }

  /// Load session history for a specific tuition
  /// Listens to real-time updates
  Future<void> loadSessionHistory(String tuitionId) async {
    try {
      _errorMessage = null;
      _tuitionService
          .getSessionHistoryStream(tuitionId)
          .listen(
            (sessions) {
              _sessionHistory = sessions;
              notifyListeners();
            },
            onError: (error) {
              _errorMessage = 'Failed to load session history: $error';
              notifyListeners();
            },
          );
    } catch (e) {
      _errorMessage = 'Failed to load session history: $e';
      notifyListeners();
    }
  }

  // ============================================================================
  // RESET FUNCTIONALITY
  // ============================================================================

  /// Reset a tuition: set sessionCount to 0 and clear all session history
  /// Returns true if successful, false otherwise
  Future<bool> resetTuition(String tuitionId) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      await _tuitionService.resetTuition(tuitionId);

      // Update selected tuition's session count
      if (_selectedTuition?.id == tuitionId) {
        _selectedTuition = _selectedTuition?.copyWith(
          sessionCount: 0,
          lastUpdated: DateTime.now(),
        );
      }

      // Clear session history
      _sessionHistory = [];

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to reset tuition: $e';
      _setLoading(false);
      return false;
    }
  }

  // ============================================================================
  // SELECTION MANAGEMENT
  // ============================================================================

  /// Select a tuition for detailed view
  void selectTuition(TuitionModel tuition) {
    _selectedTuition = tuition;
    notifyListeners();
  }

  /// Clear selected tuition
  void clearSelectedTuition() {
    _selectedTuition = null;
    _sessionHistory = [];
    notifyListeners();
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Set loading state and notify listeners
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Clear error message
  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }
}
