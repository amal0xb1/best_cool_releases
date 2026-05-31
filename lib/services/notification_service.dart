import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Initializes the notification plugin, registers the channel, and sets up timezones
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

    // Initialize Timezones for scheduled notifications
    try {
      tz.initializeTimeZones();
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = timezoneInfo.identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('Error initializing local timezone: $e');
    }
  }

  /// Sends a generic notification immediately
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
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
      id: id,
      title: title,
      body: body,
      notificationDetails: platformDetails,
    );
  }

  /// Schedules daily reminders at 10:00 AM and 11:00 PM (23:00)
  static Future<void> scheduleDailyReminders() async {
    await cancelDailyReminders();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'best_cool_channel',
      'Best Cool Alerts',
      channelDescription: 'Notifications for pending and nearby tasks',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    // 1. Morning Reminder (10:00 AM)
    await _notificationsPlugin.zonedSchedule(
      id: 9991,
      title: 'Good Morning! ☀️',
      body: 'Check your pending service requests for today.',
      scheduledDate: _nextInstanceOfTime(10, 0),
      notificationDetails: platformDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    // 2. Evening Reminder (11:00 PM / 23:00)
    await _notificationsPlugin.zonedSchedule(
      id: 9992,
      title: 'Tomorrow\'s Works 📅',
      body: 'Check your scheduled works for tomorrow.',
      scheduledDate: _nextInstanceOfTime(23, 0),
      notificationDetails: platformDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Cancels any scheduled daily reminders
  static Future<void> cancelDailyReminders() async {
    await _notificationsPlugin.cancel(id: 9991);
    await _notificationsPlugin.cancel(id: 9992);
  }

  /// Helper to get the next instance of a specific daily time
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Sends a test notification to immediately verify that the plugin works
  static Future<void> showTestNotification() async {
    await showNotification(
      id: 9999,
      title: 'Notifications Enabled! 🔔',
      body: 'You will now receive pending task reminders and proximity alerts.',
    );
  }
}
