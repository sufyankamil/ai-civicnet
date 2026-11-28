import 'package:civic_net/features/profile/presentation/screens/privacy_policy_screen.dart';
import 'package:civic_net/features/profile/presentation/screens/terms_of_service_screen.dart';
import 'package:civic_net/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(1080, 6000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: screen,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('TermsOfServiceScreen', () {
    testWidgets('has a Subscriptions section with renewal and cancel terms', (
      tester,
    ) async {
      await pumpScreen(tester, const TermsOfServiceScreen());

      expect(find.textContaining('Subscriptions'), findsWidgets);
      expect(find.textContaining('CivicNet Pro'), findsWidgets);
      expect(find.textContaining('renews automatically'), findsOneWidget);
      expect(find.textContaining('at least 24 hours'), findsOneWidget);
      expect(find.textContaining('free trial'), findsWidgets);
    });

    testWidgets('explains Emergency SOS is not an emergency service', (
      tester,
    ) async {
      await pumpScreen(tester, const TermsOfServiceScreen());

      expect(find.textContaining('Emergency SOS'), findsWidgets);
      expect(find.textContaining('not an emergency service'), findsOneWidget);
      expect(
        find.textContaining('call your local emergency number'),
        findsOneWidget,
      );
    });

    testWidgets('has a fresh last-updated date', (tester) async {
      await pumpScreen(tester, const TermsOfServiceScreen());
      expect(find.text('Last updated: November 28, 2026'), findsOneWidget);
    });
  });

  group('PrivacyPolicyScreen', () {
    testWidgets('lists RevenueCat and Google Gemini as processors', (
      tester,
    ) async {
      await pumpScreen(tester, const PrivacyPolicyScreen());

      expect(find.textContaining('RevenueCat'), findsWidgets);
      expect(find.textContaining('Gemini'), findsWidgets);
    });

    testWidgets('discloses purchase data and AI usage', (tester) async {
      await pumpScreen(tester, const PrivacyPolicyScreen());

      expect(find.textContaining('subscription status'), findsWidgets);
      expect(
        find.textContaining('do not store or see your card'),
        findsOneWidget,
      );
    });

    testWidgets('says what Emergency SOS collects and who sees it', (
      tester,
    ) async {
      await pumpScreen(tester, const PrivacyPolicyScreen());

      expect(find.textContaining('Emergency SOS and Location'), findsOneWidget);
      expect(find.textContaining('about 550 m'), findsOneWidget);
      expect(find.textContaining('exact location'), findsOneWidget);
      expect(find.textContaining('when you sign out'), findsOneWidget);
      expect(
        find.textContaining('country of your last known location'),
        findsOneWidget,
      );
    });

    testWidgets('links to the full policy on civicnet.app', (tester) async {
      await pumpScreen(tester, const PrivacyPolicyScreen());

      expect(find.text('civicnet.app/privacy'), findsOneWidget);
      expect(find.textContaining('vercel.app'), findsNothing);
    });

    testWidgets('has a fresh last-updated date', (tester) async {
      await pumpScreen(tester, const PrivacyPolicyScreen());
      expect(find.text('Last updated: November 28, 2026'), findsOneWidget);
    });
  });
}
