import '../../../../core/usecases/usecase.dart';
import '../repositories/chat_repository.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';

class DeleteMessageParams {
  final String messageId;

  DeleteMessageParams({required this.messageId});
}

class DeleteMessageUseCase implements UseCase<void, DeleteMessageParams> {
  final ChatRepository repository;
  DeleteMessageUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteMessageParams params) {
    return repository.deleteMessage(params.messageId);
  }
}
