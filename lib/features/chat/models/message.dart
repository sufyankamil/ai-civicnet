class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final String type; // 'text', 'image', 'audio'
  final DateTime createdAt;
  final bool isRead;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.type,
    required this.createdAt,
    required this.isRead,
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
    );
  }
}
