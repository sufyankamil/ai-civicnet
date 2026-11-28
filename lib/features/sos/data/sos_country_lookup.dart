import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// The country (ISO code, for example "AE") of the position the device already
/// knows, or null. Never asks for location permission and never starts the GPS,
/// so it is safe to call whenever the SOS page opens.
///
/// The place name comes from the phone's own geocoder (Apple on iOS, Google on
/// Android), which is sent the coordinates to answer.
Future<String?> countryFromLastKnownLocation() async {
  try {
    final permission = await Geolocator.checkPermission();
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      return null;
    }
    final position = await Geolocator.getLastKnownPosition();
    if (position == null) return null;
    final places = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    for (final place in places) {
      final code = place.isoCountryCode;
      if (code != null && code.isNotEmpty) return code;
    }
    return null;
  } catch (_) {
    return null;
  }
}
