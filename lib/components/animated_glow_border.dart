import 'package:flutter/material.dart';

class AnimatedGlowBorder extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final double borderWidth;
  final bool isActive;

  const AnimatedGlowBorder({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.borderWidth = 2.0,
    this.isActive = true,
  });

  @override
  State<AnimatedGlowBorder> createState() => _AnimatedGlowBorderState();
}

class _AnimatedGlowBorderState extends State<AnimatedGlowBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    if (widget.isActive) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedGlowBorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.forward(from: 0.0);
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return Padding(
        padding: EdgeInsets.all(widget.borderWidth),
        child: widget.child,
      );
    }

    final primaryColor = Theme.of(context).primaryColor;
    final secondaryColor = Colors.purpleAccent;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.all(widget.borderWidth),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius + widget.borderWidth),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: secondaryColor.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 4,
              ),
            ],
            gradient: SweepGradient(
              center: FractionalOffset.center,
              colors: [
                primaryColor.withValues(alpha: 0.1),
                primaryColor,
                secondaryColor,
                primaryColor.withValues(alpha: 0.1),
              ],
              stops: const [0.0, 0.4, 0.6, 1.0],
              transform: GradientRotation(_controller.value * 2 * 3.1415926535),
            ),
          ),
          child: child,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        child: widget.child,
      ),
    );
  }
}
