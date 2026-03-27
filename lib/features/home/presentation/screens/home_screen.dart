import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../l10n/app_localizations.dart';

import '../../../../theme/app_theme.dart';
import '../../../../services/supabase_service.dart';
import '../../../../services/logger_service.dart';
import '../../../../services/toast_service.dart';
import '../../../../components/request_card.dart';
import '../../../../components/request_card_skeleton.dart';
import '../viewmodels/home_viewmodel.dart';
import '../widgets/poll_card.dart';
import '../widgets/guild_card.dart';
import '../../../news/presentation/components/news_section.dart';
import '../../../../widgets/haptic_buttons.dart';
import '../../../../models/models.dart';

class HomeScreen extends StatefulWidget {
  final String? initialFilter;
  
  const HomeScreen({super.key, this.initialFilter});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final HomeViewModel _viewModel = Get.find<HomeViewModel>();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  bool _showSafetyBanner = false;
  String _newsSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          // Trigger rebuild to update search hint
        });
      }
    });

    if (widget.initialFilter != null) {
      _viewModel.onFilterSelected(widget.initialFilter!);
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocationPermission();
      _checkFeedbackPrompt();
      _checkSafetyBanner();
    });
  }

  Future<void> _checkSafetyBanner() async {
    final prefs = await SharedPreferences.getInstance();
    final isDismissed = prefs.getBool('safety_banner_dismissed') ?? false;
    if (!isDismissed && mounted) {
      setState(() => _showSafetyBanner = true);
    }
  }

  Future<void> _dismissSafetyBanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('safety_banner_dismissed', true);
    if (mounted) {
      setState(() => _showSafetyBanner = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    await Future.delayed(const Duration(seconds: 1)); // Reduced delay for better UX
    if (!mounted) return;

    final user = await SupabaseService().getCurrentUserProfile();
    if (user != null && (user.lat == 0.0 || user.lng == 0.0 || user.lat == null)) {
       if (!mounted) return;
       
       showDialog(
         context: context,
         barrierDismissible: false,
         builder: (context) {
           final l10n = AppLocalizations.of(context)!;
           return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.primaryLight, size: 28),
              const SizedBox(width: 8),
              Text(l10n.locationPermissionTitle),
            ],
          ),
          content: Text(l10n.locationPermissionDesc),
          actions: [
            AppHaptic(
              onTap: () => Navigator.of(context).pop(),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(l10n.notNow, style: const TextStyle(color: Colors.grey)),
              ),
            ),
            AppElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _requestLocationUpdates();
              },
              child: Text(l10n.allowAccess),
            ),
           ],
         );
       },
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
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
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
              AppLocalizations.of(context)!.enjoyingApp,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.feedbackDescription,
              textAlign: TextAlign.center,
              style: TextStyle(
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
                      AppLocalizations.of(context)!.maybeLater,
                      style: TextStyle(
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
                    child: Text(
                      AppLocalizations.of(context)!.giveFeedback,
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(l10n),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  if (_tabController.index == 0) {
                    _viewModel.onSearchChanged(value);
                  } else {
                    setState(() {
                      _newsSearchQuery = value;
                    });
                  }
                },
                decoration: InputDecoration(
                  hintText: _tabController.index == 0 
                      ? l10n.searchHelp 
                      : l10n.searchNews,
                  hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainer,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            _buildFilters(l10n),
            if (_showSafetyBanner) _buildSafetyBanner(l10n),

            // TabBar for switching between Requests and News
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TabBar(
                controller: _tabController,
                isScrollable: false,
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                indicatorPadding: const EdgeInsets.symmetric(horizontal: 16),
                indicatorColor: Theme.of(context).primaryColor,
                dividerColor: Colors.transparent,
                labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                tabs: [
                  Tab(text: AppLocalizations.of(context)!.homeTitle),
                  Tab(text: AppLocalizations.of(context)!.discoverTitle),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRequestsTab(l10n),
                  _buildNewsTab(l10n),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.appTitle,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.findMatches,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.push('/activity'),
            icon: const Icon(Icons.assignment_outlined, color: Colors.grey),
          ),
          FutureBuilder(
            future: SupabaseService().getCurrentUserProfile(),
            builder: (context, snapshot) {
              final user = snapshot.data;
              if (user != null && (user.role == 'admin' || user.role == 'super_admin')) {
                return IconButton(
                  onPressed: () => context.push('/create-poll'),
                  icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryLight),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            onPressed: () => context.push('/map'),
            icon: const Icon(Icons.map_rounded, color: AppColors.primaryLight),
            tooltip: 'Community Map',
          ),
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
    );
  }

  Widget _buildRequestsTab(AppLocalizations l10n) {
    return Column(
      children: [
        // Polls Section (Active Polls)
        Obx(() {
          if (_viewModel.polls.isEmpty) return const SizedBox.shrink();
          
          // Show a summary card that opens a bottom sheet for all active polls
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: InkWell(
              onTap: () => _showPollsBottomSheet(context, l10n),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryLight,
                      AppColors.primaryLight.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryLight.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.poll_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.activePolls,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            l10n.pollsCount(_viewModel.polls.length),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),

        // Guilds Row (Discovery)
        Obx(() => _viewModel.guilds.isEmpty 
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.findYourGuild,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () { /* TODO: Navigator to full discovery */ },
                        child: Text(l10n.seeAll),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _viewModel.guilds.length,
                    itemBuilder: (context, index) {
                      final guild = _viewModel.guilds[index];
                      return GuildCard(
                        guild: guild,
                        onToggleJoin: () => _viewModel.toggleGuildMembership(guild),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            )
        ),
        
        // List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _viewModel.fetchRequests,
            child: Obx(() {
              if (_viewModel.isLoading && _viewModel.filteredRequests.isEmpty) {
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 5,
                  itemBuilder: (context, index) => const RequestCardSkeleton(),
                );
              }
              
              if (_viewModel.filteredRequests.isEmpty) {
                return _buildRequestPlaceholder(l10n);
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
    );
  }

  Widget _buildNewsTab(AppLocalizations l10n) {
    return NewsSection(searchQuery: _newsSearchQuery);
  }

  Widget _buildSafetyBanner(AppLocalizations l10n) {
    if (!_showSafetyBanner) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentLight.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.shield_rounded, color: AppColors.accentLight, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.communityCommitment,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.accentLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.safetyDescription,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: _dismissSafetyBanner,
                icon: const Icon(Icons.close_rounded, size: 20, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => context.push('/commitment'),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.accentLight.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                l10n.learnMoreSafety,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentLight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPollsBottomSheet(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.activePolls,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Obx(() => ListView.builder(
                  controller: scrollController,
                  itemCount: _viewModel.polls.length,
                  itemBuilder: (context, index) {
                    final poll = _viewModel.polls[index];
                    return FutureBuilder(
                      future: SupabaseService().getCurrentUserProfile(),
                      builder: (context, snapshot) {
                        final user = snapshot.data;
                        return PollCard(
                          poll: poll,
                          isCreator: user?.id == poll.creatorId,
                          onVote: (optionId) => _viewModel.voteInPoll(poll.id, optionId),
                          onDelete: () => _showDeletePollDialog(poll),
                        );
                      }
                    );
                  },
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeletePollDialog(Poll poll) {
    showAdaptiveDialog(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: Text(AppLocalizations.of(context)!.deletePoll),
        content: Text(AppLocalizations.of(context)!.deletePollConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              _viewModel.deletePoll(poll.id);
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _viewModel.selectedFilter == filterKey;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) _viewModel.onFilterSelected(filterKey);
        },
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        checkmarkColor: Theme.of(context).primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? Theme.of(context).primaryColor : null,
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(AppLocalizations l10n) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Obx(() => Row(
        children: [
          _buildFilterChip('All', l10n.categoryAll),
          _buildFilterChip('Recommended', l10n.categoryRecommended),
          _buildFilterChip('Emergency', l10n.categoryEmergency),
          _buildFilterChip('Tech Support', l10n.categoryTechSupport),
          _buildFilterChip('Household', l10n.categoryHousehold),
        ],
      )),
    );
  }

  Widget _buildRequestPlaceholder(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            l10n.noRequests,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.noRequestsDescription,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                label: Text(l10n.refresh),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () => context.push('/create-request'),
                icon: const Icon(Icons.add),
                label: Text(l10n.postRequest),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
