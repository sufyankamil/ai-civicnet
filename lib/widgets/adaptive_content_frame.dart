import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/utils/adaptive_layout.dart';

/// Tells descendants how wide the empty gutters beside the capped content are,
/// and lets a screen paint its own full-window background behind the content
/// (the route's overlay clips to the column, so a screen cannot paint into the
/// gutters itself). See `AuthBackground`.
class AdaptiveFrameScope extends InheritedWidget {
  const AdaptiveFrameScope({
    super.key,
    required this.gutter,
    required this.setBackground,
    required super.child,
  });

  /// Width of the gutter on each side; 0 when content fills the window.
  final double gutter;

  /// Sets (or, with null, clears) the widget painted behind the content over
  /// the whole window. Safe to call after a frame; ignored once disposed.
  final void Function(Widget? background) setBackground;

  static AdaptiveFrameScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AdaptiveFrameScope>();

  static double gutterOf(BuildContext context) => maybeOf(context)?.gutter ?? 0;

  @override
  bool updateShouldNotify(AdaptiveFrameScope old) => gutter != old.gutter;
}

/// Wraps the whole app so it adapts to the window it is given:
///
/// * picks the allowed orientations from the window size (phones stay portrait,
///   large windows such as the iPhone Duo inner screen may rotate), and
/// * caps the content width and centres it on wide windows, so layouts keep
///   phone proportions instead of stretching.
///
/// The child sees a [MediaQuery] that matches the capped area, with side
/// insets reduced by the gutters. Insets the child still receives (for example
/// the Duo camera strip on a narrow window) are left exactly as the system
/// reports them, so content is centred in the usable area.
class AdaptiveContentFrame extends StatefulWidget {
  const AdaptiveContentFrame({
    super.key,
    required this.child,
    required this.background,
  });

  final Widget child;

  /// Colour shown in the gutters beside capped content.
  final Color background;

  @override
  State<AdaptiveContentFrame> createState() => _AdaptiveContentFrameState();
}

class _AdaptiveContentFrameState extends State<AdaptiveContentFrame>
    with WidgetsBindingObserver {
  List<DeviceOrientation>? _applied;
  Widget? _screenBackground;

  void _setScreenBackground(Widget? background) {
    if (!mounted) return;
    setState(() => _screenBackground = background);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Fires for any platform metric change, including the display changing
  /// while the window keeps its size (e.g. unfolding a foldable).
  @override
  void didChangeMetrics() {
    if (!mounted) return;
    _applyOrientations(AdaptiveLayout.displayShortestSide(View.of(context)));
  }

  void _applyOrientations(double shortestSide) {
    // iOS decides natively (AppDelegate), from the scene's own screen: Flutter
    // keeps reporting the screen the app launched on after a foldable opens.
    if (defaultTargetPlatform == TargetPlatform.iOS) return;
    final wanted = AdaptiveLayout.orientationsForShortestSide(shortestSide);
    if (_applied != null &&
        _applied!.length == wanted.length &&
        _applied!.first == wanted.first) {
      return;
    }
    _applied = wanted;
    SystemChrome.setPreferredOrientations(wanted);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Decide from the physical display, not the window: a portrait-locked app
    // gets a small portrait window even on a large screen, and judging by that
    // window would keep it locked forever.
    _applyOrientations(AdaptiveLayout.displayShortestSide(View.of(context)));

    final width = AdaptiveLayout.contentWidthFor(media.size.width);
    final gutter = (media.size.width - width) / 2;

    if (gutter <= 0) return widget.child;

    EdgeInsets trim(EdgeInsets e) => e.copyWith(
      left: AdaptiveLayout.insetAfterGutter(inset: e.left, gutter: gutter),
      right: AdaptiveLayout.insetAfterGutter(inset: e.right, gutter: gutter),
    );

    return ColoredBox(
      color: widget.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ?_screenBackground,
          Center(
            child: MediaQuery(
              data: media.copyWith(
                size: Size(width, media.size.height),
                padding: trim(media.padding),
                viewPadding: trim(media.viewPadding),
                viewInsets: trim(media.viewInsets),
              ),
              child: SizedBox(
                width: width,
                height: double.infinity,
                child: AdaptiveFrameScope(
                  gutter: gutter,
                  setBackground: _setScreenBackground,
                  child: widget.child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
