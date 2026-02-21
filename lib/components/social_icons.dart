import 'package:flutter/material.dart';

/// Returns a custom-painted Google 4-colour circle logo.
Widget googleIcon() => SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );

/// Returns the Apple logo icon (uses built-in Material symbol).
Widget appleIcon() => const Icon(
      Icons.apple_rounded,
      size: 22,
      color: Colors.black87,
    );

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    final red = Paint()..color = const Color(0xFFEA4335);
    final blue = Paint()..color = const Color(0xFF4285F4);
    final yellow = Paint()..color = const Color(0xFFFBBC05);
    final green = Paint()..color = const Color(0xFF34A853);

    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
        -1.57, 1.57, true, red);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
        0, 1.57, true, blue);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
        1.57, 1.57, true, yellow);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
        -3.14, 1.57, true, green);

    // White centre hole
    canvas.drawCircle(
        Offset(cx, cy), r * 0.6, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_) => false;
}
