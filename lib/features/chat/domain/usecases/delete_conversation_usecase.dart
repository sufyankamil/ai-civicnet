import '../../../../core/usecases/usecase.dart';
import '../repositories/chat_repository.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';

class DeleteConversationParams {
  final String conversationId;

  DeleteConversationParams({required this.conversationId});
}

class DeleteConversationUseCase implements UseCase<void, DeleteConversationParams> {
  final ChatRepository repository;
  DeleteConversationUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteConversationParams params) {
    return repository.deleteConversation(params.conversationId);
  }
}
