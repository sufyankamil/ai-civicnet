import 'package:civic_net/features/home/models/seasonal_greeting.dart';
import 'package:civic_net/features/home/presentation/widgets/seasonal_greeting_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    SeasonalGreeting greeting, {
    VoidCallback? onDismiss,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SeasonalGreetingBanner(
            greeting: greeting,
            onDismiss: onDismiss ?? () {},
          ),
        ),
      ),
    );
  }

  testWidgets('shows the flag, title and message of the greeting', (
    tester,
  ) async {
    final uae = seasonalGreetingFor('AE', DateTime(2026, 12, 2))!;
    await pump(tester, uae);

    expect(find.text(uae.flag), findsOneWidget);
    expect(find.text(uae.title), findsOneWidget);
    expect(find.text(uae.message), findsOneWidget);
  });

  testWidgets('still shows the India greeting', (tester) async {
    final india = seasonalGreetingFor('IN', DateTime(2026, 8, 15))!;
    await pump(tester, india);

    expect(find.text('🇮🇳'), findsOneWidget);
    expect(find.text('Happy Independence Day!'), findsOneWidget);
    expect(find.text('स्वतंत्रता दिवस की शुभकामनाएँ'), findsOneWidget);
  });

  testWidgets('tapping close dismisses the banner', (tester) async {
    var dismissed = 0;
    await pump(
      tester,
      seasonalGreetingFor('QA', DateTime(2026, 12, 18))!,
      onDismiss: () => dismissed++,
    );

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();

    expect(dismissed, 1);
  });
}
