import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/service_health_service.dart';
import '../components/service_status_sheet.dart';
import '../core/routes/app_router.dart';
import 'haptic_buttons.dart';

class ServiceHealthBanner extends StatefulWidget {
  const ServiceHealthBanner({super.key});

  @override
  State<ServiceHealthBanner> createState() => _ServiceHealthBannerState();
}

class _ServiceHealthBannerState extends State<ServiceHealthBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ServiceHealthService(),
      builder: (context, _) {
        final healthService = ServiceHealthService();
        final isVisible = healthService.shouldShowBanner;
        final incident = healthService.activeIncident;

        return AnimatedSize(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: isVisible ? 1.0 : 0.0,
            child: isVisible && incident != null
                ? _buildBannerContent(context, incident)
                : const SizedBox(width: double.infinity, height: 0),
          ),
        );
      },
    );
  }

  Widget _buildBannerContent(BuildContext context, ServiceIncident incident) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Premium Liquid Glass Amber Palette
    final containerBg = isDark
        ? const Color(0xFF1E1711).withValues(alpha: 0.92)
        : const Color(0xFFFFF8EC).withValues(alpha: 0.94);

    final borderColor = isDark
        ? const Color(0xFFFF9F43).withValues(alpha: 0.40)
        : const Color(0xFFFFA94D).withValues(alpha: 0.55);

    final textColor = isDark
        ? const Color(0xFFFFECD6)
        : const Color(0xFF4A3416);

    final linkColor = isDark
        ? const Color(0xFFFFBE76)
        : const Color(0xFFB45309);

    final String titleText = incident.title.isNotEmpty
        ? incident.title
        : 'We are investigating a technical issue';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: containerBg,
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1.2),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9F43).withValues(alpha: isDark ? 0.12 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              children: [
                // Animated Pulsing Beacon Icon
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9F43)
                            .withValues(alpha: 0.18 * _pulseAnimation.value),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF9F43)
                                .withValues(alpha: 0.4 * _pulseAnimation.value),
                            blurRadius: 8 * _pulseAnimation.value,
                            spreadRadius: 1 * _pulseAnimation.value,
                          ),
                        ],
                      ),
                      child: child,
                    );
                  },
                  child: const Icon(
                    Icons.error_outline_rounded,
                    size: 17,
                    color: Color(0xFFFF9F43),
                  ),
                ),
                const SizedBox(width: 10),

                // Notice & Status Page Link
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      AppHaptic.lightImpact();
                      final navContext = rootNavigatorKey.currentContext ?? context;
                      ServiceStatusSheet.show(navContext);
                    },
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                          color: textColor,
                          height: 1.25,
                        ),
                        children: [
                          TextSpan(text: '$titleText · '),
                          TextSpan(
                            text: 'Follow status page',
                            style: TextStyle(
                              color: linkColor,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                              decorationColor: linkColor.withValues(alpha: 0.7),
                            ),
                          ),
                          const TextSpan(text: ' for updates'),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 6),

                // Dismiss Button [X] (without RawTooltip to prevent No Overlay error)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    AppHaptic.lightImpact();
                    ServiceHealthService().dismissBanner();
                  },
                  child: Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: textColor.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
