/// Where tapping a push notification should go, from its data payload, or null
/// when there is nowhere to go.
String? routeForNotification(Map<String, dynamic> data) {
  final type = data['type']?.toString().toLowerCase() ?? '';
  final relatedId =
      data['related_id'] ??
      data['conversationId'] ??
      data['conversation_id'] ??
      data['id'] ??
      data['requestId'] ??
      data['eventId'];
  if (relatedId == null) return null;

  // An SOS opens the request straight away, like any new request.
  if (type == 'new_request' || type == 'sos') return '/request/$relatedId';
  if (type.contains('chat') ||
      type.contains('message') ||
      data.containsKey('conversationId') ||
      data.containsKey('conversation_id')) {
    return '/chat-detail?id=$relatedId';
  }
  if (type == 'event') return '/event/$relatedId';
  return null;
}
