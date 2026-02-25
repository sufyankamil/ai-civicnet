import 'package:equatable/equatable.dart';

/// Base Failure class to map from Exceptions in Repository level
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server Failure']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache Failure']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication Failure']);
}
