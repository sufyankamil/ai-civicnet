import 'package:dartz/dartz.dart';
import '../errors/failures.dart';

/// Base interface for all UseCases
/// UseCases encapsulate specific business rules and use Repositories to get/save data.
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// Use this for UseCases that don't need any parameters
class NoParams {
  const NoParams();
}
