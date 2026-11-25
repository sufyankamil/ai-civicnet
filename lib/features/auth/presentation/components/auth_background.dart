import 'package:flutter/material.dart';

import '../../../../widgets/adaptive_content_frame.dart';

class AuthBackground extends StatefulWidget {
  final Widget child;

  const AuthBackground({super.key, required this.child});

  @override
  State<AuthBackground> createState() => _AuthBackgroundState();
}

class _AuthBackgroundState extends State<AuthBackground> {
  void Function(Widget?)? _setFrameBackground;
  bool? _registeredDark;

  @override
  void dispose() {
    final set = _setFrameBackground;
    if (set != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => set(null));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // On wide windows the app content is capped and centred. The frame paints
    // the same gradient across the whole window behind the column, so there is
    // no seam.
    final scope = AdaptiveFrameScope.maybeOf(context);
    final gutter = scope?.gutter ?? 0;
    final fullWindow = scope != null && gutter > 0;
    if (fullWindow) {
      if (_registeredDark != isDark || _setFrameBackground == null) {
        _setFrameBackground = scope.setBackground;
        _registeredDark = isDark;
        final gradient = _AuthGradient(isDark: isDark);
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => scope.setBackground(gradient),
        );
      }
    } else if (_setFrameBackground != null) {
      final set = _setFrameBackground!;
      _setFrameBackground = null;
      _registeredDark = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => set(null));
    }

    return Stack(
      children: [
        // 1. Base Layer Gradient. Laid out over the whole window (shifted by
        // the gutter, clipped to the column) so it lines up exactly with the
        // frame's gradient behind the gutters.
        Positioned(
          left: -gutter,
          right: -gutter,
          top: 0,
          bottom: 0,
          child: _AuthGradient(isDark: isDark),
        ),

        // 2. Animated Aura / Mesh Orbs
        Positioned(
          top: -100,
          right: -100,
          child: _AuraOrb(
            color: const Color(
              0xFF6366F1,
            ).withValues(alpha: isDark ? 0.15 : 0.08),
            size: 400,
          ),
        ),
        Positioned(
          bottom: -150,
          left: -150,
          child: _AuraOrb(
            color: const Color(
              0xFF8B5CF6,
            ).withValues(alpha: isDark ? 0.15 : 0.08),
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
        widget.child,
      ],
    );
  }
}

class _AuthGradient extends StatelessWidget {
  final bool isDark;

  const _AuthGradient({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('auth_background_base'),
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
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}
