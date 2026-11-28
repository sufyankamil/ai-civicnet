import 'package:geolocator/geolocator.dart';

/// A position in degrees.
class DeviceLocation {
  const DeviceLocation(this.lat, this.lng);

  final double lat;
  final double lng;
}

/// A rough position for the device, or null.
///
/// It never asks for location permission: if the user has not allowed location
/// it returns null. With permission it uses the position the system already
/// knows; if there is none (on iOS this is empty until something has asked for
/// location), it takes a single low-accuracy fix with a short timeout, which
/// uses cell and Wi-Fi and does not start the GPS. The parameters are test
/// seams; the defaults talk to the Geolocator plugin.
Future<DeviceLocation?> approximateDeviceLocation({
  Future<LocationPermission> Function()? checkPermission,
  Future<DeviceLocation?> Function()? lastKnown,
  Future<DeviceLocation?> Function(Duration timeout)? freshFix,
  Duration timeout = const Duration(seconds: 5),
}) async {
  try {
    final permission = await (checkPermission ?? Geolocator.checkPermission)();
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      return null;
    }

    try {
      final known = await (lastKnown ?? _systemLastKnown)();
      if (known != null) return known;
    } catch (_) {
      // Not available on this platform; try a fresh fix instead.
    }

    return await (freshFix ?? _systemLowAccuracyFix)(timeout);
  } catch (_) {
    return null;
  }
}

Future<DeviceLocation?> _systemLastKnown() async {
  final p = await Geolocator.getLastKnownPosition();
  return p == null ? null : DeviceLocation(p.latitude, p.longitude);
}

Future<DeviceLocation?> _systemLowAccuracyFix(Duration timeout) async {
  final p = await Geolocator.getCurrentPosition(
    locationSettings: LocationSettings(
      accuracy: LocationAccuracy.low,
      timeLimit: timeout,
    ),
  );
  return DeviceLocation(p.latitude, p.longitude);
}
