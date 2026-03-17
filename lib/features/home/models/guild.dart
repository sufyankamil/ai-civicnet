import 'package:equatable/equatable.dart';

class Guild extends Equatable {
  final String id;
  final String creatorId;
  final String name;
  final String? description;
  final String category;
  final String? avatarUrl;
  final int memberCount;
  final bool isPrivate;
  final DateTime createdAt;
  final bool isUserMember;

  const Guild({
    required this.id,
    required this.creatorId,
    required this.name,
    this.description,
    required this.category,
    this.avatarUrl,
    this.memberCount = 1,
    this.isPrivate = false,
    required this.createdAt,
    this.isUserMember = false,
  });

  factory Guild.fromJson(Map<String, dynamic> json, {bool isUserMember = false}) {
    return Guild(
      id: json['id'],
      creatorId: json['creator_id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      avatarUrl: json['avatar_url'],
      memberCount: json['member_count'] ?? 1,
      isPrivate: json['is_private'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      isUserMember: isUserMember,
    );
  }

  @override
  List<Object?> get props => [id, creatorId, name, description, category, avatarUrl, memberCount, isPrivate, createdAt, isUserMember];
}
