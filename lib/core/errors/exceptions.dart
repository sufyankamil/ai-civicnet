/// Base Exception for server-related errors
class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'A server error occurred']);

  @override
  String toString() => message;
}

/// Base Exception for local cache/storage errors
class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'A cache error occurred']);

  @override
  String toString() => message;
}

class AuthException implements Exception {
  final String message;
  const AuthException([this.message = 'An authentication error occurred']);

  @override
  String toString() => message;
}
