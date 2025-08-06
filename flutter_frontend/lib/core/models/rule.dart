class Rule {
  final int id;
  final String name;
  final String description;
  final int points;
  final String targetType;
  final int creatorId;
  final String creatorName;
  final DateTime createdAt;

  Rule({
    required this.id,
    required this.name,
    required this.description,
    required this.points,
    required this.targetType,
    required this.creatorId,
    required this.creatorName,
    required this.createdAt,
  });

  factory Rule.fromJson(Map<String, dynamic> json) {
    return Rule(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      points: json['points'] ?? 0,
      targetType: json['target_type'] ?? 'both',
      creatorId: json['creator_id'] ?? 0,
      creatorName: json['creator_name'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'points': points,
      'target_type': targetType,
      'creator_id': creatorId,
      'creator_name': creatorName,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Rule copyWith({
    int? id,
    String? name,
    String? description,
    int? points,
    String? targetType,
    int? creatorId,
    String? creatorName,
    DateTime? createdAt,
  }) {
    return Rule(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      points: points ?? this.points,
      targetType: targetType ?? this.targetType,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String getTargetTypeText() {
    switch (targetType) {
      case 'current_user':
        return '我';
      case 'partner':
        return '对方';
      case 'both':
        return '双方';
      // 兼容旧格式
      case 'user1':
        return '用户1';
      case 'user2':
        return '用户2';
      default:
        return targetType;
    }
  }

  @override
  String toString() {
    return 'Rule{id: $id, name: $name, description: $description, points: $points, targetType: $targetType, creatorId: $creatorId, creatorName: $creatorName, createdAt: $createdAt}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Rule &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
