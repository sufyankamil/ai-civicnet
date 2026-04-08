import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:civic_net/services/logger_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_init;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Tracks the ID of the conversation currently being viewed by the user.
  /// Used to suppress notifications for the active chat.
  String? activeConversationId;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone for scheduled notifications
    tz_init.initializeTimeZones();
    try {
      final TimezoneInfo timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      String tzName = timeZoneInfo.identifier;
      if (tzName == 'Asia/Calcutta') {
        tzName = 'Asia/Kolkata';
      }
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (e) {
      logger.e('Error setting local location timezone, falling back to UTC: $e');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // Android initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    // iOS initialization
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        logger.i('Notification tapped: ${response.payload}');
        // Handle notification tap logic here (e.g., routing)
      },
    );

    // Create the channel on the device (if a channel with an id already exists, it will be updated)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description: 'This channel is used for important notifications.', // description
      importance: Importance.max,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _isInitialized = true;
    logger.i('Local Notifications Initialized');
  }

  Future<void> showNotification(RemoteMessage message) async {
    final data = message.data;
    RemoteNotification? notification = message.notification;
    
    // Extract title and body from notification OR data fallback
    final String? title = notification?.title ?? data['senderName'] ?? data['title'];
    final String? body = notification?.body ?? data['content'] ?? data['body'];

    if (title == null && body == null) return;

    // Android configuration
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'high_importance_channel', 
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
    );

    // iOS configuration
    const DarwinNotificationDetails darwinNotificationDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      id: notification.hashCode != 0 ? notification.hashCode : DateTime.now().millisecond,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: data.toString(),
    );
  }

  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'high_importance_channel', 
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload,
    );
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required Duration delay,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.now(tz.local).add(delay),
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  Future<void> scheduleDailyCheckInNotification() async {
    const int id = 999;
    const String title = 'Community Check-in';
    const String body = 'Take a moment to check if anyone in your community needs help today!';

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'daily_checkin_channel',
      'Daily Check-in Notifications',
      channelDescription: 'Daily reminders to check in with the community.',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/launcher_icon',
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    final scheduledTime = _nextInstanceOfTime(11, 00);
    logger.i('Attempting to schedule daily notification at $scheduledTime');

    try {
      // Try exact scheduling first (requires SCHEDULE_EXACT_ALARM / USE_EXACT_ALARM)
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledTime,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      logger.i('✅ Daily check-in notification scheduled exactly at 11:00 AM');
    } catch (e) {
      logger.w('Exact alarm failed ($e) — falling back to inexact scheduling');
      try {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduledTime,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexact,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        logger.i('✅ Daily check-in notification scheduled (inexact) at ~11:00 PM');
      } catch (e2) {
        logger.e('❌ Failed to schedule daily notification: $e2');
      }
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
