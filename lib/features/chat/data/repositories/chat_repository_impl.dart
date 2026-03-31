import 'package:dartz/dartz.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/entities/chat_conversation_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../datasources/chat_remote_data_source.dart';
import '../../../../core/errors/failures.dart';
import '../../../../services/logger_service.dart';
import '../../../../models/models.dart' as legacy;

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;

  ChatRepositoryImpl(this.remoteDataSource);

  ChatConversationEntity _mapConversation(legacy.ChatConversation model) {
    return ChatConversationEntity(
      id: model.id,
      otherUserId: model.otherUserId,
      otherUserName: model.otherUserName,
      otherUserAvatar: model.otherUserAvatar,
      lastMessage: model.lastMessage,
      lastMessageTime: model.lastMessageTime,
      unreadCount: model.unreadCount,
    );
  }

  MessageEntity _mapMessage(legacy.Message model) {
    return MessageEntity(
      id: model.id,
      conversationId: model.conversationId,
      senderId: model.senderId,
      content: model.content,
      type: model.type,
      createdAt: model.createdAt,
      isRead: model.isRead,
      isDeleted: model.isDeleted,
      replyToId: model.replyToId,
    );
  }

  @override
  Future<Either<Failure, List<ChatConversationEntity>>> getConversations() async {
    try {
      final models = await remoteDataSource.getConversations();
      final entities = models.map(_mapConversation).toList();
      return Right(entities);
    } catch (e) {
      logger.e('Failed to get conversations', error: e);
      return Left(ServerFailure('Failed to load conversations: \$e'));
    }
  }

  @override
  Stream<List<MessageEntity>> getMessagesStream(String conversationId) {
    return remoteDataSource.getMessagesStream(conversationId).map(
      (models) => models.map(_mapMessage).toList(),
    );
  }

  @override
  Future<Either<Failure, void>> sendMessage(String conversationId, String content, {String type = 'text', String? replyToId}) async {
    try {
      await remoteDataSource.sendMessage(conversationId, content, type: type, replyToId: replyToId);
      return const Right(null);
    } catch (e) {
      logger.e('Failed to send message', error: e);
      return Left(ServerFailure('Failed to send message: \$e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMessage(String messageId) async {
    try {
      await remoteDataSource.deleteMessage(messageId);
      return const Right(null);
    } catch (e) {
      logger.e('Failed to delete message', error: e);
      return Left(ServerFailure('Failed to delete message: \$e'));
    }
  }

  @override
  Future<Either<Failure, void>> markConversationAsRead(String conversationId) async {
    try {
      await remoteDataSource.markConversationAsRead(conversationId);
      return const Right(null);
    } catch (e) {
      logger.e('Failed to mark conversation as read', error: e);
      return Left(ServerFailure('Failed to mark conversation as read: \$e'));
    }
  }

  @override
  Future<Either<Failure, void>> blockUser(String userId) async {
    try {
      await remoteDataSource.blockUser(userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to block user: \$e'));
    }
  }

  @override
  Future<Either<Failure, void>> unblockUser(String userId) async {
    try {
      await remoteDataSource.unblockUser(userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to unblock user: \$e'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getBlockedUserIds() async {
    try {
      final ids = await remoteDataSource.getBlockedUserIds();
      return Right(ids);
    } catch (e) {
      return Left(ServerFailure('Failed to get blocked user ids: \$e'));
    }
  }

  @override
  Future<Either<Failure, bool>> isUserBlocked(String userId) async {
    try {
      final blocked = await remoteDataSource.isUserBlocked(userId);
      return Right(blocked);
    } catch (e) {
      return Left(ServerFailure('Failed to check if user is blocked: \$e'));
    }
  }

  @override
  Future<Either<Failure, void>> reportUser(String userId, String reason) async {
    try {
      await remoteDataSource.reportUser(userId, reason);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to report user: \$e'));
    }
  }

  @override
  Future<Either<Failure, void>> markAllConversationsAsRead() async {
    try {
      await remoteDataSource.markAllConversationsAsRead();
      return const Right(null);
    } catch (e) {
      logger.e('Failed to mark all as read', error: e);
      return Left(ServerFailure('Failed to mark all as read: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteConversation(String conversationId) async {
    try {
      await remoteDataSource.deleteConversation(conversationId);
      return const Right(null);
    } catch (e) {
      logger.e('Failed to delete conversation', error: e);
      return Left(ServerFailure('Failed to delete conversation: $e'));
    }
  }
}
