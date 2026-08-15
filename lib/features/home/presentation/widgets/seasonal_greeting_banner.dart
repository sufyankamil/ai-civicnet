import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/haptic_buttons.dart';

class SeasonalGreetingBanner extends StatelessWidget {
  final VoidCallback onDismiss;

  const SeasonalGreetingBanner({super.key, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF9933), Color(0xFFFFFFFF), Color(0xFF138808)],
          stops: [0, 0.5, 1],
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
          const Text('🇮🇳', style: TextStyle(fontSize: 30)),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Happy Independence Day!',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Color(0xFF102A43),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'स्वतंत्रता दिवस की शुभकामनाएँ',
                  style: TextStyle(fontSize: 12, color: Color(0xFF102A43)),
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
