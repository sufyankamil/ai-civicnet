import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/widgets.dart'; // For WidgetsFlutterBinding
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:civic_net/services/firebase_service.dart';
import 'package:civic_net/services/cache_service.dart';
import 'package:civic_net/services/logger_service.dart';
import 'package:civic_net/services/notification_service.dart';
import 'package:civic_net/services/encryption_service.dart';
import 'package:civic_net/services/ai_service.dart';
import 'package:civic_net/services/service_health_service.dart';
import 'package:civic_net/services/subscription_service.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';

class StartupService {
  static final StartupService _instance = StartupService._internal();
  factory StartupService() => _instance;
  StartupService._internal();

  bool _isInitialized = false;

  Future<void> initialize() async {
    // Always reschedule the daily notification (outside _isInitialized guard)
    // so a code change to the schedule time takes effect on the next cold start.
    if (_isInitialized) {
      await NotificationService().scheduleDailyCheckInNotification();
      return;
    }

    final stopwatch = Stopwatch()..start();
    logger.i('Starting App Initialization...');

    EncryptionService().initialize();
    logger.i('Encryption Service initialized');

    // 1. Firebase Core
    await Firebase.initializeApp();
    logger.i('Firebase Core initialized (${stopwatch.elapsedMilliseconds}ms)');

    // 2. AiService
    AiService().initialize();
    logger.i('AiService initialized (${stopwatch.elapsedMilliseconds}ms)');

    // 2. Crashlytics Setup
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // 3. Supabase with Custom Device Info
    final deviceInfo = await _getDeviceInfoString();
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      headers: {'User-Agent': deviceInfo},
    );
    logger.i(
      'Supabase initialized with Device Info: $deviceInfo (${stopwatch.elapsedMilliseconds}ms)',
    );

    // Billing: does not block startup and stays off until an SDK key is set.
    unawaited(_initBilling());

    // 4. Parallel Services (FirebaseService also calls NotificationService().initialize())
    await Future.wait([
      FirebaseService().initialize(),
      CacheService().initialize(),
    ]);

    // Schedule the daily notification after other services are up
    await NotificationService().scheduleDailyCheckInNotification();

    // 5. Service Health & Cloud Telemetry Monitor
    ServiceHealthService().initialize();

    logger.i('All Services initialized in ${stopwatch.elapsedMilliseconds}ms');
    _isInitialized = true;
  }

  /// Starts RevenueCat and keeps its user in step with the Supabase session.
  /// The RevenueCat user id must equal the Supabase user id: the
  /// revenuecat-webhook edge function writes `subscriptions` by that id.
  Future<void> _initBilling() async {
    final subscriptions = SubscriptionService();
    final apiKey = switch (kIsWeb ? null : defaultTargetPlatform) {
      TargetPlatform.iOS => dotenv.env['REVENUECAT_IOS_API_KEY'],
      TargetPlatform.android => dotenv.env['REVENUECAT_ANDROID_API_KEY'],
      _ => null,
    };
    await subscriptions.initialize(apiKey: apiKey);

    final auth = Supabase.instance.client.auth;
    await subscriptions.syncUser(auth.currentUser?.id);
    auth.onAuthStateChange.listen(
      (data) => subscriptions.syncUser(data.session?.user.id),
    );
  }

  /// Constructs a custom User-Agent string for device tracking:
  /// "CivicNet/1.1.5 (iPhone 16 Pro; iOS 17.5)"
  Future<String> _getDeviceInfoString() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final devicePlugin = DeviceInfoPlugin();
      String deviceModel = 'Unknown Device';
      String osSystem = 'Unknown OS';

      if (Platform.isIOS) {
        final iosInfo = await devicePlugin.iosInfo;
        deviceModel = iosInfo.utsname.machine; // e.g., "iPhone15,3"
        // Try to map machine name to commercial name if possible, or just use model
        if (iosInfo.model.contains('iPhone')) {
          deviceModel = iosInfo.name; // e.g. "iPhone 15 Pro"
        }
        osSystem = 'iOS ${iosInfo.systemVersion}';
      } else if (Platform.isAndroid) {
        final androidInfo = await devicePlugin.androidInfo;
        deviceModel = '${androidInfo.manufacturer} ${androidInfo.model}';
        osSystem = 'Android ${androidInfo.version.release}';
      }

      return 'CivicNet/${packageInfo.version} ($deviceModel; $osSystem)';
    } catch (e) {
      return 'CivicNet/1.0.0 (Unknown Device; Mobile)';
    }
  }
}
