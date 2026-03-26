import 'package:get/get.dart';
import '../../domain/entities/help_request_entity.dart';
import '../../domain/entities/request_enums.dart';
import '../../domain/usecases/request_usecases.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../models/models.dart' as legacy;
import '../../../../services/supabase_service.dart';

class RequestViewModel extends GetxController {
  final CreateHelpRequestUseCase createHelpRequestUseCase;
  final GetHelpRequestUseCase getHelpRequestUseCase;
  final GetMyHelpRequestsUseCase getMyHelpRequestsUseCase;
  final UpdateRequestStatusUseCase updateRequestStatusUseCase;

  RequestViewModel({
    required this.createHelpRequestUseCase,
    required this.getHelpRequestUseCase,
    required this.getMyHelpRequestsUseCase,
    required this.updateRequestStatusUseCase,
  });

  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  final RxList<HelpRequestEntity> _myRequests = <HelpRequestEntity>[].obs;
  List<HelpRequestEntity> get myRequests => _myRequests;

  final Rx<HelpRequestEntity?> _currentRequest = Rx<HelpRequestEntity?>(null);
  HelpRequestEntity? get currentRequest => _currentRequest.value;

  final RxList<legacy.Helper> _potentialHelpers = <legacy.Helper>[].obs;
  List<legacy.Helper> get potentialHelpers => _potentialHelpers;

  final RxBool _isLoadingHelpers = false.obs;
  bool get isLoadingHelpers => _isLoadingHelpers.value;

  Future<String?> createRequest(HelpRequestEntity request) async {
    _isLoading.value = true;
    final result = await createHelpRequestUseCase(request);
    _isLoading.value = false;

    return result.fold(
      (failure) => failure.message,
      (_) => null,
    );
  }

  Future<String?> fetchMyRequests() async {
    _isLoading.value = true;
    final result = await getMyHelpRequestsUseCase(const NoParams());
    _isLoading.value = false;

    return result.fold(
      (failure) => failure.message,
      (requests) {
        _myRequests.value = requests;
        return null;
      },
    );
  }

  Future<String?> fetchHelpRequest(String id) async {
    _isLoading.value = true;
    final result = await getHelpRequestUseCase(GetHelpRequestParams(id));
    _isLoading.value = false;

    return result.fold(
      (failure) => failure.message,
      (request) {
        _currentRequest.value = request;
        // Also fetch helpers when a request is fetched
        fetchPotentialHelpers(request);
        return null;
      },
    );
  }

  Future<void> fetchPotentialHelpers(HelpRequestEntity entity) async {
    _isLoadingHelpers.value = true;
    try {
      // Map entity to legacy model for SupabaseService
      final legacyRequest = legacy.HelpRequest(
        id: entity.id,
        requesterId: entity.requesterId,
        requesterName: entity.requesterName,
        requesterAvatarUrl: entity.requesterAvatarUrl,
        title: entity.title,
        description: entity.description,
        category: HelpCategory.values.firstWhere(
          (e) => e.toString().split('.').last == entity.category.toString().split('.').last,
          orElse: () => HelpCategory.other,
        ),
        urgency: legacy.UrgencyLevel.values.firstWhere(
          (e) => e.toString().split('.').last == entity.urgency.toString().split('.').last,
          orElse: () => legacy.UrgencyLevel.medium,
        ),
        postedAt: entity.postedAt,
        distance: entity.distance,
        aiRelevanceScore: entity.aiRelevanceScore,
        locationName: entity.locationName,
        lat: entity.lat,
        lng: entity.lng,
        status: legacy.RequestStatus.values.firstWhere(
          (e) => e.toString().split('.').last == entity.status.toString().split('.').last,
          orElse: () => legacy.RequestStatus.open,
        ),
        helperId: entity.helperId,
      );

      final helpers = await SupabaseService().getPotentialHelpers(legacyRequest);
      final currentUserId = SupabaseService().currentUserId;
      _potentialHelpers.value = helpers.where((h) => h.user.id != currentUserId).toList();
    } catch (e) {
      // Error handling is minimal here as it's a non-critical list
      _potentialHelpers.clear();
    } finally {
      _isLoadingHelpers.value = false;
    }
  }

  Future<String?> updateRequestStatus(String id, RequestStatusEnum status) async {
    _isLoading.value = true;
    final result = await updateRequestStatusUseCase(UpdateRequestStatusParams(id, status));
    _isLoading.value = false;

    return result.fold(
      (failure) => failure.message,
      (_) => null,
    );
  }
}
