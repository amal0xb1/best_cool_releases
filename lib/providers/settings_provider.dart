import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class SettingsProvider with ChangeNotifier {
  bool _isNightMode = false;
  bool _isLeaveMode = false;
  bool _isBackgroundLocation = false;
  bool _dailyReminders = true;
  String _userName = 'Technician';
  String _userRole = 'Service Agent';
  String? _userPhotoPath;

  bool get isNightMode => _isNightMode;
  bool get isLeaveMode => _isLeaveMode;
  bool get isBackgroundLocation => _isBackgroundLocation;
  bool get dailyReminders => _dailyReminders;
  String get userName => _userName;
  String get userRole => _userRole;
  String? get userPhotoPath => _userPhotoPath;

  ThemeMode get themeMode => _isNightMode ? ThemeMode.dark : ThemeMode.light;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isNightMode = prefs.getBool('isNightMode') ?? false;
    _isLeaveMode = prefs.getBool('isLeaveMode') ?? false;
    _isBackgroundLocation = prefs.getBool('isBackgroundLocation') ?? false;
    _dailyReminders = prefs.getBool('dailyReminders') ?? true;
    _userName = prefs.getString('userName') ?? 'Technician';
    _userRole = prefs.getString('userRole') ?? 'Service Agent';
    _userPhotoPath = prefs.getString('userPhotoPath');
    
    // Auto-schedule daily reminders if they are enabled
    if (_dailyReminders) {
      try {
        await NotificationService.scheduleDailyReminders();
      } catch (e) {
        debugPrint('Error auto-scheduling daily reminders: $e');
      }
    } else {
      try {
        await NotificationService.cancelDailyReminders();
      } catch (e) {
        debugPrint('Error cancelling daily reminders: $e');
      }
    }

    notifyListeners();
  }

  Future<void> toggleNightMode(bool value) async {
    _isNightMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isNightMode', value);
    notifyListeners();
  }

  Future<void> toggleLeaveMode(bool value) async {
    _isLeaveMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLeaveMode', value);
    notifyListeners();
  }

  Future<void> toggleBackgroundLocation(bool value) async {
    _isBackgroundLocation = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isBackgroundLocation', value);
    notifyListeners();
  }

  Future<void> toggleDailyReminders(bool value) async {
    _dailyReminders = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dailyReminders', value);
    
    if (value) {
      try {
        await NotificationService.scheduleDailyReminders();
      } catch (e) {
        debugPrint('Error scheduling daily reminders: $e');
      }
    } else {
      try {
        await NotificationService.cancelDailyReminders();
      } catch (e) {
        debugPrint('Error cancelling daily reminders: $e');
      }
    }
    
    notifyListeners();
  }

  Future<void> updateProfile({required String name, required String role, String? photoPath}) async {
    _userName = name;
    _userRole = role;
    _userPhotoPath = photoPath;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
    await prefs.setString('userRole', role);
    if (photoPath != null) {
      await prefs.setString('userPhotoPath', photoPath);
    } else {
      await prefs.remove('userPhotoPath');
    }
    notifyListeners();
  }
}
