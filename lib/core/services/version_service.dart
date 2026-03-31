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
      title: 'Enhanced Asset Cards',
      description: 'Better visibility for community assets with improved layouts and longer titles.',
      icon: Icons.auto_awesome_mosaic_outlined,
    ),
    UpdateNote(
      title: 'Priority Status',
      description: 'Your application status is now pinned to the top of help requests for quick tracking.',
      icon: Icons.notification_important_outlined,
    ),
  ];
}

