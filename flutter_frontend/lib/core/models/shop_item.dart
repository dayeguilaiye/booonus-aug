class ShopItem {
  final int id;
  final String name;
  final String description;
  final int price;
  final int ownerId;
  final String username;
  final DateTime createdAt;

  ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.ownerId,
    required this.username,
    required this.createdAt,
  });

  factory ShopItem.fromJson(Map<String, dynamic> json) {
    return ShopItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: json['price'] ?? 0,
      ownerId: json['owner_id'] ?? 0,
      username: json['username'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'owner_id': ownerId,
      'username': username,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ShopItem copyWith({
    int? id,
    String? name,
    String? description,
    int? price,
    int? ownerId,
    String? username,
    DateTime? createdAt,
  }) {
    return ShopItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      ownerId: ownerId ?? this.ownerId,
      username: username ?? this.username,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'ShopItem{id: $id, name: $name, description: $description, price: $price, ownerId: $ownerId, username: $username, createdAt: $createdAt}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShopItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
