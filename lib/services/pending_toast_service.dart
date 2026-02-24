/// Stores a success/error message to be shown on the NEXT screen build.
/// Used when the current screen navigates away before the toast can appear
/// (e.g. account deletion triggers an auth redirect).
class PendingToastService {
  static final PendingToastService _instance = PendingToastService._internal();
  factory PendingToastService() => _instance;
  PendingToastService._internal();

  String? _successMessage;
  String? get successMessage => _successMessage;

  void setSuccess(String message) => _successMessage = message;

  /// Returns the pending success message and clears it.
  String? consumeSuccess() {
    final msg = _successMessage;
    _successMessage = null;
    return msg;
  }
}
