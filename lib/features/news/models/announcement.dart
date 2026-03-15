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
  final String? sourceUrl;
  final DateTime createdAt;
  final int voteCount;
  final bool isVotedByMe;

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
    this.sourceUrl,
    required this.createdAt,
    this.voteCount = 0,
    this.isVotedByMe = false,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    // Handling profiles join if provided
    final profile = json['profiles'] as Map<String, dynamic>?;
    
    // Handling votes count and user vote state
    // Use the denormalized votes_count column for performance
    final votesCount = json['votes_count'] as int? ?? 0;
    final userVoted = json['user_voted'] as bool? ?? false;

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
      sourceUrl: json['source_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      voteCount: votesCount,
      isVotedByMe: userVoted,
    );
  }

  Announcement copyWith({
    String? id,
    String? title,
    String? content,
    String? imageUrl,
    String? authorId,
    String? authorName,
    String? authorAvatarUrl,
    AnnouncementCategory? category,
    bool? isVerified,
    String? sourceUrl,
    DateTime? createdAt,
    int? voteCount,
    bool? isVotedByMe,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      category: category ?? this.category,
      isVerified: isVerified ?? this.isVerified,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      createdAt: createdAt ?? this.createdAt,
      voteCount: voteCount ?? this.voteCount,
      isVotedByMe: isVotedByMe ?? this.isVotedByMe,
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
        sourceUrl,
        createdAt,
        voteCount,
        isVotedByMe,
      ];
}
