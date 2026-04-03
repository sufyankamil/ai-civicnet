import 'package:equatable/equatable.dart';

class ChatConversationEntity extends Equatable {
  final String id;
  final String otherUserId;
  final String otherUserName;
  final String otherUserAvatar;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;

  const ChatConversationEntity({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserAvatar,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
  });

  @override
  List<Object?> get props => [
        id,
        otherUserId,
        otherUserName,
        otherUserAvatar,
        lastMessage,
        lastMessageTime,
        unreadCount,
      ];

  ChatConversationEntity copyWith({
    String? id,
    String? otherUserId,
    String? otherUserName,
    String? otherUserAvatar,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
  }) {
    return ChatConversationEntity(
      id: id ?? this.id,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserAvatar: otherUserAvatar ?? this.otherUserAvatar,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
