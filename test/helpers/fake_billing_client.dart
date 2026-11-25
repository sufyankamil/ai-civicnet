import 'dart:async';

import 'package:civic_net/services/subscription_service.dart';

class FakeBillingClient implements BillingClient {
  final calls = <String>[];
  EntitlementSnapshot? entitlement;
  EntitlementSnapshot? purchaseResult;
  Object? purchaseError;
  Object? plansError;
  Object? restoreError;
  List<BillingPlan> planList = const [];
  final updates = StreamController<EntitlementSnapshot?>.broadcast();

  @override
  Future<void> configure(String apiKey) async => calls.add('configure:$apiKey');

  @override
  Future<EntitlementSnapshot?> logIn(String userId) async {
    calls.add('logIn:$userId');
    return entitlement;
  }

  @override
  Future<void> logOut() async => calls.add('logOut');

  @override
  Future<EntitlementSnapshot?> fetchEntitlement() async => entitlement;

  @override
  Stream<EntitlementSnapshot?> get entitlementUpdates => updates.stream;

  @override
  Future<List<BillingPlan>> fetchPlans() async {
    if (plansError != null) throw plansError!;
    return planList;
  }

  @override
  Future<EntitlementSnapshot?> purchase(String planId) async {
    calls.add('purchase:$planId');
    if (purchaseError != null) throw purchaseError!;
    return purchaseResult;
  }

  @override
  Future<EntitlementSnapshot?> restore() async {
    calls.add('restore');
    if (restoreError != null) throw restoreError!;
    return entitlement;
  }
}

EntitlementSnapshot active({bool trial = false, DateTime? expires}) =>
    EntitlementSnapshot(
      isActive: true,
      isTrial: trial,
      expiresAt: expires ?? DateTime.utc(2027, 1, 1),
      willRenew: true,
    );
