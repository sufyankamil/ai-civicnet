import 'dart:math' show cos, asin, sqrt;
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../services/supabase_service.dart';
import '../../../../services/logger_service.dart';

enum DiscoveryMode { requests, assets, neighbors }

class MapViewModel extends GetxController {
  final Rx<LocationPermission?> _permission = Rx<LocationPermission?>(null);
  final Rx<Position?> _currentPosition = Rx<Position?>(null);
  final Rx<LatLng?> _lastSearchPosition = Rx<LatLng?>(null);
  final Rx<LatLng?> _cameraPosition = Rx<LatLng?>(null);
  final RxSet<Marker> _markers = <Marker>{}.obs;
  final RxBool _isLoading = false.obs;
  final RxBool _showSearchAreaButton = false.obs;
  final Rx<dynamic> _selectedItem = Rx<dynamic>(null);
  final RxString _selectedCategory = 'All'.obs;
  final Rx<DiscoveryMode> _discoveryMode = DiscoveryMode.requests.obs;
  final RxDouble _radiusKm = 5.0.obs;
  
  GoogleMapController? _mapController;
  
  LocationPermission? get permission => _permission.value;
  Position? get currentPosition => _currentPosition.value;
  Set<Marker> get markers => _markers;
  bool get isLoading => _isLoading.value;
  bool get showSearchAreaButton => _showSearchAreaButton.value;
  dynamic get selectedItem => _selectedItem.value;
  String get selectedCategory => _selectedCategory.value;
  DiscoveryMode get discoveryMode => _discoveryMode.value;
  double get radiusKm => _radiusKm.value;

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
      final latLng = LatLng(_currentPosition.value!.latitude, _currentPosition.value!.longitude);
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(latLng, 14),
      );
      _lastSearchPosition.value = latLng;
    }
  }

  void onCameraMove(CameraPosition position) {
    _cameraPosition.value = position.target;
    
    // Show "Search this area" button if moved more than ~500m from last search
    if (_lastSearchPosition.value != null) {
      final distance = _calculateDistance(
        _lastSearchPosition.value!.latitude,
        _lastSearchPosition.value!.longitude,
        position.target.latitude,
        position.target.longitude,
      );
      _showSearchAreaButton.value = distance > 0.5;
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

  Future<void> fetchMarkers({bool useCameraCenter = false}) async {
    _isLoading.value = true;
    _showSearchAreaButton.value = false;
    
    try {
      final supabase = SupabaseService();
      final lat = useCameraCenter ? (_cameraPosition.value?.latitude ?? _currentPosition.value?.latitude) : _currentPosition.value?.latitude;
      final lng = useCameraCenter ? (_cameraPosition.value?.longitude ?? _currentPosition.value?.longitude) : _currentPosition.value?.longitude;

      if (useCameraCenter && _cameraPosition.value != null) {
        _lastSearchPosition.value = _cameraPosition.value;
      }

      final Set<Marker> newMarkers = {};

      if (_discoveryMode.value == DiscoveryMode.requests) {
        final requests = await supabase.getHelpRequests(
          centerLat: lat,
          centerLng: lng,
          radiusKm: _radiusKm.value,
        );
        for (var request in requests) {
          if (request.lat == 0 && request.lng == 0) continue;
          if (_selectedCategory.value != 'All' && 
              request.category.toString().split('.').last.toLowerCase() != _selectedCategory.value.toLowerCase()) {
            continue;
          }
          newMarkers.add(Marker(
            markerId: MarkerId('request_${request.id}'),
            position: LatLng(request.lat, request.lng),
            onTap: () => _selectedItem.value = request,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              request.urgency.toString().contains('high') ? BitmapDescriptor.hueRed : BitmapDescriptor.hueAzure,
            ),
          ));
        }
      } else if (_discoveryMode.value == DiscoveryMode.assets) {
        final assets = await supabase.getCommunityAssets(
          centerLat: lat,
          centerLng: lng,
          radiusKm: _radiusKm.value,
          category: _selectedCategory.value,
        );
        for (var asset in assets) {
          if (asset.lat == null || asset.lng == null) continue;
          newMarkers.add(Marker(
            markerId: MarkerId('asset_${asset.id}'),
            position: LatLng(asset.lat!, asset.lng!),
            onTap: () => _selectedItem.value = asset,
            icon: BitmapDescriptor.defaultMarkerWithHue(10) // Custom hue for Assets (orange-ish)
          ));
        }
      } else if (_discoveryMode.value == DiscoveryMode.neighbors) {
        final neighbors = await supabase.getActiveNeighbors(
          centerLat: lat,
          centerLng: lng,
          radiusKm: _radiusKm.value,
        );
        for (var neighbor in neighbors) {
          if (neighbor.lat == null || neighbor.lng == null) continue;
          if (neighbor.id == supabase.currentUserId) continue;
          newMarkers.add(Marker(
            markerId: MarkerId('neighbor_${neighbor.id}'),
            position: LatLng(neighbor.lat!, neighbor.lng!),
            onTap: () => _selectedItem.value = neighbor,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ));
        }
      }
      
      _markers.assignAll(newMarkers);
    } catch (e) {
      logger.e('Error fetching map markers: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  void setDiscoveryMode(DiscoveryMode mode) {
    _discoveryMode.value = mode;
    _selectedItem.value = null;
    _selectedCategory.value = 'All'; // Reset category when switching modes
    fetchMarkers();
  }

  void setRadius(double radius) {
    _radiusKm.value = radius;
    fetchMarkers(useCameraCenter: _showSearchAreaButton.value);
  }

  void searchThisArea() {
    fetchMarkers(useCameraCenter: true);
  }

  // Haversine helper for local distance checks
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const p = 0.017453292519943295;
    final a = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lng2 - lng1) * p)) / 2;
    return 12742 * asin(sqrt(a));
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
