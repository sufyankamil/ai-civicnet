import 'package:flutter/material.dart';
import '../../../../../models/models.dart' as legacy;
import '../../../../../widgets/haptic_buttons.dart';
import '../../../../../l10n/app_localizations.dart';

class StatusBannerSection extends StatelessWidget {
  final legacy.ApplicationStatus? applicationStatus;
  final VoidCallback onChat;

  const StatusBannerSection({
    super.key,
    required this.applicationStatus,
    required this.onChat,
  });

  String _getLocalizedApplicationStatus(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status.toLowerCase()) {
      case 'accepted': return l10n.applicationAccepted;
      case 'not selected': return l10n.notSelected;
      case 'applied': return l10n.interestSent;
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (applicationStatus == null) return const SizedBox.shrink();

    Color color = Colors.grey;
    IconData icon = Icons.info;
    Color textColor = Colors.grey;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (applicationStatus!) {
      case legacy.ApplicationStatus.accepted:
        color = Colors.green;
        textColor = isDark ? Colors.greenAccent : Colors.green[700]!;
        icon = Icons.check_circle_rounded;
        break;
      case legacy.ApplicationStatus.rejected:
        color = Colors.grey;
        textColor = isDark ? Colors.grey[300]! : Colors.grey[800]!;
        icon = Icons.info_outline_rounded;
        break;
      case legacy.ApplicationStatus.pending:
        color = Colors.orange;
        textColor = isDark ? Colors.orangeAccent : Colors.orange[800]!;
        icon = Icons.pending_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getLocalizedApplicationStatus(context, applicationStatus!.name).toUpperCase(),
                  style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  applicationStatus == legacy.ApplicationStatus.accepted
                      ? AppLocalizations.of(context)!.communicateWithRequester
                      : applicationStatus == legacy.ApplicationStatus.rejected
                          ? 'The requester chose someone else for this task.'
                          : 'Your interest has been noted. Please wait for a response.',
                  style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.8), height: 1.3),
                ),
              ],
            ),
          ),
          if (applicationStatus == legacy.ApplicationStatus.accepted)
            AppHaptic(
              onTap: onChat,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'CHAT',
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
