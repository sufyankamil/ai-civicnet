import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../services/ai_quota_service.dart';
import '../services/subscription_service.dart';
import '../theme/app_theme.dart';

/// "7 of 10 free AI actions left this month". Shown only to free users while
/// the quota is enforced; tapping it opens the paywall.
class AiQuotaHint extends StatefulWidget {
  const AiQuotaHint({super.key, this.quota});

  /// Injected in tests; defaults to the app-wide [AiQuotaService].
  final AiQuotaService? quota;

  @override
  State<AiQuotaHint> createState() => _AiQuotaHintState();
}

class _AiQuotaHintState extends State<AiQuotaHint> {
  late final AiQuotaService _quota = widget.quota ?? AiQuotaService();

  @override
  void initState() {
    super.initState();
    _quota.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_quota, SubscriptionService()]),
      builder: (context, _) {
        final status = _quota.status;
        if (status == null ||
            status.isUnlimited ||
            SubscriptionService().isPro) {
          return const SizedBox.shrink();
        }

        final l10n = AppLocalizations.of(context)!;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return InkWell(
          onTap: () => context.push('/subscription'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 14,
                  color: AppColors.auraPrimary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    l10n.aiQuotaRemaining(status.remaining, status.limit),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
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
