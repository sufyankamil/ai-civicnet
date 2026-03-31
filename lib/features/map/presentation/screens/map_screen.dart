import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/haptic_buttons.dart';
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
                    onCameraMove: viewModel.onCameraMove,
                    markers: viewModel.markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    style: _getMapStyle(context),
                    onTap: (_) => viewModel.deselect(),
                  )
                : _buildNoPermissionView(viewModel, context),
            
            if (viewModel.isLoading)
              const Center(child: CircularProgressIndicator()),
            
            // --- TOP OVERLAYS ---
            
            // Search & Filter Header
            Positioned(
              top: 50,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  // Mode Selector
                  _buildModeSelector(viewModel, context),
                  const SizedBox(height: 12),
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildSearchBar(context),
                  ),
                  const SizedBox(height: 12),
                  // Radius & Category Filters
                  _buildAdvancedFilters(viewModel, context),
                ],
              ),
            ),

            // Search This Area Button
            if (viewModel.showSearchAreaButton)
              Positioned(
                top: 220,
                left: 0,
                right: 0,
                child: Center(
                  child: AppHaptic(
                    onTap: viewModel.searchThisArea,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text('Search this area', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // --- BOTTOM OVERLAYS ---

            // Selection Preview Card
            _buildSelectionPreview(context, viewModel),

            // Recenter Button
            Positioned(
              bottom: viewModel.selectedItem != null ? 310 : 124,
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

  Widget _buildNoPermissionView(MapViewModel viewModel, BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: double.infinity,
      width: double.infinity,
      color: isDark ? const Color(0xFF121212) : Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, color: isDark ? Colors.white38 : Colors.grey, size: 48),
            const SizedBox(height: 16),
            Text(
              'Location permission not given',
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold, 
                color: isDark ? Colors.white60 : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            AppElevatedButton(
              onPressed: viewModel.checkPermission,
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 50,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(25),
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
          Icon(Icons.search, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Search area...', 
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
            ),
          ),
          VerticalDivider(
            width: 20, 
            indent: 12, 
            endIndent: 12, 
            color: Theme.of(context).dividerColor,
          ),
          const Icon(Icons.tune_rounded, color: AppColors.primaryLight),
        ],
      ),
    );
  }

  Widget _buildModeSelector(MapViewModel viewModel, BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          _buildModeTab(context, 'Help', DiscoveryMode.requests, viewModel),
          _buildModeTab(context, 'Tools', DiscoveryMode.assets, viewModel),
          _buildModeTab(context, 'Neighbors', DiscoveryMode.neighbors, viewModel),
        ],
      ),
    );
  }

  Widget _buildModeTab(BuildContext context, String label, DiscoveryMode mode, MapViewModel viewModel) {
    final isSelected = viewModel.discoveryMode == mode;
    return Expanded(
      child: AppHaptic(
        onTap: () => viewModel.setDiscoveryMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryLight : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedFilters(MapViewModel viewModel, BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Radius Selector
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildRadiusChip(1, viewModel),
              _buildRadiusChip(5, viewModel),
              _buildRadiusChip(10, viewModel),
              _buildRadiusChip(25, viewModel),
              _buildRadiusChip(50, viewModel),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Category Filters
        if (viewModel.discoveryMode != DiscoveryMode.neighbors)
          _buildCategoryFilters(viewModel, context),
      ],
    );
  }

  Widget _buildRadiusChip(double radius, MapViewModel viewModel) {
    final isSelected = viewModel.radiusKm == radius;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text('${radius.toInt()}km'),
        selected: isSelected,
        onSelected: (_) => viewModel.setRadius(radius),
        selectedColor: AppColors.primaryLight.withValues(alpha: 0.2),
        backgroundColor: Colors.white.withValues(alpha: 0.8),
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primaryLight : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        visualDensity: VisualDensity.compact,
        showCheckmark: false,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isSelected ? AppColors.primaryLight : Colors.transparent),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters(MapViewModel viewModel, BuildContext context) {
    final requestCategories = ['All', 'Emergency', 'TechSupport', 'Household', 'Neighbors'];
    final assetCategories = ['All', 'Tools', 'Garden', 'Transport', 'Electronics', 'Household'];
    
    final categories = viewModel.discoveryMode == DiscoveryMode.requests 
        ? requestCategories 
        : assetCategories;

    return SizedBox(
      height: 32,
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
            backgroundColor: Colors.white.withValues(alpha: 0.8),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
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
      bottom: item != null ? 124 : -200,
      left: 16,
      right: 16,
      child: item == null ? const SizedBox() : _buildPreviewCard(context, item, viewModel),
    );
  }

  Widget _buildPreviewCard(BuildContext context, dynamic item, MapViewModel viewModel) {
    final bool isRequest = item is HelpRequest;
    final bool isAsset = item is CommunityAsset;
    
    final String title = isRequest 
        ? item.title 
        : (isAsset ? item.title : (item as profile.User).name);
        
    final String subtitle = isRequest 
        ? '${item.category.toString().split('.').last} • ${item.urgency.toString().split('.').last}'
        : (isAsset 
            ? '${item.category.name} • Owned by ${item.ownerName ?? 'a neighbor'}'
            : 'Active Community Member');

    final IconData icon = isRequest 
        ? (item.urgency.toString().contains('high') ? Icons.warning_rounded : Icons.help_rounded)
        : (isAsset ? Icons.inventory_2_rounded : Icons.person_pin_circle_rounded);

    final Color color = isRequest 
        ? (item.urgency.toString().contains('high') ? AppColors.accentLight : AppColors.primaryLight)
        : (isAsset ? Colors.deepPurple : Colors.green);

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
                } else if (isAsset) {
                  // In a real app, open asset detail. For now, show context
                  context.push('/chat/${item.ownerId}'); 
                } else {
                  context.push('/profile/${item.id}');
                }
              },
              child: Text(isRequest ? 'View Request' : (isAsset ? 'Contact Owner' : 'View Profile')),
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

  static const String _darkMapStyleJson = r'''
    [
      {"elementType": "geometry", "stylers": [{"color": "#242f3e"}]},
      {"elementType": "labels.text.stroke", "stylers": [{"color": "#242f3e"}]},
      {"elementType": "labels.text.fill", "stylers": [{"color": "#746855"}]},
      {
        "featureType": "administrative.locality",
        "elementType": "labels.text.fill",
        "stylers": [{"color": "#d59563"}]
      },
      {
        "featureType": "poi",
        "elementType": "labels.text.fill",
        "stylers": [{"color": "#d59563"}]
      },
      {
        "featureType": "poi.park",
        "elementType": "geometry",
        "stylers": [{"color": "#263c3f"}]
      },
      {
        "featureType": "poi.park",
        "elementType": "labels.text.fill",
        "stylers": [{"color": "#6b9a76"}]
      },
      {
        "featureType": "road",
        "elementType": "geometry",
        "stylers": [{"color": "#38414e"}]
      },
      {
        "featureType": "road",
        "elementType": "geometry.stroke",
        "stylers": [{"color": "#212a37"}]
      },
      {
        "featureType": "road",
        "elementType": "labels.text.fill",
        "stylers": [{"color": "#9ca5b3"}]
      },
      {
        "featureType": "road.highway",
        "elementType": "geometry",
        "stylers": [{"color": "#746855"}]
      },
      {
        "featureType": "road.highway",
        "elementType": "geometry.stroke",
        "stylers": [{"color": "#1f2835"}]
      },
      {
        "featureType": "road.highway",
        "elementType": "labels.text.fill",
        "stylers": [{"color": "#f3d19c"}]
      },
      {
        "featureType": "transit",
        "elementType": "geometry",
        "stylers": [{"color": "#2f3948"}]
      },
      {
        "featureType": "transit.station",
        "elementType": "labels.text.fill",
        "stylers": [{"color": "#d59563"}]
      },
      {
        "featureType": "water",
        "elementType": "geometry",
        "stylers": [{"color": "#17263c"}]
      },
      {
        "featureType": "water",
        "elementType": "labels.text.fill",
        "stylers": [{"color": "#515c6d"}]
      },
      {
        "featureType": "water",
        "elementType": "labels.text.stroke",
        "stylers": [{"color": "#17263c"}]
      }
    ]
    ''';

  String? _getMapStyle(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? _darkMapStyleJson 
        : _mapStyleJson;
  }
}
