import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/complaint_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/dashboard_screen.dart';
import 'package:workmanager/workmanager.dart';
import 'services/background_service.dart';

import 'dart:ui';
import 'package:flutter/foundation.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
  };

  // Catch all uncaught asynchronous Dart errors to prevent app crashes
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Async Error Caught: $error');
    return true; // Returns true to signal the error has been handled
  };

  runApp(const BestCoolApp());

  // Defer Workmanager initialization to speed up app startup
  Future.delayed(const Duration(milliseconds: 600), () {
    try {
      Workmanager().initialize(callbackDispatcher);
      
      Workmanager().registerPeriodicTask(
        "task-late-checks", 
        "checkLateTasks", 
        frequency: const Duration(hours: 24),
      );
      
      Workmanager().registerPeriodicTask(
        "task-proximity-alerts",
        "checkProximity",
        frequency: const Duration(minutes: 15),
      );
    } catch (e) {
      debugPrint('Error initializing Workmanager: $e');
    }
  });
}

class BestCoolApp extends StatelessWidget {
  const BestCoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ComplaintProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return MaterialApp(
            title: 'Best Cool',
            debugShowCheckedModeBanner: false,
            themeMode: settings.themeMode,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF00796B), // Cool Teal
                secondary: const Color(0xFF0288D1), // Ice Blue
                brightness: Brightness.light,
              ),
              textTheme: GoogleFonts.nunitoTextTheme(
                ThemeData.light().textTheme,
              ),
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                elevation: 0,
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF00796B),
                secondary: const Color(0xFF0288D1),
                brightness: Brightness.dark,
              ),
              scaffoldBackgroundColor: const Color(0xFF121212),
              textTheme: GoogleFonts.nunitoTextTheme(
                ThemeData.dark().textTheme,
              ),
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                elevation: 0,
                backgroundColor: Color(0xFF1A1A1A),
              ),
            ),
            home: const DashboardScreen(),
          );
        },
      ),
    );
  }
}
