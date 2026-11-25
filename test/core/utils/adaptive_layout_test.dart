import 'package:civic_net/core/utils/adaptive_layout.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('orientationsForShortestSide', () {
    test('phones stay portrait only', () {
      expect(AdaptiveLayout.orientationsForShortestSide(390), [
        DeviceOrientation.portraitUp,
      ]);
      expect(AdaptiveLayout.orientationsForShortestSide(599.9), [
        DeviceOrientation.portraitUp,
      ]);
    });

    test('large windows may use every orientation', () {
      final all = AdaptiveLayout.orientationsForShortestSide(669);
      expect(all, containsAll(DeviceOrientation.values));
      expect(
        AdaptiveLayout.orientationsForShortestSide(
          AdaptiveLayout.largeWindowShortestSide,
        ),
        containsAll(DeviceOrientation.values),
      );
    });
  });

  group('contentWidthFor', () {
    test('narrow windows use the full width', () {
      expect(AdaptiveLayout.contentWidthFor(390), 390);
      expect(
        AdaptiveLayout.contentWidthFor(AdaptiveLayout.maxContentWidth),
        AdaptiveLayout.maxContentWidth,
      );
    });

    test('wide windows are capped', () {
      expect(
        AdaptiveLayout.contentWidthFor(951),
        AdaptiveLayout.maxContentWidth,
      );
      expect(
        AdaptiveLayout.contentWidthFor(2000),
        AdaptiveLayout.maxContentWidth,
      );
    });
  });

  group('insetAfterGutter', () {
    test('an inset fully covered by the gutter disappears', () {
      expect(AdaptiveLayout.insetAfterGutter(inset: 40, gutter: 100), 0);
    });

    test('an inset larger than the gutter keeps only the remainder', () {
      expect(AdaptiveLayout.insetAfterGutter(inset: 140, gutter: 100), 40);
    });

    test('no gutter leaves the inset untouched', () {
      expect(AdaptiveLayout.insetAfterGutter(inset: 24, gutter: 0), 24);
    });
  });
}
