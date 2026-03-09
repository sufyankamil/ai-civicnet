import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      _checkFeedbackPrompt();
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

  Future<void> _checkFeedbackPrompt() async {
    // Wait for 12 seconds as requested (10-15s range)
    await Future.delayed(const Duration(seconds: 12));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    
    // Check Grace Period (Minimum 3 launches)
    final launchCount = prefs.getInt('app_launch_count') ?? 0;
    if (launchCount < 3) {
      logger.d('Feedback prompt suppressed: New user (Launch $launchCount < 3)');
      return;
    }

    final lastPromptTimeStr = prefs.getString('last_feedback_prompt_time');
    final lastPromptType = prefs.getString('last_feedback_prompt_type'); // 'submit' or 'ignore'

    if (lastPromptTimeStr != null) {
      final lastPromptTime = DateTime.parse(lastPromptTimeStr);
      final now = DateTime.now();
      final difference = now.difference(lastPromptTime).inDays;

      if (lastPromptType == 'submit' && difference < 30) return;
      if (lastPromptType == 'ignore' && difference < 5) return;
    }

    if (!mounted) return;

    _showFeedbackInvitation();
  }

  void _showFeedbackInvitation() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Icon(Icons.favorite_rounded, color: AppColors.accentLight, size: 48),
            const SizedBox(height: 16),
            Text(
              'Enjoying Civic Net?',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your feedback is invaluable to us. Would you like to share your thoughts or suggest improvements?',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('last_feedback_prompt_time', DateTime.now().toIso8601String());
                      await prefs.setString('last_feedback_prompt_type', 'ignore');
                      if (context.mounted) Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      'Maybe Later',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      // Navigator to feedback screen
                      await context.push('/feedback');
                      
                      // If they came back from feedback, we assume they submitted or at least engaged
                      // The FeedbackScreen will handle the submission logic, but we mark it here too
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('last_feedback_prompt_time', DateTime.now().toIso8601String());
                      await prefs.setString('last_feedback_prompt_type', 'submit');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryLight,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Give Feedback',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
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
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 80,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'No Requests Nearby',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'There are no open help requests in your area right now. Be the first to post one!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[400],
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: _viewModel.fetchRequests,
                                      icon: const Icon(Icons.refresh_rounded),
                                      label: const Text('Refresh'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    FilledButton.icon(
                                      onPressed: () => context.push('/create-request'),
                                      icon: const Icon(Icons.add),
                                      label: const Text('Post a Request'),
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
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
