import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  // Local app version tracking
  static const int currentVersionCode = 2; 
  static const String currentVersionName = "1.2";

  // GitHub repository raw file endpoint
  static const String updateConfigUrl = "https://raw.githubusercontent.com/amal0xb1/best_cool_releases/main/update.json";

  /// Checks for updates silently or manually, showing appropriate UI
  static Future<void> checkForUpdates(BuildContext context, {bool showSnackbarIfLatest = false, bool isAutoCheck = false}) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);
    
    try {
      final request = await client.getUrl(Uri.parse(updateConfigUrl));
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> data = json.decode(responseBody);
        
        final int remoteVersionCode = data['versionCode'] ?? 0;
        final String remoteVersionName = data['versionName'] ?? '';
        final String changelog = data['changelog'] ?? 'No release notes provided.';
        final String apkUrl = data['apkUrl'] ?? '';
        
        if (remoteVersionCode > currentVersionCode) {
          // If auto-checking on startup, see if the user has opted to skip this version
          if (isAutoCheck) {
            final prefs = await SharedPreferences.getInstance();
            final String? skippedVersion = prefs.getString('ignored_update_version');
            if (skippedVersion == remoteVersionName) {
              client.close();
              return; // Skip displaying dialog for this version
            }
          }

          if (context.mounted) {
            _showUpdateDialog(context, remoteVersionName, changelog, apkUrl);
          }
        } else {
          if (showSnackbarIfLatest && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Best Cool is up to date! (v$currentVersionName)')),
            );
          }
        }
      } else {
        if (showSnackbarIfLatest && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Update check failed. Status code: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      if (showSnackbarIfLatest && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot check for updates: Check your internet connection.')),
        );
      }
    } finally {
      client.close();
    }
  }

  /// Displays the premium dialog showing what's new and download button
  static void _showUpdateDialog(BuildContext context, String newVersion, String changelog, String apkUrl) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161E1D).withOpacity(0.95) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark ? Colors.white.withAlpha(35) : Colors.grey.shade300,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 80 : 15),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Area
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.teal.withAlpha(25),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.teal.withAlpha(80), width: 1),
                      ),
                      child: const Icon(Icons.system_update_alt, color: Colors.teal, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "New Update Available!",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Version $newVersion is ready to install",
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 16),
                
                // What's New Title
                Text(
                  "WHAT'S NEW",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Colors.teal.shade400,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Changelog list
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(
                        changelog,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: isDark ? Colors.white.withAlpha(30) : Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "LATER",
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.redAccent.withAlpha(80)),
                          foregroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('ignored_update_version', newVersion);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Skipped update v$newVersion. You can still check manually in Settings.')),
                            );
                          }
                        },
                        child: const Text(
                          "SKIP",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          final Uri url = Uri.parse(apkUrl);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          }
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                        child: const Text(
                          "UPDATE",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
