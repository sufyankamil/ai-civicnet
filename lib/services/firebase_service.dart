import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:civic_net/services/logger_service.dart';
import 'package:civic_net/services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';
import 'package:civic_net/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:civic_net/features/home/presentation/viewmodels/home_viewmodel.dart';

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
    await _messaging.subscribeToTopic('global_requests');
    logger.i('Subscribed to global_requests topic');
    
    // Subscribe to their own user ID topic so we can exclude them from their own notifications
    try {
      final authViewModel = Get.find<AuthViewModel>();
      final userId = authViewModel.user?.id;
      if (userId != null) {
        await _messaging.subscribeToTopic(userId);
        logger.i('Subscribed to personal topic: $userId');
      }
    } catch (e) {
      logger.e('Could not subscribe to personal topic: $e');
    }

    // Initialize local notifications
    await NotificationService().initialize();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      logger.i('User granted permission');
      
      // Get the token
      try {
        String? token = await _messaging.getToken();
        logger.i('FCM Token: $token');
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

      // Get initial message if the app was opened from a terminated state
      RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        logger.i('App opened from terminated state by a notification');
        logger.d('Initial Message data: ${initialMessage.data}');
        _refreshHomeFeed();
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
