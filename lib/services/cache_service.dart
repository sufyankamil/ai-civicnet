import 'package:hive_flutter/hive_flutter.dart';
import 'package:civic_net/services/logger_service.dart';

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
      logger.i('CacheService initialized successfully');
    } catch (e) {
      logger.e('Failed to initialize CacheService', error: e);
    }
  }

  Future<void> put(String key, dynamic data, {Duration? ttl}) async {
    try {
      final entry = {
        'data': data,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'ttl': ttl?.inMilliseconds,
      };
      await _box.put(key, entry);
      logger.d('Cache entry saved for key: $key${ttl != null ? ' (TTL: ${ttl.inMinutes} mins)' : ''}');
    } catch (e) {
      logger.e('Failed to cache data for key: $key', error: e);
    }
  }

  dynamic get(String key) {
    try {
      final entry = _box.get(key);
      if (entry == null) {
        logger.d('Cache miss for key: $key');
        return null;
      }

      if (_isExpired(entry)) {
        logger.i('Cache entry expired for key: $key. Evicting...');
        _box.delete(key);
        return null;
      }

      logger.d('Cache hit for key: $key');
      return entry['data'];
    } catch (e) {
      logger.e('Failed to retrieve data for key: $key', error: e);
      return null;
    }
  }

  bool _isExpired(dynamic entry) {
    if (entry['ttl'] == null) return false;
    
    final timestamp = DateTime.parse(entry['timestamp']);
    final ttl = Duration(milliseconds: entry['ttl']);
    return DateTime.now().difference(timestamp) > ttl;
  }

  Future<void> delete(String key) async {
    await _box.delete(key);
    logger.d('Cache entry deleted for key: $key');
  }

  Future<void> clear() async {
    await _box.clear();
    logger.i('Global cache cleared');
  }
}
