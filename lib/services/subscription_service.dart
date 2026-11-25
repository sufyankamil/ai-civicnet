import 'dart:async';

import 'package:civic_net/services/logger_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// RevenueCat entitlement that unlocks CivicNet Pro.
const proEntitlementId = 'pro';

/// What the billing layer knows about the user's Pro entitlement.
class EntitlementSnapshot {
  const EntitlementSnapshot({
    required this.isActive,
    required this.isTrial,
    required this.expiresAt,
    required this.willRenew,
  });

  final bool isActive;
  final bool isTrial;

  /// Null for entitlements that never expire.
  final DateTime? expiresAt;
  final bool willRenew;
}

/// The user's subscription as the UI sees it.
@immutable
class SubscriptionState {
  const SubscriptionState({
    required this.isPro,
    required this.isTrialing,
    required this.expiresAt,
    required this.willRenew,
  });

  static const free = SubscriptionState(
    isPro: false,
    isTrialing: false,
    expiresAt: null,
    willRenew: false,
  );

  final bool isPro;
  final bool isTrialing;
  final DateTime? expiresAt;
  final bool willRenew;

  factory SubscriptionState.fromSnapshot(
    EntitlementSnapshot? snapshot, {
    required DateTime now,
  }) {
    if (snapshot == null || !snapshot.isActive) return free;
    final expires = snapshot.expiresAt;
    // Defensive: never trust a snapshot whose period already ended.
    if (expires != null && !expires.isAfter(now)) return free;
    return SubscriptionState(
      isPro: true,
      isTrialing: snapshot.isTrial,
      expiresAt: expires,
      willRenew: snapshot.willRenew,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SubscriptionState &&
      other.isPro == isPro &&
      other.isTrialing == isTrialing &&
      other.expiresAt == expiresAt &&
      other.willRenew == willRenew;

  @override
  int get hashCode => Object.hash(isPro, isTrialing, expiresAt, willRenew);
}

/// A purchasable plan shown on the paywall (Phase 3).
class BillingPlan {
  const BillingPlan({
    required this.id,
    required this.title,
    required this.priceString,
    required this.hasFreeTrial,
  });

  final String id;
  final String title;
  final String priceString;
  final bool hasFreeTrial;
}

class SubscriptionUnavailableException implements Exception {
  const SubscriptionUnavailableException();

  @override
  String toString() =>
      'SubscriptionUnavailableException: billing is not configured';
}

class PurchaseCancelledException implements Exception {
  const PurchaseCancelledException();
}

/// Seam over the billing SDK so the service can be unit tested.
abstract class BillingClient {
  Future<void> configure(String apiKey);
  Future<EntitlementSnapshot?> logIn(String userId);
  Future<void> logOut();
  Future<EntitlementSnapshot?> fetchEntitlement();
  Stream<EntitlementSnapshot?> get entitlementUpdates;
  Future<List<BillingPlan>> fetchPlans();

  /// Throws [PurchaseCancelledException] if the user backs out.
  Future<EntitlementSnapshot?> purchase(String planId);
  Future<EntitlementSnapshot?> restore();
}

/// Tracks whether the signed-in user has CivicNet Pro.
///
/// Stays dormant (everyone is free, nothing is called) until a RevenueCat SDK
/// key is configured, so the app runs fine before billing is set up. The
/// server is the source of truth for AI quota (see the revenuecat-webhook edge
/// function); this state only drives the UI.
class SubscriptionService extends ChangeNotifier {
  static final SubscriptionService _instance = SubscriptionService._internal(
    RevenueCatBillingClient(),
    DateTime.now,
  );
  factory SubscriptionService() => _instance;

  SubscriptionService._internal(this._client, this._now);

  @visibleForTesting
  factory SubscriptionService.forTest(
    BillingClient client, {
    DateTime Function()? now,
  }) => SubscriptionService._internal(client, now ?? DateTime.now);

  final BillingClient _client;
  final DateTime Function() _now;

  StreamSubscription<EntitlementSnapshot?>? _updatesSub;
  bool _configured = false;
  String? _userId;
  // Distinguishes "never synced" from "synced as signed out": RevenueCat
  // remembers the last user across launches, so a signed-out start must still
  // log that user out.
  bool _hasSynced = false;
  SubscriptionState _state = SubscriptionState.free;

  bool get isConfigured => _configured;
  SubscriptionState get state => _state;
  bool get isPro => _state.isPro;

  /// [apiKey] is the public RevenueCat SDK key for this platform. Null or
  /// empty leaves billing off.
  Future<void> initialize({required String? apiKey}) async {
    if (_configured) return;
    if (apiKey == null || apiKey.isEmpty) {
      logger.i('SubscriptionService: no RevenueCat key, billing disabled');
      return;
    }

    try {
      await _client.configure(apiKey);
      _configured = true;
      _updatesSub = _client.entitlementUpdates.listen(_apply);
      _apply(await _client.fetchEntitlement());
    } catch (e) {
      _configured = false;
      logger.e('SubscriptionService: failed to initialize', error: e);
    }
  }

  /// Keeps RevenueCat's user in step with the Supabase user. The ids must
  /// match: the webhook uses RevenueCat's app user id as `subscriptions.user_id`.
  Future<void> syncUser(String? userId) async {
    if (!_configured || (_hasSynced && userId == _userId)) return;
    try {
      if (userId == null) {
        await _client.logOut();
        _userId = null;
        _hasSynced = true;
        _apply(null);
      } else {
        final snapshot = await _client.logIn(userId);
        _userId = userId;
        _hasSynced = true;
        _apply(snapshot);
      }
    } catch (e) {
      logger.e('SubscriptionService: failed to sync user', error: e);
    }
  }

  Future<List<BillingPlan>> plans() async {
    if (!_configured) return const [];
    return _client.fetchPlans();
  }

  /// Returns true when the purchase succeeded, false if the user cancelled.
  Future<bool> purchase(String planId) async {
    if (!_configured) throw const SubscriptionUnavailableException();
    try {
      _apply(await _client.purchase(planId));
      return true;
    } on PurchaseCancelledException {
      return false;
    }
  }

  Future<void> restore() async {
    if (!_configured) throw const SubscriptionUnavailableException();
    _apply(await _client.restore());
  }

  void _apply(EntitlementSnapshot? snapshot) {
    final next = SubscriptionState.fromSnapshot(snapshot, now: _now());
    if (next == _state) return;
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _updatesSub?.cancel();
    super.dispose();
  }
}

/// [BillingClient] backed by RevenueCat (`purchases_flutter`).
class RevenueCatBillingClient implements BillingClient {
  final _updates = StreamController<EntitlementSnapshot?>.broadcast();
  List<Package> _packages = const [];

  @override
  Future<void> configure(String apiKey) async {
    await Purchases.configure(PurchasesConfiguration(apiKey));
    Purchases.addCustomerInfoUpdateListener(
      (info) => _updates.add(_snapshot(info)),
    );
  }

  @override
  Future<EntitlementSnapshot?> logIn(String userId) async =>
      _snapshot((await Purchases.logIn(userId)).customerInfo);

  @override
  Future<void> logOut() async {
    // logOut throws if the current user is already anonymous.
    if (await Purchases.isAnonymous) return;
    await Purchases.logOut();
  }

  @override
  Future<EntitlementSnapshot?> fetchEntitlement() async =>
      _snapshot(await Purchases.getCustomerInfo());

  @override
  Stream<EntitlementSnapshot?> get entitlementUpdates => _updates.stream;

  @override
  Future<List<BillingPlan>> fetchPlans() async {
    final offerings = await Purchases.getOfferings();
    _packages = offerings.current?.availablePackages ?? const [];
    return _packages
        .map(
          (p) => BillingPlan(
            id: p.identifier,
            title: p.storeProduct.title,
            priceString: p.storeProduct.priceString,
            hasFreeTrial: (p.storeProduct.introductoryPrice?.price ?? 1) == 0,
          ),
        )
        .toList();
  }

  @override
  Future<EntitlementSnapshot?> purchase(String planId) async {
    if (_packages.isEmpty) await fetchPlans();
    final package = _packages.firstWhere(
      (p) => p.identifier == planId,
      orElse: () => throw ArgumentError('Unknown plan: $planId'),
    );
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      return _snapshot(result.customerInfo);
    } on PlatformException catch (e) {
      if (PurchasesErrorHelper.getErrorCode(e) ==
          PurchasesErrorCode.purchaseCancelledError) {
        throw const PurchaseCancelledException();
      }
      rethrow;
    }
  }

  @override
  Future<EntitlementSnapshot?> restore() async =>
      _snapshot(await Purchases.restorePurchases());

  EntitlementSnapshot? _snapshot(CustomerInfo info) {
    final entitlement = info.entitlements.active[proEntitlementId];
    if (entitlement == null) return null;
    return EntitlementSnapshot(
      isActive: entitlement.isActive,
      isTrial: entitlement.periodType == PeriodType.trial,
      expiresAt: entitlement.expirationDate == null
          ? null
          : DateTime.tryParse(entitlement.expirationDate!),
      willRenew: entitlement.willRenew,
    );
  }
}
