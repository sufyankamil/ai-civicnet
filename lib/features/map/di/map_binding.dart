import 'package:get/get.dart';
import '../presentation/viewmodels/map_viewmodel.dart';

class MapBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => MapViewModel());
  }
}

Future<void> initMapDI() async {
  Get.lazyPut(() => MapViewModel(), fenix: true);
}
