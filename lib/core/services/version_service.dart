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
      title: 'AI Neighborhood Connection',
      description: "Experience 'AI RECOMMENDED' matches that highlight the best ways to help your neighbors with a glowing personalized touch.",
      icon: Icons.auto_awesome_rounded,
    ),
    UpdateNote(
      title: 'Enhanced Home Screen',
      description: "A refined header and subtitle system that shows you exactly what's happening 'near you' at a single glance.",
      icon: Icons.home_rounded,
    ),
    UpdateNote(
      title: 'Dark Mode Perfection',
      description: 'Reimagined category filters with higher contrast and better visibility, specifically tuned for a premium dark mode experience.',
      icon: Icons.dark_mode_rounded,
    ),
    UpdateNote(
      title: 'Privacy & Transparency',
      description: 'Updated location permission flows and clearer descriptions to ensure you always know how your data is being used.',
      icon: Icons.privacy_tip_rounded,
    ),
  ];
}

