import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/utils/adaptive_layout.dart';

/// Hides a screen's own top-left back/close button while the shared one is shown
/// in the right-hand status strip (see [AdaptiveContentFrame]).
class HideOnSideStrip extends StatelessWidget {
  const HideOnSideStrip({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final strip = AdaptiveLayout.hasSideStrip(
      AdaptiveLayout.windowPadding(View.of(context)),
    );
    return strip ? const SizedBox.shrink() : child;
  }
}

/// Keeps the allowed orientations in sync with the screen the app is on
/// (non-iOS only): phones stay portrait, large screens may rotate. The content
/// itself is never capped: it fills the whole window.
///
/// When the screen has a status strip on the right (iPhone Duo) and there is
/// somewhere to go back to, it also shows one shared back (or close) button in
/// that strip, under the system indicators. Screens hide their own top-left
/// button with [HideOnSideStrip].
///

/// iOS decides natively (see `AppDelegate.swift`), from the scene's own screen,
/// because Flutter keeps reporting the screen the app launched on after a
/// foldable opens.
class AdaptiveContentFrame extends StatefulWidget {
  const AdaptiveContentFrame({
    super.key,
    required this.child,
    this.canGoBack = false,
    this.isClose = false,
    this.onBack,
  });

  final Widget child;

  /// Whether the current route can be popped.
  final bool canGoBack;

  /// Show a close (X) icon instead of a back arrow (create/modal-style routes).
  final bool isClose;

  /// Called when the strip button is tapped.
  final VoidCallback? onBack;

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

    final padding = AdaptiveLayout.windowPadding(View.of(context));
    final active =
        widget.canGoBack &&
        widget.onBack != null &&
        AdaptiveLayout.hasSideStrip(padding);

    // While the strip button is shown the screen stops before the strip, so
    // nothing interactive hides under the frosted panel. The structure is the
    // same either way so the navigator below keeps its state.
    final inset = active ? padding.right : 0.0;
    final media = MediaQuery.of(context);
    final content = MediaQuery(
      data: active
          ? media.copyWith(
              size: Size(media.size.width - inset, media.size.height),
              padding: media.padding.copyWith(right: 0),
              viewPadding: media.viewPadding.copyWith(right: 0),
            )
          : media,
      child: Padding(
        padding: EdgeInsets.only(right: inset),
        child: widget.child,
      ),
    );
    if (!active) return Stack(children: [content]);

    // Below the system indicators: the outer screen stacks camera, time and
    // wifi (taller) while the inner screen only shows time and wifi.
    // Judge by the window: Flutter keeps reporting the launch screen for the
    // display after a foldable opens.
    final large =
        MediaQuery.sizeOf(context).shortestSide >=
        AdaptiveLayout.largeWindowShortestSide;
    final top = large ? 112.0 : 164.0;
    const size = 48.0;
    return Stack(
      children: [
        content,
        // Solid base: the screen no longer extends under the strip, so there
        // is nothing to blur; this keeps the strip from showing the window
        // background.
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: padding.right,
          child: ColoredBox(color: Theme.of(context).scaffoldBackgroundColor),
        ),
        // Frosted panel over the whole strip so the button and the system
        // indicators stay legible over maps, photos and tinted headers.
        Positioned(
          key: const Key('side_strip_blur'),
          right: 0,
          top: 0,
          bottom: 0,
          width: padding.right,
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: ColoredBox(
                color: Theme.of(
                  context,
                ).scaffoldBackgroundColor.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
        Positioned(
          right: (padding.right - size) / 2,
          top: top,
          child: Material(
            type: MaterialType.transparency,
            child: IconButton(
              key: const Key('side_strip_back'),
              iconSize: 24,
              constraints: const BoxConstraints.tightFor(
                width: size,
                height: size,
              ),
              icon: Icon(widget.isClose ? Icons.close : Icons.arrow_back),
              onPressed: widget.onBack,
            ),
          ),
        ),
      ],
    );
  }
}
