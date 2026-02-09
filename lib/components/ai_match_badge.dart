
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AiMatchBadge extends StatelessWidget {
  final double score; // 0.0 to 1.0

  const AiMatchBadge({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    // Determine color and text based on score
    Color color;
    String text;
    IconData icon;

    if (score >= 0.9) {
      color = AppColors.secondaryLight;
      text = 'Best Match';
      icon = Icons.stars;
    } else if (score >= 0.7) {
      color = Colors.orangeAccent;
      text = 'Good Match';
      icon = Icons.thumb_up;
    } else {
      color = Colors.grey;
      text = 'Match';
      icon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '${(score * 100).toInt()}% $text',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
