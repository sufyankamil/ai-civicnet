import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/haptic_buttons.dart';
import 'aura_ai_sheet.dart';

/// Floating AI Orb with breathing aura glow and micro-animations for the Home screen.
class AuraFloatingOrb extends StatefulWidget {
  const AuraFloatingOrb({super.key});

  @override
  State<AuraFloatingOrb> createState() => _AuraFloatingOrbState();
}

class _AuraFloatingOrbState extends State<AuraFloatingOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glowAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.75).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    AppHaptic.mediumImpact();
    AuraAiSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Tooltip(
            message: 'Ask Aura AI',
            child: AppHaptic(
              onTap: _handleTap,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.auraGradient,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.45),
                    width: 1.5,
                  ),
                  boxShadow: [
                    // Outer pulsating aura glow
                    BoxShadow(
                      color: AppColors.auraPrimary.withValues(
                        alpha: _glowAnimation.value,
                      ),
                      blurRadius: 18 * _scaleAnimation.value,
                      spreadRadius: 2 * _scaleAnimation.value,
                      offset: const Offset(0, 4),
                    ),
                    // Inner depth shadow
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 26,
                    ),

                    // Tiny live status indicator
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981), // Emerald green
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.8),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
