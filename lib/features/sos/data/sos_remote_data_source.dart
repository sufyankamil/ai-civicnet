import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/sos_models.dart';

abstract class SosRemoteDataSource {
  /// Creates the SOS on the server (which enforces the limits) and returns its id.
  Future<int> createSos({
    required double lat,
    required double lng,
    String? note,
  });

  Future<void> endSos(int id);

  Future<SosStatus> getStatus(int id);
}

/// Talks to the RPCs in `sql_scripts/sos_schema.sql`.
class SupabaseSosRemoteDataSource implements SosRemoteDataSource {
  SupabaseSosRemoteDataSource([this._injected]);

  final SupabaseClient? _injected;

  SupabaseClient get _client => _injected ?? Supabase.instance.client;

  @override
  Future<int> createSos({
    required double lat,
    required double lng,
    String? note,
  }) async {
    final id = await _client.rpc(
      'create_sos',
      params: {'p_lat': lat, 'p_lng': lng, 'p_note': note},
    );
    return (id as num).toInt();
  }

  @override
  Future<void> endSos(int id) async {
    await _client.rpc('end_sos', params: {'p_request_id': id});
  }

  @override
  Future<SosStatus> getStatus(int id) async {
    final row = await _client
        .from('help_requests')
        .select('id, status, sos_alert_count, sos_expires_at')
        .eq('id', id)
        .single();
    return SosStatus(
      id: (row['id'] as num).toInt(),
      alertCount: (row['sos_alert_count'] as num?)?.toInt(),
      expiresAt: DateTime.parse(row['sos_expires_at'] as String).toUtc(),
      closed: row['status'] == 'closed',
    );
  }
}

/// A fresh position for an SOS, asking for location permission if needed.
/// Returns null if the user declines, location is off, or it takes too long.
Future<SosPosition?> currentSosPosition() async {
  try {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 8),
      ),
    );
    return SosPosition(position.latitude, position.longitude);
  } catch (_) {
    try {
      final last = await Geolocator.getLastKnownPosition();
      return last == null ? null : SosPosition(last.latitude, last.longitude);
    } catch (_) {
      return null;
    }
  }
}
