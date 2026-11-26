import 'package:civic_net/features/onboarding/presentation/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('splash content stays centred when a side inset exists', (
    tester,
  ) async {
    // Like the iPhone Duo inner screen: a status strip eats the right edge.
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(951, 669);
    tester.view.padding = const FakeViewPadding(right: 84);
    tester.view.viewPadding = const FakeViewPadding(right: 84);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    final title = find.text('Civic Net');
    expect(title, findsOneWidget);
    expect(tester.getCenter(title).dx, closeTo(951 / 2, 1));
  });
}
