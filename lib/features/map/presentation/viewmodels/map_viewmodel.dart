import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';

class MapViewModel extends GetxController {
  final Rx<LocationPermission?> _permission = Rx<LocationPermission?>(null);
  final Rx<Position?> _currentPosition = Rx<Position?>(null);
  
  LocationPermission? get permission => _permission.value;
  Position? get currentPosition => _currentPosition.value;

  bool get hasPermission => _permission.value == LocationPermission.always || _permission.value == LocationPermission.whileInUse;

  @override
  void onInit() {
    super.onInit();
    checkPermission();
  }

  Future<void> checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    
    Position? pos;
    if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
      try {
        pos = await Geolocator.getCurrentPosition();
      } catch (e) {
        // Fallback or ignore
      }
    }

    _permission.value = perm;
    _currentPosition.value = pos;
  }
}
