import 'package:civic_net/core/utils/adaptive_layout.dart';
import 'package:flutter/material.dart';
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
  group('hasSideStrip', () {
    test('a large right inset (Duo status strip) counts', () {
      expect(
        AdaptiveLayout.hasSideStrip(const EdgeInsets.only(right: 84)),
        true,
      );
    });

    test('normal phone insets do not', () {
      expect(
        AdaptiveLayout.hasSideStrip(const EdgeInsets.only(top: 47, bottom: 34)),
        false,
      );
      expect(
        AdaptiveLayout.hasSideStrip(const EdgeInsets.only(right: 20)),
        false,
      );
    });
  });
}
