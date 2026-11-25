import 'package:civic_net/features/ai_assistant/presentation/widgets/aura_ai_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('auraSheetHeight', () {
    test('uses 75% of the screen when the keyboard is closed', () {
      final height = auraSheetHeight(
        screenHeight: 900,
        keyboardInset: 0,
        topSafeInset: 59,
      );
      expect(height, 675);
    });

    test('shrinks so the header stays below the top safe area when the '
        'keyboard is open', () {
      const screen = 900.0;
      const keyboard = 350.0;
      const topSafe = 59.0;

      final height = auraSheetHeight(
        screenHeight: screen,
        keyboardInset: keyboard,
        topSafeInset: topSafe,
      );

      expect(height, lessThan(screen * 0.75));
      // Sheet top edge (screen - keyboard - height) must clear the notch.
      expect(screen - keyboard - height, greaterThanOrEqualTo(topSafe));
    });

    test('never returns a negative height for an oversized keyboard', () {
      final height = auraSheetHeight(
        screenHeight: 600,
        keyboardInset: 700,
        topSafeInset: 59,
      );
      expect(height, 0);
    });
  });
}
