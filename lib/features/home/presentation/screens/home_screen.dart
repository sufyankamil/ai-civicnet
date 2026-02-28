import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../theme/app_theme.dart';
import '../../../../services/supabase_service.dart';
import '../../../../services/logger_service.dart';
import '../../../../services/toast_service.dart';
import '../../../../components/request_card.dart';
import '../viewmodels/home_viewmodel.dart';

class HomeScreen extends StatefulWidget {
  final String? initialFilter;
  
  const HomeScreen({super.key, this.initialFilter});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeViewModel _viewModel = Get.find<HomeViewModel>();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter != null) {
      _viewModel.onFilterSelected(widget.initialFilter!);
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocationPermission();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    await Future.delayed(const Duration(seconds: 5));
    if (!mounted) return;

    final user = await SupabaseService().getCurrentUserProfile();
    if (user != null && (user.lat == 0.0 || user.lng == 0.0 || user.lat == null)) {
       if (!mounted) return;
       
       showDialog(
         context: context,
         barrierDismissible: false,
         builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.primaryLight, size: 28),
              const SizedBox(width: 8),
              const Text('Enable Location'),
            ],
          ),
          content: const Text(
            'To show accurate help requests and matches near you, Civic Net needs access to your location.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Not Now', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _requestLocationUpdates();
              },
              child: const Text('Allow Access'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _requestLocationUpdates() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) ToastService.showInfo(context, 'Location services are disabled.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
         if (mounted) ToastService.showInfo(context, 'Location permission denied.');
         return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (mounted) ToastService.showInfo(context, 'Location permissions are permanently denied, we cannot request permissions.');
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      await SupabaseService().updateUserLocation(position.latitude, position.longitude);
      if (mounted) ToastService.showSuccess(context, 'Location updated successfully!');
      
      _viewModel.fetchRequests();
    } catch (e) {
      logger.e('Error updating location: $e');
      if (mounted) ToastService.showError(context, 'Unable to update location. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Community Help',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Finding matches near you...',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                   const Spacer(),
                   IconButton(
                     onPressed: () => context.push('/notifications'),
                     icon: Badge(
                       label: const Text('2'), 
                       backgroundColor: Colors.red,
                       child: const Icon(Icons.notifications_outlined, size: 28),
                     ),
                   ),
                   const SizedBox(width: 8),
                   FutureBuilder(
                     future: SupabaseService().getCurrentUserProfile(),
                     builder: (context, snapshot) {
                       final user = snapshot.data;
                       final hasAvatar = user?.avatarUrl != null && user!.avatarUrl.isNotEmpty;
                       
                       return InkWell(
                         onTap: () => context.push('/profile'), 
                         borderRadius: BorderRadius.circular(20),
                         child: Padding(
                           padding: const EdgeInsets.all(4.0),
                           child: CircleAvatar(
                             radius: 20,
                             backgroundColor: Colors.grey,
                             backgroundImage: hasAvatar ? NetworkImage(user.avatarUrl) : null,
                             child: hasAvatar ? null : const Icon(Icons.person, color: Colors.white),
                           ),
                         ),
                       );
                     }
                   ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _searchController,
                onChanged: _viewModel.onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search requests, skills...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // Filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(16),
              child: Obx(() => Row(
                children: [
                  _buildFilterChip('All'),
                  _buildFilterChip('Recommended'),
                  _buildFilterChip('Emergency'),
                  _buildFilterChip('Tech Support'),
                  _buildFilterChip('Household'),
                ],
              )),
            ),

            // List
            Expanded(
              child: RefreshIndicator(
                onRefresh: _viewModel.fetchRequests,
                child: Obx(() {
                  if (_viewModel.isLoading && _viewModel.filteredRequests.isEmpty) {
                    return const Center(child: CircularProgressIndicator.adaptive());
                  }
                  
                  if (_viewModel.filteredRequests.isEmpty) {
                    return ListView(
                      children: const [
                         SizedBox(height: 100),
                         Center(
                           child: Padding(
                             padding: EdgeInsets.all(32.0),
                             child: Text('No requests found nearby.\\nPull to refresh.', textAlign: TextAlign.center),
                           ),
                         )
                      ],
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _viewModel.filteredRequests.length,
                    itemBuilder: (context, index) {
                      return RequestCard(request: _viewModel.filteredRequests[index]);
                    },
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _viewModel.selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => _viewModel.onFilterSelected(label),
        backgroundColor: Colors.transparent,
        shape: StadiumBorder(
          side: BorderSide(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        labelStyle: TextStyle(
          color: isSelected ? Theme.of(context).primaryColor : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        showCheckmark: false,
      ),
    );
  }
}
