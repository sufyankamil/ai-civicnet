import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'dart:ui' show FlutterView;

/// Pure rules for adapting the app to screens of different sizes, such as the
/// small outer and large inner screens of the iPhone Duo.
class AdaptiveLayout {
  const AdaptiveLayout._();

  /// Screens whose shortest side (in logical pixels) is below this stay
  /// portrait only, like a normal phone.
  static const double largeWindowShortestSide = 600;

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
}
