import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/haptic_buttons.dart';

class NotFoundScreen extends StatelessWidget {
  final String? location;
  const NotFoundScreen({super.key, this.location});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          gradient: RadialGradient(
            center: const Alignment(0, -0.3),
            radius: 1.2,
            colors: [
              AppColors.primaryLight.withValues(alpha: isDark ? 0.15 : 0.1),
              Theme.of(context).scaffoldBackgroundColor,
            ],
            stops: const [0.0, 0.7],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Top Icon / Visual
                Hero(
                  tag: '404_icon',
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.2),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.explore_off_rounded,
                      size: 80,
                      color: primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                
                // 404 Text
                const Text(
                  '404',
                  style: TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -2,
                    height: 1,
                    color: AppColors.primaryLight,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Heading
                const Text(
                  'Lost in CivicNet?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Subtitle
                Text(
                  "The page you're looking for doesn't exist or has been moved to another neighborhood.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5),
                    height: 1.5,
                  ),
                ),
                
                if (location != null && location!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      'Path: $location',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 48),
                
                // Return Button
                AppHaptic(
                  onTap: () => context.go('/home'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      gradient: AppColors.auraGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryLight.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'Back to Safety',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
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
