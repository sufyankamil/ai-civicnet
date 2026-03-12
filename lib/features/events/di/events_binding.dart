import 'package:get/get.dart';
import '../presentation/viewmodels/events_viewmodel.dart';

class EventsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EventsViewModel>(() => EventsViewModel());
  }
}

Future<void> initEventsDI() async {
  EventsBinding().dependencies();
}
