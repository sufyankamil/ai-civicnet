import 'package:civic_net/features/home/presentation/widgets/home_safety_banner.dart';
import 'package:civic_net/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: HomeSafetyBanner(onDismiss: () {})),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('says requests and events are free and that Pro is optional', (
    tester,
  ) async {
    await pump(tester);

    expect(
      find.text(
        'CivicNet is committed to community safety. Requests and events are always free, and we never ask for money for them. Pro is optional and only adds AI features.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('the Hindi text carries the same message', (tester) async {
    await pump(tester, locale: const Locale('hi'));

    expect(
      find.text(
        'CivicNet सामुदायिक सुरक्षा के लिए प्रतिबद्ध है। अनुरोध और कार्यक्रम हमेशा निःशुल्क हैं, और हम इनके लिए कभी पैसे नहीं मांगते। Pro वैकल्पिक है और केवल AI सुविधाएँ जोड़ता है।',
      ),
      findsOneWidget,
    );
  });
}
