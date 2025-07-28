import 'user.dart';

class Couple {
  final int id;
  final User partner;
  final DateTime createdAt;

  Couple({
    required this.id,
    required this.partner,
    required this.createdAt,
  });

  factory Couple.fromJson(Map<String, dynamic> json) {
    return Couple(
      id: json['id'],
      partner: User.fromJson(json['partner']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'partner': partner.toJson(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
