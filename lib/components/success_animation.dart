import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/services.dart';

class SuccessAnimation extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final Color baseColor;
  final double? size;

  const SuccessAnimation({
    super.key,
    this.title,
    this.subtitle,
    this.icon,
    this.baseColor = const Color(0xFF7B61FF),
    this.size,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    HapticFeedback.vibrate();
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.85),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return SuccessAnimation(
          title: title,
          subtitle: subtitle,
          icon: icon,
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const String confettiUrl = 'https://lottie.host/6ab623c2-d1d5-4521-862a-0630b925f385/u6mE1j0c8o.json';

    if (size != null) {
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Lottie.network(
              confettiUrl,
              fit: BoxFit.contain,
              repeat: false,
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
            if (icon != null)
              Icon(icon, size: size! * 0.4, color: baseColor),
          ],
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Lottie.network(
            confettiUrl,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            repeat: false,
            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: baseColor.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: baseColor, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: baseColor.withValues(alpha: 0.4),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          icon ?? Icons.check_circle_rounded,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
                if (title != null)
                  Text(
                    title!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                if (subtitle != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.8),
                      height: 1.5,
                    ),
                  ),
                ],
                const SizedBox(height: 60),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: baseColor,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text(
                    'AMAZING!',
                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
