import 'package:supabase_flutter/supabase_flutter.dart';

import 'timeout_extension.dart';

/// After profiles RLS was tightened to "own row only", PostgREST embeds like
/// `profiles:requester_id(...)` return null for other users. Attach display
/// fields from [profiles_safe] instead (no lat/lng/role).
Future<List<Map<String, dynamic>>> attachSafeProfiles(
  SupabaseClient client,
  List<dynamic> rows, {
  required String userIdKey,
  String embedKey = 'profiles',
}) async {
  final maps = rows
      .map((row) => Map<String, dynamic>.from(row as Map))
      .toList();
  if (maps.isEmpty) return maps;

  final ids = maps
      .map((row) => row[userIdKey]?.toString())
      .whereType<String>()
      .where((id) => id.isNotEmpty)
      .toSet()
      .toList();
  if (ids.isEmpty) return maps;

  try {
    final profiles = await client
        .from('profiles_safe')
        .select('id, name, avatar_url')
        .inFilter('id', ids)
        .withServerTimeout();

    final byId = <String, Map<String, dynamic>>{
      for (final profile in profiles as List)
        profile['id'].toString(): Map<String, dynamic>.from(profile as Map),
    };

    for (final row in maps) {
      final id = row[userIdKey]?.toString();
      if (id == null) continue;
      final profile = byId[id];
      if (profile == null) continue;
      row[embedKey] = {
        'name': profile['name'],
        'avatar_url': profile['avatar_url'],
      };
    }
  } catch (_) {
    // Leave rows unchanged; UI falls back to "Unknown".
  }

  return maps;
}

Future<Map<String, dynamic>> attachSafeProfile(
  SupabaseClient client,
  Map<String, dynamic> row, {
  required String userIdKey,
  String embedKey = 'profiles',
}) async {
  final enriched = await attachSafeProfiles(
    client,
    [row],
    userIdKey: userIdKey,
    embedKey: embedKey,
  );
  return enriched.first;
}
