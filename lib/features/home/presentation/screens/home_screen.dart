import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../widgets/haptic_buttons.dart';
import '../../../../services/logger_service.dart';
import '../../../../services/toast_service.dart';
import '../../../../services/rating_service.dart';
import '../../../../components/request_card.dart';

import '../../../../theme/app_theme.dart';
import '../../../../services/supabase_service.dart';
import '../viewmodels/home_viewmodel.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/home_filter_bar.dart';
import '../widgets/home_safety_banner.dart';
import '../widgets/home_requests_list.dart';
import '../widgets/home_polls_section.dart';
import '../widgets/guild_card.dart';
import '../widgets/community_briefing_card.dart';
import '../widgets/update_notice_modal.dart';
import '../../../news/presentation/components/news_section.dart';
import '../../../../core/services/version_service.dart';
import '../widgets/update_popup.dart';
import '../../../../core/services/vpn_service.dart';
import '../widgets/vpn_warning_banner.dart';
import 'dart:async';

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
  bool _isVpnActive = false;
  bool _vpnWarningDismissed = false;
  StreamSubscription<bool>? _vpnSubscription;
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
      _checkVpnStatus();
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
    _vpnSubscription?.cancel();
    super.dispose();
  }

  // --- Logic Helpers ---

  Future<void> _checkVpnStatus() async {
    final vpnService = VpnService();
    final isActive = await vpnService.isVpnActive();
    if (mounted) setState(() => _isVpnActive = isActive);

    _vpnSubscription = vpnService.vpnStatusStream.listen((isActive) {
      if (mounted) setState(() => _isVpnActive = isActive);
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
    
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
       _hasShownLocationPrompt = true;
       if (!mounted) return;
       showDialog(
         context: context,
         barrierDismissible: false,
         builder: (context) {
           final l10n = AppLocalizations.of(context)!;
           return Center(
             child: ConstrainedBox(
               constraints: const BoxConstraints(maxWidth: 450),
               child: AlertDialog(
                title: Row(
                  children: [
                    const Icon(Icons.location_on, color: AppColors.primaryLight, size: 28),
                    const SizedBox(width: 8),
                    Text(l10n.locationPermissionTitle),
                  ],
                ),
                content: Text(l10n.locationPermissionDesc),
                actions: [
                  AppElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      final permission = await Geolocator.checkPermission();
                      if (permission == LocationPermission.deniedForever) {
                        await Geolocator.openAppSettings();
                      } else {
                        _requestLocationUpdates();
                      }
                    },
                    child: Center(child: Text(l10n.allowAccess)),
                  ),
                 ],
               ),
             ),
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
      builder: (context) => Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 550),
          child: Container(
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
                  Text(
                    AppLocalizations.of(context)!.feedbackDescription,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 32),
                  Column(
                    children: [
                      AppHaptic(
                        onTap: () async {
                          Navigator.pop(context);
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('last_feedback_prompt_time', DateTime.now().toIso8601String());
                          await prefs.setString('last_feedback_prompt_type', 'submit'); // Consider 'rate' but shared logic
                          await RatingService.requestReview();
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient(Theme.of(context).brightness),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryLight.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'I love it!',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.setString('last_feedback_prompt_time', DateTime.now().toIso8601String());
                                await prefs.setString('last_feedback_prompt_type', 'ignore');
                              },
                              child: Text(AppLocalizations.of(context)!.maybeLater),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                context.push('/feedback');
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: AppColors.primaryLight.withValues(alpha: 0.5)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text(
                                'Need Help / Feedback',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
              const HomeAppBar(),
              HomeSearchBar(
                searchController: _searchController,
                tabController: _tabController,
                onSearchChanged: (v) => _tabController.index == 0 ? _viewModel.onSearchChanged(v) : setState(() => _newsSearchQuery = v),
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    if (_isVpnActive && !_vpnWarningDismissed) 
                      VpnWarningBanner(onDismiss: () => setState(() => _vpnWarningDismissed = true)),
                    if (_showSafetyBanner) HomeSafetyBanner(onDismiss: _dismissSafetyBanner),
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

  Widget _buildRequestsTabContent(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          Obx(() => HomeFilterBar(
            selectedFilter: _viewModel.selectedFilter,
            onFilterSelected: _viewModel.onFilterSelected,
          )),
          Obx(() => ((_viewModel.communityBriefing.isNotEmpty || (_viewModel.isBriefingLoading && !_viewModel.briefingTimedOut)) || _viewModel.topRecommendation != null)
              ? _buildAiInsightSection(l10n) : const SizedBox.shrink()),
          Obx(() => _viewModel.guilds.isEmpty ? const SizedBox.shrink() : _buildGuildsSection(l10n)),
          HomeRequestsList(viewModel: _viewModel),
        ],
      ),
    );
  }

  Widget _buildNewsTabContent(AppLocalizations l10n) {
    return Column(
      children: [
        Obx(() => _viewModel.polls.isEmpty ? const SizedBox.shrink() : HomePollsSection(viewModel: _viewModel)),
        NewsSection(searchQuery: _newsSearchQuery),
      ],
    );
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
        if (_viewModel.topRecommendation != null && _viewModel.topRecommendation!.aiRelevanceScore > 0.4)
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
}
