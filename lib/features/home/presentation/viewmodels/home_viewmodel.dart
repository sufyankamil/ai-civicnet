import 'dart:async';
import 'package:get/get.dart';
import '../../../request/domain/entities/help_request_entity.dart';
import '../../../request/domain/usecases/request_usecases.dart';
import '../../../request/domain/entities/request_enums.dart' as domain;
import '../../../../core/usecases/usecase.dart';
import '../../../../services/supabase_service.dart';
import '../../../../models/models.dart';
import '../../../../services/logger_service.dart';
import '../../../../services/ai_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeViewModel extends GetxController {
  final GetHelpRequestsUseCase getHelpRequestsUseCase;

  HomeViewModel({required this.getHelpRequestsUseCase});

  final RxList<HelpRequestEntity> _allRequests = <HelpRequestEntity>[].obs;
  final RxList<HelpRequestEntity> _filteredRequests = <HelpRequestEntity>[].obs;
  final RxList<Poll> _polls = <Poll>[].obs;
  final RxList<Guild> _guilds = <Guild>[].obs;
  final RxBool _isLoading = false.obs;
  final RxBool _hasFetchedOnce = false.obs;
  final RxBool _fetchError = false.obs;
  final RxBool _isTakingTooLong = false.obs;
  final Rxn<HelpRequestEntity> _topRecommendation = Rxn<HelpRequestEntity>();
  final RxString _searchQuery = ''.obs;
  final RxString _selectedFilter = 'All'.obs;
  final RxString _communityBriefing = ''.obs;
  final RxBool _isBriefingLoading = false.obs;
  final RxBool _briefingTimedOut = false.obs;
  
  Timer? _debounce;
  Timer? _longLoadTimer;
  Timer? _briefingTimer;
  bool _isDisposed = false;

  List<HelpRequestEntity> get filteredRequests => _filteredRequests;
  HelpRequestEntity? get topRecommendation => _topRecommendation.value;
  List<Poll> get polls => _polls;
  List<Guild> get guilds => _guilds;
  bool get isLoading => _isLoading.value;
  bool get hasFetchedOnce => _hasFetchedOnce.value;
  bool get fetchError => _fetchError.value;
  bool get isTakingTooLong => _isTakingTooLong.value;
  String get selectedFilter => _selectedFilter.value;
  String get searchQuery => _searchQuery.value;
  String get communityBriefing => _communityBriefing.value;
  bool get isBriefingLoading => _isBriefingLoading.value;
  bool get briefingTimedOut => _briefingTimedOut.value;

  @override
  void onInit() {
    super.onInit();
    // Subscribe to requests changes
    getHelpRequestsUseCase.repository.subscribeToHelpRequests(_onRequestsUpdated);
    refreshHome();
    fetchPolls();
    fetchGuilds();
    
    // Defer the checking logic as before
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!_isDisposed) {
        _checkWarnings();
      }
    });
  }

  Future<void> fetchTopRecommendation() async {
    try {
      final recommendations = await SupabaseService().getRecommendedHelpRequests();
      if (recommendations.isNotEmpty) {
        // Recommendations are sorted by similarity in the RPC
        final first = recommendations.first;
        logger.d('AI MATCH DEBUG: Found "${first.title}" with Relevance Score: ${first.aiRelevanceScore}');
        
        _topRecommendation.value = HelpRequestEntity(
          id: first.id,
          title: first.title,
          description: first.description,
          category: first.category,
          urgency: domain.UrgencyLevel.values.firstWhere(
            (e) => e.name == first.urgency.name,
            orElse: () => domain.UrgencyLevel.medium,
          ), 
          postedAt: first.postedAt,
          distance: first.distance,
          aiRelevanceScore: first.aiRelevanceScore,
          locationName: first.locationName,
          lat: first.lat,
          lng: first.lng,
          requesterId: first.requesterId,
          requesterName: first.requesterName,
          requesterAvatarUrl: first.requesterAvatarUrl,
          status: domain.RequestStatusEnum.values.firstWhere(
            (e) => e.name == first.status.name,
            orElse: () => domain.RequestStatusEnum.open,
          ),
        );
      } else {
        _topRecommendation.value = null;
      }
    } catch (e) {
      logger.e('Error fetching top recommendation: $e');
      _topRecommendation.value = null;
    }
  }

  @override
  void onClose() {
    _debounce?.cancel();
    _longLoadTimer?.cancel();
    _briefingTimer?.cancel();
    _isDisposed = true;
    getHelpRequestsUseCase.repository.unsubscribeFromHelpRequests();
    super.onClose();
  }

  void _onRequestsUpdated() {
    if (!_isDisposed) {
      refreshHome();
    }
  }

  Future<void> refreshHome() async {
    await Future.wait([
      fetchRequests(),
      fetchTopRecommendation(),
      fetchCommunityBriefing(),
    ]);
  }

  Future<void> fetchCommunityBriefing({bool force = false}) async {
    // Only apply timing/frequency logic if not a manual force-refresh
    if (!force) {
      final now = DateTime.now();
      
      // 1. Time Check: Only show after 11:00 AM
      if (now.hour < 11) {
        logger.d('AI Scribe: Suppressed briefing - too early (Hour: ${now.hour})');
        _communityBriefing.value = '';
        return;
      }

      // 2. Frequency Check: Only show once per day
      final prefs = await SharedPreferences.getInstance();
      final lastDate = prefs.getString('last_community_briefing_date');
      final todayDate = "${now.year}-${now.month}-${now.day}";

      if (lastDate == todayDate) {
        logger.d('AI Scribe: Suppressed briefing - already shown today ($todayDate)');
        _communityBriefing.value = '';
        return;
      }
    }

    _isBriefingLoading.value = true;
    _briefingTimedOut.value = false;
    
    // Set 10s timeout for briefing
    _briefingTimer?.cancel();
    _briefingTimer = Timer(const Duration(seconds: 10), () {
      if (_isBriefingLoading.value && !_isDisposed) {
        logger.w('AI Scribe: Briefing timed out after 10s');
        _briefingTimedOut.value = true;
        // We don't necessarily set isLoading to false, as it might still complete, 
        // but the UI will hide it based on this flag.
      }
    });

    try {
      final user = await SupabaseService().getCurrentUserProfile();
      if (user == null) return;

      // Get some context data
      final recentRequests = _allRequests.take(5).toList();
      final upcomingEvents = await SupabaseService().getEvents(); 
      
      final briefing = await AiService().generateCommunityBriefing(
        requests: recentRequests,
        events: upcomingEvents,
        user: user,
      );
      
      _communityBriefing.value = briefing;

      // If briefing was successfully shown (not empty and not the local fallback), mark as seen
      if (!force && briefing.isNotEmpty && !briefing.contains(' neighborhood is bustling')) {
        final prefs = await SharedPreferences.getInstance();
        final now = DateTime.now();
        final todayDate = "${now.year}-${now.month}-${now.day}";
        await prefs.setString('last_community_briefing_date', todayDate);
        logger.d('AI Scribe: Briefing marked as seen for $todayDate');
      }
    } catch (e) {
      logger.e('Error fetching community briefing: $e');
    } finally {
      if (!_isDisposed) {
        _isBriefingLoading.value = false;
        _briefingTimer?.cancel();
      }
    }
  }

  Future<void> fetchRequests() async {
    _isLoading.value = true;
    _fetchError.value = false;
    _isTakingTooLong.value = false;

    // Start timer for "taking too long" message
    _longLoadTimer?.cancel();
    _longLoadTimer = Timer(const Duration(seconds: 5), () {
      if (_isLoading.value && !_isDisposed) {
        _isTakingTooLong.value = true;
      }
    });

    final result = await getHelpRequestsUseCase(const NoParams());
    
    result.fold(
      (failure) {
        _fetchError.value = true;
        // Handle failure silently or with toast (silently to not spam on refresh)
      },
      (requests) {
        _allRequests.value = requests;
        _hasFetchedOnce.value = true;
        _applyFilters();
      },
    );
    _isLoading.value = false;
    _longLoadTimer?.cancel();
    _isTakingTooLong.value = false;
  }

  Future<void> fetchPolls() async {
    try {
      final activePolls = await SupabaseService().getActivePolls();
      _polls.assignAll(activePolls);
    } catch (e) {
      // silenced
    }
  }

  Future<void> voteInPoll(String pollId, String optionId) async {
    try {
      await SupabaseService().voteInPoll(pollId, optionId);
      await fetchPolls(); // Refresh polls to show updated counts and user vote
    } catch (e) {
      // Handle error (could use ToastService)
    }
  }

  Future<void> deletePoll(String pollId) async {
    try {
      await SupabaseService().deletePoll(pollId);
      await fetchPolls();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> fetchGuilds() async {
    try {
      final guilds = await SupabaseService().getGuilds();
      _guilds.assignAll(guilds);
    } catch (e) {
      // silenced
    }
  }

  Future<void> toggleGuildMembership(Guild guild) async {
    try {
      if (guild.isUserMember) {
        await SupabaseService().leaveGuild(guild.id);
      } else {
        await SupabaseService().joinGuild(guild.id);
      }
      await fetchGuilds();
    } catch (e) {
      // Handle error
    }
  }

  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 1000), () {
      _searchQuery.value = query.toLowerCase();
      _applyFilters();
    });
  }

  void onFilterSelected(String filter) {
    _selectedFilter.value = filter;
    _applyFilters();
  }

  void _applyFilters() {
    List<HelpRequestEntity> filtered = _allRequests;

    if (_searchQuery.value.isNotEmpty) {
      filtered = filtered.where((r) {
        return r.title.toLowerCase().contains(_searchQuery.value) || 
               r.description.toLowerCase().contains(_searchQuery.value) ||
               r.category.toString().toLowerCase().contains(_searchQuery.value);
      }).toList();
    }

    if (_selectedFilter.value == 'All') {
      _filteredRequests.value = filtered;
      return;
    } else if (_selectedFilter.value == 'Recommended') {
      _filteredRequests.value = filtered.where((r) => r.aiRelevanceScore > 0.8).toList();
      return;
    } else {
      _filteredRequests.value = filtered.where((r) {
        if (_selectedFilter.value == 'Tech Support') return r.category.toString().split('.').last == 'techSupport';
        if (_selectedFilter.value == 'Emergency') return r.category.toString().split('.').last == 'emergency';
        if (_selectedFilter.value == 'Household') return r.category.toString().split('.').last == 'household';
        return r.category.toString().split('.').last.toLowerCase() == _selectedFilter.value.toLowerCase().replaceAll(' ', '');
      }).toList();
    }
  }

  Future<void> _checkWarnings() async {
    try {
      final user = await SupabaseService().getCurrentUserProfile();
      if (user != null && user.reportCount > 2) {
        // Safe dialog call using GetX with context check
        if (Get.context != null) {
          Get.defaultDialog(
            title: 'Warning Issued',
            middleText: 'Your account has been reported by multiple users for violating community guidelines. Please ensure you respect other users and follow our safety guidelines. Continued reports will result in a temporary ban.',
            textConfirm: 'I Understand',
            onConfirm: () => Get.back(),
            barrierDismissible: false,
          );
        }
      }
    } catch (e) {
      logger.e('Error checking user warnings: $e');
    }
  }
}
