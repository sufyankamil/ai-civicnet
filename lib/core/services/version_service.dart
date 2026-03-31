import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/logger_service.dart';
import 'package:flutter/material.dart';

class VersionService {
  static const String _kLastNotifiedVersionKey = 'last_notified_version';

  /// Compares the current app version with the last version the user was notified about.
  /// Returns null if no update is needed, otherwise returns the current version string.
  static Future<String?> checkUpdateNeeded() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
      
      final prefs = await SharedPreferences.getInstance();
      final lastNotifiedVersion = prefs.getString(_kLastNotifiedVersionKey);

      if (lastNotifiedVersion != currentVersion) {
        logger.d('Update detected: Old Version ($lastNotifiedVersion) -> New Version ($currentVersion)');
        return currentVersion;
      }
      
      return null;
    } catch (e) {
      logger.e('Error checking version update', error: e);
      return null;
    }
  }

  /// Marks the current version as "notified" in persistent storage.
  static Future<void> markAsNotified() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLastNotifiedVersionKey, currentVersion);
      logger.d('Version $currentVersion marked as notified.');
    } catch (e) {
      logger.e('Error marking version as notified', error: e);
    }
  }
}

class UpdateNote {
  final String title;
  final String description;
  final IconData icon;

  UpdateNote({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class AppUpdates {
  static List<UpdateNote> get currentUpdates => [
    UpdateNote(
      title: 'Delete for Me',
      description: 'Clear your own chat history and hide conversations without affecting the other participant.',
      icon: Icons.delete_sweep_rounded,
    ),
    UpdateNote(
      title: 'Modernized Tech Stack',
      description: 'Upgraded core Firebase and notification services to the latest major versions for better stability.',
      icon: Icons.system_update_rounded,
    ),
  ];
}

