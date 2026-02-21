import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:community_net/services/logger_service.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Request permission for notifications
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

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
        }
      });
    } else {
      logger.w('User declined or has not accepted permission');
    }
  }
}
