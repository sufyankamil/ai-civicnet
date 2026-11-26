import 'dart:math' as math;

import 'dart:ui' show FlutterView;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show EdgeInsets, Size;

/// Pure rules for adapting the app to screens of different sizes, such as the
/// small outer and large inner screens of the iPhone Duo.
class AdaptiveLayout {
  const AdaptiveLayout._();

  /// Screens whose shortest side (in logical pixels) is below this stay
  /// portrait only, like a normal phone.
  static const double largeWindowShortestSide = 600;

  /// A right-hand inset at least this wide is a status strip (the iPhone Duo
  /// camera, time and wifi column), not a notch or rounded corner.
  static const double sideStripMinInset = 40;

  static bool hasSideStrip(EdgeInsets padding) =>
      padding.right >= sideStripMinInset;

  /// Whether to show the frosted strip, the shared back button and strip
  /// actions: only on a large window (the opened Duo), never on the small outer
  /// screen where the strip is just the system's camera column.
  static bool showsStripPanel(EdgeInsets padding, Size window) =>
      hasSideStrip(padding) && window.shortestSide >= largeWindowShortestSide;

  /// The window's own safe-area padding in logical pixels. Unlike
  /// `MediaQuery.padding` it is not reduced by a `SafeArea` or `AppBar` above
  /// the caller, which consume the inset for their children.
  static EdgeInsets windowPadding(FlutterView view) {
    final p = view.padding;
    final dpr = view.devicePixelRatio;
    return EdgeInsets.fromLTRB(
      p.left / dpr,
      p.top / dpr,
      p.right / dpr,
      p.bottom / dpr,
    );
  }

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
