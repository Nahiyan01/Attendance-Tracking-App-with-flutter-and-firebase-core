/// Represents a tuition/class record with attendance tracking.
class TuitionModel {
  /// Unique identifier for the tuition document
  final String id;

  /// Name of the tuition/class
  final String name;

  /// Days of week when classes are held (e.g., ['Monday', 'Wednesday', 'Friday'])
  final List<String> days;

  /// Number of students in this tuition
  final int studentCount;

  /// Total number of sessions/classes marked
  final int sessionCount;

  /// When this tuition was created
  final DateTime createdAt;

  /// When this tuition was last updated
  final DateTime lastUpdated;

  TuitionModel({
    required this.id,
    required this.name,
    required this.days,
    required this.studentCount,
    required this.sessionCount,
    required this.createdAt,
    required this.lastUpdated,
  });

  /// Create a copy of TuitionModel with some fields replaced
  TuitionModel copyWith({
    String? id,
    String? name,
    List<String>? days,
    int? studentCount,
    int? sessionCount,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return TuitionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      days: days ?? this.days,
      studentCount: studentCount ?? this.studentCount,
      sessionCount: sessionCount ?? this.sessionCount,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Convert TuitionModel to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'days': days,
      'studentCount': studentCount,
      'sessionCount': sessionCount,
      'createdAt': createdAt,
      'lastUpdated': lastUpdated,
    };
  }

  /// Create TuitionModel from Firestore JSON
  factory TuitionModel.fromJson(Map<String, dynamic> json, String id) {
    return TuitionModel(
      id: id,
      name: json['name'] as String? ?? '',
      days: List<String>.from(json['days'] as List? ?? []),
      studentCount: json['studentCount'] as int? ?? 0,
      sessionCount: json['sessionCount'] as int? ?? 0,
      createdAt: (json['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      lastUpdated: (json['lastUpdated'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  @override
  String toString() =>
      'TuitionModel(id: $id, name: $name, days: $days, sessionCount: $sessionCount)';
}
