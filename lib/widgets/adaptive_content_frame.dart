import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/utils/adaptive_layout.dart';

/// Keeps the allowed orientations in sync with the screen the app is on
/// (non-iOS only): phones stay portrait, large screens may rotate. The content
/// itself is never capped: it fills the whole window.
///
/// iOS decides natively (see `AppDelegate.swift`), from the scene's own screen,
/// because Flutter keeps reporting the screen the app launched on after a
/// foldable opens.
class AdaptiveContentFrame extends StatefulWidget {
  const AdaptiveContentFrame({super.key, required this.child});

  final Widget child;

  @override
  State<AdaptiveContentFrame> createState() => _AdaptiveContentFrameState();
}

class _AdaptiveContentFrameState extends State<AdaptiveContentFrame>
    with WidgetsBindingObserver {
  List<DeviceOrientation>? _applied;

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
  /// while the window keeps its size.
  @override
  void didChangeMetrics() {
    if (!mounted) return;
    _applyOrientations(AdaptiveLayout.displayShortestSide(View.of(context)));
  }

  void _applyOrientations(double shortestSide) {
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
    // Judge by the physical display, not the window: a portrait-locked app
    // gets a small portrait window even on a large screen.
    _applyOrientations(AdaptiveLayout.displayShortestSide(View.of(context)));
    return widget.child;
  }
}
