import '../../../../core/usecases/usecase.dart';
import '../repositories/chat_repository.dart';
import '../entities/chat_conversation_entity.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';

class GetConversationsUseCase implements UseCase<List<ChatConversationEntity>, NoParams> {
  final ChatRepository repository;
  GetConversationsUseCase(this.repository);

  @override
  Future<Either<Failure, List<ChatConversationEntity>>> call(NoParams params) {
    return repository.getConversations();
  }
}

class SendMessageParams {
  final String conversationId;
  final String content;
  final String type;

  SendMessageParams({required this.conversationId, required this.content, this.type = 'text'});
}

class SendMessageUseCase implements UseCase<void, SendMessageParams> {
  final ChatRepository repository;
  SendMessageUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(SendMessageParams params) {
    return repository.sendMessage(params.conversationId, params.content, type: params.type);
  }
}

class MarkConversationAsReadParams {
  final String conversationId;

  MarkConversationAsReadParams({required this.conversationId});
}

class MarkConversationAsReadUseCase implements UseCase<void, MarkConversationAsReadParams> {
  final ChatRepository repository;
  MarkConversationAsReadUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(MarkConversationAsReadParams params) {
    return repository.markConversationAsRead(params.conversationId);
  }
}
