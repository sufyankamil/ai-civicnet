import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
import '../widgets/community_briefing_card.dart';
import '../widgets/update_notice_modal.dart';
import '../../../news/presentation/components/news_section.dart';
import '../../../../widgets/haptic_buttons.dart';
import '../../../../core/services/version_service.dart';
import '../widgets/update_popup.dart';

class HomeScreen extends StatefulWidget {
  final String? initialFilter;
  
  const HomeScreen({super.key, this.initialFilter});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  static bool _hasShownLocationPrompt = false;
  final HomeViewModel _viewModel = Get.find<HomeViewModel>();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _filterScrollController = ScrollController();
  late TabController _tabController;
  bool _showSafetyBanner = false;
  String _newsSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {}); // Update search hint
      }
    });

    if (widget.initialFilter != null) {
      _viewModel.onFilterSelected(widget.initialFilter!);
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocationPermission();
      _checkFeedbackPrompt();
      _checkSafetyBanner();
      _checkVersionUpdate();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _filterScrollController.dispose();
    super.dispose();
  }

  // --- Logic Helpers ---

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

  Future<void> _checkVersionUpdate() async {
    final newVersion = await VersionService.checkUpdateNeeded();
    if (newVersion != null && mounted) {
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      await UpdateNoticeModal.show(context, AppUpdates.currentUpdates, () => VersionService.markAsNotified());
    }
    if (mounted) _checkStoreUpdate();
  }

  Future<void> _checkStoreUpdate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final storeVersion = await VersionService.checkStoreUpdateAvailable();
    if (storeVersion != null && mounted) {
      UpdatePopup.show(
        context,
        newVersion: storeVersion,
        onUpdate: () => VersionService.upgrader.sendUserToAppStore(),
        onLater: () => logger.d('User chose to update later'),
      );
    }
  }

  Future<void> _checkLocationPermission() async {
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted || _hasShownLocationPrompt) return;
    
    final user = await SupabaseService().getCurrentUserProfile();
    if (user != null && (user.lat == 0.0 || user.lat == null)) {
       _hasShownLocationPrompt = true;
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
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.notNow, style: const TextStyle(color: Colors.grey)),
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
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    try {
      final position = await Geolocator.getCurrentPosition();
      await SupabaseService().updateUserLocation(position.latitude, position.longitude);
      if (mounted) ToastService.showSuccess(context, 'Location updated!');
      _viewModel.fetchRequests();
    } catch (e) {
      logger.e('Error updating location: $e');
    }
  }

  Future<void> _checkFeedbackPrompt() async {
    await Future.delayed(const Duration(seconds: 12));
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final launchCount = prefs.getInt('app_launch_count') ?? 0;
    if (launchCount < 3) return;

    final lastPromptTimeStr = prefs.getString('last_feedback_prompt_time');
    final lastPromptType = prefs.getString('last_feedback_prompt_type');

    if (lastPromptTimeStr != null) {
      final lastPromptTime = DateTime.parse(lastPromptTimeStr);
      final difference = DateTime.now().difference(lastPromptTime).inDays;
      if (lastPromptType == 'submit' && difference < 30) return;
      if (lastPromptType == 'ignore' && difference < 5) return;
    }
    _showFeedbackInvitation();
  }

  void _showFeedbackInvitation() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite_rounded, color: AppColors.accentLight, size: 48),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.enjoyingApp, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(AppLocalizations.of(context)!.feedbackDescription, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context)!.maybeLater),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/feedback');
                    },
                    child: Text(AppLocalizations.of(context)!.giveFeedback),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Build Methods ---

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          gradient: RadialGradient(
            center: const Alignment(0.7, -0.6),
            radius: 1.5,
            colors: [
              AppColors.primaryLight.withValues(alpha: isDark ? 0.08 : 0.05),
              Theme.of(context).scaffoldBackgroundColor,
            ],
            stops: const [0.0, 0.8],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              _buildModernSliverAppBar(l10n),
              _buildPinnedSearchAndTabs(l10n),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    if (_showSafetyBanner) _buildSafetyBanner(l10n),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _tabController.index == 0
                          ? _buildRequestsTabContent(l10n)
                          : _buildNewsTabContent(l10n),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernSliverAppBar(AppLocalizations l10n) {
    return SliverAppBar(
      expandedHeight: 108,
      floating: false,
      pinned: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: _buildHeaderCompact(l10n),
        ),
      ),
    );
  }

  Widget _buildHeaderCompact(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder(
              future: SupabaseService().getCurrentUserProfile(),
              builder: (context, snapshot) {
                final name = snapshot.data?.name ?? 'Friend';
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return Text(
                  'Hey, $name!',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
            Text(l10n.appTitle, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.7)),
          ],
        ),
        Row(
          children: [
            _buildHeaderIconButton(Icons.history_rounded, () => context.push('/activity')),
            const SizedBox(width: 12),
            _buildProfileAvatar(),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderIconButton(IconData icon, VoidCallback onTap, {bool isClose = false}) {
     return AppHaptic(
       onTap: onTap,
       child: Container(
         padding: const EdgeInsets.all(10),
         decoration: BoxDecoration(
           color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black).withValues(alpha: isClose ? 0.1 : 0.05),
           shape: BoxShape.circle,
         ),
         child: Icon(icon, size: isClose ? 18 : 22, color: isClose ? Colors.grey[400] : Colors.grey[600]),
       ),
     );
  }

  Widget _buildProfileAvatar() {
    return FutureBuilder(
      future: SupabaseService().getCurrentUserProfile(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final hasAvatar = user?.avatarUrl != null && user!.avatarUrl.isNotEmpty;
        return AppHaptic(
          onTap: () => context.push('/profile'),
          child: Hero(
            tag: 'profile-avatar',
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(gradient: AppColors.auraGradient, shape: BoxShape.circle),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[200],
                backgroundImage: hasAvatar ? CachedNetworkImageProvider(user.avatarUrl) : null,
                child: hasAvatar ? null : const Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPinnedSearchAndTabs(AppLocalizations l10n) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _PinnedHeaderDelegate(
        child: Container(
          decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.85)),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Column(
                children: [
                  Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 8), child: _buildAuraSearch(l10n)),
                  _buildFloatingTabs(l10n),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuraSearch(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1), width: 1),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => _tabController.index == 0 ? _viewModel.onSearchChanged(v) : setState(() => _newsSearchQuery = v),
        decoration: InputDecoration(
          hintText: _tabController.index == 0 ? l10n.searchHelp : l10n.searchNews,
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400], size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFloatingTabs(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(22),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey[600],
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          dividerColor: Colors.transparent,
          tabs: [Tab(text: l10n.homeTitle), Tab(text: l10n.communityTitle)],
        ),
      ),
    );
  }

  Widget _buildRequestsTabContent(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          _buildFiltersModern(l10n),
          Obx(() => (_viewModel.communityBriefing.isNotEmpty || _viewModel.isBriefingLoading || _viewModel.topRecommendation != null)
              ? _buildAiInsightSection(l10n) : const SizedBox.shrink()),
          Obx(() => _viewModel.guilds.isEmpty ? const SizedBox.shrink() : _buildGuildsSection(l10n)),
          _buildRequestsList(l10n),
        ],
      ),
    );
  }

  Widget _buildNewsTabContent(AppLocalizations l10n) {
    return Column(
      children: [
        Obx(() => _viewModel.polls.isEmpty ? const SizedBox.shrink() : _buildPollsTriggerCard(l10n)),
        NewsSection(searchQuery: _newsSearchQuery),
      ],
    );
  }

  Widget _buildFiltersModern(AppLocalizations l10n) {
    final filters = ['All', 'Recommended', 'Emergency', 'Tech Support', 'Household'];
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          return Obx(() {
            final isSelected = _viewModel.selectedFilter == filter;
            final color = _getFilterColor(filter);
            return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: AppHaptic(
              onTap: () => _viewModel.onFilterSelected(filter),
              child: AnimatedScale(
                scale: isSelected ? 1.05 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 90,
                  decoration: BoxDecoration(
                    color: isSelected ? color : color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Colors.white.withValues(alpha: 0.2) : color.withValues(alpha: 0.1), 
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 15,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getFilterIcon(filter), 
                          color: isSelected ? Colors.white : color, 
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _getFilterLabel(filter, l10n), 
                        style: TextStyle(
                          fontSize: 10, 
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold, 
                          color: isSelected ? Colors.white : color,
                        ), 
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            );
          });
        },
      ),
    );
  }

  Color _getFilterColor(String f) {
    if (f == 'Emergency') return Colors.red;
    if (f == 'Household') return Colors.orange;
    if (f == 'Tech Support') return Colors.blue;
    if (f == 'Recommended') return Colors.purple;
    return AppColors.primaryLight;
  }

  IconData _getFilterIcon(String f) {
    if (f == 'All') return Icons.grid_view_rounded;
    if (f == 'Recommended') return Icons.auto_awesome_rounded;
    if (f == 'Emergency') return Icons.bolt_rounded;
    if (f == 'Tech Support') return Icons.biotech_rounded;
    if (f == 'Household') return Icons.home_rounded;
    return Icons.category_rounded;
  }

  String _getFilterLabel(String k, AppLocalizations l) {
    if (k == 'All') return l.categoryAll;
    if (k == 'Recommended') return l.categoryRecommended;
    if (k == 'Emergency') return l.categoryEmergency;
    if (k == 'Tech Support') return l.categoryTechSupport;
    if (k == 'Household') return l.categoryHousehold;
    return k;
  }

  Widget _buildAiInsightSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_viewModel.communityBriefing.isNotEmpty || _viewModel.isBriefingLoading)
          CommunityBriefingCard(
            briefing: _viewModel.communityBriefing,
            isLoading: _viewModel.isBriefingLoading,
            onRefresh: () => _viewModel.fetchCommunityBriefing(force: true),
          ),
        if (_viewModel.topRecommendation != null && _viewModel.topRecommendation!.aiRelevanceScore > 0.6)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: RequestCard(request: _viewModel.topRecommendation!),
          ),
      ],
    );
  }

  Widget _buildGuildsSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 8, 16, 12), child: Text(l10n.findYourGuild, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        SizedBox(
          height: 170,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _viewModel.guilds.length,
            itemBuilder: (context, index) {
              final guild = _viewModel.guilds[index];
              return GuildCard(guild: guild, onToggleJoin: () => _viewModel.toggleGuildMembership(guild));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPollsTriggerCard(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: AppHaptic(
        onTap: () => _showPollsBottomSheet(l10n),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppColors.auraGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryLight.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.how_to_vote_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.activePolls,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                    ),
                    Text(
                      'Voice your opinion in community decisions',
                      style: TextStyle(
                        fontSize: 13,
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Obx(() => Text(
                  '${_viewModel.polls.length}',
                  style: const TextStyle(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                )),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3)),
            ],
          ),
        ),
      ),
    );
  }

  void _showPollsBottomSheet(AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPollsSheetContent(l10n),
    );
  }

  Widget _buildPollsSheetContent(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                color: (isDark ? AppColors.glassSurfaceDark : AppColors.glassSurfaceLight).withValues(alpha: 0.8),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.activePolls,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                          ),
                          _buildHeaderIconButton(Icons.close_rounded, () => Navigator.pop(context), isClose: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Obx(() => ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                        itemCount: _viewModel.polls.length,
                        itemBuilder: (context, index) {
                          final poll = _viewModel.polls[index];
                          return PollCard(
                            poll: poll,
                            onVote: (id) => _viewModel.voteInPoll(poll.id, id),
                            isCreator: false,
                          );
                        },
                      )),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSafetyBanner(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accentLight.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_rounded, color: AppColors.accentLight, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.communityCommitment, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.accentLight)),
                const SizedBox(height: 4),
                Text(l10n.safetyDescription, style: const TextStyle(fontSize: 12, height: 1.4)),
              ],
            ),
          ),
          _buildHeaderIconButton(Icons.close_rounded, _dismissSafetyBanner, isClose: true),
        ],
      ),
    );
  }

  Widget _buildRequestsList(AppLocalizations l10n) {
    return Obx(() {
      if (_viewModel.isLoading && _viewModel.filteredRequests.isEmpty) {
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 5,
          itemBuilder: (context, index) => const RequestCardSkeleton(),
        );
      }
      if (_viewModel.filteredRequests.isEmpty) {
        final filter = _viewModel.selectedFilter;
        final icon = _getFilterIcon(filter);
        final color = _getFilterColor(filter);
        
        return Center(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(40, 60, 40, 80),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 64, color: color.withValues(alpha: 0.5)),
                ),
                const SizedBox(height: 24),
                Text(
                  filter == 'All' ? l10n.noRequests : 'No $filter Requests',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.w900, 
                    color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black).withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.noRequestsDescription,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14, 
                    color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black).withValues(alpha: 0.4),
                    height: 1.5,
                  ),
                ),
                if (filter != 'All') ...[
                  const SizedBox(height: 32),
                  AppHaptic(
                    onTap: () => _viewModel.onFilterSelected('All'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.2)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh_rounded, size: 18, color: AppColors.primaryLight),
                          SizedBox(width: 8),
                          Text(
                            'Show All Requests',
                            style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _viewModel.filteredRequests.length,
        itemBuilder: (context, index) => RequestCard(request: _viewModel.filteredRequests[index]),
      );
    });
  }
}

class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _PinnedHeaderDelegate({required this.child});
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;
  @override
  double get maxExtent => 125;
  @override
  double get minExtent => 125;
  @override
  bool shouldRebuild(covariant _PinnedHeaderDelegate oldDelegate) => true;
}
