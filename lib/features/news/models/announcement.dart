import 'package:equatable/equatable.dart';

enum AnnouncementCategory {
  warning,
  update,
  event,
  community,
}

class Announcement extends Equatable {
  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final String authorId;
  final String? authorName;
  final String? authorAvatarUrl;
  final AnnouncementCategory category;
  final bool isVerified;
  final DateTime createdAt;

  const Announcement({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.authorId,
    this.authorName,
    this.authorAvatarUrl,
    required this.category,
    this.isVerified = false,
    required this.createdAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    // Handling profiles join if provided
    final profile = json['profiles'] as Map<String, dynamic>?;
    
    return Announcement(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      imageUrl: json['image_url'] as String?,
      authorId: json['author_id'] as String,
      authorName: profile?['name'] as String?,
      authorAvatarUrl: profile?['avatar_url'] as String?,
      category: _parseCategory(json['category'] as String?),
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static AnnouncementCategory _parseCategory(String? category) {
    switch (category?.toLowerCase()) {
      case 'warning':
        return AnnouncementCategory.warning;
      case 'update':
        return AnnouncementCategory.update;
      case 'event':
        return AnnouncementCategory.event;
      case 'community':
      default:
        return AnnouncementCategory.community;
    }
  }

  @override
  List<Object?> get props => [
        id,
        title,
        content,
        imageUrl,
        authorId,
        authorName,
        authorAvatarUrl,
        category,
        isVerified,
        createdAt,
      ];
}
