class Event {
  final int id;
  final String name;
  final String description;
  final int points;
  final int creatorId;
  final String creatorName;
  final int targetId;
  final String targetName;
  final DateTime createdAt;

  Event({
    required this.id,
    required this.name,
    required this.description,
    required this.points,
    required this.creatorId,
    required this.creatorName,
    required this.targetId,
    required this.targetName,
    required this.createdAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    try {
      print('Event.fromJson - 输入数据: $json');

      // 逐个字段解析，捕获具体错误
      final id = json['id'] ?? 0;
      print('Event.fromJson - id: $id (${id.runtimeType})');

      final name = json['name'] ?? '';
      print('Event.fromJson - name: $name (${name.runtimeType})');

      final description = json['description'] ?? '';
      print('Event.fromJson - description: $description (${description.runtimeType})');

      final points = json['points'] ?? 0;
      print('Event.fromJson - points: $points (${points.runtimeType})');

      final creatorId = json['creator_id'] ?? 0;
      print('Event.fromJson - creatorId: $creatorId (${creatorId.runtimeType})');

      final creatorName = json['creator_name'] ?? '';
      print('Event.fromJson - creatorName: $creatorName (${creatorName.runtimeType})');

      final targetId = json['target_id'] ?? 0;
      print('Event.fromJson - targetId: $targetId (${targetId.runtimeType})');

      final targetName = json['target_name'] ?? '';
      print('Event.fromJson - targetName: $targetName (${targetName.runtimeType})');

      final createdAtStr = json['created_at'] ?? '';
      print('Event.fromJson - createdAtStr: $createdAtStr (${createdAtStr.runtimeType})');
      final createdAt = DateTime.tryParse(createdAtStr.toString()) ?? DateTime.now();
      print('Event.fromJson - createdAt: $createdAt');

      return Event(
        id: id is int ? id : int.tryParse(id.toString()) ?? 0,
        name: name.toString(),
        description: description.toString(),
        points: points is int ? points : int.tryParse(points.toString()) ?? 0,
        creatorId: creatorId is int ? creatorId : int.tryParse(creatorId.toString()) ?? 0,
        creatorName: creatorName.toString(),
        targetId: targetId is int ? targetId : int.tryParse(targetId.toString()) ?? 0,
        targetName: targetName.toString(),
        createdAt: createdAt,
      );
    } catch (e, stackTrace) {
      print('Event.fromJson - 解析失败: $e');
      print('Event.fromJson - 输入数据: $json');
      print('Event.fromJson - 堆栈跟踪: $stackTrace');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'points': points,
      'creator_id': creatorId,
      'creator_name': creatorName,
      'target_id': targetId,
      'target_name': targetName,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Event copyWith({
    int? id,
    String? name,
    String? description,
    int? points,
    int? creatorId,
    String? creatorName,
    int? targetId,
    String? targetName,
    DateTime? createdAt,
  }) {
    return Event(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      points: points ?? this.points,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      targetId: targetId ?? this.targetId,
      targetName: targetName ?? this.targetName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String formatDate() {
    return '${createdAt.month}月${createdAt.day}日 ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'Event{id: $id, name: $name, description: $description, points: $points, creatorId: $creatorId, creatorName: $creatorName, targetId: $targetId, targetName: $targetName, createdAt: $createdAt}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Event &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
