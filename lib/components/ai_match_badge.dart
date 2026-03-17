
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class AiMatchBadge extends StatelessWidget {
  final double score; // 0.0 to 1.0

  const AiMatchBadge({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Color color;
    String text;
    IconData icon;

    if (score >= 0.99) {
      color = AppColors.secondaryLight;
      text = l10n.bestMatch;
      icon = Icons.stars;
    } else if (score >= 0.7) {
      color = Colors.green;
      text = l10n.goodMatch;
      icon = Icons.thumb_up;
    } else if (score >= 0.4) {
      color = Colors.orange;
      text = l10n.match;
      icon = Icons.check_circle_outline;
    } else {
      color = Colors.grey;
      text = l10n.match;
      icon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '${(score.isFinite ? score * 100 : 0).toInt()}% $text',
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
