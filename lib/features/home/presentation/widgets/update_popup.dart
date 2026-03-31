import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/haptic_buttons.dart';

class UpdatePopup extends StatelessWidget {
  final String newVersion;
  final VoidCallback onUpdate;
  final VoidCallback onLater;

  const UpdatePopup({
    super.key,
    required this.newVersion,
    required this.onUpdate,
    required this.onLater,
  });

  static Future<void> show(
    BuildContext context, {
    required String newVersion,
    required VoidCallback onUpdate,
    required VoidCallback onLater,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => UpdatePopup(
        newVersion: newVersion,
        onUpdate: onUpdate,
        onLater: onLater,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: GlassmorphicContainer(
            width: double.infinity,
            height: 420,
            borderRadius: 32,
            blur: 20,
            alignment: Alignment.bottomCenter,
            border: 2,
            linearGradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.1),
                Colors.white.withValues(alpha: 0.05),
              ],
              stops: const [0.1, 1],
            ),
            borderGradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.5),
                Colors.white.withValues(alpha: 0.2),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Icon/Illustration
                  _buildAnimatedHeader(),
                  const SizedBox(height: 24),
                  
                  // Text Content
                  const Text(
                    'Time to Upgrade!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'A new version of CivicNet ($newVersion) is available with better performance and new community features.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.7),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
                  // Action Buttons
                  AppElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onUpdate();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryLight,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Update Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onLater();
                    },
                    child: Text(
                      'Maybe Later',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow effect
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryLight.withValues(alpha: 0.3),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
        ),
        // Icon Container
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.system_update_rounded,
            color: Colors.white,
            size: 40,
          ),
        ),
      ],
    );
  }
}
