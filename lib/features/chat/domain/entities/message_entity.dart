import 'package:equatable/equatable.dart';

class MessageEntity extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final String type; // 'text', 'image', 'audio'
  final DateTime createdAt;
  final bool isDeleted;
  final bool isRead;
  final String? replyToId;
  final bool isPending;

  const MessageEntity({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.type,
    required this.createdAt,
    required this.isRead,
    this.isDeleted = false,
    this.replyToId,
    this.isPending = false,
  });

  @override
  List<Object?> get props => [
        id,
        conversationId,
        senderId,
        content,
        type,
        createdAt,
        isRead,
        isDeleted,
        replyToId,
        isPending,
      ];
}
