import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../request/data/datasources/request_remote_data_source.dart';
import '../../request/data/repositories/request_repository_impl.dart';
import '../../request/domain/repositories/request_repository.dart';
import '../../request/domain/usecases/request_usecases.dart';
import '../presentation/viewmodels/home_viewmodel.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Data Sources
    Get.lazyPut<RequestRemoteDataSource>(
      () => RequestRemoteDataSourceImpl(supabaseClient: Supabase.instance.client),
    );

    // Repositories
    Get.lazyPut<RequestRepository>(
      () => RequestRepositoryImpl(remoteDataSource: Get.find()),
    );

    // UseCases
    Get.lazyPut(() => GetHelpRequestsUseCase(Get.find()));

    // ViewModels
    Get.lazyPut(() => HomeViewModel(getHelpRequestsUseCase: Get.find()));
  }
}
