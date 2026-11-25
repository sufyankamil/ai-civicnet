import 'package:civic_net/services/logger_service.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The signed-in user's monthly AI quota, as reported by the server's
/// `get_ai_quota_status` function. Display only: the ai-proxy enforces it.
@immutable
class AiQuotaStatus {
  const AiQuotaStatus({
    required this.used,
    required this.limit,
    required this.resetsAt,
    required this.isPro,
    required this.enforced,
  });

  factory AiQuotaStatus.fromJson(Map<String, dynamic> json) {
    final resets = json['resets_at'];
    return AiQuotaStatus(
      used: (json['used'] as num?)?.toInt() ?? 0,
      limit: (json['quota_limit'] as num?)?.toInt() ?? 0,
      resetsAt: resets is String ? DateTime.tryParse(resets)?.toUtc() : null,
      isPro: json['is_pro'] == true,
      enforced: json['enforced'] != false,
    );
  }

  final int used;
  final int limit;
  final DateTime? resetsAt;
  final bool isPro;
  final bool enforced;

  int get remaining => (limit - used).clamp(0, limit);

  /// No cap applies: Pro, or the paywall is switched off server-side.
  bool get isUnlimited => isPro || !enforced;

  @override
  bool operator ==(Object other) =>
      other is AiQuotaStatus &&
      other.used == used &&
      other.limit == limit &&
      other.resetsAt == resetsAt &&
      other.isPro == isPro &&
      other.enforced == enforced;

  @override
  int get hashCode => Object.hash(used, limit, resetsAt, isPro, enforced);
}

typedef AiQuotaFetcher = Future<Map<String, dynamic>?> Function();

class AiQuotaService extends ChangeNotifier {
  static final AiQuotaService _instance = AiQuotaService._internal(
    _fetchFromSupabase,
  );
  factory AiQuotaService() => _instance;

  AiQuotaService._internal(this._fetch);

  @visibleForTesting
  factory AiQuotaService.forTest(AiQuotaFetcher fetcher) =>
      AiQuotaService._internal(fetcher);

  final AiQuotaFetcher _fetch;

  AiQuotaStatus? _status;
  AiQuotaStatus? get status => _status;

  /// Re-reads the quota. Keeps the last known value if the call fails, and
  /// clears it when nobody is signed in.
  Future<void> refresh() async {
    try {
      final row = await _fetch();
      _set(row == null ? null : AiQuotaStatus.fromJson(row));
    } catch (e) {
      logger.w('AiQuotaService: could not refresh quota', error: e);
    }
  }

  void _set(AiQuotaStatus? next) {
    if (next == _status) return;
    _status = next;
    notifyListeners();
  }

  static Future<Map<String, dynamic>?> _fetchFromSupabase() async {
    final client = Supabase.instance.client;
    if (client.auth.currentUser == null) return null;
    final data = await client.rpc('get_ai_quota_status');
    if (data is List && data.isNotEmpty) {
      return Map<String, dynamic>.from(data.first as Map);
    }
    return null;
  }
}
