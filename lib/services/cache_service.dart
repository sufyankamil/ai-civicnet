import 'package:hive_flutter/hive_flutter.dart';
import 'package:community_net/services/logger_service.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  static const String _boxName = 'app_cache';
  late Box _box;

  Future<void> initialize() async {
    try {
      await Hive.initFlutter();
      _box = await Hive.openBox(_boxName);
      logger.i('CacheService initialized');
    } catch (e) {
      logger.e('Failed to initialize CacheService', error: e);
    }
  }

  Future<void> put(String key, dynamic data, {Duration? ttl}) async {
    try {
      final entry = {
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
        'ttl': ttl?.inMilliseconds,
      };
      await _box.put(key, entry);
    } catch (e) {
      logger.e('Failed to cache data for key: $key', error: e);
    }
  }

  dynamic get(String key) {
    try {
      final entry = _box.get(key);
      if (entry == null) return null;

      // Check TTL if exists
      if (entry['ttl'] != null) {
        final timestamp = DateTime.parse(entry['timestamp']);
        final ttl = Duration(milliseconds: entry['ttl']);
        if (DateTime.now().difference(timestamp) > ttl) {
          _box.delete(key);
          return null;
        }
      }
      return entry['data'];
    } catch (e) {
      logger.e('Failed to retrieve data for key: $key', error: e);
      return null;
    }
  }

  Future<void> clear() async {
    await _box.clear();
  }
}
