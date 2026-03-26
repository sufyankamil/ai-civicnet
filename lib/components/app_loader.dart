import 'package:flutter/material.dart';

class AppLoader extends StatefulWidget {
  final double size;
  final bool centered;
  final bool showRing;
  final Color? color;
  final IconData? iconData;

  const AppLoader({
    super.key,
    this.size = 44.0,
    this.centered = true,
    this.showRing = true,
    this.color,
    this.iconData,
  });

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.08)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.08, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconPath = isDark ? 'assets/icons/app_icon_dark.png' : 'assets/icons/app_icon.png';
    final loaderColor = widget.color ?? Theme.of(context).primaryColor;

    final bool effectiveShowRing = widget.showRing && widget.size > 30;
    final iconSize = widget.size * (effectiveShowRing ? 0.6 : 0.85);

    Widget loader = SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (effectiveShowRing)
            RotationTransition(
              turns: _controller,
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    loaderColor.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          ScaleTransition(
            scale: _pulseAnimation,
            child: widget.iconData != null
                ? Icon(
                    widget.iconData,
                    size: iconSize * 0.9,
                    color: loaderColor,
                  )
                : Container(
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      iconPath,
                      width: iconSize,
                      height: iconSize,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.handshake_rounded,
                        size: iconSize * 0.8,
                        color: loaderColor,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );

    if (widget.centered) {
      return Center(child: loader);
    }
    return loader;
  }
}
