import 'package:geocoding/geocoding.dart';
import '../../../services/approximate_location.dart';

/// The country (ISO code, for example "AE") of the device's approximate
/// position, or null. Never asks for location permission; with permission it
/// uses the known position or one cheap low-accuracy fix (see
/// [approximateDeviceLocation]).
///
/// The place name comes from the phone's own geocoder (Apple on iOS, Google on
/// Android), which is sent the coordinates to answer.
Future<String?> countryFromApproximateLocation() async {
  try {
    final here = await approximateDeviceLocation();
    if (here == null) return null;
    final places = await placemarkFromCoordinates(here.lat, here.lng);
    for (final place in places) {
      final code = place.isoCountryCode;
      if (code != null && code.isNotEmpty) return code;
    }
    return null;
  } catch (_) {
    return null;
  }
}
