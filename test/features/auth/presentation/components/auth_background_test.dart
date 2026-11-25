import 'package:civic_net/features/auth/presentation/components/auth_background.dart';
import 'package:civic_net/widgets/adaptive_content_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('background gradient spans the whole window inside the frame', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(951, 669);
    tester.view.display.size = const Size(951, 669);
    tester.view.display.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      Builder(
        builder: (context) => MediaQuery.fromView(
          view: View.of(context),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Theme(
              data: ThemeData(),
              child: const AdaptiveContentFrame(
                background: Colors.black,
                child: AuthBackground(child: SizedBox()),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump(); // frame registers the full-window background

    // One gradient behind the gutters (frame) and one in the column: both are
    // laid out over the whole window so they line up exactly.
    final gradients = find.byKey(const Key('auth_background_base'));
    expect(gradients, findsNWidgets(2));
    for (var i = 0; i < 2; i++) {
      final rect = tester.getRect(gradients.at(i));
      expect(rect.left, 0);
      expect(rect.right, 951);
    }
  });
}
