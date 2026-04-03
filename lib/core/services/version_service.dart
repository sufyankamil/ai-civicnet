import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';
import '../../../services/logger_service.dart';
import 'package:flutter/material.dart';

class VersionService {
  static const String _kLastNotifiedVersionKey = 'last_notified_version';

  static final Upgrader _upgrader = Upgrader(
    debugLogging: false,
    durationUntilAlertAgain: const Duration(days: 1),
  );

  static Upgrader get upgrader => _upgrader;

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

  /// Checks if a new version is available on the Store (App Store / Play Store).
  /// Returns the new version string if available, otherwise null.
  static Future<String?> checkStoreUpdateAvailable() async {
    try {
      await _upgrader.initialize();
      final isAvailable = _upgrader.isUpdateAvailable();
      
      if (isAvailable) {
        final storeVersion = _upgrader.currentAppStoreVersion;
        logger.d('Store Update Available: Current: ${_upgrader.currentInstalledVersion} -> Store: $storeVersion');
        return storeVersion;
      }
      
      return null;
    } catch (e) {
      logger.e('Error checking store update', error: e);
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
      title: 'A Stunning New Look',
      description: "We've completely redesigned the 'My Activity' and 'Event Details' screens with a premium, glass-like beautiful aesthetic.",
      icon: Icons.diamond_rounded,
    ),
    UpdateNote(
      title: 'Smarter Directions',
      description: "Getting to events is easier than ever! Tapping an event's location now intelligently opens Apple Maps on iOS or Google Maps on Android.",
      icon: Icons.map_rounded,
    ),
    UpdateNote(
      title: 'Track Your Volunteering',
      description: "Your 'My Activity' dashboard now features beautiful, glowing status badges so you can easily track your accepted and pending requests.",
      icon: Icons.volunteer_activism_rounded,
    ),
  ];
}

