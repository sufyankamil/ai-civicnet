import 'dart:async';
import 'dart:ui';
import 'package:flutter/widgets.dart'; // For WidgetsFlutterBinding
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:community_net/services/firebase_service.dart';
import 'package:community_net/services/cache_service.dart';
import 'package:community_net/services/logger_service.dart';

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
      url: 'https://zofkjhpfeqkvajglltlf.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpvZmtqaHBmZXFrdmFqZ2xsdGxmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA1MTAzOTEsImV4cCI6MjA4NjA4NjM5MX0.Btd6hVkBrspTnlchcbS-gsyoLD2Bwcbb5pocZJ_LchI',
    );
    logger.i('Supabase initialized (${stopwatch.elapsedMilliseconds}ms)');

    // 4. Parallel Services
    await Future.wait([
      FirebaseService().initialize(),
      CacheService().initialize(),
    ]);

    logger.i('All Services initialized in ${stopwatch.elapsedMilliseconds}ms');
    _isInitialized = true;
  }
}
