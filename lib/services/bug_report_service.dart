import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'logger_service.dart';
import '../core/routes/app_router.dart';

class BugReportService {
  static final BugReportService _instance = BugReportService._internal();
  factory BugReportService() => _instance;
  BugReportService._internal();

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  Future<Map<String, dynamic>> collectMetadata() async {
    final Map<String, dynamic> metadata = {};

    try {
      // 1. App Info
      final packageInfo = await PackageInfo.fromPlatform();
      metadata['app'] = {
        'name': packageInfo.appName,
        'package': packageInfo.packageName,
        'version': packageInfo.version,
        'build_number': packageInfo.buildNumber,
      };

      // 2. Device Info
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        metadata['device'] = {
          'platform': 'Android',
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'version': androidInfo.version.release,
          'sdk': androidInfo.version.sdkInt,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        metadata['device'] = {
          'platform': 'iOS',
          'model': iosInfo.utsname.machine,
          'version': iosInfo.systemVersion,
          'name': iosInfo.name,
        };
      } else {
        metadata['device'] = {
          'platform': kIsWeb ? 'Web' : Platform.operatingSystem,
        };
      }

      // 3. Connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      metadata['connectivity'] = connectivityResult.map((e) => e.name).toList();

      // 4. Current Screen
      // Using our custom tracker since Get.currentRoute might be empty with GoRouter
      metadata['screen'] = lastAppLocation;

      // 5. Theme Info
      metadata['theme'] = Get.isDarkMode ? 'dark' : 'light';

      // 6. Log History
      metadata['logs'] = getLogHistory();

      // 7. Timestamp
      metadata['timestamp'] = DateTime.now().toUtc().toIso8601String();
      
      logger.i('Enhanced bug report metadata collected successfully');
    } catch (e) {
      logger.e('Error collecting bug report metadata: $e');
      metadata['error'] = 'Failed to collect full metadata: $e';
    }

    return metadata;
  }
}
