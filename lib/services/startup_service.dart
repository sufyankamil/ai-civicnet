import 'dart:async';
import 'dart:ui';
import 'package:flutter/widgets.dart'; // For WidgetsFlutterBinding
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:civic_net/services/firebase_service.dart';
import 'package:civic_net/services/cache_service.dart';
import 'package:civic_net/services/logger_service.dart';
import 'package:civic_net/services/notification_service.dart';
class StartupService {
  static final StartupService _instance = StartupService._internal();
  factory StartupService() => _instance;
  StartupService._internal();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    final stopwatch = Stopwatch()..start();
    logger.i('Starting App Initialization...');

    // 1. Firebase Core
    await Firebase.initializeApp();
    logger.i('Firebase Core initialized (${stopwatch.elapsedMilliseconds}ms)');

    // 2. Crashlytics Setup
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // 3. Supabase
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
    logger.i('Supabase initialized (${stopwatch.elapsedMilliseconds}ms)');

    // 4. Parallel Services
    await Future.wait([
      FirebaseService().initialize(),
      CacheService().initialize(),
    ]);

    // Schedule the daily notification after other services are up
    await NotificationService().scheduleDailyCheckInNotification();

    logger.i('All Services initialized in ${stopwatch.elapsedMilliseconds}ms');
    _isInitialized = true;
  }
}
