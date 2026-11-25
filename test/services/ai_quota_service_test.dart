import 'package:civic_net/services/ai_quota_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiQuotaStatus', () {
    test('parses the RPC row', () {
      final status = AiQuotaStatus.fromJson({
        'used': 3,
        'quota_limit': 10,
        'resets_at': '2026-12-01T00:00:00+00:00',
        'is_pro': false,
        'enforced': true,
      });

      expect(status.used, 3);
      expect(status.limit, 10);
      expect(status.remaining, 7);
      expect(status.resetsAt, DateTime.utc(2026, 12, 1));
      expect(status.isUnlimited, isFalse);
    });

    test('remaining never goes below zero', () {
      final status = AiQuotaStatus.fromJson({
        'used': 12,
        'quota_limit': 10,
        'resets_at': null,
        'is_pro': false,
        'enforced': true,
      });
      expect(status.remaining, 0);
    });

    test('Pro users are unlimited', () {
      final status = AiQuotaStatus.fromJson({
        'used': 0,
        'quota_limit': 10,
        'resets_at': null,
        'is_pro': true,
        'enforced': true,
      });
      expect(status.isUnlimited, isTrue);
    });

    test('everyone is unlimited when enforcement is switched off', () {
      final status = AiQuotaStatus.fromJson({
        'used': 5,
        'quota_limit': 10,
        'resets_at': null,
        'is_pro': false,
        'enforced': false,
      });
      expect(status.isUnlimited, isTrue);
    });
  });

  group('AiQuotaService.refresh', () {
    const row = {
      'used': 4,
      'quota_limit': 10,
      'resets_at': null,
      'is_pro': false,
      'enforced': true,
    };

    test('stores the fetched status and notifies', () async {
      final service = AiQuotaService.forTest(() async => row);
      var notified = 0;
      service.addListener(() => notified++);

      await service.refresh();

      expect(service.status?.remaining, 6);
      expect(notified, 1);
    });

    test('keeps the previous status when the fetch fails', () async {
      var fail = false;
      final service = AiQuotaService.forTest(() async {
        if (fail) throw StateError('offline');
        return row;
      });
      await service.refresh();

      fail = true;
      await service.refresh();

      expect(service.status?.used, 4);
    });

    test('clears the status when there is no signed-in user', () async {
      var signedIn = true;
      final service = AiQuotaService.forTest(() async => signedIn ? row : null);
      await service.refresh();
      expect(service.status, isNotNull);

      signedIn = false;
      await service.refresh();

      expect(service.status, isNull);
    });

    test('does not notify when nothing changed', () async {
      final service = AiQuotaService.forTest(() async => row);
      await service.refresh();
      var notified = 0;
      service.addListener(() => notified++);

      await service.refresh();

      expect(notified, 0);
    });
  });
}
