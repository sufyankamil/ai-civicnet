import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'theme/app_theme.dart';
import 'services/theme_service.dart';
import 'services/startup_service.dart';
import 'widgets/connectivity_wrapper.dart';

import 'package:toastification/toastification.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/routes/app_router.dart';
import 'features/auth/di/auth_binding.dart';
import 'features/home/di/home_binding.dart';
import 'features/request/di/request_binding.dart';
import 'features/map/di/map_binding.dart';
import 'features/chat/di/chat_binding.dart';
import 'features/onboarding/presentation/screens/splash_screen.dart';
SharedPreferences? prefsGlobal;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((
    _,
  ) {
    runApp(const RootApp());
  });
}

class RootApp extends StatefulWidget {
  const RootApp({super.key});

  @override
  State<RootApp> createState() => _RootAppState();
}

class _RootAppState extends State<RootApp> {
  bool _isInitialized = false;
  String? _initError;
  String _initialLocation = '/';

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    final minSplash = Future.delayed(const Duration(seconds: 2));

    // Initialize Hive & Dotenv before any services use it
    await Hive.initFlutter();
    await dotenv.load(fileName: ".env");
    prefsGlobal = await SharedPreferences.getInstance();

    // Initialize Dependencies
    await initAuthDI();
    HomeBinding().dependencies();
    await initRequestDI();
    await initMapDI();
    await initChatDI();

    // Read the initial deep-link URI BEFORE Supabase.initialize() so we can
    // detect a password-recovery link. The PASSWORD_RECOVERY auth event fires
    // INSIDE Supabase.initialize() and cannot be caught by a stream listener
    // added afterward, so we check the URI directly here instead.
    try {
      final initialUri = await AppLinks().getInitialLink();
      if (initialUri != null) {
        final uriStr = initialUri.toString();
        if (uriStr.contains('type=recovery') ||
            uriStr.startsWith('civicnet://reset-password')) {
          _initialLocation = '/reset-password';
        }
      }
    } catch (_) {}

    try {
      await Future.wait([
        StartupService().initialize(),
        ThemeService().init(),
        minSplash,
      ]);

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _initError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _initError = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to initialize app',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _initError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _initError = null;
                      });
                      _initApp();
                    },
                    child: const Text('Retry'),
                  )
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: CommunityHelpApp(initialLocation: _initialLocation),
    );
  }
}

class CommunityHelpApp extends StatefulWidget {
  final String initialLocation;
  const CommunityHelpApp({super.key, this.initialLocation = '/'});

  @override
  State<CommunityHelpApp> createState() => _CommunityHelpAppState();
}

class _CommunityHelpAppState extends State<CommunityHelpApp> {
  late final GoRouter _router = createRouter(initialLocation: widget.initialLocation);
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    // Listen for PASSWORD_RECOVERY event — fired when the user taps the reset
    // link in their email and Android deep-links them back into the app.
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        _router.go('/reset-password');
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return ToastificationWrapper(
      child: MaterialApp.router(
        title: 'CivicNet',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeService.themeMode,
        routerConfig: _router,
        builder: (context, child) {
          return ConnectivityWrapper(child: child!);
        },
      ),
    );
  }
}

