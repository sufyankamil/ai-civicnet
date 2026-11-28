import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:supabase_flutter/supabase_flutter.dart';

import 'approximate_location.dart';
import 'logger_service.dart';

// Existing code and tests import DeviceLocation from here.
export 'approximate_location.dart' show DeviceLocation;

/// Where device tokens are stored. A seam so tests do not need Supabase.
abstract class DeviceTokenBackend {
  Future<void> register({
    required String token,
    required String platform,
    double? lat,
    double? lng,
  });

  Future<void> unregister(String token);
}

/// Stores tokens through the `register_device_token` / `unregister_device_token`
/// RPCs (see `sql_scripts/sos_schema.sql`). The server rounds the location to
/// about 550 m, so exact positions are never stored.
class SupabaseDeviceTokenBackend implements DeviceTokenBackend {
  SupabaseDeviceTokenBackend([this._injected]);

  final SupabaseClient? _injected;

  // Resolved on use: this is created before Supabase finishes initializing.
  SupabaseClient get _client => _injected ?? Supabase.instance.client;

  @override
  Future<void> register({
    required String token,
    required String platform,
    double? lat,
    double? lng,
  }) async {
    await _client.rpc(
      'register_device_token',
      params: {
        'p_token': token,
        'p_platform': platform,
        'p_lat': lat,
        'p_lng': lng,
      },
    );
  }

  @override
  Future<void> unregister(String token) async {
    await _client.rpc('unregister_device_token', params: {'p_token': token});
  }
}

/// Keeps the server's copy of this device's push token and rough location
/// current, so nearby-only pushes such as SOS can find the device.
///
/// It never throws: push targeting must not be able to break sign-in or startup.
class DeviceTokenService {
  DeviceTokenService({
    required DeviceTokenBackend backend,
    required this.platform,
    required Future<DeviceLocation?> Function() location,
    DateTime Function()? now,
  }) : _backend = backend,
       _location = location,
       _now = now ?? DateTime.now;

  /// The app-wide instance, wired to Supabase and the device's location.
  static final DeviceTokenService shared = DeviceTokenService(
    backend: SupabaseDeviceTokenBackend(),
    platform: Platform.isIOS ? 'ios' : 'android',
    location: approximateDeviceLocation,
  );

  /// How far the user must move before the location is sent again.
  static const double moveThresholdMeters = 500;

  /// The location is refreshed at least this often while the app is used.
  static const Duration refreshInterval = Duration(hours: 6);

  final DeviceTokenBackend _backend;
  final String platform;
  final Future<DeviceLocation?> Function() _location;
  final DateTime Function() _now;

  String? _lastToken;
  DeviceLocation? _lastLocation;
  DateTime? _lastSyncedAt;

  /// Call after sign-in, on app start and whenever the FCM token changes.
  Future<void> sync({required String? token, required bool signedIn}) async {
    if (!signedIn || token == null || token.isEmpty) return;
    try {
      final here = await _location();
      if (!_shouldSend(token, here)) return;

      await _backend.register(
        token: token,
        platform: platform,
        lat: here?.lat,
        lng: here?.lng,
      );
      _lastToken = token;
      _lastLocation = here ?? _lastLocation;
      _lastSyncedAt = _now();
    } catch (e) {
      logger.w('DeviceTokenService: could not register token: $e');
    }
  }

  /// Call when the user signs out, so this device stops receiving pushes meant
  /// for the previous account.
  Future<void> onSignedOut() async {
    final token = _lastToken;
    _lastToken = null;
    _lastLocation = null;
    _lastSyncedAt = null;
    if (token == null) return;
    try {
      await _backend.unregister(token);
    } catch (e) {
      logger.w('DeviceTokenService: could not remove token: $e');
    }
  }

  bool _shouldSend(String token, DeviceLocation? here) {
    if (token != _lastToken || _lastSyncedAt == null) return true;
    if (_now().difference(_lastSyncedAt!) >= refreshInterval) return true;
    final before = _lastLocation;
    if (here != null &&
        (before == null ||
            _distanceMeters(before, here) > moveThresholdMeters)) {
      return true;
    }
    return false;
  }

  static double _distanceMeters(DeviceLocation a, DeviceLocation b) {
    const earthRadius = 6371000.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(b.lat - a.lat);
    final dLng = rad(b.lng - a.lng);
    final h =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(a.lat)) *
            math.cos(rad(b.lat)) *
            math.pow(math.sin(dLng / 2), 2);
    return 2 * earthRadius * math.asin(math.sqrt(h.toDouble()));
  }
}
