import '../../../../services/supabase_service.dart';
import '../../../../models/models.dart' as legacy;

class ChatRemoteDataSource {
  final SupabaseService supabaseService;

  ChatRemoteDataSource(this.supabaseService);

  Future<List<legacy.ChatConversation>> getConversations() {
    return supabaseService.getConversations();
  }

  Stream<List<legacy.Message>> getMessagesStream(String conversationId) {
    return supabaseService.getMessagesStream(conversationId);
  }

  Future<void> sendMessage(String conversationId, String content, {String type = 'text', String? replyToId}) {
    return supabaseService.sendMessage(conversationId, content, type: type, replyToId: replyToId);
  }

  Future<void> deleteMessage(String messageId) {
    return supabaseService.deleteMessage(messageId);
  }

  Future<void> markConversationAsRead(String conversationId) {
    return supabaseService.markConversationAsRead(conversationId);
  }

  Future<void> markAllConversationsAsRead() {
    return supabaseService.markAllConversationsAsRead();
  }

  Future<void> blockUser(String userId) {
    return supabaseService.blockUser(userId);
  }

  Future<void> unblockUser(String userId) {
    return supabaseService.unblockUser(userId);
  }

  Future<List<String>> getBlockedUserIds() {
    return supabaseService.getBlockedUserIds();
  }

  Future<bool> isUserBlocked(String userId) {
    return supabaseService.isUserBlocked(userId);
  }

  Future<void> reportUser(String userId, String reason) {
    return supabaseService.reportUser(userId, reason);
  }

  Future<void> deleteConversation(String conversationId) {
    return supabaseService.deleteConversation(conversationId);
  }
}
