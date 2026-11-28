import 'package:civic_net/features/home/presentation/widgets/sos_floating_button.dart';
import 'package:civic_net/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  Future<void> pump(WidgetTester tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: Center(child: SosFloatingButton())),
        ),
        GoRoute(
          path: '/sos',
          builder: (context, state) => const Scaffold(body: Text('SOS page')),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows a clear SOS button', (tester) async {
    await pump(tester);

    expect(find.text('SOS'), findsOneWidget);
    expect(find.bySemanticsLabel('Emergency SOS'), findsOneWidget);
  });

  testWidgets('is a round button the same size as the Aura orb', (
    tester,
  ) async {
    await pump(tester);

    final size = tester.getSize(find.byType(SosFloatingButton));
    expect(size.width, 56);
    expect(size.height, 56);
  });

  testWidgets('opens the SOS page when tapped', (tester) async {
    await pump(tester);
    await tester.tap(find.text('SOS'));
    await tester.pumpAndSettle();

    expect(find.text('SOS page'), findsOneWidget);
  });
}
