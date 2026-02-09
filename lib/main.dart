
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'services/theme_service.dart';
import 'screens/profile/privacy_policy_screen.dart';
import 'screens/onboarding/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/main_scaffold.dart';
import 'screens/home/home_screen.dart';
import 'screens/request/create_request_screen.dart';
import 'screens/request/request_detail_screen.dart';
import 'screens/secondary_screens.dart'; // Map, Chat, Profile
import 'screens/profile/edit_profile_screen.dart';
import 'screens/profile/settings_screen.dart';
import 'screens/profile/faq_screen.dart';
import 'screens/chat/chat_detail_screen.dart';
import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'dart:ui'; // For PlatformDispatcher
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();

  // Pass all uncaught "fatal" errors from the framework to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Initialize Services
  await Supabase.initialize(
    url: 'https://zofkjhpfeqkvajglltlf.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpvZmtqaHBmZXFrdmFqZ2xsdGxmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA1MTAzOTEsImV4cCI6MjA4NjA4NjM5MX0.Btd6hVkBrspTnlchcbS-gsyoLD2Bwcbb5pocZJ_LchI',
  );

  await FirebaseService().initialize();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: const CommunityHelpApp(),
    ),
  );
}

class CommunityHelpApp extends StatelessWidget {
  const CommunityHelpApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return MaterialApp.router(
      title: 'Community Help',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeService.themeMode,
      routerConfig: _router,
    );
  }
}

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final GoRouter _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  refreshListenable: GoRouterRefreshStream(Supabase.instance.client.auth.onAuthStateChange),
  redirect: (context, state) {
    // Check if user is logged in
    final session = Supabase.instance.client.auth.currentSession;
    final loggedIn = session != null;
    final loggingIn = state.uri.toString() == '/login' || state.uri.toString() == '/signup' || state.uri.toString() == '/onboarding' || state.uri.toString() == '/';

    // If logged in and trying to go to login/splash, redirect to home
    if (loggedIn && loggingIn) {
      return '/home';
    }

    return null; // No redirect
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
      navigatorKey: _shellNavigatorKey,
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
    // Routes outside Shell (Full Screen)
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
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
      parentNavigatorKey: _rootNavigatorKey,
      path: '/request/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return RequestDetailScreen(requestId: id);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/edit-profile',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/faq',
      builder: (context, state) => const FAQScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
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
    // Privacy Policy Route
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/privacy-policy',
      builder: (context, state) => const PrivacyPolicyScreen(),
    ),
  ],
);

// Helper for GoRouter to listen to streams (like Auth)
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
