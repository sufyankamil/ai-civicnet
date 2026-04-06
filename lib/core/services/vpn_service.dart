import 'dart:async';
import 'package:vpn_connection_detector/vpn_connection_detector.dart';

class VpnService {
  static final VpnService _instance = VpnService._internal();
  factory VpnService() => _instance;
  VpnService._internal();

  final _detector = VpnConnectionDetector();
  
  /// Check if VPN is currently active
  Future<bool> isVpnActive() async {
    try {
      return await VpnConnectionDetector.isVpnActive();
    } catch (e) {
      // Fallback or log error
      return false;
    }
  }

  /// Stream of VPN connection status changes
  Stream<bool> get vpnStatusStream {
    return _detector.vpnConnectionStream.map((state) {
      return state == VpnConnectionState.connected;
    });
  }

  void dispose() {
    // Note: In a singleton, we might not dispose this unless the app is shutting down
    // but it's good practice to have it.
  }
}
