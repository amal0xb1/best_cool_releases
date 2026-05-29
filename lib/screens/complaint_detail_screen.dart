import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/complaint.dart';
import '../providers/complaint_provider.dart';
import 'add_complaint_screen.dart';
import 'full_screen_image_viewer.dart';

class ComplaintDetailScreen extends StatefulWidget {
  final Complaint complaint;

  const ComplaintDetailScreen({super.key, required this.complaint});

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  late Complaint _currentComplaint;

  @override
  void initState() {
    super.initState();
    _currentComplaint = widget.complaint;
  }

  Future<void> _makeCall(String phoneNumber) async {
    final Uri url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch dialer')),
        );
      }
    }
  }

  Future<void> _openMap(String address) async {
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch Google Maps')),
        );
      }
    }
  }

  Widget _buildGlassContainer({required Widget child, EdgeInsetsGeometry? padding}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(15) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(55) : Colors.grey.shade200,
          width: 1.2,
        ),
        boxShadow: isDark
            ? null
            : [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Find updated version of complaint if it was edited
    return Consumer<ComplaintProvider>(
      builder: (context, provider, child) {
        // Retrieve the latest data for this complaint from the provider lists
        Complaint? updated;
        try {
          updated = provider.pendingComplaints.firstWhere((c) => c.id == _currentComplaint.id);
        } catch (_) {
          try {
            updated = provider.completedComplaints.firstWhere((c) => c.id == _currentComplaint.id);
          } catch (_) {
            try {
              updated = provider.trashedComplaints.firstWhere((c) => c.id == _currentComplaint.id);
            } catch (_) {}
          }
        }
        
        if (updated != null) {
          _currentComplaint = updated;
        }

        final item = _currentComplaint;
        final formattedDate = DateFormat('MMMM dd, yyyy - hh:mm a').format(DateTime.parse(item.createdAt));
        final priorityColor = item.priority == 2 ? Colors.red.shade400 : (item.priority == 1 ? Colors.orange.shade400 : Colors.green.shade400);
        final priorityText = item.priority == 2 ? 'High Priority' : (item.priority == 1 ? 'Medium Priority' : 'Low Priority');
        
        IconData getDeviceIcon(String type) {
          switch (type) {
            case 'AC': return Icons.ac_unit;
            case 'Fridge': return Icons.kitchen;
            case 'Washing Machine': return Icons.local_laundry_service;
            default: return Icons.home_repair_service;
          }
        }

        final photoList = item.photoPath != null && item.photoPath!.isNotEmpty
            ? item.photoPath!.split('|')
            : <String>[];

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text('Service details', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor.withAlpha(150),
            elevation: 0,
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                child: Container(color: Colors.transparent),
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 110, left: 16, right: 16, bottom: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Device Header Card
                  _buildGlassContainer(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: priorityColor.withAlpha(30),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: priorityColor.withAlpha(100), width: 1.5),
                              ),
                              child: Icon(getDeviceIcon(item.deviceType), color: priorityColor, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.brand.isEmpty ? 'Generic Brand' : item.brand,
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.deviceType,
                                    style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: item.status == 'COMPLETED' ? Colors.green.withAlpha(40) : Colors.orange.withAlpha(40),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: item.status == 'COMPLETED' ? Colors.green.shade400 : Colors.orange.shade400,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                item.status,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: item.status == 'COMPLETED' ? Colors.green.shade400 : Colors.orange.shade400,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.priority_high, size: 16, color: priorityColor),
                                const SizedBox(width: 4),
                                Text(
                                  priorityText,
                                  style: TextStyle(fontWeight: FontWeight.bold, color: priorityColor, fontSize: 13),
                                ),
                              ],
                            ),
                            Text(
                              'Model: ${item.model.isEmpty ? "N/A" : item.model}',
                              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 8),
                            Text(
                              formattedDate,
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Customer Information Card
                  _buildGlassContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Customer Details',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.teal),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: Colors.teal.withAlpha(20),
                            child: const Icon(Icons.person, color: Colors.teal),
                          ),
                          title: const Text('Name', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          subtitle: Text(
                            item.customerName,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.withAlpha(20),
                            child: const Icon(Icons.phone, color: Colors.blue),
                          ),
                          title: const Text('Phone Number', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          subtitle: Text(
                            item.customerNumber,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          trailing: IconButton.filledTonal(
                            onPressed: () => _makeCall(item.customerNumber),
                            icon: const Icon(Icons.call),
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: Colors.red.withAlpha(20),
                            child: const Icon(Icons.location_on, color: Colors.red),
                          ),
                          title: const Text('Address Location', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          subtitle: Text(
                            item.address,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          trailing: IconButton.filledTonal(
                            onPressed: () => _openMap(item.address),
                            icon: const Icon(Icons.map),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Job Description & Notes Card
                  _buildGlassContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Job Details',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.teal),
                        ),
                        const SizedBox(height: 16),
                        const Text('Main Issue Description', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          item.issueDescription.isEmpty ? 'No description provided' : item.issueDescription,
                          style: const TextStyle(fontSize: 14, height: 1.4),
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        const Text('Extra Notes', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          item.extraNotes ?? 'None',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: item.extraNotes == null ? Colors.grey.shade500 : null,
                            fontStyle: item.extraNotes == null ? FontStyle.italic : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        const Text('Required Spare Parts', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          item.spareIssue ?? 'None',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: item.spareIssue == null ? Colors.grey.shade500 : null,
                            fontStyle: item.spareIssue == null ? FontStyle.italic : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. Photo Attachments
                  if (photoList.isNotEmpty) ...[
                    _buildGlassContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Photos & Attachments',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.teal),
                          ),
                          const SizedBox(height: 16),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: photoList.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemBuilder: (context, index) {
                              final path = photoList[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FullScreenImageViewer(
                                        photoPaths: photoList,
                                        initialIndex: index,
                                      ),
                                    ),
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    File(path),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey.withAlpha(40),
                                        child: const Icon(Icons.broken_image, color: Colors.grey),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 5. Actions row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.grey.shade400),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddComplaintScreen(existingComplaint: item),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit Details'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () {
                            if (item.status == 'PENDING') {
                              provider.moveToCompleted(item);
                            } else {
                              // If completed or trashed, restore to pending or completed
                              provider.restoreFromTrash(item); // this sets status to COMPLETED, but we want pending
                              // Wait, restoreFromTrash sets it to COMPLETED. What if it's completed and we want pending?
                              // Currently the ComplaintProvider does not have a moveToPending, but we can do updateComplaint with status: 'PENDING'
                              final pendingComplaint = item.copyWith(status: 'PENDING');
                              provider.updateComplaint(pendingComplaint);
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  item.status == 'PENDING'
                                      ? 'Job completed successfully!'
                                      : 'Job marked as active pending.',
                                ),
                              ),
                            );
                          },
                          icon: Icon(
                            item.status == 'PENDING'
                                ? Icons.check_circle_outline
                                : Icons.restore_outlined,
                          ),
                          label: Text(
                            item.status == 'PENDING' ? 'Complete Job' : 'Mark Pending',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.redAccent, width: 1.2),
                      foregroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Move to Trash?'),
                          content: const Text('This will move the service request to the recycle bin.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('CANCEL'),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              onPressed: () {
                                provider.moveToTrash(item);
                                Navigator.pop(context); // dialog
                                Navigator.pop(context); // details screen
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Service request moved to recycle bin')),
                                );
                              },
                              child: const Text('TRASH'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Trash Service Request'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
