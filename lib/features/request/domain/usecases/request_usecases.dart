import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/help_request_entity.dart';
import '../repositories/request_repository.dart';
import '../entities/request_enums.dart';

class GetHelpRequestsUseCase implements UseCase<List<HelpRequestEntity>, NoParams> {
  final RequestRepository repository;
  GetHelpRequestsUseCase(this.repository);

  @override
  Future<Either<Failure, List<HelpRequestEntity>>> call(NoParams params) async {
    return await repository.getHelpRequests();
  }
}

class GetMyHelpRequestsUseCase implements UseCase<List<HelpRequestEntity>, NoParams> {
  final RequestRepository repository;
  GetMyHelpRequestsUseCase(this.repository);

  @override
  Future<Either<Failure, List<HelpRequestEntity>>> call(NoParams params) async {
    return await repository.getMyHelpRequests();
  }
}

class GetHelpRequestParams {
  final String id;
  const GetHelpRequestParams(this.id);
}

class GetHelpRequestUseCase implements UseCase<HelpRequestEntity, GetHelpRequestParams> {
  final RequestRepository repository;
  GetHelpRequestUseCase(this.repository);

  @override
  Future<Either<Failure, HelpRequestEntity>> call(GetHelpRequestParams params) async {
    return await repository.getHelpRequest(params.id);
  }
}

class CreateHelpRequestUseCase implements UseCase<void, HelpRequestEntity> {
  final RequestRepository repository;
  CreateHelpRequestUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(HelpRequestEntity params) async {
    return await repository.createHelpRequest(params);
  }
}

class UpdateRequestStatusParams {
  final String requestId;
  final RequestStatusEnum status;
  const UpdateRequestStatusParams(this.requestId, this.status);
}

class UpdateRequestStatusUseCase implements UseCase<void, UpdateRequestStatusParams> {
  final RequestRepository repository;
  UpdateRequestStatusUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateRequestStatusParams params) async {
    return await repository.updateHelpRequestStatus(params.requestId, params.status);
  }
}

class DeleteHelpRequestUseCase implements UseCase<void, String> {
  final RequestRepository repository;

  DeleteHelpRequestUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String requestId) async {
    return await repository.deleteHelpRequest(requestId);
  }
}
