import 'package:civic_net/components/upgrade_prompt.dart';
import 'package:civic_net/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Widget app(Widget home) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(body: home),
      ),
      GoRoute(
        path: '/subscription',
        builder: (_, _) => const Scaffold(body: Text('paywall page')),
      ),
    ],
  );
  return MaterialApp.router(
    routerConfig: router,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  );
}

void main() {
  testWidgets('AiUpgradeAction opens the paywall', (tester) async {
    await tester.pumpWidget(app(const Center(child: AiUpgradeAction())));
    await tester.pumpAndSettle();

    await tester.tap(find.text('See Pro plans'));
    await tester.pumpAndSettle();

    expect(find.text('paywall page'), findsOneWidget);
  });

  group('showUpgradeSheet', () {
    Widget opener() => Center(
      child: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showUpgradeSheet(context),
          child: const Text('open'),
        ),
      ),
    );

    testWidgets('explains the limit and offers both actions', (tester) async {
      await tester.pumpWidget(app(opener()));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          "You've used your free AI actions for this month. Upgrade to CivicNet Pro for unlimited AI.",
        ),
        findsOneWidget,
      );
      expect(find.text('See Pro plans'), findsOneWidget);
      expect(find.text('Not now'), findsOneWidget);
    });

    testWidgets('Not now just closes the sheet', (tester) async {
      await tester.pumpWidget(app(opener()));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();

      expect(find.text('See Pro plans'), findsNothing);
      expect(find.text('paywall page'), findsNothing);
    });

    testWidgets('See Pro plans closes the sheet and opens the paywall', (
      tester,
    ) async {
      await tester.pumpWidget(app(opener()));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('See Pro plans'));
      await tester.pumpAndSettle();

      expect(find.text('paywall page'), findsOneWidget);
    });
  });
}
