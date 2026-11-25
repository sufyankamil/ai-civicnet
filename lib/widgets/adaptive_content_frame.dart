import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/utils/adaptive_layout.dart';

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

class _AdaptiveContentFrameState extends State<AdaptiveContentFrame> {
  List<DeviceOrientation>? _applied;

  void _applyOrientations(double shortestSide) {
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
    _applyOrientations(media.size.shortestSide);

    final width = AdaptiveLayout.contentWidthFor(media.size.width);
    final gutter = (media.size.width - width) / 2;

    if (gutter <= 0) return widget.child;

    EdgeInsets trim(EdgeInsets e) => e.copyWith(
      left: AdaptiveLayout.insetAfterGutter(inset: e.left, gutter: gutter),
      right: AdaptiveLayout.insetAfterGutter(inset: e.right, gutter: gutter),
    );

    return ColoredBox(
      color: widget.background,
      child: Center(
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
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
