import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> signIn(String email, String password);
  Future<Either<Failure, UserEntity>> signUp(String email, String password, String name);
  Future<Either<Failure, void>> signOut();
  Future<Either<Failure, UserEntity>> signInWithGoogle();
  Future<Either<Failure, UserEntity>> signInWithApple();
  Future<Either<Failure, void>> sendPasswordResetEmail(String email);
  Future<Either<Failure, void>> deleteUserAccount();
  
  // Stream to listen to auth state changes
  Stream<UserEntity?> get authStateChanges;
  
  // Get current user sync
  UserEntity? getCurrentUser();
}
