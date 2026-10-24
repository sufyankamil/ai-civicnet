import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'logger_service.dart';

enum ServiceStatus {
  operational,
  degraded,
  outage,
}

enum IncidentSource {
  localDetection,
  remoteCloudStatus,
}

class ServiceIncident {
  final String title;
  final String description;
  final String? lastError;
  final String? lastFailedOperation;
  final DateTime timestamp;
  final IncidentSource source;

  const ServiceIncident({
    required this.title,
    required this.description,
    this.lastError,
    this.lastFailedOperation,
    required this.timestamp,
    required this.source,
  });
}

class OperationLog {
  final String operation;
  final bool isSuccess;
  final String? error;
  final DateTime timestamp;

  const OperationLog({
    required this.operation,
    required this.isSuccess,
    this.error,
    required this.timestamp,
  });
}

class DiagnosticResult {
  final bool isHealthy;
  final int latencyMs;
  final String message;

  const DiagnosticResult({
    required this.isHealthy,
    required this.latencyMs,
    required this.message,
  });
}

class ServiceHealthService extends ChangeNotifier {
  static final ServiceHealthService _instance = ServiceHealthService._internal();
  factory ServiceHealthService() => _instance;
  ServiceHealthService._internal();

  ServiceStatus _status = ServiceStatus.operational;
  ServiceIncident? _activeIncident;
  bool _isBannerDismissed = false;
  int _consecutiveFailures = 0;
  int _consecutiveSuccesses = 0;
  DateTime? _lastFailureTime;
  DateTime? _lastRemoteCheckTime;
  int _lastPingLatencyMs = 0;
  bool _isCheckingRemote = false;

  final List<OperationLog> _recentLogs = [];
  Timer? _periodicRemoteCheckTimer;

  // Getters
  ServiceStatus get status => _status;
  ServiceIncident? get activeIncident => _activeIncident;
  bool get isBannerDismissed => _isBannerDismissed;
  bool get hasActiveIncident => _status != ServiceStatus.operational && _activeIncident != null;
  bool get shouldShowBanner => hasActiveIncident && !_isBannerDismissed;
  int get lastPingLatencyMs => _lastPingLatencyMs;
  List<OperationLog> get recentLogs => List.unmodifiable(_recentLogs);

