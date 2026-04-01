import 'package:flutter/material.dart';

class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Stack(
      children: [
        // 1. Base Layer Gradient
        Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0F172A),
                      Color(0xFF1E1B4B),
                      Color(0xFF0F172A),
                    ],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFF8FAFC),
                      Color(0xFFEEF2FF),
                      Color(0xFFF1F5F9),
                    ],
                  ),
          ),
        ),

        // 2. Animated Aura / Mesh Orbs
        Positioned(
          top: -100,
          right: -100,
          child: _AuraOrb(
            color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.15 : 0.08),
            size: 400,
          ),
        ),
        Positioned(
          bottom: -150,
          left: -150,
          child: _AuraOrb(
            color: const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.15 : 0.08),
            size: 500,
          ),
        ),
        if (isDark)
          Positioned(
            top: 200,
            left: -50,
            child: _AuraOrb(
              color: const Color(0xFFDB2777).withValues(alpha: 0.05),
              size: 300,
            ),
          ),

        // 3. Main Content
        child,
      ],
    );
  }
}

class _AuraOrb extends StatelessWidget {
  final Color color;
  final double size;

  const _AuraOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}
