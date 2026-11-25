import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/haptic_buttons.dart';
import '../../models/seasonal_greeting.dart';

class SeasonalGreetingBanner extends StatelessWidget {
  final SeasonalGreeting greeting;
  final VoidCallback onDismiss;

  const SeasonalGreetingBanner({
    super.key,
    required this.greeting,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: greeting.colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(greeting.flag, style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Color(0xFF102A43),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  greeting.message,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF102A43),
                  ),
                ),
              ],
            ),
          ),
          AppHaptic(
            onTap: onDismiss,
            child: const Icon(
              Icons.close_rounded,
              color: Color(0xFF102A43),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
