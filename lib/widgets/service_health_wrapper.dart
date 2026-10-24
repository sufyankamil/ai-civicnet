import 'package:flutter/material.dart';
import '../services/service_health_service.dart';
import 'service_health_banner.dart';

/// Wraps the application navigation tree to automatically display
/// the [ServiceHealthBanner] at the top of all screens when service disruptions occur.
class ServiceHealthWrapper extends StatelessWidget {
  final Widget child;

  const ServiceHealthWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ServiceHealthService(),
      builder: (context, _) {
        final shouldShow = ServiceHealthService().shouldShowBanner;

        return Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (ctx) => Material(
                type: MaterialType.transparency,
                child: Column(
                  children: [
                    if (shouldShow)
                      SafeArea(
                        bottom: false,
                        child: const ServiceHealthBanner(),
                      ),
                    Expanded(child: child),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
