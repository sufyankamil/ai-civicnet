import 'package:get/get.dart';
import '../../../../services/biometric_service.dart';

class SettingsController extends GetxController {
  final RxBool _isBiometricEnabled = false.obs;
  bool get isBiometricEnabled => _isBiometricEnabled.value;
  
  final RxBool _isLoadingBiometrics = true.obs;
  bool get isLoadingBiometrics => _isLoadingBiometrics.value;

  @override
  void onInit() {
    super.onInit();
    loadBiometricSettings();
  }

  Future<void> loadBiometricSettings() async {
    _isLoadingBiometrics.value = true;
    final enabled = await BiometricService().isBiometricEnabled();
    _isBiometricEnabled.value = enabled;
    _isLoadingBiometrics.value = false;
  }

  Future<void> toggleBiometrics(bool value) async {
    if (value) {
      // Toggle to true is handled via dialog in UI for now
      // but we update the state after success
      _isBiometricEnabled.value = true;
    } else {
      await BiometricService().disableBiometrics();
      _isBiometricEnabled.value = false;
    }
  }
}
