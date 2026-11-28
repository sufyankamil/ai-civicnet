import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/subscription_service.dart';
import '../theme/app_theme.dart';

/// Small "PRO" pill shown next to a signed-in user's name while their
/// CivicNet Pro subscription (or free trial) is active. Draws nothing for
/// free users and updates live as the subscription changes.
class ProBadge extends StatelessWidget {
  const ProBadge({super.key, this.subscriptions, this.compact = false});

  /// Defaults to the app-wide [SubscriptionService]. Tests pass their own.
  final SubscriptionService? subscriptions;

  /// Smaller size for tight spots such as an app bar title.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final service = subscriptions ?? SubscriptionService();
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        if (!service.isPro) return const SizedBox.shrink();
        final l10n = AppLocalizations.of(context)!;
        final iconSize = compact ? 12.0 : 14.0;
        return Semantics(
          label: l10n.proBadgeLabel,
          excludeSemantics: true,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 7 : 9,
              vertical: compact ? 2 : 3,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.workspace_premium_rounded,
                  size: iconSize,
                  color: AppColors.auraPrimary,
                ),
                const SizedBox(width: 3),
                Text(
                  l10n.settingsProBadge,
                  style: TextStyle(
                    fontSize: compact ? 10 : 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: AppColors.auraPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
