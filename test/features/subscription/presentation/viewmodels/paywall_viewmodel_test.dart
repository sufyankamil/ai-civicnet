import 'package:civic_net/features/subscription/presentation/viewmodels/paywall_viewmodel.dart';
import 'package:civic_net/services/subscription_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_billing_client.dart';

const monthly = BillingPlan(
  id: r'$rc_monthly',
  title: 'CivicNet Pro Monthly',
  priceString: '₹99.00',
  hasFreeTrial: true,
  trialDays: 7,
  period: BillingPeriod.monthly,
);

const annual = BillingPlan(
  id: r'$rc_annual',
  title: 'CivicNet Pro Annual',
  priceString: '₹799.00',
  hasFreeTrial: true,
  trialDays: 7,
  period: BillingPeriod.annual,
);

void main() {
  late FakeBillingClient client;
  late SubscriptionService service;
  late PaywallViewModel vm;

  Future<void> start({String? apiKey = 'key'}) async {
    await service.initialize(apiKey: apiKey);
    vm = PaywallViewModel(service);
  }

  setUp(() {
    client = FakeBillingClient()..planList = const [monthly, annual];
    service = SubscriptionService.forTest(
      client,
      now: () => DateTime.utc(2026, 12, 1),
    );
  });

  group('load', () {
    test('is unavailable when billing is not configured', () async {
      await start(apiKey: null);
      await vm.load();

      expect(vm.unavailable, isTrue);
      expect(vm.plans, isEmpty);
      expect(vm.loading, isFalse);
    });

    test('loads plans and preselects the annual plan', () async {
      await start();
      await vm.load();

      expect(vm.unavailable, isFalse);
      expect(vm.plans, hasLength(2));
      expect(vm.selectedPlan?.id, annual.id);
    });

    test('preselects the first plan when there is no annual plan', () async {
      client.planList = const [monthly];
      await start();
      await vm.load();

      expect(vm.selectedPlan?.id, monthly.id);
    });

    test('reports a load error when the store call fails', () async {
      client.plansError = StateError('offline');
      await start();
      await vm.load();

      expect(vm.error, PaywallError.loadFailed);
      expect(vm.plans, isEmpty);
      expect(vm.loading, isFalse);
    });

    test('reports an empty store as a load error', () async {
      client.planList = const [];
      await start();
      await vm.load();

      expect(vm.error, PaywallError.loadFailed);
    });
  });

  group('selection', () {
    test('select changes the selected plan', () async {
      await start();
      await vm.load();
      vm.select(monthly.id);

      expect(vm.selectedPlan?.id, monthly.id);
    });

    test('select ignores unknown plans', () async {
      await start();
      await vm.load();
      vm.select('nope');

      expect(vm.selectedPlan?.id, annual.id);
    });
  });

  group('purchase', () {
    test('a successful purchase marks the user as Pro', () async {
      await start();
      await vm.load();
      client.purchaseResult = active(trial: true);

      await vm.purchase();

      expect(client.calls, contains('purchase:${annual.id}'));
      expect(vm.purchased, isTrue);
      expect(vm.error, isNull);
      expect(vm.busy, isFalse);
    });

    test('a cancelled purchase is not an error', () async {
      await start();
      await vm.load();
      client.purchaseError = const PurchaseCancelledException();

      await vm.purchase();

      expect(vm.purchased, isFalse);
      expect(vm.error, isNull);
      expect(vm.busy, isFalse);
    });

    test('a failed purchase reports an error and stays retryable', () async {
      await start();
      await vm.load();
      client.purchaseError = StateError('store down');

      await vm.purchase();

      expect(vm.error, PaywallError.purchaseFailed);
      expect(vm.purchased, isFalse);
      expect(vm.busy, isFalse);
    });

    test('purchase does nothing without a selected plan', () async {
      client.planList = const [];
      await start();
      await vm.load();

      await vm.purchase();

      expect(client.calls.where((c) => c.startsWith('purchase')), isEmpty);
    });

    test('purchase is ignored while another action is running', () async {
      await start();
      await vm.load();
      client.purchaseResult = active();

      final first = vm.purchase();
      final second = vm.purchase();
      await Future.wait([first, second]);

      expect(client.calls.where((c) => c.startsWith('purchase')), hasLength(1));
    });
  });

  group('restore', () {
    test('restores an active entitlement', () async {
      await start();
      await vm.load();
      client.entitlement = active();

      await vm.restore();

      expect(vm.restored, isTrue);
      expect(vm.error, isNull);
    });

    test(
      'reports nothing to restore when the user has no entitlement',
      () async {
        await start();
        await vm.load();
        client.entitlement = null;

        await vm.restore();

        expect(vm.restored, isFalse);
        expect(vm.error, PaywallError.nothingToRestore);
      },
    );

    test('reports a restore failure', () async {
      await start();
      await vm.load();
      client.restoreError = StateError('offline');

      await vm.restore();

      expect(vm.error, PaywallError.restoreFailed);
    });
  });

  group('copy helpers', () {
    test('trial plans advertise a free trial', () {
      expect(monthly.hasFreeTrial, isTrue);
      expect(PaywallViewModel.isBestValue(annual), isTrue);
      expect(PaywallViewModel.isBestValue(monthly), isFalse);
    });
  });
}
