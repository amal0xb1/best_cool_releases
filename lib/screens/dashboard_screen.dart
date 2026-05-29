import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/complaint_provider.dart';
import '../providers/settings_provider.dart';
import '../models/complaint.dart';
import '../services/update_service.dart';
import 'add_complaint_screen.dart';
import 'recycle_bin_screen.dart';
import 'settings_screen.dart';
import 'complaint_detail_screen.dart';
import 'full_screen_image_viewer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

enum SortStrategy { date, name, priority }

// Standalone Helper: Reusable Simulated Glass Container (high-performance)
Widget _buildGlassBox(BuildContext context, {required Widget child, EdgeInsetsGeometry? padding, double? height}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Container(
    height: height,
    padding: padding ?? const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      color: isDark ? Colors.white.withAlpha(15) : Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: isDark ? Colors.white.withAlpha(30) : Colors.grey.shade200,
        width: 1.0,
      ),
      boxShadow: isDark
          ? null
          : [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 20, offset: const Offset(0, 10))],
    ),
    child: child,
  );
}

// Standalone Helper: Detail Row styling
Widget _detailRow(IconData icon, String text, {VoidCallback? onTap}) {
  final row = Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: onTap != null ? Colors.blue.shade400 : Colors.grey.shade400),
      const SizedBox(width: 12),
      Expanded(child: Text(text, style: TextStyle(
        fontSize: 13, height: 1.4,
        color: onTap != null ? Colors.blue.shade400 : null,
        decoration: onTap != null ? TextDecoration.underline : null,
        decorationColor: Colors.blue.shade400,
      ))),
    ],
  );
  if (onTap != null) {
    return InkWell(onTap: onTap, child: row);
  }
  return row;
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late PageController _pageController;
  int _currentIndex = 0; // 0 for Home, 1 for Pending, 2 for Completed
  SortStrategy _sortStrategy = SortStrategy.date;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _requestNotificationPermission();
    
    // Check for updates silently after app launch
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        UpdateService.checkForUpdates(context, isAutoCheck: true);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isDenied) {
      await Permission.notification.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 24;

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 24,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Best Cool', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
            Text('Service Manager', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.normal)),
          ],
        ),
        backgroundColor: isDark ? const Color(0xFF121212).withAlpha(180) : Colors.white.withAlpha(240),
        elevation: 0,
        flexibleSpace: isDark ? ClipRect(
          child: RepaintBoundary(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
              child: Container(color: Colors.transparent),
            ),
          ),
        ) : null,
        actions: [
          PopupMenuButton<SortStrategy>(
            icon: const Icon(Icons.sort, size: 22),
            tooltip: 'Sort List',
            onSelected: (SortStrategy item) {
              setState(() {
                _sortStrategy = item;
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<SortStrategy>>[
              const PopupMenuItem<SortStrategy>(
                value: SortStrategy.date,
                child: Text('Sort by Date'),
              ),
              const PopupMenuItem<SortStrategy>(
                value: SortStrategy.priority,
                child: Text('Sort by Priority'),
              ),
              const PopupMenuItem<SortStrategy>(
                value: SortStrategy.name,
                child: Text('Sort by Name'),
              ),
            ],
          ),
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, size: 22),
            tooltip: 'Toggle Theme',
            onPressed: () {
              final settings = Provider.of<SettingsProvider>(context, listen: false);
              settings.toggleNightMode(!isDark);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 22),
            tooltip: 'Recycle Bin',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecycleBinScreen())),
          ),
          const SizedBox(width: 8),
        ],
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
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: [
            _HomeTab(topPadding: topPadding),
            _ComplaintListTab(
              isPending: true,
              sortStrategy: _sortStrategy,
              topPadding: topPadding,
            ),
            _ComplaintListTab(
              isPending: false,
              sortStrategy: _sortStrategy,
              topPadding: topPadding,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 12, right: 12, bottom: 24),
          child: _buildFloatingDock(),
        ),
      ),
    );
  }

  Widget _buildFloatingDock() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Widget dockContent = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _dockItem(icon: Icons.grid_view_rounded, label: 'Home', index: 0),
        _dockItem(icon: Icons.pending_actions, label: 'Pending', index: 1),
        
        InkWell(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AddComplaintScreen()));
          },
          child: Container(
            height: 60,
            width: 60,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              gradient: isDark ? LinearGradient(colors: [Colors.teal.shade300, Colors.tealAccent.shade400]) : null,
              color: isDark ? null : Colors.black,
              shape: BoxShape.circle,
              border: isDark ? Border.all(color: Colors.white.withAlpha(20), width: 1.5) : null,
              boxShadow: isDark ? [BoxShadow(color: Colors.tealAccent.withAlpha(80), blurRadius: 15, offset: const Offset(0, 4))] : [BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Icon(Icons.create, color: isDark ? Colors.black : Colors.white, size: 26),
          ),
        ),

        _dockItem(icon: Icons.done_all, label: 'Finished', index: 2),
        _dockActionItem(icon: Icons.settings, label: 'Settings', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
      ],
    );

    if (isDark) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: RepaintBoundary(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 75,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(15),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Colors.white.withAlpha(30), width: 1.0),
              ),
              child: dockContent,
            ),
          ),
        ),
      );
    } else {
      return Container(
        height: 75,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: dockContent,
      );
    }
  }

  Widget _dockItem({required IconData icon, required String label, required int index}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _currentIndex == index;
    final color = isSelected ? (isDark ? Colors.white : Colors.black) : Colors.grey.shade400;
    
    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _dockActionItem({required IconData icon, required String label, required VoidCallback onTap}) {
    final color = Colors.grey.shade400;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// HOME TAB WITH KEEP-ALIVE
// ----------------------------------------------------
class _HomeTab extends StatefulWidget {
  final double topPadding;
  const _HomeTab({required this.topPadding});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final topPadding = widget.topPadding;
    final settings = Provider.of<SettingsProvider>(context);
    final provider = Provider.of<ComplaintProvider>(context);
    final now = DateTime.now();
    final todayStr = DateFormat('EEEE, MMM d, yyyy').format(now);
    
    // Calculate Monthly Stats
    final allComplaints = [...provider.pendingComplaints, ...provider.completedComplaints];
    int monthlyTotal = 0;
    int monthlyCompleted = 0;
    for (var c in allComplaints) {
      final date = DateTime.parse(c.createdAt);
      if (date.month == now.month && date.year == now.year) {
        monthlyTotal++;
        if (c.status == 'COMPLETED') monthlyCompleted++;
      }
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(top: topPadding, left: 24, right: 24, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: settings.userPhotoPath != null ? FileImage(File(settings.userPhotoPath!)) : null,
                child: settings.userPhotoPath == null ? const Icon(Icons.person, size: 30, color: Colors.white) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(settings.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                    Text(settings.userRole, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Hi ${settings.userName.split(' ').first}, you have ${provider.pendingComplaints.length} pending works to clear', 
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, height: 1.2),
          ),
          const SizedBox(height: 4),
          Text(todayStr, style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          _buildWeeklyChart(context, provider),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _buildGlassBox(
                context,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_month, size: 22, color: Colors.blue),
                    const SizedBox(height: 6),
                    Text('$monthlyTotal', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.normal)),
                    Text('Month Total', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              _buildGlassBox(
                context,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.task_alt, size: 22, color: Colors.green),
                    const SizedBox(height: 6),
                    Text('$monthlyCompleted', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.normal)),
                    Text('Month Completed', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              _buildGlassBox(
                context,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.pending_actions, size: 22, color: Colors.orange),
                    const SizedBox(height: 6),
                    Text('${provider.pendingComplaints.length}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.normal)),
                    Text('Active Pending', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              _buildGlassBox(
                context,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 22, color: Colors.red.shade400),
                    const SizedBox(height: 6),
                    Text(
                      '${provider.pendingComplaints.where((c) => DateTime.now().difference(DateTime.parse(c.createdAt)).inDays >= 5).length}',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.normal, color: Colors.red.shade400),
                    ),
                    Text('Overdue Jobs', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red.shade300)),
                  ],
                ),
              ),
            ]
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(BuildContext context, ComplaintProvider provider) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final List<int> completionCounts = List.filled(7, 0);
    final List<String> dayLabels = [];

    for (int i = 6; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      dayLabels.add(DateFormat('E').format(d).substring(0, 1)); 
    }

    for (var c in provider.completedComplaints) {
      if (c.status == 'COMPLETED') { 
         final dateStr = DateTime.parse(c.createdAt);
         final compDate = DateTime(dateStr.year, dateStr.month, dateStr.day);
         final diffDays = today.difference(compDate).inDays;
         
         if (diffDays >= 0 && diffDays < 7) {
            completionCounts[6 - diffDays]++;
         }
      }
    }

    final maxCount = completionCounts.isNotEmpty ? completionCounts.reduce((a, b) => a > b ? a : b) : 0;
    
    return _buildGlassBox(
      context,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Weekly Performance', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (index) {
              final count = completionCounts[index];
              final height = maxCount == 0 ? 10.0 : (count / maxCount) * 100.0 + 10.0;
              final isToday = index == 6;
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final color = isToday ? Colors.teal : (isDark ? Colors.teal.shade300.withAlpha(50) : Colors.teal.shade200.withAlpha(80));

              return Column(
                children: [
                  Text('$count', style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutQuart,
                    width: 24,
                    height: height,
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
                  ),
                  const SizedBox(height: 8),
                  Text(dayLabels[index], style: TextStyle(fontSize: 12, fontWeight: isToday ? FontWeight.bold : FontWeight.normal, color: isToday ? null : Colors.grey.shade500)),
                ],
              );
            }),
          )
        ],
      )
    );
  }
}

