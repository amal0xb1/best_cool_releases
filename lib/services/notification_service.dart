import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Initializes the notification plugin and registers the channel in Android system settings
  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
    );

    // Create the notification channel explicitly so it registers in system settings immediately
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'best_cool_channel',
      'Best Cool Alerts',
      description: 'Notifications for pending and nearby tasks',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Sends a test notification to immediately verify that the plugin works
  static Future<void> showTestNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'best_cool_channel',
      'Best Cool Alerts',
      channelDescription: 'Notifications for pending and nearby tasks',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      id: 9999,
      title: 'Notifications Enabled! 🔔',
      body: 'You will now receive pending task reminders and proximity alerts.',
      notificationDetails: platformDetails,
    );
  }
}
