import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:civic_net/services/logger_service.dart';
import 'package:civic_net/services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:civic_net/features/home/presentation/viewmodels/home_viewmodel.dart';
import 'dart:io';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  logger.i("Handling a background message: ${message.messageId}");
}

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Setup background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Explicitly request notification permission for Android 13+
    await Permission.notification.request();

    // Request permission for notifications
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Set foreground notification presentation options for iOS
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Subscribe to global requests topic to receive new request notifications
    try {
      if (Platform.isIOS) {
        final apnsToken = await _messaging.getAPNSToken();
        if (apnsToken != null) {
          await _messaging.subscribeToTopic('global_requests');
          logger.i('Subscribed to global_requests topic');
        } else {
          logger.w('APNS token not available, skipping topic subscription');
        }
      } else {
        await _messaging.subscribeToTopic('global_requests');
        logger.i('Subscribed to global_requests topic');
      }
    } catch (e) {
      logger.e('Error subscribing to global_requests: $e');
    }
    
    // Subscribe to their own user ID topic dynamically so it works even if they log in later
    try {
      String? currentUserTopic;

      // Subscribe synchronously on init if already logged in (fixes Hot Restart bug)
      final initialUser = Supabase.instance.client.auth.currentUser;
      if (initialUser != null) {
        final safeTopic = 'user_${initialUser.id}'.replaceAll('-', '_');
        
        bool canSubscribe = true;
        if (Platform.isIOS) {
          final apnsToken = await _messaging.getAPNSToken();
          if (apnsToken == null) {
            canSubscribe = false;
            logger.w('APNS token not available for personal topic init');
          }
        }
        
        if (canSubscribe) {
          await _messaging.subscribeToTopic(safeTopic);
          currentUserTopic = safeTopic;
          logger.i('Subscribed to personal FCM topic synchronously on init: $safeTopic');
        }
      }

      Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
        final user = data.session?.user;
        if (user != null) {
          final safeTopic = 'user_${user.id}'.replaceAll('-', '_');
          if (currentUserTopic != safeTopic) {
            if (currentUserTopic != null) {
              await _messaging.unsubscribeFromTopic(currentUserTopic!).catchError((e) => logger.e('Unsubscribe error: $e'));
            }
            
            bool canSubscribe = true;
            if (Platform.isIOS) {
              final apnsToken = await _messaging.getAPNSToken();
              if (apnsToken == null) {
                canSubscribe = false;
                logger.w('APNS token not available for personal topic change');
              }
            }

            if (canSubscribe) {
              await _messaging.subscribeToTopic(safeTopic);
              currentUserTopic = safeTopic;
              logger.i('Subscribed to personal FCM topic via listener: $safeTopic');
            }
          }
        } else if (user == null && currentUserTopic != null) {
          await _messaging.unsubscribeFromTopic(currentUserTopic!);
          logger.i('Unsubscribed from personal topic: $currentUserTopic');
          currentUserTopic = null;
        }
      });
    } catch (e) {
      logger.e('Could not setup personal topic listener: $e');
    }

    // Initialize local notifications
    await NotificationService().initialize();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      logger.i('User granted permission');
      
      // Get the token
      try {
        bool canGetToken = true;
        if (Platform.isIOS) {
          final apnsToken = await _messaging.getAPNSToken();
          if (apnsToken == null) {
            canGetToken = false;
            logger.w('APNS token not available, skipping FCM token retrieval');
          }
        }
        
        if (canGetToken) {
          String? token = await _messaging.getToken();
          logger.i('FCM Token: $token');
        }
      } catch (e) {
        logger.e('FCM Token Error: $e');
        logger.w('Note: FCM on iOS requires a real device and "Push Notifications" capability in Xcode.');
      }
      
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        logger.i('Got a message whilst in the foreground!');
        logger.d('Message data: ${message.data}');

        if (message.notification != null) {
          logger.i('Message also contained a notification: ${message.notification}');
          // Show local notification for foreground messages
          NotificationService().showNotification(message);
        }
      });

      // Handle background/terminated state notification taps
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        logger.i('A new onMessageOpenedApp event was published!');
        logger.d('Message background data: ${message.data}');
        _refreshHomeFeed();
      });

      try {
        RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage().timeout(const Duration(milliseconds: 500));
        if (initialMessage != null) {
          logger.i('App opened from terminated state by a notification');
          logger.d('Initial Message data: ${initialMessage.data}');
          _refreshHomeFeed();
        }
      } catch (e) {
        logger.w('Timeout or error getting initial message: $e');
      }
    } else {
      logger.w('User declined or has not accepted permission');
    }
  }

  void _refreshHomeFeed() {
    try {
      final homeViewModel = Get.find<HomeViewModel>();
      homeViewModel.fetchRequests();
      logger.i('Successfully triggered home feed refresh from notification.');
    } catch (e) {
      logger.e('Error attempting to refresh home feed: $e');
    }
  }
}
