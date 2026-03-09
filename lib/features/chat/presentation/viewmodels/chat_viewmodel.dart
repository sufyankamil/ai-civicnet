import 'dart:async';
import 'package:get/get.dart';
import '../../domain/usecases/chat_usecases.dart';
import '../../domain/entities/chat_conversation_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../../../services/logger_service.dart';
import '../../../../core/usecases/usecase.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class ChatViewModel extends GetxController {
  final GetConversationsUseCase getConversationsUseCase;
  final SendMessageUseCase sendMessageUseCase;
  final MarkConversationAsReadUseCase markConversationAsReadUseCase;
  final MarkAllConversationsAsReadUseCase markAllConversationsAsReadUseCase;

  ChatViewModel({
    required this.getConversationsUseCase,
    required this.sendMessageUseCase,
    required this.markConversationAsReadUseCase,
    required this.markAllConversationsAsReadUseCase,
  });

  final RxList<ChatConversationEntity> _conversations = <ChatConversationEntity>[].obs;
  final RxBool _isLoading = false.obs;
  final RxBool _isSending = false.obs;
  RealtimeChannel? _messageSubscription;
  StreamSubscription? _authSubscription;
  String? _currentUserId;

  List<ChatConversationEntity> get conversations => _conversations;
  bool get isLoading => _isLoading.value;
  bool get isSending => _isSending.value;

  final RxInt _totalUnreadCount = 0.obs;
  int get totalUnreadCount => _totalUnreadCount.value;

  void _updateUnreadCount() {
    _totalUnreadCount.value = _conversations.fold(0, (sum, conv) => sum + conv.unreadCount);
  }

  @override
  void onInit() {
    super.onInit();
    
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      final newUserId = session?.user.id;

      if (newUserId != _currentUserId) {
        _currentUserId = newUserId;
        if (newUserId == null) {
          // Logged out
          _conversations.clear();
          _updateUnreadCount();
          _messageSubscription?.unsubscribe();
          _messageSubscription = null;
        } else {
          // New user logged in
          _conversations.clear();
          _updateUnreadCount();
          fetchConversations();
          _setupRealtime();
        }
      }
    });

    if (_currentUserId != null) {
      fetchConversations();
      _setupRealtime();
    }
  }

  void _setupRealtime() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return;

    _messageSubscription?.unsubscribe();

    _messageSubscription = Supabase.instance.client
        .channel('public:messages:badge_update_$currentUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
             final newRecord = payload.newRecord;
             if (newRecord['sender_id'] != currentUserId) {
                fetchConversations();
             }
          },
        )
        .subscribe();
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    _messageSubscription?.unsubscribe();
    super.onClose();
  }

  Future<void> fetchConversations() async {
    _isLoading.value = true;
    final result = await getConversationsUseCase(const NoParams());
    
    result.fold(
      (failure) {
        logger.e('Failed to fetch conversations: ${failure.message}');
      },
      (convos) {
        _conversations.assignAll(convos);
        _updateUnreadCount();
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

  Future<bool> markConversationAsRead(String conversationId) async {
    final params = MarkConversationAsReadParams(conversationId: conversationId);
    final result = await markConversationAsReadUseCase(params);
    
    return result.fold(
      (failure) {
        logger.e('Failed to mark conversation as read: ${failure.message}');
        return false;
      },
      (_) {
        // Optimistically update the UI by resetting the unread count for this conversation
        final index = _conversations.indexWhere((c) => c.id == conversationId);
        if (index != -1) {
          final updatedConv = _conversations[index].copyWith(unreadCount: 0);
          _conversations[index] = updatedConv;
          _updateUnreadCount();
        }
        return true;
      },
    );
  }

  Future<bool> markAllMessagesAsRead() async {
    _isLoading.value = true;
    final result = await markAllConversationsAsReadUseCase(const NoParams());
    _isLoading.value = false;
    
    return result.fold(
      (failure) {
        logger.e('Failed to mark all as read: ${failure.message}');
        return false;
      },
      (_) {
        // Update all local conversations unreadCount to 0
        for (int i = 0; i < _conversations.length; i++) {
          if (_conversations[i].unreadCount > 0) {
            _conversations[i] = _conversations[i].copyWith(unreadCount: 0);
          }
        }
        _updateUnreadCount();
        return true;
      },
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
