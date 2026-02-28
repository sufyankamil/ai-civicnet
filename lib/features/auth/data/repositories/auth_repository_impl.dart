import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<UserEntity?> get authStateChanges => remoteDataSource.authStateChanges.map((user) {
    if (user != null) {
      return remoteDataSource.getCurrentUser();
    }
    return null;
  });

  @override
  UserEntity? getCurrentUser() {
    return remoteDataSource.getCurrentUser();
  }

  @override
  Future<Either<Failure, UserEntity>> signIn(String email, String password) async {
    try {
      final user = await remoteDataSource.signIn(email, password);
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on SocketException catch (_) {
      return const Left(ServerFailure('Network connection error. Please try again.'));
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('SocketException') || errorStr.contains('Failed host lookup') || errorStr.contains('ClientException')) {
        return const Left(ServerFailure('A network error occurred. Please check your internet connection.'));
      }
      return Left(ServerFailure(errorStr));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signUp(String email, String password, String name) async {
    try {
      final user = await remoteDataSource.signUp(email, password, name);
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on SocketException catch (_) {
      return const Left(ServerFailure('Network connection error. Please try again.'));
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('SocketException') || errorStr.contains('Failed host lookup') || errorStr.contains('ClientException')) {
        return const Left(ServerFailure('A network error occurred. Please check your internet connection.'));
      }
      return Left(ServerFailure(errorStr));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await remoteDataSource.signOut();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() async {
    try {
      final user = await remoteDataSource.signInWithGoogle();
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on SocketException catch (_) {
      return const Left(ServerFailure('Network connection error. Please try again.'));
    } catch (e) {
       final errorStr = e.toString();
      if (errorStr.contains('SocketException') || errorStr.contains('Failed host lookup') || errorStr.contains('ClientException')) {
        return const Left(ServerFailure('A network error occurred. Please check your internet connection.'));
      }
      return Left(ServerFailure(errorStr));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithApple() async {
    try {
      final user = await remoteDataSource.signInWithApple();
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on SocketException catch (_) {
      return const Left(ServerFailure('Network connection error. Please try again.'));
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('SocketException') || errorStr.contains('Failed host lookup') || errorStr.contains('ClientException')) {
        return const Left(ServerFailure('A network error occurred. Please check your internet connection.'));
      }
      return Left(ServerFailure(errorStr));
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async {
    try {
      await remoteDataSource.sendPasswordResetEmail(email);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteUserAccount() async {
    try {
      await remoteDataSource.deleteUserAccount();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
