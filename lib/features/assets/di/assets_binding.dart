import 'package:get/get.dart';
import '../presentation/viewmodels/assets_viewmodel.dart';

class AssetsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AssetsViewModel());
  }
}

Future<void> initAssetsDI() async {
  AssetsBinding().dependencies();
}
