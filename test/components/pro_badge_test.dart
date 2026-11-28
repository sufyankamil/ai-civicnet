import 'package:civic_net/components/pro_badge.dart';
import 'package:civic_net/l10n/app_localizations.dart';
import 'package:civic_net/services/subscription_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_billing_client.dart';

void main() {
  late FakeBillingClient client;
  late SubscriptionService service;

  setUp(() {
    client = FakeBillingClient();
    service = SubscriptionService.forTest(
      client,
      now: () => DateTime.utc(2026, 12, 1),
    );
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(child: ProBadge(subscriptions: service)),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('is hidden for a free user', (tester) async {
    await service.initialize(apiKey: 'key');
    await service.syncUser('user-1');
    await pump(tester);

    expect(find.text('PRO'), findsNothing);
    expect(find.byType(ProBadge), findsOneWidget);
  });

  testWidgets('shows PRO for a subscriber', (tester) async {
    client.entitlement = active();
    await service.initialize(apiKey: 'key');
    await service.syncUser('user-1');
    await pump(tester);

    expect(find.text('PRO'), findsOneWidget);
  });

  testWidgets('shows PRO during a free trial', (tester) async {
    client.entitlement = active(trial: true);
    await service.initialize(apiKey: 'key');
    await service.syncUser('user-1');
    await pump(tester);

    expect(find.text('PRO'), findsOneWidget);
  });

  testWidgets('has an accessible label', (tester) async {
    client.entitlement = active();
    await service.initialize(apiKey: 'key');
    await service.syncUser('user-1');
    await pump(tester);

    expect(find.bySemanticsLabel('CivicNet Pro member'), findsOneWidget);
  });

  testWidgets('appears and disappears as the subscription changes', (
    tester,
  ) async {
    await service.initialize(apiKey: 'key');
    await service.syncUser('user-1');
    await pump(tester);
    expect(find.text('PRO'), findsNothing);

    client.updates.add(active());
    await tester.pump();
    await tester.pump();
    expect(find.text('PRO'), findsOneWidget);

    client.updates.add(null);
    await tester.pump();
    await tester.pump();
    expect(find.text('PRO'), findsNothing);
  });
}
