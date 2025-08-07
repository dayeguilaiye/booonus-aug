class PointsHistoryWithUser {
  final int id;
  final int userId;
  final int points;
  final String type;
  final int? referenceId;
  final String description;
  final bool canRevert;
  final bool isReverted;
  final DateTime createdAt;
  final String username;

  PointsHistoryWithUser({
    required this.id,
    required this.userId,
    required this.points,
    required this.type,
    this.referenceId,
    required this.description,
    required this.canRevert,
    required this.isReverted,
    required this.createdAt,
    required this.username,
  });

  factory PointsHistoryWithUser.fromJson(Map<String, dynamic> json) {
    return PointsHistoryWithUser(
      id: json['id'],
      userId: json['user_id'],
      points: json['points'],
      type: json['type'] ?? '',
      referenceId: json['reference_id'],
      description: json['description'],
      canRevert: json['can_revert'] ?? false,
      isReverted: json['is_reverted'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      username: json['username'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'points': points,
      'type': type,
      'reference_id': referenceId,
      'description': description,
      'can_revert': canRevert,
      'is_reverted': isReverted,
      'created_at': createdAt.toIso8601String(),
      'username': username,
    };
  }
}
