import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../theme/app_theme.dart';
import '../../../../models/models.dart';
import '../../../../features/profile/models/user.dart' as profile;
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
                    onTap: (_) => viewModel.deselect(),
                  )
                : _buildNoPermissionView(viewModel),
            
            if (viewModel.isLoading)
              const Center(child: CircularProgressIndicator()),
            
            // --- TOP OVERLAYS ---
            
            // Search & Filter Header
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildSearchBar(),
                  ),
                  const SizedBox(height: 12),
                  // Category Filters
                  _buildCategoryFilters(viewModel),
                ],
              ),
            ),

            // --- BOTTOM OVERLAYS ---

            // Selection Preview Card
            _buildSelectionPreview(context, viewModel),

            // Recenter Button
            Positioned(
              bottom: viewModel.selectedItem != null ? 240 : 100,
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

  Widget _buildNoPermissionView(MapViewModel viewModel) {
    return Container(
      height: double.infinity,
      width: double.infinity,
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, color: Colors.grey, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Location permission not given',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: viewModel.checkPermission,
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Search area...', style: TextStyle(color: Colors.grey)),
          ),
          const VerticalDivider(width: 20, indent: 10, endIndent: 10),
          const Icon(Icons.tune_rounded, color: AppColors.primaryLight),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters(MapViewModel viewModel) {
    final categories = ['All', 'Emergency', 'TechSupport', 'Household', 'Neighbors'];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = viewModel.selectedCategory == cat;
          return ChoiceChip(
            label: Text(cat),
            selected: isSelected,
            onSelected: (_) => viewModel.selectCategory(cat),
            selectedColor: AppColors.primaryLight,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            showCheckmark: false,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          );
        },
      ),
    );
  }

  Widget _buildSelectionPreview(BuildContext context, MapViewModel viewModel) {
    final item = viewModel.selectedItem;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      bottom: item != null ? 100 : -200,
      left: 16,
      right: 16,
      child: item == null ? const SizedBox() : _buildPreviewCard(context, item, viewModel),
    );
  }

  Widget _buildPreviewCard(BuildContext context, dynamic item, MapViewModel viewModel) {
    final bool isRequest = item is HelpRequest;
    final String title = isRequest ? item.title : (item as profile.User).name;
    final String subtitle = isRequest 
        ? '${item.category.toString().split('.').last} • ${item.urgency.toString().split('.').last}'
        : 'Active Community Member';
    final IconData icon = isRequest 
        ? (item.urgency.toString().contains('high') ? Icons.warning_rounded : Icons.help_rounded)
        : Icons.person_pin_circle_rounded;
    final Color color = isRequest 
        ? (item.urgency.toString().contains('high') ? AppColors.accentLight : AppColors.primaryLight)
        : Colors.green;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
              IconButton(
                onPressed: viewModel.deselect,
                icon: const Icon(Icons.close_rounded, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (isRequest) {
                  context.push('/request/${item.id}');
                } else {
                  context.push('/profile/${item.id}');
                }
              },
              child: Text(isRequest ? 'View Request' : 'View Profile'),
            ),
          ),
        ],
      ),
    );
  }

  static const String _mapStyleJson = '''
    [
      {"elementType": "geometry", "stylers": [{"color": "#f5f5f5"}]},
      {"elementType": "labels.icon", "stylers": [{"visibility": "off"}]},
      {"elementType": "labels.text.fill", "stylers": [{"color": "#616161"}]},
      {"elementType": "labels.text.stroke", "stylers": [{"color": "#f5f5f5"}]},
      {"featureType": "administrative.land_parcel", "elementType": "labels.text.fill", "stylers": [{"color": "#bdbdbd"}]},
      {"featureType": "poi", "elementType": "geometry", "stylers": [{"color": "#eeeeee"}]},
      {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#757575"}]},
      {"featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#e5e5e5"}]},
      {"featureType": "poi.park", "elementType": "labels.text.fill", "stylers": [{"color": "#9e9e9e"}]},
      {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#ffffff"}]},
      {"featureType": "road.arterial", "elementType": "labels.text.fill", "stylers": [{"color": "#757575"}]},
      {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#dadada"}]},
      {"featureType": "road.highway", "elementType": "labels.text.fill", "stylers": [{"color": "#616161"}]},
      {"featureType": "road.local", "elementType": "labels.text.fill", "stylers": [{"color": "#9e9e9e"}]},
      {"featureType": "transit.line", "elementType": "geometry", "stylers": [{"color": "#e5e5e5"}]},
      {"featureType": "transit.station", "elementType": "geometry", "stylers": [{"color": "#eeeeee"}]},
      {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#c9c9c9"}]},
      {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#9e9e9e"}]}
    ]
    ''';

  String? _getMapStyle(BuildContext context) {
    return _mapStyleJson;
  }
}
