import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';
import 'package:url_launcher/url_launcher.dart';
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
      final currentVersion =
          '${packageInfo.version}+${packageInfo.buildNumber}';

      final prefs = await SharedPreferences.getInstance();
      final lastNotifiedVersion = prefs.getString(_kLastNotifiedVersionKey);

      if (lastNotifiedVersion != currentVersion) {
        logger.d(
          'Update detected: Old Version ($lastNotifiedVersion) -> New Version ($currentVersion)',
        );
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
        logger.d(
          'Store Update Available: Current: ${_upgrader.currentInstalledVersion} -> Store: $storeVersion',
        );
        return storeVersion;
      }

      return null;
    } catch (e) {
      logger.e('Error checking store update', error: e);
      return null;
    }
  }

  /// Opens the store listing directly on App Store (iOS) or Google Play (Android).
  /// Falls back gracefully to the web URL if native store schemes cannot be opened (e.g. on Simulator).
  static Future<bool> openStore() async {
    try {
      final isIos = Platform.isIOS;
      final nativeUri = isIos
          ? Uri.parse('itms-apps://itunes.apple.com/app/id6761416586')
          : Uri.parse('market://details?id=com.sufyankamil.communityNet');

      final webUri = isIos
          ? Uri.parse('https://apps.apple.com/app/id6761416586')
          : Uri.parse(
              'https://play.google.com/store/apps/details?id=com.sufyankamil.communityNet',
            );

      // 1. Try launching native store application scheme
      if (await canLaunchUrl(nativeUri)) {
        final launched = await launchUrl(
          nativeUri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return true;
      }

      // 2. Try launching upgrader's resolved listing URL
      final listingUrl = _upgrader.currentAppStoreListingURL;
      if (listingUrl != null && listingUrl.isNotEmpty) {
        final uri = Uri.parse(listingUrl);
        if (await canLaunchUrl(uri)) {
          final launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          if (launched) return true;
        }
      }

      // 3. Fallback to HTTPS web browser (works reliably on Simulator and all devices)
      if (await canLaunchUrl(webUri)) {
        return await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }

      return false;
    } catch (e) {
      logger.e('Error opening app store listing', error: e);
      return false;
    }
  }

  /// Marks the current version as "notified" in persistent storage.
  static Future<void> markAsNotified() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion =
          '${packageInfo.version}+${packageInfo.buildNumber}';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLastNotifiedVersionKey, currentVersion);
      logger.d('Version $currentVersion marked as notified.');
    } catch (e) {
      logger.e('Error marking version as notified', error: e);
    }
  }

  /// Returns the full version string (e.g. "1.1.5+46") for display.
  static Future<String> getFullVersionString() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return '${packageInfo.version}+${packageInfo.buildNumber}';
    } catch (e) {
      return '1.0.0';
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
      title: 'Aura AI Assistant',
      description:
          "Tap the new glowing floating orb on your Home screen for instant neighborhood intelligence, urgent requests, and borrowable items.",
      icon: Icons.auto_awesome_rounded,
    ),
    UpdateNote(
      title: 'AI-Assisted Support',
      description:
          "Get 24/7 intelligent assistance on opportunity matching, request creation, volunteering, and safety directly in Settings.",
      icon: Icons.support_agent_rounded,
    ),
    UpdateNote(
      title: 'Turbo Chat & Haptics',
      description:
          "Experience ultra-smooth messaging with tactile haptic feedback and streamlined single-capsule input styling.",
      icon: Icons.bolt_rounded,
    ),
  ];
}
