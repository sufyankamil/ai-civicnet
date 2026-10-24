import 'dart:async';
import '../errors/exceptions.dart';
import '../../services/service_health_service.dart';

extension FutureTimeoutExtension<T> on Future<T> {
  /// Adds a global timeout to any Future.
  /// Throws a [ServerException] if the [Future] does not complete within [seconds].
  Future<T> withServerTimeout([int seconds = 10, String? operation]) {
    return timeout(
      Duration(seconds: seconds),
      onTimeout: () {
        const err = ServerException(
          'Unable to reach server. Please try again.',
        );
        ServiceHealthService().recordFailure(
          operation: operation ?? 'Server Request Timeout',
          error: err,
        );
        throw err;
      },
    );
  }

  /// Automatically tracks operation success or failure in [ServiceHealthService]
  Future<T> trackHealth({required String operation}) {
    return then((value) {
      ServiceHealthService().recordSuccess(operation: operation);
      return value;
    }).catchError((error, stackTrace) {
      ServiceHealthService().recordFailure(
        operation: operation,
        error: error,
        stackTrace: stackTrace,
      );
      throw error;
    });
  }
}

