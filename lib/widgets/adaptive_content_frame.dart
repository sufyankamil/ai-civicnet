import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/utils/adaptive_layout.dart';

/// Actions that screens moved into the right-hand status strip, below the back
/// button. Owned by [AdaptiveContentFrame].
class SideStripController extends ChangeNotifier {
  final Map<Object, Widget> _actions = {};
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  List<Widget> get actions => _actions.values.toList(growable: false);

  void set(Object owner, Widget action) {
    if (_disposed) return;
    _actions[owner] = action;
    notifyListeners();
  }

  void remove(Object owner) {
    if (_disposed) return;
    if (_actions.remove(owner) != null) notifyListeners();
  }
}

class SideStripScope extends InheritedWidget {
  const SideStripScope({
    super.key,
    required this.controller,
    required this.backShown,
    required super.child,
  });

  final SideStripController controller;

  /// Whether the shared back/close button is currently shown in the strip.
  final bool backShown;

  static SideStripController? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<SideStripScope>()?.controller;

  /// Whether screens should hide their own back/close button because the
  /// shared one is in the strip. Subscribes the caller to changes.
  static bool backShownOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SideStripScope>()?.backShown ??
      false;

  @override
  bool updateShouldNotify(SideStripScope old) =>
      controller != old.controller || backShown != old.backShown;
}

/// A screen's top-right action (for example "add"). On a screen with a status
/// strip on the right (iPhone Duo) it is shown in the strip, under the back
/// button, instead of in place; elsewhere it stays where the screen put it.
class SideStripAction extends StatefulWidget {
  const SideStripAction({super.key, required this.child});

  final Widget child;

  @override
  State<SideStripAction> createState() => _SideStripActionState();
}

class _SideStripActionState extends State<SideStripAction> {
  SideStripController? _controller;
  bool _registered = false;

  bool get _inStrip => AdaptiveLayout.hasSideStrip(
    AdaptiveLayout.windowPadding(View.of(context)),
  );

  void _sync() {
    final controller = _controller;
    if (controller == null) return;
    final wantStrip = _inStrip;
    final action = widget.child;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (wantStrip) {
        controller.set(this, action);
        _registered = true;
      } else if (_registered) {
        controller.remove(this);
        _registered = false;
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = SideStripScope.maybeOf(context);
    _sync();
  }

  @override
  void didUpdateWidget(SideStripAction old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    final controller = _controller;
    if (_registered && controller != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => controller.remove(this),
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _inStrip ? const SizedBox.shrink() : widget.child;
}

/// Pads [child] by the right-hand status strip (iPhone Duo) so text and buttons
/// clear the frosted panel. Use it on a screen's content, not on its header or
/// background, which should keep running under the panel so there is something
/// to frost. Adds nothing where there is no strip.
class SideStripInset extends StatelessWidget {
  const SideStripInset({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: MediaQuery.paddingOf(context).right),
      child: child,
    );
  }
}

/// Hides a screen's own top-left back/close button while the shared one is shown
/// in the right-hand status strip (see [AdaptiveContentFrame]).
class HideOnSideStrip extends StatelessWidget {
  const HideOnSideStrip({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Only when the shared button really is in the strip: on a route that
    // cannot pop there is none, and hiding this one would leave no way back.
    return SideStripScope.backShownOf(context)
        ? const SizedBox.shrink()
        : child;
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
  final SideStripController _strip = SideStripController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _strip.addListener(_onStripActions);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _strip.removeListener(_onStripActions);
    _strip.dispose();
    super.dispose();
  }

  void _onStripActions() {
    if (mounted) setState(() {});
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
    final strip = AdaptiveLayout.hasSideStrip(padding);
    final showBack = strip && widget.canGoBack && widget.onBack != null;

    // Screens run full width under the strip so the frosted panel has
    // something to blur, and keep the inset in MediaQuery so SafeArea-aware
    // screens still stop before it. The structure is the same with or
    // without a strip so the navigator below keeps its state.
    final content = Padding(
      padding: EdgeInsets.zero,
      child: SideStripScope(
        controller: _strip,
        backShown: showBack,
        child: widget.child,
      ),
    );
    if (!strip) return Stack(children: [content]);

    // Below the system indicators: the outer screen stacks camera, time and
    // wifi (taller) while the inner screen only shows time and wifi. Judge by
    // the window: Flutter keeps reporting the launch screen for the display
    // after a foldable opens.
    final large =
        MediaQuery.sizeOf(context).shortestSide >=
        AdaptiveLayout.largeWindowShortestSide;
    final top = large ? 112.0 : 164.0;
    const size = 48.0;
    final scaffold = Theme.of(context).scaffoldBackgroundColor;
    return Stack(
      children: [
        content,
        // Frosted, translucent panel over the whole strip so the indicators
        // and buttons stay legible without a flat slab. It absorbs touches so
        // nothing hidden underneath is triggered by accident.
        Positioned(
          key: const Key('side_strip_blur'),
          right: 0,
          top: 0,
          bottom: 0,
          width: padding.right,
          child: AbsorbPointer(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: ColoredBox(color: scaffold.withValues(alpha: 0.35)),
              ),
            ),
          ),
        ),
        Positioned(
          right: (padding.right - size) / 2,
          top: top,
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showBack)
                  IconButton(
                    key: const Key('side_strip_back'),
                    iconSize: 24,
                    constraints: const BoxConstraints.tightFor(
                      width: size,
                      height: size,
                    ),
                    icon: Icon(widget.isClose ? Icons.close : Icons.arrow_back),
                    onPressed: widget.onBack,
                  ),
                for (final action in _strip.actions)
                  SizedBox(
                    width: size,
                    height: size,
                    child: Center(child: action),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
