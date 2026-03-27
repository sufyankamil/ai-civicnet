import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../theme/app_theme.dart';
import '../viewmodels/map_viewmodel.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final MapViewModel viewModel = Get.find<MapViewModel>();

    return Scaffold(
      body: Obx(() {
        final hasPermission = viewModel.hasPermission;
        final currentPosition = viewModel.currentPosition;

        return Stack(
          children: [
            // Interactive Google Map
            hasPermission
                ? GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        currentPosition?.latitude ?? 0,
                        currentPosition?.longitude ?? 0,
                      ),
                      zoom: 13,
                    ),
                    onMapCreated: viewModel.onMapCreated,
                    markers: viewModel.markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    style: _getMapStyle(context),
                  )
                : Container(
                    height: double.infinity,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_off,
                              color: Colors.grey, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'Location permission not given',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: viewModel.checkPermission,
                            child: const Text('Grant Permission'),
                          ),
                        ],
                      ),
                    ),
                  ),
            
            if (viewModel.isLoading)
              const Center(child: CircularProgressIndicator()),
            
            // Search Bar Overlay
            Positioned(
              top: 60,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Search area...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    const Icon(Icons.filter_list, color: AppColors.primaryLight),
                  ],
                ),
              ),
            ),

            // Proximity Badge
            if (viewModel.markers.isNotEmpty)
              Positioned(
                top: 125,
                left: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.people_alt_rounded,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '${viewModel.markers.length} Active Neighbors Nearby',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Bottom Sheet Preview (Mock)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.accentLight.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.warning, color: AppColors.accentLight),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Structure Fire nearby',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '0.2 km away • Emergency',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),

            // Recenter Button
            Positioned(
              bottom: 180,
              right: 16,
              child: FloatingActionButton.small(
                onPressed: viewModel.recenter,
                backgroundColor: Theme.of(context).cardColor,
                child: const Icon(Icons.my_location, color: AppColors.primaryLight),
              ),
            ),
          ],
        );
      }),
    );
  }

  String? _getMapStyle(BuildContext context) {
    // Return a JSON string for map styling if needed, or null for default
    // For a premium feel, we could use a custom retro or silver style
    return null; 
  }
}
