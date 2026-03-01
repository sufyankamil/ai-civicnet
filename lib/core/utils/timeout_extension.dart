import 'dart:async';
import '../errors/exceptions.dart';

extension FutureTimeoutExtension<T> on Future<T> {
  /// Adds a global timeout to any Future.
  /// Throws a [ServerException] if the [Future] does not complete within [seconds].
  Future<T> withServerTimeout([int seconds = 10]) {
    return timeout(
      Duration(seconds: seconds),
      onTimeout: () => throw const ServerException('Unable to reach server. Please try again.'),
    );
  }
}
