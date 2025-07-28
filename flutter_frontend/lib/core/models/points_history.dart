class PointsHistory {
  final int id;
  final int userId;
  final int points;
  final String description;
  final DateTime createdAt;

  PointsHistory({
    required this.id,
    required this.userId,
    required this.points,
    required this.description,
    required this.createdAt,
  });

  factory PointsHistory.fromJson(Map<String, dynamic> json) {
    return PointsHistory(
      id: json['id'],
      userId: json['user_id'],
      points: json['points'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'points': points,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
