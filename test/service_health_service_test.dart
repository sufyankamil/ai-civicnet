import 'package:flutter_test/flutter_test.dart';
import 'package:civic_net/services/service_health_service.dart';

void main() {
  group('ServiceHealthService Tests', () {
    late ServiceHealthService service;

    setUp(() {
      service = ServiceHealthService();
      // Reset state for test
      service.recordSuccess(operation: 'setup');
      service.recordSuccess(operation: 'setup_2');
      service.restoreBanner();
    });

    test('Initial or recovered status should be operational', () {
      expect(service.status, equals(ServiceStatus.operational));
      expect(service.hasActiveIncident, isFalse);
      expect(service.shouldShowBanner, isFalse);
    });

    test('500 server error triggers degraded state and shows banner', () {
      service.recordFailure(
        operation: 'GET /help_requests',
        error: '500 Internal Server Error',
      );

      expect(service.status, equals(ServiceStatus.degraded));
      expect(service.hasActiveIncident, isTrue);
      expect(service.shouldShowBanner, isTrue);
      expect(service.activeIncident?.title, contains('We are investigating a technical issue'));
      expect(service.activeIncident?.lastFailedOperation, equals('GET /help_requests'));
    });

    test('User can dismiss banner and restore it', () {
      service.recordFailure(
        operation: 'POST /help_requests',
        error: '502 Bad Gateway',
      );
      expect(service.shouldShowBanner, isTrue);

      service.dismissBanner();
      expect(service.isBannerDismissed, isTrue);
      expect(service.shouldShowBanner, isFalse);

      service.restoreBanner();
      expect(service.isBannerDismissed, isFalse);
      expect(service.shouldShowBanner, isTrue);
    });

    test('Consecutive successes trigger auto-recovery', () {
      service.recordFailure(
        operation: 'UPDATE /help_requests',
        error: 'TimeoutException after 10s',
      );
      service.recordFailure(
        operation: 'UPDATE /help_requests',
        error: 'TimeoutException after 10s',
      );
      expect(service.status, equals(ServiceStatus.degraded));

      // Record 2 consecutive successes
      service.recordSuccess(operation: 'GET /help_requests');
      service.recordSuccess(operation: 'GET /announcements');

      expect(service.status, equals(ServiceStatus.operational));
      expect(service.hasActiveIncident, isFalse);
      expect(service.shouldShowBanner, isFalse);
    });
  });
}
