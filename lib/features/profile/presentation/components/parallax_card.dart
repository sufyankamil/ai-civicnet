import 'package:flutter/material.dart';

class ParallaxCard extends StatelessWidget {
  final Widget child;
  final ScrollController scrollController;
  final double parallaxSpeed;
  final Axis axis;

  const ParallaxCard({
    super.key,
    required this.child,
    required this.scrollController,
    this.parallaxSpeed = 0.1,
    this.axis = Axis.vertical,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, child) {
        if (!scrollController.hasClients) return child!;

        final RenderObject? renderObject = context.findRenderObject();
        if (renderObject == null || !renderObject.attached) return child!;

        final box = renderObject as RenderBox;
        final offset = box.localToGlobal(Offset.zero);
        final size = MediaQuery.of(context).size;
        
        double parallaxOffset;
        if (axis == Axis.vertical) {
          final centerOffset = (offset.dy + box.size.height / 2) / size.height;
          parallaxOffset = (centerOffset - 0.5) * 40 * parallaxSpeed;
          return Transform.translate(
            offset: Offset(0, parallaxOffset),
            child: child,
          );
        } else {
          final centerOffset = (offset.dx + box.size.width / 2) / size.width;
          parallaxOffset = (centerOffset - 0.5) * 30 * parallaxSpeed;
          return Transform.translate(
            offset: Offset(parallaxOffset, 0),
            child: child,
          );
        }
      },
      child: child,
    );
  }
}
