import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/datasources/auth_remote_data_source.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/usecases/auth_usecases.dart';
import '../presentation/viewmodels/auth_viewmodel.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Data sources
    Get.lazyPut<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(supabaseClient: Supabase.instance.client),
    );

    // Repositories
    Get.lazyPut<AuthRepository>(
      () => AuthRepositoryImpl(remoteDataSource: Get.find()),
    );

    // Use cases
    Get.lazyPut(() => SignInUseCase(Get.find()));
    Get.lazyPut(() => SignUpUseCase(Get.find()));
    Get.lazyPut(() => SignOutUseCase(Get.find()));
    Get.lazyPut(() => SignInWithGoogleUseCase(Get.find()));
    Get.lazyPut(() => SignInWithAppleUseCase(Get.find()));
    Get.lazyPut(() => SendPasswordResetEmailUseCase(Get.find()));

    // ViewModels
    Get.lazyPut(
      () => AuthViewModel(
        signInUseCase: Get.find(),
        signUpUseCase: Get.find(),
        signOutUseCase: Get.find(),
        signInWithGoogleUseCase: Get.find(),
        signInWithAppleUseCase: Get.find(),
        sendPasswordResetEmailUseCase: Get.find(),
      ),
    );
  }
}

Future<void> initAuthDI() async {
  AuthBinding().dependencies();
}
