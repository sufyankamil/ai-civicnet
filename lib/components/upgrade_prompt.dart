import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Small "See Pro plans" button shown under an AI message that says the free
/// quota is used up.
class AiUpgradeAction extends StatelessWidget {
  const AiUpgradeAction({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(left: 34, bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.auraPrimary,
            visualDensity: VisualDensity.compact,
          ),
          onPressed: () => context.push('/subscription'),
          icon: const Icon(Icons.auto_awesome_rounded, size: 16),
          label: Text(l10n.upgradeCta),
        ),
      ),
    );
  }
}

/// Bottom sheet that explains the free quota is used up and offers the Pro
/// plans. For places that have no message list to attach a button to.
Future<void> showUpgradeSheet(BuildContext context) {
  final router = GoRouter.of(context);
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    builder: (sheetContext) {
      final l10n = AppLocalizations.of(sheetContext)!;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 36,
                color: AppColors.auraPrimary,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.upgradeQuotaMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, height: 1.4),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    router.push('/subscription');
                  },
                  child: Text(l10n.upgradeCta),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: Text(l10n.upgradeNotNow),
              ),
            ],
          ),
        ),
      );
    },
  );
}
