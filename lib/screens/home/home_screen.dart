
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:civic_net/services/logger_service.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../components/help_request_card.dart';
import '../../theme/app_theme.dart';

import '../../services/supabase_service.dart';
import '../../services/toast_service.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatefulWidget {
  final String? initialFilter;
  
  const HomeScreen({super.key, this.initialFilter});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Removed local _requests list
  late String _selectedFilter;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';
  late Future<List<HelpRequest>> _requestsFuture;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _isDisposed = true;
    if (_subscription != null) {
      if (_subscription is StreamSubscription) {
         _subscription.cancel();
      } else {
         _subscription.unsubscribe();
      }
    }
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 1000), () {
      setState(() {
        _searchQuery = query.toLowerCase();
      });
    });
  }

  // Helper to filter requests locally after fetching
  List<HelpRequest> _filterRequests(List<HelpRequest> requests) {
    // First, filter by search query if exists
    List<HelpRequest> filtered = requests;
    
    if (_searchQuery.isNotEmpty) {
      filtered = requests.where((r) {
        return r.title.toLowerCase().contains(_searchQuery) || 
               r.description.toLowerCase().contains(_searchQuery) ||
               r.category.toString().toLowerCase().contains(_searchQuery);
      }).toList();
    }

    // Then filter by category chips
    if (_selectedFilter == 'All') {
      return filtered;
    } else if (_selectedFilter == 'Recommended') {
      return filtered.where((r) => r.aiRelevanceScore > 0.8).toList();
    } else {
      return filtered.where((r) {
        if (_selectedFilter == 'Tech Support') return r.category == HelpCategory.techSupport;
        if (_selectedFilter == 'Emergency') return r.category == HelpCategory.emergency;
        if (_selectedFilter == 'Household') return r.category == HelpCategory.household;
        // Fallback text match
        return r.category.toString().split('.').last == _selectedFilter.toLowerCase().replaceAll(' ', '');
      }).toList();
    }
  }

  // Subscription for realtime updates
  late final dynamic _subscription;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter ?? 'All';
    _requestsFuture = SupabaseService().getHelpRequests();
    
    // Subscribe to changes in help_requests
    _subscription = SupabaseService().subscribeToHelpRequests(() {
      if (mounted && !_isDisposed) {
        setState(() {
          _requestsFuture = SupabaseService().getHelpRequests();
        });
      }
    });
    
    // Check for warnings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkWarnings();
      _checkLocationPermission();
    });
  }

  Future<void> _checkLocationPermission() async {
    // Wait 5 seconds
    await Future.delayed(const Duration(seconds: 5));
    if (!mounted) return;

    final user = await SupabaseService().getCurrentUserProfile();
    // Check if location is missing (0.0 is the default fallback in model)
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
              onPressed: () => Navigator.pop(context),
              child: const Text('Not Now', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
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

    // Get Position
    try {
      final position = await Geolocator.getCurrentPosition();
      await SupabaseService().updateUserLocation(position.latitude, position.longitude);
      if (mounted) ToastService.showSuccess(context, 'Location updated successfully!');
      
      // Refresh home data
      setState(() {
        _requestsFuture = SupabaseService().getHelpRequests();
      });
    } catch (e) {
      if (mounted) ToastService.showError(context, 'Error updating location: $e');
    }
  }

  Future<void> _checkWarnings() async {
    final user = await SupabaseService().getCurrentUserProfile();
    logger.i('Checking warnings for user ${user?.id}, report count: ${user?.reportCount}');
    if (user != null && user.reportCount > 2) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                const SizedBox(width: 8),
                const Text('Warning Issued'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your account has been reported by multiple users for violating community guidelines.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'Please ensure you respect other users and follow our safety guidelines. Continued reports will result in a temporary ban.',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('I Understand'),
              ),
            ],
          ),
        );
      }
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
                   // Notifications Icon
                   IconButton(
                     onPressed: () => context.push('/notifications'),
                     icon: Badge(
                       label: const Text('2'), // Example count
                       backgroundColor: Colors.red,
                       child: const Icon(Icons.notifications_outlined, size: 28),
                     ),
                   ),
                   const SizedBox(width: 8),
                   // Real User Avatar
                   FutureBuilder<User?>( // Use specific User type if needed, or rely on inference
                     future: SupabaseService().getCurrentUserProfile(),
                     builder: (context, snapshot) {
                       final user = snapshot.data;
                       final avatarUrl = user?.avatarUrl;
                       
                       return InkWell( // Use InkWell for better touch feedback
                         onTap: () => context.push('/profile'), 
                         borderRadius: BorderRadius.circular(20),
                         child: Padding( // Add padding to increase hit area
                           padding: const EdgeInsets.all(4.0),
                           child: CircleAvatar(
                             radius: 20,
                             backgroundColor: Colors.grey[200],
                             backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) 
                                ? CachedNetworkImageProvider(avatarUrl) 
                                : null,
                             child: (avatarUrl == null || avatarUrl.isEmpty) 
                                ? const Icon(Icons.person, color: Colors.grey) 
                                : null,
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
                onChanged: _onSearchChanged,
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
              child: Row(
                children: [
                  _buildFilterChip('All'),
                  _buildFilterChip('Recommended'),
                  _buildFilterChip('Emergency'),
                  _buildFilterChip('Tech Support'),
                  _buildFilterChip('Household'),
                ],
              ),
            ),

            // List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _requestsFuture = SupabaseService().getHelpRequests();
                  }); 
                },
                child: FutureBuilder<List<HelpRequest>>(
                  future: _requestsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator.adaptive());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return ListView(
                        children: const [
                           SizedBox(height: 100),
                           Center(
                             child: Padding(
                               padding: EdgeInsets.all(32.0),
                               child: Text('No requests found nearby.\nPull to refresh.', textAlign: TextAlign.center),
                             ),
                           )
                        ],
                      );
                    }

                    final filtered = _filterRequests(snapshot.data!);

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        return HelpRequestCard(request: filtered[index]);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),

    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          setState(() {
            _selectedFilter = label;
          });
        },
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
