import 'dart:async';
import 'package:get/get.dart';
import '../../domain/usecases/chat_usecases.dart';
import '../../domain/entities/chat_conversation_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../../../services/logger_service.dart';
import '../../../../core/usecases/usecase.dart';

class ChatViewModel extends GetxController {
  final GetConversationsUseCase getConversationsUseCase;
  final SendMessageUseCase sendMessageUseCase;

  ChatViewModel({
    required this.getConversationsUseCase,
    required this.sendMessageUseCase,
  });

  final RxList<ChatConversationEntity> _conversations = <ChatConversationEntity>[].obs;
  final RxBool _isLoading = false.obs;
  final RxBool _isSending = false.obs;

  List<ChatConversationEntity> get conversations => _conversations;
  bool get isLoading => _isLoading.value;
  bool get isSending => _isSending.value;

  @override
  void onInit() {
    super.onInit();
    fetchConversations();
  }

  Future<void> fetchConversations() async {
    _isLoading.value = true;
    final result = await getConversationsUseCase(const NoParams());
    
    result.fold(
      (failure) {
        logger.e('Failed to fetch conversations: ${failure.message}');
      },
      (convos) {
        _conversations.value = convos;
      },
    );
    _isLoading.value = false;
  }

  Stream<List<MessageEntity>> getMessagesStream(String conversationId) {
    // For streams, usecases are a bit verbose without stream support, so we pass through repository
    return getConversationsUseCase.repository.getMessagesStream(conversationId);
  }

  Future<bool> sendMessage(String conversationId, String content, {String type = 'text'}) async {
    if (content.isEmpty || _isSending.value) return false;
    
    _isSending.value = true;
    final params = SendMessageParams(conversationId: conversationId, content: content, type: type);
    final result = await sendMessageUseCase(params);
    
    _isSending.value = false;
    return result.fold(
      (failure) {
        logger.e('Failed to send message: ${failure.message}');
        return false;
      },
      (_) => true,
    );
  }

  Future<bool> isUserBlocked(String userId) async {
    final result = await getConversationsUseCase.repository.isUserBlocked(userId);
    return result.fold((l) => false, (r) => r);
  }

  Future<List<String>> getBlockedUserIds() async {
    final result = await getConversationsUseCase.repository.getBlockedUserIds();
    return result.fold((l) => [], (r) => r);
  }

  Future<bool> blockUser(String userId) async {
    final result = await getConversationsUseCase.repository.blockUser(userId);
    return result.fold((l) => false, (r) => true);
  }

  Future<bool> unblockUser(String userId) async {
    final result = await getConversationsUseCase.repository.unblockUser(userId);
    return result.fold((l) => false, (r) => true);
  }

  Future<bool> reportUser(String userId, String reason) async {
    final result = await getConversationsUseCase.repository.reportUser(userId, reason);
    return result.fold((l) => false, (r) => true);
  }
}
