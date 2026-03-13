import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../services/logger_service.dart';

class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const LocationPickerScreen({super.key, this.initialLocation});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  LatLng? _selectedLocation;
  GoogleMapController? _mapController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setInitialLocation();
  }

  Future<void> _setInitialLocation() async {
    logger.i('LocationPickerScreen: _setInitialLocation started');
    if (widget.initialLocation != null && (widget.initialLocation!.latitude != 0 || widget.initialLocation!.longitude != 0)) {
      logger.i('LocationPickerScreen: Using provided initialLocation: ${widget.initialLocation}');
      setState(() {
        _selectedLocation = widget.initialLocation;
        _isLoading = false;
      });
      return;
    }

    try {
      // 1. Check permissions
      logger.d('LocationPickerScreen: Checking permissions...');
      LocationPermission permission = await Geolocator.checkPermission();
      logger.d('LocationPickerScreen: Permission status: $permission');
      
      if (permission == LocationPermission.denied) {
        logger.i('LocationPickerScreen: Permission denied, requesting...');
        permission = await Geolocator.requestPermission();
        logger.i('LocationPickerScreen: Permission after request: $permission');
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          _handleLocationError('Location permissions are required.');
          return;
        }
      }

      // 2. Check service
      logger.d('LocationPickerScreen: Checking if location services are enabled...');
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      logger.d('LocationPickerScreen: Service enabled: $serviceEnabled');
      if (!serviceEnabled) {
        _handleLocationError('GPS is disabled. Please enable it.');
        return;
      }

      // 3. Try last known (fast)
      logger.d('LocationPickerScreen: Fetching last known position...');
      Position? lastPosition = await Geolocator.getLastKnownPosition();
      logger.d('LocationPickerScreen: Last known position: $lastPosition');
      
      // Ignore (0,0) which some devices return when they don't have a real fix
      if (lastPosition != null && (lastPosition.latitude != 0 || lastPosition.longitude != 0)) {
        logger.i('LocationPickerScreen: Successfully used last known position');
        setState(() {
          _selectedLocation = LatLng(lastPosition.latitude, lastPosition.longitude);
          _isLoading = false;
        });
        _updateWithCurrentPosition();
        return;
      }
      
      // 4. Get current position
      logger.i('LocationPickerScreen: No valid last known pos, fetching fresh position...');
      await _updateWithCurrentPosition();
    } catch (e) {
      logger.e('LocationPickerScreen: Error in _setInitialLocation: $e');
      _handleLocationError('Location fetch failed: $e');
    }
  }

  Future<void> _updateWithCurrentPosition() async {
    try {
      logger.d('LocationPickerScreen: getCurrentPosition starting (12s timeout)...');
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      logger.i('LocationPickerScreen: Fresh position received: (${position.latitude}, ${position.longitude})');
      
      // Again, ignore if it's mock (0,0)
      if (position.latitude == 0 && position.longitude == 0) {
        logger.w('LocationPickerScreen: Received (0,0) position, ignoring.');
        if (_selectedLocation == null) _handleLocationError('Received invalid (0,0) location.');
        return;
      }

      if (mounted) {
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });
        logger.d('LocationPickerScreen: Moving camera to fresh position');
        _moveCameraToSelected();
      }
    } catch (e) {
      logger.w('LocationPickerScreen: Failed to get current position: $e');
      if (_selectedLocation == null) {
        _handleLocationError('Could not get your precise location.');
      }
    }
  }

  void _moveCameraToSelected() {
    if (_mapController != null && _selectedLocation != null) {
      if (_selectedLocation!.latitude == 0 && _selectedLocation!.longitude == 0) {
         logger.e('LocationPickerScreen: Attempted to move camera to (0,0)! Blocking.');
         return;
      }
      logger.d('LocationPickerScreen: Camera animating to $_selectedLocation');
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_selectedLocation!, 15),
      );
    } else {
      logger.w('LocationPickerScreen: Skip camera move - mapController or selectedLocation is null');
    }
  }

  void _handleLocationError([String? message]) {
    logger.w('LocationPickerScreen: Error handler triggered: $message');
    if (!mounted) return;
    setState(() {
      // Default to India center instead of 0,0
      _selectedLocation = const LatLng(20.5937, 78.9629); 
      _isLoading = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message ?? 'Could not find your location. Defaulting to India.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _onTap(LatLng location) {
    logger.i('LocationPickerScreen: User tapped map at $location');
    setState(() {
      _selectedLocation = location;
    });
    _moveCameraToSelected();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select Location',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_selectedLocation != null)
            TextButton(
              onPressed: () => Navigator.pop(context, _selectedLocation),
              child: const Text('CONFIRM', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _selectedLocation ?? const LatLng(20.5937, 78.9629),
                    zoom: 15,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                    _moveCameraToSelected();
                  },
                  onTap: _onTap,
                  markers: _selectedLocation == null
                      ? {}
                      : {
                          Marker(
                            markerId: const MarkerId('selected-location'),
                            position: _selectedLocation!,
                          ),
                        },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  mapType: MapType.normal,
                ),
                Positioned(
                  bottom: 24,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Tap on the map to select a precise location for your event.',
                          style: TextStyle(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _selectedLocation == null 
                                ? null 
                                : () => Navigator.pop(context, _selectedLocation),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Confirm Location',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
