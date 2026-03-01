import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
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

    await Future.wait([
      StartupService().initialize(),
      ThemeService().init(),
      minSplash,
    ]);

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: const CommunityHelpApp(),
    );
  }
}

class CommunityHelpApp extends StatefulWidget {
  const CommunityHelpApp({super.key});

  @override
  State<CommunityHelpApp> createState() => _CommunityHelpAppState();
}

class _CommunityHelpAppState extends State<CommunityHelpApp> {
  late final GoRouter _router = createRouter();

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

