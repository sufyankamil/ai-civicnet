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
  final Rx<dynamic> _selectedItem = Rx<dynamic>(null);
  final RxString _selectedCategory = 'All'.obs;
  
  GoogleMapController? _mapController;
  
  LocationPermission? get permission => _permission.value;
  Position? get currentPosition => _currentPosition.value;
  Set<Marker> get markers => _markers;
  bool get isLoading => _isLoading.value;
  dynamic get selectedItem => _selectedItem.value;
  String get selectedCategory => _selectedCategory.value;

  bool get hasPermission => _permission.value == LocationPermission.always || _permission.value == LocationPermission.whileInUse;

  @override
  void onInit() {
    super.onInit();
    // Allow navigation transition to finish before heavy lifting
    Future.delayed(const Duration(milliseconds: 300), () {
      checkPermission().then((_) => fetchMarkers());
    });
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
      final supabase = SupabaseService();
      
      // Fetch both requests and neighbors
      final requests = await supabase.getHelpRequests();
      final neighbors = await supabase.getActiveNeighbors();
      
      final Set<Marker> newMarkers = {};

      // Add Request Markers
      for (var request in requests) {
        if (request.lat == 0 && request.lng == 0) continue;
        
        // Filter by category if selected
        if (_selectedCategory.value != 'All' && 
            request.category.toString().split('.').last.toLowerCase() != _selectedCategory.value.toLowerCase()) {
          continue;
        }

        newMarkers.add(Marker(
          markerId: MarkerId('request_${request.id}'),
          position: LatLng(request.lat, request.lng),
          onTap: () => _selectedItem.value = request,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            request.urgency.toString().contains('high') 
              ? BitmapDescriptor.hueRed 
              : BitmapDescriptor.hueAzure,
          ),
        ));
      }

      // Add Neighbor Markers
      for (var neighbor in neighbors) {
        if (neighbor.lat == null || neighbor.lng == null) continue;
        if (neighbor.id == supabase.currentUserId) continue; // Don't show self as a pin

        newMarkers.add(Marker(
          markerId: MarkerId('neighbor_${neighbor.id}'),
          position: LatLng(neighbor.lat!, neighbor.lng!),
          onTap: () => _selectedItem.value = neighbor,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ));
      }
      
      _markers.assignAll(newMarkers);
    } catch (e) {
      logger.e('Error fetching map markers: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  void selectCategory(String category) {
    _selectedCategory.value = category;
    _selectedItem.value = null; // Clear selection when filtering
    fetchMarkers();
  }

  void deselect() {
    _selectedItem.value = null;
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
