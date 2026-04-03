import 'package:in_app_review/in_app_review.dart';
import 'logger_service.dart';

class RatingService {
  static final InAppReview _inAppReview = InAppReview.instance;

  /// The App Store ID for CivicNet
  static const String _appStoreId = '6761416586';

  /// Requests a native in-app review dialog.
  /// Note: This is subject to strict quotas by Apple and Google.
  static Future<void> requestReview() async {
    try {
      final bool isAvailable = await _inAppReview.isAvailable();
      if (isAvailable) {
        await _inAppReview.requestReview();
        logger.i('Native app review requested successfully');
      } else {
        logger.w('Native app review not available on this platform/device');
        // Fallback to opening the store directly
        await openStore();
      }
    } catch (e) {
      logger.e('Error requesting native review: $e');
    }
  }

  /// Opens the App Store page for CivicNet directly.
  static Future<void> openStore() async {
    try {
      await _inAppReview.openStoreListing(appStoreId: _appStoreId);
      logger.i('App Store listing opened successfully');
    } catch (e) {
      logger.e('Error opening store listing: $e');
    }
  }
}
