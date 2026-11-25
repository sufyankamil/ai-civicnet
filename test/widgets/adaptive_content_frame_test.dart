import 'package:civic_net/widgets/adaptive_content_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sizes the test window and display (1 logical px = 1 physical px) and builds
/// the frame under a [MediaQuery] taken from that window.
Widget _host(WidgetTester tester, Size size, {Size? display}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.view.display.size = display ?? size;
  tester.view.display.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  return Builder(
    builder: (context) => MediaQuery.fromView(
      view: View.of(context),
      child: const Directionality(
        textDirection: TextDirection.ltr,
        child: AdaptiveContentFrame(child: SizedBox.expand(key: Key('probe'))),
      ),
    ),
  );
}

List<List<dynamic>> _recordOrientations(WidgetTester tester) {
  final calls = <List<dynamic>>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'SystemChrome.setPreferredOrientations') {
        calls.add(call.arguments as List<dynamic>);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return calls;
}

void main() {
  testWidgets('content fills the whole window, however wide', (tester) async {
    await tester.pumpWidget(_host(tester, const Size(951, 669)));

    expect(
      tester.getSize(find.byKey(const Key('probe'))),
      const Size(951, 669),
    );
  });

  testWidgets('orientation policy applies preferred orientations', (
    tester,
  ) async {
    final calls = _recordOrientations(tester);

    await tester.pumpWidget(_host(tester, const Size(951, 669)));
    expect(calls.last.length, DeviceOrientation.values.length);

    await tester.pumpWidget(_host(tester, const Size(390, 844)));
    expect(calls.last, ['DeviceOrientation.portraitUp']);
  });

  testWidgets('portrait window on a large display keeps rotation unlocked', (
    tester,
  ) async {
    final calls = _recordOrientations(tester);

    // iOS letterboxes a portrait-locked app into a 466x678 window on the Duo
    // inner screen (951x669). The display is large, so rotation must stay on.
    await tester.pumpWidget(
      _host(tester, const Size(466, 678), display: const Size(951, 669)),
    );
    expect(calls.last.length, DeviceOrientation.values.length);
  });
}
