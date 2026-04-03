import 'package:get/get.dart';
import '../domain/usecases/request_usecases.dart';
import '../presentation/viewmodels/request_viewmodel.dart';

class RequestBinding extends Bindings {
  @override
  void dependencies() {
    // Note: RequestRemoteDataSource and RequestRepository are already injected in HomeBinding
    // or initAuthDI? If we want a separate init, we could use Get.put. But we lazyPut them in HomeBinding.
    // Instead of assuming HomeBinding ran, we can inject UseCases directly if get_it or GetX allows.
    // Assuming RequestRepository is available:
    Get.lazyPut(() => CreateHelpRequestUseCase(Get.find()));
    Get.lazyPut(() => GetHelpRequestUseCase(Get.find()));
    Get.lazyPut(() => GetMyHelpRequestsUseCase(Get.find()));
    Get.lazyPut(() => UpdateRequestStatusUseCase(Get.find()));
    Get.lazyPut(() => DeleteHelpRequestUseCase(Get.find()));

    Get.lazyPut(() => RequestViewModel(
          createHelpRequestUseCase: Get.find(),
          getHelpRequestUseCase: Get.find(),
          getMyHelpRequestsUseCase: Get.find(),
          updateRequestStatusUseCase: Get.find(),
          deleteHelpRequestUseCase: Get.find(),
        ));
  }
}

Future<void> initRequestDI() async {
  RequestBinding().dependencies();
}
