import 'package:get/get.dart';
import '../../domain/entities/help_request_entity.dart';
import '../../domain/entities/request_enums.dart';
import '../../domain/usecases/request_usecases.dart';
import '../../../../core/usecases/usecase.dart';

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
        return null;
      },
    );
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
