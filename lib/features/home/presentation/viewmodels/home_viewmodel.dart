import 'dart:async';
import 'package:get/get.dart';
import '../../../request/domain/entities/help_request_entity.dart';
import '../../../request/domain/usecases/request_usecases.dart';
import '../../../request/domain/entities/request_enums.dart' as domain;
import '../../../../core/usecases/usecase.dart';
import '../../../../services/supabase_service.dart';
import '../../../../models/models.dart';
import '../../../../services/logger_service.dart';

class HomeViewModel extends GetxController {
  final GetHelpRequestsUseCase getHelpRequestsUseCase;

  HomeViewModel({required this.getHelpRequestsUseCase});

  final RxList<HelpRequestEntity> _allRequests = <HelpRequestEntity>[].obs;
  final RxList<HelpRequestEntity> _filteredRequests = <HelpRequestEntity>[].obs;
  final RxList<Poll> _polls = <Poll>[].obs;
  final RxList<Guild> _guilds = <Guild>[].obs;
  final RxBool _isLoading = false.obs;
  final Rxn<HelpRequestEntity> _topRecommendation = Rxn<HelpRequestEntity>();
  final RxString _searchQuery = ''.obs;
  final RxString _selectedFilter = 'All'.obs;
  
  Timer? _debounce;
  bool _isDisposed = false;

  List<HelpRequestEntity> get filteredRequests => _filteredRequests;
  HelpRequestEntity? get topRecommendation => _topRecommendation.value;
  List<Poll> get polls => _polls;
  List<Guild> get guilds => _guilds;
  bool get isLoading => _isLoading.value;
  String get selectedFilter => _selectedFilter.value;
  String get searchQuery => _searchQuery.value;

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
    ]);
  }

  Future<void> fetchRequests() async {
    _isLoading.value = true;
    final result = await getHelpRequestsUseCase(const NoParams());
    
    result.fold(
      (failure) {
        // Handle failure silently or with toast (silently to not spam on refresh)
      },
      (requests) {
        _allRequests.value = requests;
        _applyFilters();
      },
    );
    _isLoading.value = false;
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
    final user = await SupabaseService().getCurrentUserProfile();
    if (user != null && user.reportCount > 2) {
      // Trigger dialog through GetX dialog
      Get.defaultDialog(
        title: 'Warning Issued',
        middleText: 'Your account has been reported by multiple users for violating community guidelines. Please ensure you respect other users and follow our safety guidelines. Continued reports will result in a temporary ban.',
        textConfirm: 'I Understand',
        onConfirm: () => Get.back(),
      );
    }
  }
}
