import '../entities/chat_conversation_entity.dart';
import '../entities/message_entity.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';

abstract class ChatRepository {
  Future<Either<Failure, List<ChatConversationEntity>>> getConversations();
  Stream<List<MessageEntity>> getMessagesStream(String conversationId);
  Future<Either<Failure, void>> sendMessage(String conversationId, String content, {String type = 'text'});
  Future<Either<Failure, void>> markConversationAsRead(String conversationId);
  Future<Either<Failure, void>> blockUser(String userId);
  Future<Either<Failure, void>> unblockUser(String userId);
  Future<Either<Failure, List<String>>> getBlockedUserIds();
  Future<Either<Failure, bool>> isUserBlocked(String userId);
  Future<Either<Failure, void>> reportUser(String userId, String reason);
}
