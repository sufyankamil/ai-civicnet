
enum SupportSenderType {
  user,
  bot,
  agent
}

class SupportMessage {
  final String id;
  final String conversationId;
  final SupportSenderType senderType;
  final String content;
  final List<String>? options;
  final DateTime createdAt;

  SupportMessage({
    required this.id,
    required this.conversationId,
    required this.senderType,
    required this.content,
    this.options,
    required this.createdAt,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderType: SupportSenderType.values.firstWhere(
        (e) => e.name == json['sender_type'],
        orElse: () => SupportSenderType.bot,
      ),
      content: json['content'] as String,
      options: json['options'] != null 
          ? List<String>.from(json['options'] as List) 
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversation_id': conversationId,
      'sender_type': senderType.name,
      'content': content,
      'options': options,
    };
  }
}

class SupportConversation {
  final String id;
  final String userId;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  SupportConversation({
    required this.id,
    required this.userId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupportConversation.fromJson(Map<String, dynamic> json) {
    return SupportConversation(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      status: json['status'] as String? ?? 'open',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
