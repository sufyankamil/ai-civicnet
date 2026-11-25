import 'package:civic_net/widgets/adaptive_content_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sizes the test window and display (1 logical px = 1 physical px) and builds
/// the frame under a [MediaQuery] taken from that window.
Widget _host(
  WidgetTester tester,
  Size size, {
  Size? display,
  double rightInset = 0,
  bool canGoBack = false,
  bool isClose = false,
  VoidCallback? onBack,
  Widget child = const SizedBox.expand(key: Key('probe')),
}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.view.display.size = display ?? size;
  tester.view.display.devicePixelRatio = 1;
  tester.view.padding = FakeViewPadding(right: rightInset);
  tester.view.viewPadding = FakeViewPadding(right: rightInset);
  addTearDown(tester.view.reset);
  return Builder(
    builder: (context) => MediaQuery.fromView(
      view: View.of(context),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: AdaptiveContentFrame(
            canGoBack: canGoBack,
            isClose: isClose,
            onBack: onBack,
            child: child,
          ),
        ),
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
  group('side strip back button', () {
    const duo = Size(466, 678);

    testWidgets('shows in the strip when there is a side inset and a back', (
      tester,
    ) async {
      var backs = 0;
      await tester.pumpWidget(
        _host(
          tester,
          duo,
          rightInset: 84,
          canGoBack: true,
          onBack: () => backs++,
        ),
      );

      final button = find.byKey(const Key('side_strip_back'));
      expect(button, findsOneWidget);
      // Centred in the 84 px strip at the right edge.
      expect(tester.getCenter(button).dx, closeTo(466 - 42, 1));

      await tester.tap(button);
      expect(backs, 1);
    });

    testWidgets('frosts the whole strip behind the button', (tester) async {
      await tester.pumpWidget(
        _host(tester, duo, rightInset: 84, canGoBack: true, onBack: () {}),
      );

      final blur = find.byKey(const Key('side_strip_blur'));
      expect(blur, findsOneWidget);
      final rect = tester.getRect(blur);
      expect(rect.width, 84);
      expect(rect.right, 466);
      expect(rect.top, 0);
      expect(rect.height, 678);
    });

    testWidgets('screen content stops before the strip while it is shown', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(tester, duo, rightInset: 84, canGoBack: true, onBack: () {}),
      );
      expect(tester.getSize(find.byKey(const Key('probe'))).width, 466 - 84);
    });

    testWidgets('every screen stops before the strip, back or not', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(tester, duo, rightInset: 84, canGoBack: false, onBack: () {}),
      );
      expect(tester.getSize(find.byKey(const Key('probe'))).width, 466 - 84);
      expect(find.byKey(const Key('side_strip_blur')), findsOneWidget);
      expect(find.byKey(const Key('side_strip_back')), findsNothing);
    });

    testWidgets('a normal phone gets no strip, padding or frost', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(tester, const Size(390, 844), canGoBack: true, onBack: () {}),
      );
      expect(tester.getSize(find.byKey(const Key('probe'))).width, 390);
      expect(find.byKey(const Key('side_strip_blur')), findsNothing);
    });

    testWidgets('SideStripAction moves a screen action into the strip', (
      tester,
    ) async {
      var taps = 0;
      final action = TextButton(
        key: const Key('act'),
        onPressed: () => taps++,
        child: const Text('+'),
      );
      await tester.pumpWidget(
        _host(
          tester,
          duo,
          rightInset: 84,
          canGoBack: true,
          onBack: () {},
          child: SideStripAction(child: action),
        ),
      );
      await tester.pump(); // registers with the frame after the first frame

      final act = find.byKey(const Key('act'));
      expect(act, findsOneWidget, reason: 'only the strip copy is shown');
      expect(tester.getCenter(act).dx, closeTo(466 - 42, 2));
      // Stacked below the back button.
      expect(
        tester.getCenter(act).dy,
        greaterThan(
          tester.getCenter(find.byKey(const Key('side_strip_back'))).dy,
        ),
      );
      await tester.tap(act);
      expect(taps, 1);
    });

    testWidgets('SideStripAction stays in place without a strip', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          tester,
          const Size(390, 844),
          child: const Align(
            alignment: Alignment.topLeft,
            child: SideStripAction(child: Text('+', key: Key('act'))),
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(const Key('act')), findsOneWidget);
      expect(tester.getTopLeft(find.byKey(const Key('act'))).dx, lessThan(100));
    });

    testWidgets('uses a close icon for close-style routes', (tester) async {
      await tester.pumpWidget(
        _host(
          tester,
          duo,
          rightInset: 84,
          canGoBack: true,
          isClose: true,
          onBack: () {},
        ),
      );
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('hidden without a side inset (normal phone)', (tester) async {
      await tester.pumpWidget(
        _host(tester, const Size(390, 844), canGoBack: true, onBack: () {}),
      );
      expect(find.byKey(const Key('side_strip_back')), findsNothing);
    });

    testWidgets('hidden when there is nothing to go back to', (tester) async {
      await tester.pumpWidget(
        _host(tester, duo, rightInset: 84, canGoBack: false, onBack: () {}),
      );
      expect(find.byKey(const Key('side_strip_back')), findsNothing);
    });

    testWidgets(
      'HideOnSideStrip still hides after a SafeArea consumed the inset',
      (tester) async {
        // AppBar wraps its leading widget in a SafeArea, so MediaQuery there
        // reports no side inset; the window's own padding must be used.
        const own = Text('own back', key: Key('own_back'));
        await tester.pumpWidget(
          _host(
            tester,
            duo,
            rightInset: 84,
            canGoBack: true,
            onBack: () {},
            child: const SafeArea(child: HideOnSideStrip(child: own)),
          ),
        );
        expect(find.byKey(const Key('own_back')), findsNothing);
      },
    );

    testWidgets('own button stays when there is no strip back to replace it', (
      tester,
    ) async {
      const own = Text('own back', key: Key('own_back'));
      await tester.pumpWidget(
        _host(
          tester,
          duo,
          rightInset: 84,
          canGoBack: false,
          child: const HideOnSideStrip(child: own),
        ),
      );
      expect(find.byKey(const Key('own_back')), findsOneWidget);
    });

    testWidgets('HideOnSideStrip hides a screen\'s own button in the strip', (
      tester,
    ) async {
      const own = Text('own back', key: Key('own_back'));
      await tester.pumpWidget(
        _host(
          tester,
          duo,
          rightInset: 84,
          canGoBack: true,
          onBack: () {},
          child: const HideOnSideStrip(child: own),
        ),
      );
      expect(find.byKey(const Key('own_back')), findsNothing);

      await tester.pumpWidget(
        _host(
          tester,
          const Size(390, 844),
          child: const HideOnSideStrip(child: own),
        ),
      );
      expect(find.byKey(const Key('own_back')), findsOneWidget);
    });
  });
}