// ----------------------------------------------------
// COMPLAINT LIST TAB (PENDING OR COMPLETED) WITH KEEP-ALIVE
// ----------------------------------------------------
class _ComplaintListTab extends StatefulWidget {
  final bool isPending;
  final SortStrategy sortStrategy;
  final double topPadding;

  const _ComplaintListTab({
    required this.isPending,
    required this.sortStrategy,
    required this.topPadding,
  });

  @override
  State<_ComplaintListTab> createState() => _ComplaintListTabState();
}

class _ComplaintListTabState extends State<_ComplaintListTab> with AutomaticKeepAliveClientMixin {
  String _searchQuery = '';

  @override
  bool get wantKeepAlive => true;

  List<Complaint> _getFilteredAndSortedComplaints(List<Complaint> baseList) {
    var rawList = List<Complaint>.from(baseList);
    
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      rawList = rawList.where((c) {
        return c.customerName.toLowerCase().contains(q) ||
               c.customerNumber.toLowerCase().contains(q) ||
               c.brand.toLowerCase().contains(q) ||
               c.model.toLowerCase().contains(q) ||
               c.deviceType.toLowerCase().contains(q);
      }).toList();
    }

    switch (widget.sortStrategy) {
      case SortStrategy.date:
        rawList.sort((a, b) => DateTime.parse(b.createdAt).compareTo(DateTime.parse(a.createdAt)));
        break;
      case SortStrategy.name:
        rawList.sort((a, b) => a.customerName.compareTo(b.customerName));
        break;
      case SortStrategy.priority:
        rawList.sort((a, b) => b.priority.compareTo(a.priority));
        break;
    }
    return rawList;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final topPadding = widget.topPadding;
    final provider = Provider.of<ComplaintProvider>(context);
    final targetList = widget.isPending ? provider.pendingComplaints : provider.completedComplaints;
    final complaints = _getFilteredAndSortedComplaints(targetList);

