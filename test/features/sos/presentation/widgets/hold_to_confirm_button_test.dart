import 'package:civic_net/features/sos/presentation/widgets/hold_to_confirm_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late int confirmed;

  Future<void> pump(WidgetTester tester) async {
    confirmed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: HoldToConfirmButton(
              label: 'Hold to alert',
              holdDuration: const Duration(seconds: 2),
              onConfirmed: () => confirmed++,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('does nothing on a quick tap', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Hold to alert'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(confirmed, 0);
  });

  testWidgets('confirms after the full hold', (tester) async {
    await pump(tester);
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Hold to alert')),
    );
    await tester.pump(); // the hold animation starts on the next frame
    await tester.pump(const Duration(milliseconds: 1900));
    expect(confirmed, 0);
    await tester.pump(const Duration(milliseconds: 200));
    expect(confirmed, 1);
    await gesture.up();
    await tester.pump();

    expect(confirmed, 1);
  });

  testWidgets('letting go early cancels', (tester) async {
    await pump(tester);
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Hold to alert')),
    );
    await tester.pump(); // the hold animation starts on the next frame
    await tester.pump(const Duration(milliseconds: 1000));
    await gesture.up();
    await tester.pump(const Duration(seconds: 3));

    expect(confirmed, 0);
  });

  testWidgets('can only confirm once per hold', (tester) async {
    await pump(tester);
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Hold to alert')),
    );
    await tester.pump(); // the hold animation starts on the next frame
    await tester.pump(const Duration(seconds: 5));
    await gesture.up();
    await tester.pump();

    expect(confirmed, 1);
  });

  testWidgets('screen readers get a long-press action', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);

    expect(
      tester.getSemantics(find.byType(HoldToConfirmButton)),
      matchesSemantics(
        label: 'Hold to alert',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasLongPressAction: true,
        hasTapAction: false,
      ),
    );
    handle.dispose();
  });
}
