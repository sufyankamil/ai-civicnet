import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:civic_net/services/logger_service.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Keys for secure storage
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyUserEmail = 'biometric_email';
  static const String _keyUserPassword = 'biometric_password';

  /// Check if the device hardware supports biometrics
  Future<bool> isBiometricAvailable() async {
    try {
      final canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (e) {
      logger.e('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Check if the user has manually enabled biometrics in settings
  Future<bool> isBiometricEnabled() async {
    final isEnabled = await _secureStorage.read(key: _keyBiometricEnabled);
    return isEnabled == 'true';
  }

  /// Prompt the user to authenticate using Face ID / Fingerprint
  Future<bool> authenticate({required String localizedReason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: true,
      );
    } on PlatformException catch (e) {
      logger.e('Error authenticating with biometrics: $e');
      return false;
    }
  }

  /// Saves the user's credentials securely and marks biometrics as enabled
  Future<void> enableBiometrics(String email, String password) async {
    await _secureStorage.write(key: _keyBiometricEnabled, value: 'true');
    await _secureStorage.write(key: _keyUserEmail, value: email);
    await _secureStorage.write(key: _keyUserPassword, value: password);
  }

  /// Removes the user's credentials and disables biometrics
  Future<void> disableBiometrics() async {
    await _secureStorage.write(key: _keyBiometricEnabled, value: 'false');
    await _secureStorage.delete(key: _keyUserEmail);
    await _secureStorage.delete(key: _keyUserPassword);
  }

  /// Retrieves the saved credentials. Returns a map with 'email' and 'password' if they exist.
  Future<Map<String, String>?> getSavedCredentials() async {
    final email = await _secureStorage.read(key: _keyUserEmail);
    final password = await _secureStorage.read(key: _keyUserPassword);

    if (email != null && password != null) {
      return {'email': email, 'password': password};
    }
    return null;
  }
}
