class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final String type; // 'text', 'image', 'audio'
  final DateTime createdAt;
  final bool isDeleted;
  final bool isRead;
  final String? replyToId;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.type,
    required this.createdAt,
    required this.isRead,
    this.isDeleted = false,
    this.replyToId,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      conversationId: json['conversation_id'],
        senderId: json['sender_id'],
        content: json['content'] ?? '',
        type: json['message_type'] ?? 'text',
        createdAt: DateTime.parse(json['created_at']),
        isRead: json['is_read'] ?? false,
        isDeleted: json['is_deleted'] ?? false,
        replyToId: json['reply_to_id'],
    );
  }
}
