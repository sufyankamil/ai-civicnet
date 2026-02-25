import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SignInParams {
  final String email;
  final String password;
  const SignInParams(this.email, this.password);
}

class SignUpParams {
  final String email;
  final String password;
  final String name;
  const SignUpParams(this.email, this.password, this.name);
}

class SignInUseCase implements UseCase<UserEntity, SignInParams> {
  final AuthRepository repository;
  SignInUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(SignInParams params) async {
    return await repository.signIn(params.email, params.password);
  }
}

class SignUpUseCase implements UseCase<UserEntity, SignUpParams> {
  final AuthRepository repository;
  SignUpUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(SignUpParams params) async {
    return await repository.signUp(params.email, params.password, params.name);
  }
}

class SignOutUseCase implements UseCase<void, NoParams> {
  final AuthRepository repository;
  SignOutUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await repository.signOut();
  }
}

class SignInWithGoogleUseCase implements UseCase<UserEntity, NoParams> {
  final AuthRepository repository;
  SignInWithGoogleUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) async {
    return await repository.signInWithGoogle();
  }
}

class SignInWithAppleUseCase implements UseCase<UserEntity, NoParams> {
  final AuthRepository repository;
  SignInWithAppleUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) async {
    return await repository.signInWithApple();
  }
}

class SendPasswordResetEmailParams {
  final String email;
  const SendPasswordResetEmailParams(this.email);
}

class SendPasswordResetEmailUseCase implements UseCase<void, SendPasswordResetEmailParams> {
  final AuthRepository repository;
  SendPasswordResetEmailUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(SendPasswordResetEmailParams params) async {
    return await repository.sendPasswordResetEmail(params.email);
  }
}
