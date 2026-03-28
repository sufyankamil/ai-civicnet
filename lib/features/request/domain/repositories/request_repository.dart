import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/help_request_entity.dart';
import '../entities/request_enums.dart';

abstract class RequestRepository {
  Future<Either<Failure, List<HelpRequestEntity>>> getHelpRequests();
  Future<Either<Failure, List<HelpRequestEntity>>> getMyHelpRequests();
  Future<Either<Failure, HelpRequestEntity>> getHelpRequest(String id);
  Future<Either<Failure, void>> createHelpRequest(HelpRequestEntity request);
  Future<Either<Failure, void>> updateHelpRequestStatus(String requestId, RequestStatusEnum status);
  Future<Either<Failure, void>> deleteHelpRequest(String requestId);
  
  // Realtime subscription callback
  void subscribeToHelpRequests(Function() callback);
  void unsubscribeFromHelpRequests();
}
