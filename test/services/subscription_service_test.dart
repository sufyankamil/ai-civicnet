import 'package:civic_net/services/subscription_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_billing_client.dart';

void main() {
  late FakeBillingClient client;
  late SubscriptionService service;
  final now = DateTime.utc(2026, 12, 1);

  setUp(() {
    client = FakeBillingClient();
    service = SubscriptionService.forTest(client, now: () => now);
  });

  group('when no SDK key is configured', () {
    test('initialize is a no-op and the user stays free', () async {
      await service.initialize(apiKey: '');
      await service.initialize(apiKey: null);

      expect(service.isConfigured, isFalse);
      expect(service.isPro, isFalse);
      expect(client.calls, isEmpty);
    });

    test('syncUser does nothing', () async {
      await service.initialize(apiKey: null);
      await service.syncUser('user-1');
      expect(client.calls, isEmpty);
    });

    test('plans is empty and purchase throws', () async {
      await service.initialize(apiKey: null);
      expect(await service.plans(), isEmpty);
      expect(
        () => service.purchase('monthly'),
        throwsA(isA<SubscriptionUnavailableException>()),
      );
    });
  });

  group('state', () {
    test('an active trial entitlement is Pro and trialing', () async {
      client.entitlement = active(trial: true);
      await service.initialize(apiKey: 'key');

      expect(client.calls, ['configure:key']);
      expect(service.isConfigured, isTrue);
      expect(service.isPro, isTrue);
      expect(service.state.isTrialing, isTrue);
      expect(service.state.expiresAt, DateTime.utc(2027, 1, 1));
    });

    test('no entitlement means free', () async {
      client.entitlement = null;
      await service.initialize(apiKey: 'key');
      expect(service.isPro, isFalse);
      expect(service.state, SubscriptionState.free);
    });

    test('an inactive entitlement means free', () async {
      client.entitlement = const EntitlementSnapshot(
        isActive: false,
        isTrial: false,
        expiresAt: null,
        willRenew: false,
      );
      await service.initialize(apiKey: 'key');
      expect(service.isPro, isFalse);
    });

    test('an entitlement that already expired is not Pro', () async {
      client.entitlement = active(
        expires: now.subtract(const Duration(days: 1)),
      );
      await service.initialize(apiKey: 'key');
      expect(service.isPro, isFalse);
    });

    test('an active entitlement without an expiry (lifetime) is Pro', () async {
      client.entitlement = const EntitlementSnapshot(
        isActive: true,
        isTrial: false,
        expiresAt: null,
        willRenew: false,
      );
      await service.initialize(apiKey: 'key');
      expect(service.isPro, isTrue);
    });

    test('entitlement updates change state and notify listeners', () async {
      await service.initialize(apiKey: 'key');
      var notified = 0;
      service.addListener(() => notified++);

      client.updates.add(active());
      await Future<void>.delayed(Duration.zero);

      expect(service.isPro, isTrue);
      expect(notified, 1);
    });
  });

  group('user sync', () {
    test(
      'syncUser logs in with the Supabase id and adopts the state',
      () async {
        client.entitlement = active();
        await service.initialize(apiKey: 'key');
        client.entitlement = active(trial: true);

        await service.syncUser('user-1');

        expect(client.calls, contains('logIn:user-1'));
        expect(service.state.isTrialing, isTrue);
      },
    );

    test('syncUser(null) logs out and resets to free', () async {
      client.entitlement = active();
      await service.initialize(apiKey: 'key');
      expect(service.isPro, isTrue);

      await service.syncUser(null);

      expect(client.calls, contains('logOut'));
      expect(service.isPro, isFalse);
    });

    test('syncing the same user twice logs in once', () async {
      await service.initialize(apiKey: 'key');
      await service.syncUser('user-1');
      await service.syncUser('user-1');
      expect(client.calls.where((c) => c == 'logIn:user-1'), hasLength(1));
    });
  });

  group('purchase and restore', () {
    test('a successful purchase makes the user Pro', () async {
      await service.initialize(apiKey: 'key');
      client.purchaseResult = active(trial: true);

      final ok = await service.purchase('monthly');

      expect(ok, isTrue);
      expect(service.isPro, isTrue);
      expect(client.calls, contains('purchase:monthly'));
    });

    test('a cancelled purchase returns false and changes nothing', () async {
      await service.initialize(apiKey: 'key');
      client.purchaseError = const PurchaseCancelledException();

      expect(await service.purchase('monthly'), isFalse);
      expect(service.isPro, isFalse);
    });

    test('other purchase errors are rethrown', () async {
      await service.initialize(apiKey: 'key');
      client.purchaseError = StateError('store down');

      expect(() => service.purchase('monthly'), throwsStateError);
    });

    test('restore adopts the restored entitlement', () async {
      await service.initialize(apiKey: 'key');
      client.entitlement = active();

      await service.restore();

      expect(service.isPro, isTrue);
    });

    test('plans come from the billing client', () async {
      await service.initialize(apiKey: 'key');
      client.planList = const [
        BillingPlan(
          id: 'monthly',
          title: 'Pro Monthly',
          priceString: '₹99.00',
          hasFreeTrial: true,
        ),
      ];

      final plans = await service.plans();

      expect(plans.single.id, 'monthly');
      expect(plans.single.hasFreeTrial, isTrue);
    });
  });
}
