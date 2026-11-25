import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'dart:ui' show FlutterView;

/// Pure rules for adapting the app to windows of different sizes, such as the
/// small outer and large inner screens of the iPhone Duo.
class AdaptiveLayout {
  const AdaptiveLayout._();

  /// Windows whose shortest side (in logical pixels) is below this stay
  /// portrait only, like a normal phone.
  static const double largeWindowShortestSide = 600;

  /// Widest the app content is allowed to grow before it is centred with
  /// gutters on both sides.
  static const double maxContentWidth = 640;

  static List<DeviceOrientation> orientationsForShortestSide(
    double shortestSide,
  ) {
    if (shortestSide < largeWindowShortestSide) {
      return const [DeviceOrientation.portraitUp];
    }
    return DeviceOrientation.values;
  }

  /// Shortest side, in logical pixels, of the physical screen [view] is shown
  /// on. Unlike the window, it does not shrink when iOS letterboxes the app.
  static double displayShortestSide(FlutterView view) {
    final display = view.display;
    return math.min(display.size.width, display.size.height) /
        display.devicePixelRatio;
  }

  static double contentWidthFor(double windowWidth) =>
      math.min(windowWidth, maxContentWidth);

  /// What is left of a side [inset] once a [gutter] of the same side already
  /// sits between the window edge and the content.
  static double insetAfterGutter({
    required double inset,
    required double gutter,
  }) => math.max(0, inset - gutter);
}
