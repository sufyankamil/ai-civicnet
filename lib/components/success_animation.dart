import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SuccessAnimation extends StatefulWidget {
  final double size;
  final Color? color;
  final VoidCallback? onComplete;

  const SuccessAnimation({
    super.key,
    this.size = 100,
    this.color,
    this.onComplete,
  });

  @override
  State<SuccessAnimation> createState() => _SuccessAnimationState();
}

class _SuccessAnimationState extends State<SuccessAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _checkAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _checkAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
      ),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2).chain(CurveTween(curve: Curves.easeOut)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
    ]).animate(_controller);

    _controller.forward().then((_) {
      if (widget.onComplete != null) widget.onComplete!();
    });

    // Premium haptic pop
    HapticFeedback.mediumImpact();
    Future.delayed(const Duration(milliseconds: 400), () {
      HapticFeedback.lightImpact();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.color ?? Theme.of(context).primaryColor;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: themeColor.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: CustomPaint(
              painter: _CheckPainter(
                progress: _checkAnimation.value,
                color: themeColor,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CheckPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CheckPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.08
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    
    // Start of checkmark
    final startX = size.width * 0.25;
    final startY = size.height * 0.5;
    
    // Middle of checkmark (the bend)
    final midX = size.width * 0.45;
    final midY = size.height * 0.7;
    
    // End of checkmark
    final endX = size.width * 0.75;
    final endY = size.height * 0.35;

    if (progress > 0) {
      path.moveTo(startX, startY);
      
      // First segment (downwards)
      if (progress < 0.3) {
        final p = progress / 0.3;
        path.lineTo(
          startX + (midX - startX) * p,
          startY + (midY - startY) * p,
        );
      } else {
        path.lineTo(midX, midY);
        
        // Second segment (upwards)
        final p = (progress - 0.3) / 0.7;
        path.lineTo(
          midX + (endX - midX) * p,
          midY + (endY - midY) * p,
        );
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
