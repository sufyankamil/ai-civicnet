import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../services/subscription_service.dart';
import '../../../../services/toast_service.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/haptic_buttons.dart';
import '../viewmodels/paywall_viewmodel.dart';

/// Where CivicNet Pro is explained and bought. Everyone sees the plans; Pro
/// members see their status instead.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key, this.subscriptions});

  /// Injected in tests; defaults to the app-wide [SubscriptionService].
  final SubscriptionService? subscriptions;

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  late final SubscriptionService _subscriptions =
      widget.subscriptions ?? SubscriptionService();
  late final PaywallViewModel _vm = PaywallViewModel(_subscriptions);
  bool _celebrated = false;

  @override
  void initState() {
    super.initState();
    _vm.addListener(_onViewModelChanged);
    _vm.load();
  }

  @override
  void dispose() {
    _vm.removeListener(_onViewModelChanged);
    _vm.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (_celebrated || !(_vm.purchased || _vm.restored)) return;
    _celebrated = true;
    if (!mounted) return;
    ToastService.showSuccess(
      context,
      AppLocalizations.of(context)!.paywallWelcome,
    );
    Navigator.of(context).maybePop();
  }

  Future<void> _openManageSubscription() async {
    final url = defaultTargetPlatform == TargetPlatform.android
        ? 'https://play.google.com/store/account/subscriptions'
        : 'https://apps.apple.com/account/subscriptions';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([_vm, _subscriptions]),
          builder: (context, _) {
            final isPro = _subscriptions.isPro;
            return Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    children: [
                      const _Hero(),
                      const SizedBox(height: 24),
                      if (isPro)
                        _ProStatus(
                          state: _subscriptions.state,
                          onManage: _openManageSubscription,
                        )
                      else
                        ..._buildPlans(context),
                    ],
                  ),
                ),
                // The buy button stays visible however long the content is.
                if (!isPro && _canBuy) _buildBuyBar(context),
              ],
            );
          },
        ),
      ),
    );
  }

  bool get _canBuy => !_vm.loading && !_vm.unavailable && _vm.plans.isNotEmpty;

  List<Widget> _buildPlans(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    if (_vm.loading) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (_vm.unavailable) {
      return [_Message(text: l10n.paywallUnavailable)];
    }

    if (_vm.plans.isEmpty) {
      return [
        _Message(text: l10n.paywallLoadFailed),
        const SizedBox(height: 12),
        Center(
          child: OutlinedButton(
            onPressed: _vm.load,
            child: Text(l10n.paywallRetry),
          ),
        ),
      ];
    }

    return [
      for (final plan in _vm.plans) ...[
        _PlanCard(
          plan: plan,
          selected: plan.id == _vm.selectedId,
          onTap: _vm.busy ? null : () => _vm.select(plan.id),
        ),
        const SizedBox(height: 12),
      ],
      if (_vm.error != null) ...[
        _Message(text: _errorText(l10n, _vm.error!), isError: true),
        const SizedBox(height: 12),
      ],
      const SizedBox(height: 4),
      Text(
        l10n.paywallDisclosure,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, height: 1.4, color: secondary),
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: () => context.push('/terms-of-service'),
            child: Text(l10n.termsAndConditions),
          ),
          Text('•', style: TextStyle(color: secondary)),
          TextButton(
            onPressed: () => context.push('/privacy-policy'),
            child: Text(l10n.privacyPolicy),
          ),
        ],
      ),
    ];
  }

  Widget _buildBuyBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selected = _vm.selectedPlan;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _vm.busy || selected == null
                  ? null
                  : () {
                      AppHaptic.mediumImpact();
                      _vm.purchase();
                    },
              child: _vm.busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Text(
                      (selected?.hasFreeTrial ?? false)
                          ? l10n.paywallCtaTrial
                          : l10n.paywallCtaSubscribe,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          TextButton(
            onPressed: _vm.busy ? null : _vm.restore,
            child: Text(l10n.paywallRestore),
          ),
        ],
      ),
    );
  }

  String _errorText(AppLocalizations l10n, PaywallError error) =>
      switch (error) {
        PaywallError.loadFailed => l10n.paywallLoadFailed,
        PaywallError.purchaseFailed => l10n.paywallPurchaseFailed,
        PaywallError.restoreFailed => l10n.paywallRestoreFailed,
        PaywallError.nothingToRestore => l10n.paywallNothingToRestore,
      };
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: AppColors.auraGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.auraPrimary.withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 34,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.paywallTitle,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.paywallSubtitle,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: secondary),
        ),
        const SizedBox(height: 20),
        _Benefit(text: l10n.paywallBenefitAssistant),
        _Benefit(text: l10n.paywallBenefitVoice),
        _Benefit(text: l10n.paywallBenefitBriefing),
        _Benefit(text: l10n.paywallBenefitSupport),
      ],
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 20,
            color: AppColors.auraPrimary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final BillingPlan plan;
  final bool selected;
  final VoidCallback? onTap;

  String _priceLine(AppLocalizations l10n) {
    final period = switch (plan.period) {
      BillingPeriod.monthly => l10n.paywallPerMonth,
      BillingPeriod.annual => l10n.paywallPerYear,
      BillingPeriod.other => '',
    };
    final days = plan.trialDays;
    if (plan.hasFreeTrial && days != null) {
      return l10n.paywallTrialPriceLine(days, plan.priceString, period).trim();
    }
    return l10n.paywallPriceLine(plan.priceString, period).trim();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final primary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.auraPrimary
                : secondary.withValues(alpha: 0.25),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? AppColors.auraPrimary : secondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          plan.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: primary,
                          ),
                        ),
                      ),
                      if (PaywallViewModel.isBestValue(plan)) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.auraPrimary.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            l10n.paywallBestValue,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.auraPrimary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _priceLine(l10n),
                    style: TextStyle(fontSize: 13, color: secondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProStatus extends StatelessWidget {
  const _ProStatus({required this.state, required this.onManage});

  final SubscriptionState state;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    final expires = state.expiresAt;
    final date = expires == null
        ? null
        : DateFormat.yMMMd(
            Localizations.localeOf(context).toString(),
          ).format(expires.toLocal());

    return Column(
      children: [
        Text(
          l10n.paywallProActive,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: primary,
          ),
        ),
        if (state.isTrialing) ...[
          const SizedBox(height: 6),
          Text(
            l10n.paywallProTrialing,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.auraPrimary,
            ),
          ),
        ],
        if (date != null) ...[
          const SizedBox(height: 6),
          Text(
            state.willRenew
                ? l10n.paywallRenewsOn(date)
                : l10n.paywallEndsOn(date),
            style: TextStyle(fontSize: 13, color: secondary),
          ),
        ],
        const SizedBox(height: 20),
        OutlinedButton(onPressed: onManage, child: Text(l10n.paywallManage)),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.isError = false});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 14,
        color: isError
            ? (isDark ? AppColors.accentDark : AppColors.accentLight)
            : (isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight),
      ),
    );
  }
}
