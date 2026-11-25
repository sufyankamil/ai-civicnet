import 'package:civic_net/core/utils/adaptive_layout.dart';
import 'package:civic_net/widgets/adaptive_content_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sizes the test window (1 logical px = 1 physical px) and builds the frame
/// under a [MediaQuery] taken from that window.
Widget _host(WidgetTester tester, Size size, {double rightInset = 0}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.view.padding = FakeViewPadding(right: rightInset);
  tester.view.viewPadding = FakeViewPadding(right: rightInset);
  addTearDown(tester.view.reset);
  return Builder(
    builder: (context) => MediaQuery.fromView(
      view: View.of(context),
      child: const Directionality(
        textDirection: TextDirection.ltr,
        child: AdaptiveContentFrame(
          background: Color(0xFF123456),
          child: _Probe(),
        ),
      ),
    ),
  );
}

class _Probe extends StatelessWidget {
  const _Probe();

  static MediaQueryData? seen;

  @override
  Widget build(BuildContext context) {
    seen = MediaQuery.of(context);
    return const SizedBox.expand(key: Key('probe'));
  }
}

void main() {
  testWidgets('narrow window: child gets the full window untouched', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(tester, const Size(390, 844), rightInset: 20),
    );

    expect(
      tester.getSize(find.byKey(const Key('probe'))),
      const Size(390, 844),
    );
    expect(_Probe.seen!.size, const Size(390, 844));
    expect(_Probe.seen!.padding.right, 20);
  });

  testWidgets('wide window: child is capped and centred', (tester) async {
    await tester.pumpWidget(_host(tester, const Size(951, 669)));

    final box = tester.getRect(find.byKey(const Key('probe')));
    expect(box.width, AdaptiveLayout.maxContentWidth);
    expect(box.center.dx, closeTo(951 / 2, 0.01));
    expect(_Probe.seen!.size.width, AdaptiveLayout.maxContentWidth);
    expect(_Probe.seen!.size.height, 669);
  });

  testWidgets('wide window: side insets inside the gutters are consumed', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(tester, const Size(951, 669), rightInset: 40),
    );

    expect(_Probe.seen!.padding.right, 0);
    expect(_Probe.seen!.viewPadding.right, 0);
  });

  testWidgets('wide window: gutters use the background colour', (tester) async {
    await tester.pumpWidget(_host(tester, const Size(951, 669)));

    final colored = tester
        .widgetList<ColoredBox>(find.byType(ColoredBox))
        .where((b) => b.color == const Color(0xFF123456));
    expect(colored, isNotEmpty);
  });

  testWidgets('orientation policy applies preferred orientations', (
    tester,
  ) async {
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

    await tester.pumpWidget(_host(tester, const Size(951, 669)));
    expect(calls.last.length, DeviceOrientation.values.length);

    await tester.pumpWidget(_host(tester, const Size(390, 844)));
    expect(calls.last, ['DeviceOrientation.portraitUp']);
  });
}
