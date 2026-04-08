import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../main.dart'; // for prefsGlobal
import '../../services/logger_service.dart';


// Screens
import '../../features/profile/presentation/screens/privacy_policy_screen.dart';
import '../../features/profile/presentation/screens/terms_of_service_screen.dart';
import '../../features/onboarding/presentation/screens/splash_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/auth_check_screen.dart';
import '../../features/auth/presentation/screens/complete_profile_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/feedback_screen.dart';
import '../../features/home/presentation/screens/poll_creation_screen.dart';

import '../../core/presentation/layouts/main_scaffold.dart';
import '../../features/map/presentation/screens/map_screen.dart';
import '../../features/request/presentation/screens/create_request_screen.dart';
import '../../features/request/presentation/screens/request_detail_screen.dart';
import '../../features/discover/presentation/screens/discover_screen.dart';
import '../../features/activity/presentation/screens/activity_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/chat/presentation/screens/chat_detail_screen.dart';

import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/delete_account_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../features/profile/presentation/screens/faq_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/profile/presentation/screens/how_tasknet_works_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/commitment_screen.dart';
import '../../features/profile/presentation/screens/public_profile_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/events/presentation/screens/events_list_screen.dart';
import '../../features/events/presentation/screens/create_event_screen.dart';
import '../../features/events/presentation/screens/event_detail_screen.dart';
import '../../features/events/presentation/screens/location_picker_screen.dart';
import '../../features/profile/presentation/screens/admin_panel_screen.dart';
import '../../features/ai_assistant/presentation/screens/ai_assistant_screen.dart';
import '../../features/assets/presentation/screens/my_assets_screen.dart';
import '../../features/assets/presentation/screens/asset_discovery_screen.dart';
import '../../features/profile/presentation/screens/account_management_screen.dart';
import '../../features/profile/presentation/screens/referral_screen.dart';
import '../../features/profile/presentation/screens/legal_screen.dart';
import '../../features/profile/presentation/screens/active_sessions_screen.dart';
import '../presentation/screens/not_found_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

String lastAppLocation = '/';



final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

GoRouter createRouter({String initialLocation = '/'}) {
  final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'shell',
  );

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    errorBuilder: (context, state) => NotFoundScreen(location: state.uri.toString()),
    refreshListenable: GoRouterRefreshStream(
      Supabase.instance.client.auth.onAuthStateChange,
    ),
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final loggedIn = session != null;

      // Determine if we should go to onboarding/login or home
      final currentPath = state.uri.toString();

      if (!loggedIn) {
        if (currentPath == '/' || currentPath.startsWith('/home')) {
          // Check if onboarding was seen
          final prefs = prefsGlobal;
          final hasSeenOnboarding = prefs?.getBool('has_seen_onboarding') ?? false;
          if (hasSeenOnboarding) {
            return '/login';
          }
          return '/onboarding';
        } else if (currentPath.startsWith('/profile') || currentPath == '/chat' || currentPath == '/activity' || currentPath == '/discover' || currentPath == '/map' || currentPath == '/events') {
            return '/login';
        }
      } else {
        if (currentPath == '/' ||
            currentPath == '/login' ||
            currentPath == '/signup' ||
            currentPath == '/onboarding') {
          return '/auth-check'; // Send to auth check interceptor
        }
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/auth-check',
        builder: (context, state) => const AuthCheckScreen(),
      ),
      GoRoute(
        path: '/complete-profile',
        builder: (context, state) => const CompleteProfileScreen(),
      ),
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) {
          return MainScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) {
              final filter = state.uri.queryParameters['filter'];
              return HomeScreen(initialFilter: filter);
            },
          ),
          GoRoute(
            path: '/discover',
            builder: (context, state) => const DiscoverScreen(),
          ),
          GoRoute(
            path: '/activity',
            builder: (context, state) => const ActivityScreen(),
          ),
          GoRoute(path: '/map', builder: (context, state) => const MapScreen()),
          GoRoute(
            path: '/chat',
            builder: (context, state) => const ChatScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/events',
            builder: (context, state) => const EventsListScreen(),
          ),
        ],
      ),
      // Routes outside Shell
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/profile/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PublicProfileScreen(userId: id);
        },
      ),
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
        path: '/delete-account',
        builder: (context, state) => const DeleteAccountScreen(),
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
          final otherUserAvatar = state.uri.queryParameters['avatar'];
          final initialMessage = state.uri.queryParameters['msg'];
          return ChatDetailScreen(
            conversationId: conversationId,
            otherUserName: otherUserName,
            otherUserId: otherUserId,
            otherUserAvatar: otherUserAvatar,
            initialMessage: initialMessage,
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
        path: '/terms-of-service',
        builder: (context, state) => const TermsOfServiceScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/how-it-works',
        builder: (context, state) => const HowTaskNetWorksScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/commitment',
        builder: (context, state) => const CommitmentScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/feedback',
        builder: (context, state) => const FeedbackScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/create-event',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CreateEventScreen(),
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
        path: '/event/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EventDetailScreen(eventId: id);
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/location-picker',
        builder: (context, state) {
          final initialLocation = state.extra as LatLng?;
          return LocationPickerScreen(initialLocation: initialLocation);
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/admin-panel',
        builder: (context, state) => const AdminPanelScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/create-poll',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PollCreationScreen(),
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
        path: '/ai-assistant',
        builder: (context, state) => const AiAssistantScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/my-assets',
        builder: (context, state) => const MyAssetsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/asset-library',
        builder: (context, state) => const AssetDiscoveryScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/account-management',
        builder: (context, state) => const AccountManagementScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/referral',
        builder: (context, state) => const ReferralScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/legal',
        builder: (context, state) => const LegalScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/active-sessions',
        builder: (context, state) => const ActiveSessionsScreen(),
      ),
    ],
  );

  router.routerDelegate.addListener(() {
    final String location = router.routerDelegate.currentConfiguration.uri.toString();
    lastAppLocation = location;
    logger.d('Navigation update: $location');
  });

  return router;
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
