import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/complaint_provider.dart';
import '../providers/settings_provider.dart';
import '../services/update_service.dart';
import '../services/notification_service.dart';
import 'edit_profile_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _backup() async {
    try {
      final String? selectedDirectory = await FilePicker.getDirectoryPath();
      if (selectedDirectory == null) {
        _showSnackBar('Backup cancelled.');
        return;
      }

      if (!mounted) return;
      setState(() => _isLoading = true);
      final provider = Provider.of<ComplaintProvider>(context, listen: false);
      final backupPath = await provider.backupData(selectedDirectory);
      
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Backup successful! Saved to $backupPath');
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Backup failed: $e');
      }
    }
  }

  Future<void> _restore() async {
    try {
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.any,
      );

      if (result == null || result.files.single.path == null) {
        _showSnackBar('Restore cancelled.');
        return;
      }

      final String selectedFile = result.files.single.path!;

      if (!mounted) return;
      setState(() => _isLoading = true);
      final provider = Provider.of<ComplaintProvider>(context, listen: false);
      final success = await provider.restoreData(selectedFile);
      
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (success) {
        _showSnackBar('Restore successful! Data loaded.');
      } else {
        _showSnackBar('Restore failed: Unknown error.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Restore failed: $e');
      }
    }
  }

  Widget _buildProfileHeader(BuildContext context, SettingsProvider settings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(15) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(55) : Colors.grey.shade200,
          width: 1.2,
        ),
        boxShadow: isDark
            ? null
            : [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: settings.userPhotoPath != null ? FileImage(File(settings.userPhotoPath!)) : null,
            child: settings.userPhotoPath == null ? const Icon(Icons.person, size: 32, color: Colors.white) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  settings.userName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  settings.userRole,
                  style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            style: IconButton.styleFrom(
              backgroundColor: Colors.teal.withAlpha(30),
              foregroundColor: Colors.teal,
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
            },
            icon: const Icon(Icons.edit_outlined, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: const TextStyle(color: Colors.teal, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _aboutRow(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade700, fontSize: 13)),
          Text(value, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(color: isDark ? Colors.white.withAlpha(15) : Colors.grey.shade200, height: 1);
  }

  Widget _buildBuildNotice(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(8) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(30) : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Text(
        'NOTICE: This software is proprietary to AURYNTRIX. Unauthorized copying, reverse engineering, or distribution is strictly prohibited. Use of this application constitutes acceptance of these terms.',
        style: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade600, fontSize: 10, height: 1.6),
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor.withAlpha(150),
        elevation: 0,
        flexibleSpace: ClipRect(
          child: RepaintBoundary(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
              child: Container(color: Colors.transparent),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? null : Colors.white,
          gradient: isDark ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).primaryColor.withAlpha(40),
            ],
          ) : null,
        ),
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 40),
          children: [
            // 1. Profile Card
            _buildProfileHeader(context, settings),
            const SizedBox(height: 24),

            // 2. Preferences
            _sectionLabel('PREFERENCES'),
            const SizedBox(height: 10),
            _SettingsTile(
              icon: Icons.nightlight_round,
              label: 'Night Mode',
              sub: 'Toggle light or dark theme',
              color: Colors.purpleAccent,
              trailing: Switch(
                value: settings.isNightMode,
                onChanged: (val) => settings.toggleNightMode(val),
              ),
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.notifications_active,
              label: 'Daily Reminders',
              sub: '10 AM morning / 11 PM summary alerts',
              color: Colors.orangeAccent,
              trailing: Switch(
                value: settings.dailyReminders,
                onChanged: (val) async {
                  if (val) {
                    final status = await Permission.notification.request();
                    if (status.isDenied) {
                      _showSnackBar('Notification permission is required for Daily Reminders.');
                      return;
                    }
                    try {
                      await NotificationService.showTestNotification();
                    } catch (e) {
                      debugPrint('Error showing test notification: $e');
                    }
                  }
                  settings.toggleDailyReminders(val);
                },
              ),
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.location_searching,
              label: 'Proximity Scanning',
              sub: 'Scan for nearby active jobs in background',
              color: Colors.blueAccent,
              trailing: Switch(
                value: settings.isBackgroundLocation,
                onChanged: (val) async {
                  if (val) {
                    final locStatus = await Permission.location.request();
                    if (locStatus.isDenied) {
                      _showSnackBar('Location permission is required for Proximity Scanning.');
                      return;
                    }
                    final bgStatus = await Permission.locationAlways.request();
                    if (bgStatus.isDenied) {
                      _showSnackBar('Background location permission is required for Proximity Scanning.');
                      return;
                    }
                  }
                  settings.toggleBackgroundLocation(val);
                },
              ),
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.do_not_disturb,
              label: 'Leave Mode',
              sub: 'Mute background alerts & reminders',
              color: Colors.redAccent,
              trailing: Switch(
                value: settings.isLeaveMode,
                onChanged: (val) => settings.toggleLeaveMode(val),
              ),
            ),
            const SizedBox(height: 24),

            // 3. Data Management
            _sectionLabel('DATA MANAGEMENT'),
            const SizedBox(height: 10),
            _SettingsTile(
              icon: Icons.backup,
              label: 'Backup Data',
              sub: 'Save database backup securely to storage',
              color: Colors.teal,
              onTap: () => _backup(),
            ),
             const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.restore,
              label: 'Import / Restore Data',
              sub: 'Load backup database from local storage',
              color: Colors.green,
              onTap: () => _restore(),
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.system_update,
              label: 'Check for Updates',
              sub: 'Check remote repository for new releases',
              color: Colors.blue,
              onTap: () async {
                setState(() => _isLoading = true);
                await UpdateService.checkForUpdates(context, showSnackbarIfLatest: true);
                setState(() => _isLoading = false);
              },
            ),
            const SizedBox(height: 24),

            // 4. About Info
            _sectionLabel('ABOUT'),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withAlpha(15) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white.withAlpha(50) : Colors.grey.shade200,
                  width: 1.2,
                ),
                boxShadow: isDark
                    ? null
                    : [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  _aboutRow(context, 'App Name', 'Best Cool'),
                  _divider(context),
                  _aboutRow(context, 'Developer', 'IU_MTX'),
                  _divider(context),
                  _aboutRow(context, 'Version', 'v${UpdateService.currentVersionName}'),
                  _divider(context),
                  _aboutRow(context, 'Copyright', '© AURYNTRIX'),
                  _divider(context),
                  _aboutRow(context, 'Build', 'Proprietary — Internal Distribution'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildBuildNotice(context),
          ],
        ),
      ),
    );
  }
}

// Reusable Settings Tile Component in Crypton Hover Style
class _SettingsTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
    this.onTap,
    this.trailing,
  });

  @override
  State<_SettingsTile> createState() => _SettingsTileState();
}

class _SettingsTileState extends State<_SettingsTile> {
  bool _isTapped = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTapDown: (_) => setState(() => _isTapped = true),
      onTapUp: (_) => setState(() => _isTapped = false),
      onTapCancel: () => setState(() => _isTapped = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: _isTapped
              ? widget.color.withAlpha(20)
              : (isDark ? Colors.white.withAlpha(15) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isTapped
                ? widget.color.withAlpha(80)
                : (isDark ? Colors.white.withAlpha(30) : Colors.grey.shade200),
            width: 1.2,
          ),
          boxShadow: isDark
              ? null
              : [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: widget.color.withAlpha(30),
                  shape: BoxShape.circle,
                  border: Border.all(color: widget.color.withAlpha(100), width: 1),
                ),
                child: Icon(widget.icon, color: widget.color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.sub,
                      style: TextStyle(
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.trailing != null)
                widget.trailing!
              else if (widget.onTap != null)
                Icon(
                  Icons.chevron_right,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
