import '../../profile/models/user.dart';

class EventComment {
  final String id;
  final String eventId;
  final String userId;
  final String userName;
  final String userAvatarUrl;
  final String content;
  final String? parentId;
  final DateTime createdAt;
  final List<EventComment> replies;

  EventComment({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    required this.userAvatarUrl,
    required this.content,
    this.parentId,
    required this.createdAt,
    this.replies = const [],
  });

  factory EventComment.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>? ?? {};
    
    return EventComment(
      id: json['id'].toString(),
      eventId: json['event_id'].toString(),
      userId: json['user_id'].toString(),
      userName: profile['name'] ?? 'Unknown',
      userAvatarUrl: sanitizeAvatarUrl(profile['avatar_url']),
      content: json['content'] ?? '',
      parentId: json['parent_id']?.toString(),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      replies: [],
    );
  }

  EventComment copyWith({
    List<EventComment>? replies,
  }) {
    return EventComment(
      id: id,
      eventId: eventId,
      userId: userId,
      userName: userName,
      userAvatarUrl: userAvatarUrl,
      content: content,
      parentId: parentId,
      createdAt: createdAt,
      replies: replies ?? this.replies,
    );
  }
}
