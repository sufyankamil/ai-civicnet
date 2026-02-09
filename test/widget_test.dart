import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:community_net/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CommunityHelpApp());

    // Verify that the splash screen shows up.
    expect(find.text('Community Help'), findsOneWidget);
    expect(find.text('Connect. Help. Grow.'), findsOneWidget);
  });
}
