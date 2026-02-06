/// Represents a single attendance session/class marking.
class SessionModel {
  /// Unique identifier for the session document
  final String id;

  /// Date when the attendance was marked (timestamp)
  final DateTime date;

  /// When the session record was created in Firestore
  final DateTime createdAt;

  SessionModel({required this.id, required this.date, required this.createdAt});

  /// Convert SessionModel to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {'date': date, 'createdAt': createdAt};
  }

  /// Create SessionModel from Firestore JSON
  factory SessionModel.fromJson(Map<String, dynamic> json, String id) {
    return SessionModel(
      id: id,
      date: (json['date'] as dynamic)?.toDate() ?? DateTime.now(),
      createdAt: (json['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  @override
  String toString() => 'SessionModel(id: $id, date: $date)';
}
