import 'package:get/get.dart';

import '../data/sos_remote_data_source.dart';
import '../presentation/viewmodels/sos_viewmodel.dart';

Future<void> initSosDI() async {
  if (Get.isRegistered<SosViewModel>()) return;
  Get.put<SosViewModel>(
    SosViewModel(
      dataSource: SupabaseSosRemoteDataSource(),
      position: currentSosPosition,
    ),
    permanent: true,
  );
}
