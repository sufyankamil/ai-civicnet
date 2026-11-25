import 'package:civic_net/services/logger_service.dart';
import 'package:civic_net/services/subscription_service.dart';
import 'package:flutter/foundation.dart';

enum PaywallError {
  loadFailed,
  purchaseFailed,
  restoreFailed,
  nothingToRestore,
}

/// Logic behind the paywall screen: loading plans, picking one, buying and
/// restoring. The screen only renders this state.
class PaywallViewModel extends ChangeNotifier {
  PaywallViewModel(this._subscriptions);

  final SubscriptionService _subscriptions;

  bool loading = false;

  /// Billing is not configured (no RevenueCat key), so nothing can be bought.
  bool unavailable = false;

  /// A purchase or restore is in flight.
  bool busy = false;

  bool purchased = false;
  bool restored = false;
  PaywallError? error;

  List<BillingPlan> plans = const [];
  String? selectedId;

  BillingPlan? get selectedPlan {
    for (final plan in plans) {
      if (plan.id == selectedId) return plan;
    }
    return null;
  }

  static bool isBestValue(BillingPlan plan) =>
      plan.period == BillingPeriod.annual;

  Future<void> load() async {
    loading = true;
    error = null;
    unavailable = !_subscriptions.isConfigured;
    notifyListeners();

    if (unavailable) {
      loading = false;
      notifyListeners();
      return;
    }

    try {
      final loaded = await _subscriptions.plans();
      plans = loaded;
      if (loaded.isEmpty) {
        error = PaywallError.loadFailed;
      } else {
        selectedId = (loaded.where(isBestValue).firstOrNull ?? loaded.first).id;
      }
    } catch (e) {
      logger.e('PaywallViewModel: failed to load plans', error: e);
      plans = const [];
      error = PaywallError.loadFailed;
    }

    loading = false;
    notifyListeners();
  }

  void select(String planId) {
    if (!plans.any((p) => p.id == planId)) return;
    selectedId = planId;
    notifyListeners();
  }

  Future<void> purchase() async {
    final plan = selectedPlan;
    if (busy || plan == null) return;

    busy = true;
    error = null;
    notifyListeners();

    try {
      purchased = await _subscriptions.purchase(plan.id);
    } catch (e) {
      logger.e('PaywallViewModel: purchase failed', error: e);
      error = PaywallError.purchaseFailed;
    }

    busy = false;
    notifyListeners();
  }

  Future<void> restore() async {
    if (busy) return;

    busy = true;
    error = null;
    notifyListeners();

    try {
      await _subscriptions.restore();
      if (_subscriptions.isPro) {
        restored = true;
      } else {
        error = PaywallError.nothingToRestore;
      }
    } catch (e) {
      logger.e('PaywallViewModel: restore failed', error: e);
      error = PaywallError.restoreFailed;
    }

    busy = false;
    notifyListeners();
  }
}
