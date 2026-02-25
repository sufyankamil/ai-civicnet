import 'dart:async';
import 'package:get/get.dart';
import '../../../request/domain/entities/help_request_entity.dart';
import '../../../request/domain/usecases/request_usecases.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../services/supabase_service.dart'; // Temporarily for warnings/location

class HomeViewModel extends GetxController {
  final GetHelpRequestsUseCase getHelpRequestsUseCase;

  HomeViewModel({required this.getHelpRequestsUseCase});

  final RxList<HelpRequestEntity> _allRequests = <HelpRequestEntity>[].obs;
  final RxList<HelpRequestEntity> _filteredRequests = <HelpRequestEntity>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _searchQuery = ''.obs;
  final RxString _selectedFilter = 'All'.obs;
  
  Timer? _debounce;
  bool _isDisposed = false;

  List<HelpRequestEntity> get filteredRequests => _filteredRequests;
  bool get isLoading => _isLoading.value;
  String get selectedFilter => _selectedFilter.value;
  String get searchQuery => _searchQuery.value;

  @override
  void onInit() {
    super.onInit();
    // Subscribe to requests changes
    getHelpRequestsUseCase.repository.subscribeToHelpRequests(_onRequestsUpdated);
    fetchRequests();
    
    // Defer the checking logic as before
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!_isDisposed) {
        _checkWarnings();
      }
    });
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
      fetchRequests();
    }
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
