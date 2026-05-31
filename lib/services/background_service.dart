import 'dart:convert';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'database_helper.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final prefs = await SharedPreferences.getInstance();
    final isLeaveMode = prefs.getBool('isLeaveMode') ?? false;
    
    // If leave mode is ON, absolutely no background tasks.
    if (isLeaveMode) return Future.value(true);

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'best_cool_channel', 'Best Cool Alerts',
      channelDescription: 'Notifications for pending and nearby tasks',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    final dbHelper = DatabaseHelper.instance;
    final pendingComplaints = await dbHelper.readComplaintsByStatus('PENDING');

    final dailyReminders = prefs.getBool('dailyReminders') ?? true;
    if (dailyReminders && pendingComplaints.isNotEmpty) {
      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month}-${now.day}';

      if (now.hour == 10) {
        if (prefs.getString('last10AM') != todayStr) {
          await flutterLocalNotificationsPlugin.show(
            id: 9991, title: 'Good Morning! ☀️', 
            body: 'You have ${pendingComplaints.length} pending service requests today.',
            notificationDetails: platformDetails,
          );
          await prefs.setString('last10AM', todayStr);
        }
      }

      if (now.hour == 23) {
        if (prefs.getString('last11PM') != todayStr) {
          await flutterLocalNotificationsPlugin.show(
            id: 9992, title: 'Tomorrow\'s Works 📅', 
            body: '${pendingComplaints.length} pending works are scheduled for tomorrow.',
            notificationDetails: platformDetails,
          );
          await prefs.setString('last11PM', todayStr);
        }
      }
    }

    if (task == 'checkLateTasks') {
      // 1. Existing late task notifications
      for (var complaint in pendingComplaints) {
        final created = DateTime.parse(complaint.createdAt);
        final diff = DateTime.now().difference(created).inDays;
        
        if (diff >= 5) {
          await flutterLocalNotificationsPlugin.show(
            id: complaint.id ?? 0,
            title: 'Late Service Warning!',
            body: 'Task for ${complaint.customerName} (${complaint.deviceType}) is $diff days late!',
            notificationDetails: platformDetails,
          );
        }
      }

      // 2. Silent update check in background
      try {
        final updateRequest = await HttpClient().getUrl(
          Uri.parse("https://raw.githubusercontent.com/amal0xb1/best_cool_releases/main/update.json")
        );
        final updateResponse = await updateRequest.close();
        if (updateResponse.statusCode == 200) {
          final resBody = await updateResponse.transform(utf8.decoder).join();
          final Map<String, dynamic> data = json.decode(resBody);
          final int remoteVersionCode = data['versionCode'] ?? 0;
          final String remoteVersionName = data['versionName'] ?? '';
          
          const int currentVersionCode = 3;

          if (remoteVersionCode > currentVersionCode) {
            await flutterLocalNotificationsPlugin.show(
              id: 9995,
              title: 'Best Cool Update Available! 🚀',
              body: 'Version $remoteVersionName is ready. Tap to check out the changelog.',
              notificationDetails: platformDetails,
            );
          }
        }
      } catch (e) {
        // Fail silently in background
      }
    }

    if (task == 'checkProximity') {
      final isBackLocation = prefs.getBool('isBackgroundLocation') ?? false;
      if (!isBackLocation) return Future.value(true);

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return Future.value(true);

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return Future.value(true);
      }

      try {
        Position position = await Geolocator.getCurrentPosition();
        
        for (var complaint in pendingComplaints) {
          if (complaint.latitude != null && complaint.longitude != null) {
            double distanceInMeters = Geolocator.distanceBetween(
              position.latitude, position.longitude,
              complaint.latitude!, complaint.longitude!
            );
            
            if (distanceInMeters < 5000) { // Within 5km
              await flutterLocalNotificationsPlugin.show(
                id: (complaint.id ?? 0) + 1000,
                title: 'Service Nearby!',
                body: 'Pending job for ${complaint.customerName} is only ${(distanceInMeters/1000).toStringAsFixed(1)}km away!',
                notificationDetails: platformDetails,
              );
            }
          }
        }
      } catch (e) {
        return Future.value(false);
      }
    }

    return Future.value(true);
  });
}
