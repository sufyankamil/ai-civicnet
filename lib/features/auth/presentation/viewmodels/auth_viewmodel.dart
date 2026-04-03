import 'package:civic_net/services/logger_service.dart';
import 'package:get/get.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../../../../core/usecases/usecase.dart';

class AuthViewModel extends GetxController {
  final SignInUseCase signInUseCase;
  final SignUpUseCase signUpUseCase;
  final SignOutUseCase signOutUseCase;
  final SignInWithGoogleUseCase signInWithGoogleUseCase;
  final SignInWithAppleUseCase signInWithAppleUseCase;
  final SendPasswordResetEmailUseCase sendPasswordResetEmailUseCase;

  AuthViewModel({
    required this.signInUseCase,
    required this.signUpUseCase,
    required this.signOutUseCase,
    required this.signInWithGoogleUseCase,
    required this.signInWithAppleUseCase,
    required this.sendPasswordResetEmailUseCase,
  });

  final Rx<UserEntity?> _user = Rx<UserEntity?>(null);
  UserEntity? get user => _user.value;

  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;
  
  final RxBool _isGoogleLoading = false.obs;
  bool get isGoogleLoading => _isGoogleLoading.value;
  
  final RxBool _isAppleLoading = false.obs;
  bool get isAppleLoading => _isAppleLoading.value;

  Future<String?> signIn(String email, String password) async {
    _isLoading.value = true;
    final result = await signInUseCase(SignInParams(email, password));
    logger.e('AuthViewModel signIn result: $result');
    _isLoading.value = false;

    return result.fold(
      (failure) => failure.message,
      (userEntity) {
        _user.value = userEntity;
        return null;
      },
    );
  }

  Future<String?> signUp(String email, String password, String name) async {
    _isLoading.value = true;
    final result = await signUpUseCase(SignUpParams(email, password, name));
    _isLoading.value = false;

    return result.fold(
      (failure) => failure.message,
      (userEntity) {
        _user.value = userEntity;
        return null;
      },
    );
  }

  Future<String?> signOut() async {
    final result = await signOutUseCase(const NoParams());
    return result.fold(
      (failure) => failure.message,
      (_) {
        _user.value = null;
        return null;
      },
    );
  }

  Future<String?> signInWithGoogle() async {
    _isGoogleLoading.value = true;
    final result = await signInWithGoogleUseCase(const NoParams());
    _isGoogleLoading.value = false;

    return result.fold(
      (failure) => failure.message,
      (userEntity) {
        _user.value = userEntity;
        return null;
      },
    );
  }

  Future<String?> signInWithApple() async {
    _isAppleLoading.value = true;
    final result = await signInWithAppleUseCase(const NoParams());
    _isAppleLoading.value = false;

    return result.fold(
      (failure) => failure.message,
      (userEntity) {
        _user.value = userEntity;
        return null;
      },
    );
  }

  Future<String?> sendPasswordResetEmail(String email) async {
    _isLoading.value = true;
    final result = await sendPasswordResetEmailUseCase(SendPasswordResetEmailParams(email));
    _isLoading.value = false;

    return result.fold(
      (failure) => failure.message,
      (_) => null,
    );
  }
}
