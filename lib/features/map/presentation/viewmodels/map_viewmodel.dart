import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../services/supabase_service.dart';
import '../../../../services/logger_service.dart';

class MapViewModel extends GetxController {
  final Rx<LocationPermission?> _permission = Rx<LocationPermission?>(null);
  final Rx<Position?> _currentPosition = Rx<Position?>(null);
  final RxSet<Marker> _markers = <Marker>{}.obs;
  final RxBool _isLoading = false.obs;
  
  GoogleMapController? _mapController;
  
  LocationPermission? get permission => _permission.value;
  Position? get currentPosition => _currentPosition.value;
  Set<Marker> get markers => _markers;
  bool get isLoading => _isLoading.value;

  bool get hasPermission => _permission.value == LocationPermission.always || _permission.value == LocationPermission.whileInUse;

  @override
  void onInit() {
    super.onInit();
    checkPermission().then((_) => fetchMarkers());
  }

  void onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_currentPosition.value != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition.value!.latitude, _currentPosition.value!.longitude),
          14,
        ),
      );
    }
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

  Future<void> fetchMarkers() async {
    _isLoading.value = true;
    try {
      final requests = await SupabaseService().getHelpRequests();
      final newMarkers = requests.where((r) => r.lat != 0 && r.lng != 0).map((request) {
        return Marker(
          markerId: MarkerId(request.id),
          position: LatLng(request.lat, request.lng),
          infoWindow: InfoWindow(
            title: request.title,
            snippet: '${request.category.toString().split('.').last} • ${request.urgency.toString().split('.').last}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            request.urgency.toString().contains('high') 
              ? BitmapDescriptor.hueRed 
              : BitmapDescriptor.hueAzure,
          ),
        );
      }).toSet();
      
      _markers.assignAll(newMarkers);
    } catch (e) {
      logger.e('Error fetching map markers: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  void recenter() {
    if (_currentPosition.value != null && _mapController != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition.value!.latitude, _currentPosition.value!.longitude),
          15,
        ),
      );
    }
  }
}
