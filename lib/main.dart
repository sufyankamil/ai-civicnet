import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'theme/app_theme.dart';
import 'services/theme_service.dart';
import 'services/startup_service.dart';
import 'widgets/connectivity_wrapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Screens
import 'screens/profile/privacy_policy_screen.dart';
import 'screens/onboarding/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/main_scaffold.dart';
import 'screens/home/home_screen.dart';
import 'screens/request/create_request_screen.dart';
import 'screens/request/request_detail_screen.dart';
import 'screens/secondary_screens.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/profile/settings_screen.dart';
import 'screens/profile/faq_screen.dart';
import 'screens/chat/chat_detail_screen.dart';
import 'screens/profile/how_tasknet_works_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/profile/profile_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RootApp());
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
    // Artificial delay for splash visibility (optional)
    final minSplash = Future.delayed(const Duration(seconds: 2));
    
    // Initialize Hive before any services use it
    await Hive.initFlutter();
    
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
      // Show pure Splash Screen without routing
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme, // Use theme for colors
        home: const SplashScreen(),
      );
    }

    // App is ready
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
  // Router is created once and cached — not rebuilt on every theme change.
  late final GoRouter _router = _createRouter();

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return MaterialApp.router(
      title: 'CivicNet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeService.themeMode,
      routerConfig: _router,
      builder: (context, child) {
        return ConnectivityWrapper(child: child!);
      },
    );
  }
}

// Router Creation
GoRouter _createRouter() {
  final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(Supabase.instance.client.auth.onAuthStateChange),
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final loggedIn = session != null;
      
      // Determine if we should go to onboarding/login or home
      // Note: We don't have a 'splash' route anymore as the root, effectively.
      // But we can map '/' to Home or Onboarding logic.
      
      final currentPath = state.uri.toString();
      
      if (!loggedIn) {
         if (currentPath == '/' || currentPath.startsWith('/home')) {
           return '/onboarding';
         }
      } else {
         if (currentPath == '/' || currentPath == '/login' || currentPath == '/signup' || currentPath == '/onboarding') {
           return '/home';
         }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) {
          return MainScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/map',
            builder: (context, state) => const MapScreen(),
          ),
          GoRoute(
            path: '/chat',
            builder: (context, state) => const ChatScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      // Routes outside Shell
       GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/create-request',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CreateRequestScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/request/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return RequestDetailScreen(requestId: id);
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/faq',
        builder: (context, state) => const FAQScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/chat-detail',
        builder: (context, state) {
          final conversationId = state.uri.queryParameters['id']!;
          final otherUserName = state.uri.queryParameters['name'] ?? 'Chat';
          final otherUserId = state.uri.queryParameters['uid'] ?? '';
          return ChatDetailScreen(
            conversationId: conversationId,
            otherUserName: otherUserName,
            otherUserId: otherUserId,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/privacy-policy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/how-it-works',
        builder: (context, state) => const HowTaskNetWorksScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
    ],
  );
}

// Helper for GoRouter to listen to streams
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