    final searchBox = Padding(
      padding: EdgeInsets.only(top: topPadding, left: 24, right: 24, bottom: 16),
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: 'Search by name, phone, or unit...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withAlpha(20) : Colors.grey.shade100,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );

    if (complaints.isEmpty && _searchQuery.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No ${widget.isPending ? "pending" : "completed"} services.', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
          ],
        ),
      );
    }

    if (complaints.isEmpty) {
      return Column(
        children: [
          searchBox,
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No results found for "$_searchQuery".', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                ],
              ),
            ),
          )
        ],
      );
    }

    return Column(
      children: [
        searchBox,
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 120, left: 24, right: 24),
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              final item = complaints[index];
              final priorityColor = item.priority == 2 ? Colors.red.shade400 : (item.priority == 1 ? Colors.orange.shade400 : Colors.green.shade400);
              final formattedDate = DateFormat('MMM dd, yyyy h:mm a').format(DateTime.parse(item.createdAt));

              IconData getDeviceIcon(String type) {
                switch (type) {
                  case 'AC': return Icons.ac_unit;
                  case 'Fridge': return Icons.kitchen;
                  case 'Washing Machine': return Icons.local_laundry_service;
                  default: return Icons.home_repair_service;
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildGlassBox(
                  context,
                  padding: EdgeInsets.zero,
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      shape: const Border(),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(color: priorityColor.withAlpha(20), borderRadius: BorderRadius.circular(16)),
                        child: Icon(getDeviceIcon(item.deviceType), color: priorityColor, size: 20),
                      ),
                      title: Text(item.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('${item.brand} - ${item.deviceType}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                          const SizedBox(height: 4),
                          Text(formattedDate, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _detailRow(Icons.phone_outlined, item.customerNumber, onTap: () async {
                                 final Uri url = Uri.parse('tel:${item.customerNumber}');
                                 if (await canLaunchUrl(url)) {
                                   await launchUrl(url);
                                 }
                              }),
                              const SizedBox(height: 12),
                              _detailRow(Icons.propane_tank_outlined, 'Model: ${item.model}'),
                              const SizedBox(height: 12),
                              _detailRow(Icons.location_on_outlined, item.address, onTap: () async {
                                 final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(item.address)}');
                                 if (await canLaunchUrl(url)) {
                                   await launchUrl(url, mode: LaunchMode.externalApplication);
                                 }
                              }),
                              const SizedBox(height: 12),
                              _detailRow(Icons.description_outlined, item.issueDescription),
                              if (item.extraNotes != null && item.extraNotes!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                _detailRow(Icons.note_alt_outlined, "Notes: ${item.extraNotes!}"),
                              ],
                              if (item.spareIssue != null && item.spareIssue!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                _detailRow(Icons.settings_suggest_outlined, "Spares: ${item.spareIssue!}"),
                              ],
                              if (item.photoPath != null && item.photoPath!.isNotEmpty) ...[
                                 const SizedBox(height: 12),
                                 Row(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Icon(Icons.image_outlined, size: 18, color: Colors.grey.shade400),
                                     const SizedBox(width: 12),
                                     Expanded(
                                       child: Wrap(
                                         spacing: 8,
                                         runSpacing: 8,
                                          children: item.photoPath!.split('|').map((path) {
                                            final photoList = item.photoPath!.split('|');
                                            return GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => FullScreenImageViewer(
                                                      photoPaths: photoList,
                                                      initialIndex: photoList.indexOf(path),
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.file(File(path), width: 50, height: 50, fit: BoxFit.cover),
                                              ),
                                            );
                                          }).toList(),
                                       ),
                                     )
                                   ],
                                 )
                              ],
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.teal.withAlpha(50),
                                      foregroundColor: Colors.teal.shade400,
                                      elevation: 0,
                                    ),
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ComplaintDetailScreen(complaint: item),
                                      ),
                                    ),
                                    icon: const Icon(Icons.visibility_outlined, size: 18),
                                    label: const Text('View'),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.grey.withAlpha(50), 
                                      foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, 
                                      elevation: 0
                                    ),
                                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddComplaintScreen(existingComplaint: item))),
                                    icon: const Icon(Icons.edit_outlined, size: 18),
                                    label: const Text('Edit'),
                                  ),
                                  const SizedBox(width: 8),
                                  if (widget.isPending) 
                                    FilledButton.icon(
                                      style: FilledButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, elevation: 0),
                                      onPressed: () => provider.moveToCompleted(item),
                                      icon: const Icon(Icons.check_circle_outline, size: 18),
                                      label: const Text('Complete'),
                                    ),
                                  if (!widget.isPending)
                                    FilledButton.icon(
                                      style: FilledButton.styleFrom(backgroundColor: Colors.red.withAlpha(30), foregroundColor: Colors.red.shade400, elevation: 0),
                                      onPressed: () => provider.moveToTrash(item),
                                      icon: const Icon(Icons.delete_outline, size: 18),
                                      label: const Text('Delete'),
                                    ),
                                ],
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