  /// Initializes periodic cloud status checks
  void initialize() {
    _periodicRemoteCheckTimer?.cancel();
    // Run an initial lightweight cloud status check in background
    checkRemoteStatus();
    // Check cloud status every 15 minutes
    _periodicRemoteCheckTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) => checkRemoteStatus(),
    );
  }

  /// Records a successful data operation (GET, POST, UPDATE)
  void recordSuccess({required String operation}) {
    _addLog(OperationLog(
      operation: operation,
      isSuccess: true,
      timestamp: DateTime.now(),
    ));

    _consecutiveSuccesses++;
    if (_consecutiveFailures > 0) {
      _consecutiveFailures = 0;
    }

    // Auto-recovery: if local degraded state and 2 consecutive successes happen
    if (_status != ServiceStatus.operational &&
        _activeIncident?.source == IncidentSource.localDetection &&
        _consecutiveSuccesses >= 2) {
      logger.i('Service Health Auto-Recovery: Back to operational after successful operations.');
      _status = ServiceStatus.operational;
      _activeIncident = null;
      _isBannerDismissed = false;
      notifyListeners();
    }
  }

  /// Records a failed data operation (GET, POST, UPDATE)
  void recordFailure({
    required String operation,
    required dynamic error,
    StackTrace? stackTrace,
  }) {
    final now = DateTime.now();
    final errStr = error.toString();

    _addLog(OperationLog(
      operation: operation,
      isSuccess: false,
      error: errStr,
      timestamp: now,
    ));

    _consecutiveFailures++;
    _consecutiveSuccesses = 0;
    _lastFailureTime = now;

    logger.w(
      'ServiceHealth: Failure on $operation (Consecutive: $_consecutiveFailures). Error: $errStr',
    );

    final isSevereServerIssue = _isServerIssue(errStr, error);

    // Trigger banner if 5xx/server error OR >= 2 consecutive failures
    if (isSevereServerIssue || _consecutiveFailures >= 2) {
      // If previously dismissed but a brand new failure happened > 3 minutes later, un-dismiss
      if (_isBannerDismissed && _lastFailureTime != null && now.difference(_lastFailureTime!).inMinutes > 3) {
        _isBannerDismissed = false;
      }

      _status = _consecutiveFailures >= 4 ? ServiceStatus.outage : ServiceStatus.degraded;
      _activeIncident = ServiceIncident(
        title: 'We are investigating a technical issue',
        description: 'Some features may take longer than usual to load while our team investigates.',
        lastError: errStr,
        lastFailedOperation: operation,
        timestamp: now,
        source: IncidentSource.localDetection,
      );

      notifyListeners();

      // Proactively check if Supabase declared an official incident
      checkRemoteStatus(force: true);
    }
  }

  bool _isServerIssue(String errStr, dynamic error) {
    if (errStr.contains('500') ||
        errStr.contains('502') ||
        errStr.contains('503') ||
        errStr.contains('504') ||
        errStr.contains('ServerException') ||
        errStr.contains('SocketException') ||
        errStr.contains('TimeoutException') ||
        errStr.contains('Connection refused') ||
        errStr.contains('Failed host lookup') ||
        errStr.contains('network_error')) {
      return true;
    }
    return false;
  }

  /// Queries Supabase official status API
  Future<void> checkRemoteStatus({bool force = false}) async {
    if (_isCheckingRemote) return;

    final now = DateTime.now();
    if (!force && _lastRemoteCheckTime != null && now.difference(_lastRemoteCheckTime!).inMinutes < 15) {
      return;
    }

    _isCheckingRemote = true;
    _lastRemoteCheckTime = now;

    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final request = await client.getUrl(
        Uri.parse('https://status.supabase.com/api/v2/summary.json'),
      );
      final response = await request.close().timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body) as Map<String, dynamic>;

        final statusMap = data['status'] as Map<String, dynamic>?;
        final indicator = statusMap?['indicator']?.toString().toLowerCase() ?? 'none';

        final incidents = (data['incidents'] as List<dynamic>?) ?? [];

        // Check for active incidents that directly affect app runtime services
        Map<String, dynamic>? activeClientIncident;
        for (final inc in incidents) {
          if (inc is Map<String, dynamic>) {
            final name = (inc['name']?.toString() ?? '').toLowerCase();
            final impact = (inc['impact']?.toString() ?? '').toLowerCase();

            // Exclude backend developer/management portal incidents (do not impact mobile client)
            final isDevOpsOnly = name.contains('mgmt api') ||
                name.contains('management api') ||
                name.contains('branching') ||
                name.contains('billing') ||
                name.contains('cli') ||
                name.contains('studio') ||
                name.contains('dashboard') ||
                name.contains('project creation') ||
                name.contains('project resize');

            if (isDevOpsOnly) continue;

            final components = (inc['components'] as List<dynamic>?) ?? [];
            final affectsRuntime = components.any((c) {
              final cName = (c['name']?.toString() ?? '').toLowerCase();
              return cName.contains('data api') ||
                  cName.contains('postgres') ||
                  cName.contains('auth') ||
                  cName.contains('realtime');
            });

            if (affectsRuntime || impact == 'major' || impact == 'critical') {
              activeClientIncident = inc;
              break;
            }
          }
        }

        final isMajorOutage = indicator == 'major' || indicator == 'critical';
        final isDegraded = indicator == 'minor' || activeClientIncident != null;

        if (isMajorOutage || isDegraded) {
          final isCritical = isMajorOutage ||
              (activeClientIncident?['impact']?.toString().toLowerCase() == 'critical');

          _status = isCritical ? ServiceStatus.outage : ServiceStatus.degraded;
          _activeIncident = ServiceIncident(
            title: isCritical
                ? 'Temporary Service Disruption'
                : 'Temporary Service Slowdown',
            description: isCritical
                ? 'We are experiencing temporary service interruptions. Feeds and messaging may be delayed.'
                : 'Some community updates and requests may take a moment to sync. Our team is actively monitoring.',
            timestamp: now,
            source: IncidentSource.remoteCloudStatus,
          );
          notifyListeners();
        } else if (_status != ServiceStatus.operational && _activeIncident?.source == IncidentSource.remoteCloudStatus) {
          // Cloud incident resolved or irrelevant to mobile runtime
          _status = ServiceStatus.operational;
          _activeIncident = null;
          _isBannerDismissed = false;
          notifyListeners();
        }
      }
      client.close();
    } catch (e) {
      logger.d('ServiceHealth: Remote status check skipped/failed ($e)');
    } finally {
      _isCheckingRemote = false;
    }
  }

  /// Runs an active live diagnostic round-trip ping to the database
  Future<DiagnosticResult> runDiagnostics() async {
    final sw = Stopwatch()..start();
    try {
      // Lightweight probe: Select 1 profile row or timestamp
      await Supabase.instance.client
          .from('profiles')
          .select('id')
          .limit(1)
          .timeout(const Duration(seconds: 5));

      sw.stop();
      _lastPingLatencyMs = sw.elapsedMilliseconds;
      _consecutiveFailures = 0;

      // If remote cloud check is also ok, clear degraded state
      await checkRemoteStatus(force: true);

      if (_activeIncident?.source != IncidentSource.remoteCloudStatus) {
        _status = ServiceStatus.operational;
        _activeIncident = null;
        _isBannerDismissed = false;
      }

      notifyListeners();
      return DiagnosticResult(
        isHealthy: true,
        latencyMs: _lastPingLatencyMs,
        message: 'Connection verified: Response latency is ${_lastPingLatencyMs}ms',
      );
    } catch (e) {
      sw.stop();
      final latency = sw.elapsedMilliseconds;
      _consecutiveFailures++;
      _status = ServiceStatus.degraded;
      _activeIncident = ServiceIncident(
        title: 'We are investigating a technical issue',
        description: 'Connection probe failed ($latency ms). Database unreachable.',
        lastError: e.toString(),
        lastFailedOperation: 'Diagnostic Ping',
        timestamp: DateTime.now(),
        source: IncidentSource.localDetection,
      );
      notifyListeners();
      return DiagnosticResult(
        isHealthy: false,
        latencyMs: latency,
        message: 'Connection failed: $e',
      );
    }
  }

  void dismissBanner() {
    _isBannerDismissed = true;
    notifyListeners();
  }

  void restoreBanner() {
    _isBannerDismissed = false;
    notifyListeners();
  }

  void _addLog(OperationLog log) {
    _recentLogs.insert(0, log);
    if (_recentLogs.length > 15) {
      _recentLogs.removeLast();
    }
  }

  @override
  void dispose() {
    _periodicRemoteCheckTimer?.cancel();
    super.dispose();
  }
}
