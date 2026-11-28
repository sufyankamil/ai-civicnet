import 'package:civic_net/features/subscription/presentation/screens/paywall_screen.dart';
import 'package:civic_net/l10n/app_localizations.dart';
import 'package:civic_net/services/subscription_service.dart';
import 'package:flutter/material.dart';
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

  setUp(() {
    client = FakeBillingClient()..planList = const [monthly, annual];
    service = SubscriptionService.forTest(
      client,
      now: () => DateTime.utc(2026, 12, 1),
    );
  });

  Future<void> pumpScreen(WidgetTester tester, {String? apiKey = 'key'}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await service.initialize(apiKey: apiKey);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PaywallScreen(subscriptions: service),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows both plans with the trial price line and best value', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('CivicNet Pro Monthly'), findsOneWidget);
    expect(find.text('CivicNet Pro Annual'), findsOneWidget);
    expect(
      find.text('7-day free trial, then ₹799.00 per year'),
      findsOneWidget,
    );
    expect(
      find.text('7-day free trial, then ₹99.00 per month'),
      findsOneWidget,
    );
    expect(find.text('Best value'), findsOneWidget);
    expect(find.text('Start free trial'), findsOneWidget);
    expect(find.text('Restore purchases'), findsOneWidget);
  });

  testWidgets('buying the selected plan calls the store', (tester) async {
    await pumpScreen(tester);
    client.purchaseResult = active(trial: true);

    await tester.tap(find.text('CivicNet Pro Monthly'));
    await tester.pump();
    await tester.tap(find.text('Start free trial'));
    await tester.pump();
    // Let the success toast's auto-close timer finish.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(client.calls, contains(r'purchase:$rc_monthly'));
  });

  testWidgets(
    'shows the unavailable message and no buy button when billing is off',
    (tester) async {
      await pumpScreen(tester, apiKey: null);

      expect(
        find.text(
          "Subscriptions aren't available right now. Please try again later.",
        ),
        findsOneWidget,
      );
      expect(find.text('Start free trial'), findsNothing);
      expect(find.text('Subscribe'), findsNothing);
    },
  );

  testWidgets('offers a retry when plans fail to load', (tester) async {
    client.plansError = StateError('offline');
    await pumpScreen(tester);

    expect(
      find.text(
        "Couldn't load the plans. Check your connection and try again.",
      ),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsOneWidget);

    client.plansError = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('CivicNet Pro Annual'), findsOneWidget);
  });

  testWidgets('a Pro user sees their status and manage link, not the plans', (
    tester,
  ) async {
    client.entitlement = active(expires: DateTime.utc(2027, 1, 1));
    await pumpScreen(tester);

    expect(find.text("You're a CivicNet Pro member"), findsOneWidget);
    expect(find.text('Manage subscription'), findsOneWidget);
    expect(find.text('Start free trial'), findsNothing);
  });

  group('Pro status text', () {
    final ends = DateTime.utc(2027, 1, 1, 12);

    EntitlementSnapshot snapshot({
      required bool trial,
      required bool willRenew,
    }) => EntitlementSnapshot(
      isActive: true,
      isTrial: trial,
      expiresAt: ends,
      willRenew: willRenew,
    );

    testWidgets('trial that will convert says when and that you are charged', (
      tester,
    ) async {
      client.entitlement = snapshot(trial: true, willRenew: true);
      await pumpScreen(tester);

      expect(find.text('Free trial active'), findsOneWidget);
      expect(
        find.text(
          "Your trial ends on Jan 1, 2027. You'll be charged then unless you cancel.",
        ),
        findsOneWidget,
      );
    });

    testWidgets('cancelled trial says you will not be charged', (tester) async {
      client.entitlement = snapshot(trial: true, willRenew: false);
      await pumpScreen(tester);

      expect(find.text('Free trial active'), findsOneWidget);
      expect(
        find.text("Your trial ends on Jan 1, 2027. You won't be charged."),
        findsOneWidget,
      );
    });

    testWidgets('paid subscription shows the renewal date', (tester) async {
      client.entitlement = snapshot(trial: false, willRenew: true);
      await pumpScreen(tester);

      expect(find.text('Renews on Jan 1, 2027'), findsOneWidget);
      expect(find.text('Free trial active'), findsNothing);
    });

    testWidgets('cancelled paid subscription says Pro lasts until then', (
      tester,
    ) async {
      client.entitlement = snapshot(trial: false, willRenew: false);
      await pumpScreen(tester);

      expect(
        find.text('Ends on Jan 1, 2027. You keep Pro until then.'),
        findsOneWidget,
      );
    });

    testWidgets('tells the user where to cancel or change the plan', (
      tester,
    ) async {
      client.entitlement = snapshot(trial: false, willRenew: true);
      await pumpScreen(tester);

      expect(
        find.text('Cancel or change your plan in your App Store settings.'),
        findsOneWidget,
      );
    });
  });
}
