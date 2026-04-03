import 'package:equatable/equatable.dart';

class Badge extends Equatable {
  final String id;
  final String name;
  final String description;
  final String? iconUrl;
  final DateTime? awardedAt;

  const Badge({
    required this.id,
    required this.name,
    required this.description,
    this.iconUrl,
    this.awardedAt,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      iconUrl: json['icon_url'],
      awardedAt: json['awarded_at'] != null ? DateTime.parse(json['awarded_at']) : null,
    );
  }

  @override
  List<Object?> get props => [id, name, description, iconUrl, awardedAt];
}
