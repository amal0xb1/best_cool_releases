import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:call_log/call_log.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/complaint_provider.dart';
import '../models/complaint.dart';
import 'full_screen_image_viewer.dart';

class AddComplaintScreen extends StatefulWidget {
  final Complaint? existingComplaint;
  const AddComplaintScreen({super.key, this.existingComplaint});

  @override
  State<AddComplaintScreen> createState() => _AddComplaintScreenState();
}

class _AddComplaintScreenState extends State<AddComplaintScreen> {
  final _formKey = GlobalKey<FormState>();

  String _deviceType = 'AC';
  final List<String> _deviceTypes = ['AC', 'Fridge', 'Washing Machine', 'Other'];

  String _brandParam = '';
  final List<String> _topBrands = ['LG', 'Samsung', 'Whirlpool', 'Panasonic', 'Lloyd', 'Haier', 'Bosch', 'Voltas', 'Hitachi', 'Daikin', 'Godrej', 'Carrier', 'Blue Star', 'IFB', 'O General'];

  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _issueController = TextEditingController();
  final _extraNotesController = TextEditingController();
  final _spareIssueController = TextEditingController();
  final _addressController = TextEditingController();

  final List<String> _photoPaths = [];
  double? _latitude;
  double? _longitude;
  int _priority = 1;

  bool _isLoadingLocation = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.existingComplaint != null) {
      final c = widget.existingComplaint!;
      _deviceType = c.deviceType;
      if (_topBrands.contains(c.brand)) {
        _brandParam = c.brand;
      } else {
        _brandController.text = c.brand;
      }
      _modelController.text = c.model;
      _nameController.text = c.customerName;
      _phoneController.text = c.customerNumber;
      _issueController.text = c.issueDescription;
      _extraNotesController.text = c.extraNotes ?? '';
      _spareIssueController.text = c.spareIssue ?? '';
      _addressController.text = c.address;
      _priority = c.priority;
      _latitude = c.latitude;
      _longitude = c.longitude;
      if (c.photoPath != null && c.photoPath!.isNotEmpty) {
        _photoPaths.addAll(c.photoPath!.split('|'));
      }
    }
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _issueController.dispose();
    _extraNotesController.dispose();
    _spareIssueController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          _photoPaths.add(photo.path);
        });
      }
    } else {
      _showErrorSnackBar('Camera permission is required');
    }
  }

  Future<void> _getLocation() async {
    setState(() => _isLoadingLocation = true);

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isLoadingLocation = false);
      _showErrorSnackBar('Location services are disabled.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLoadingLocation = false);
        _showErrorSnackBar('Location permissions are denied');
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      _latitude = position.latitude;
      _longitude = position.longitude;

      List<Placemark> placemarks = await placemarkFromCoordinates(_latitude!, _longitude!);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _addressController.text = "${place.street}, ${place.locality}, ${place.administrativeArea}";
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to get location');
    }

    setState(() => _isLoadingLocation = false);
  }

  Future<void> _openCallLog() async {
    final status = await Permission.phone.request();
    
    if (status.isGranted) {
        try {
          Iterable<CallLogEntry> entries = await CallLog.get();
          List<CallLogEntry> callLogs = entries.take(50).toList();

          if (!mounted) return;
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (BuildContext bc) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return Container(
                height: MediaQuery.of(context).size.height * 0.6,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161E1D).withOpacity(0.94) : Colors.white.withOpacity(0.96),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  border: Border.all(
                    color: isDark ? Colors.white.withAlpha(30) : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withAlpha(60) : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Recent Calls',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: callLogs.length,
                              itemBuilder: (context, index) {
                                final log = callLogs[index];
                                return ListTile(
                                  leading: Icon(
                                      log.callType == CallType.missed ? Icons.call_missed :
                                      log.callType == CallType.incoming ? Icons.call_received : Icons.call_made,
                                      color: log.callType == CallType.missed ? Colors.red : Colors.green,
                                  ),
                                  title: Text(
                                    log.name ?? 'Unknown',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  subtitle: Text(
                                    log.number ?? '',
                                    style: TextStyle(
                                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                    ),
                                  ),
                                  onTap: () {
                                    if (log.number != null) {
                                      setState(() {
                                        _phoneController.text = log.number!;
                                      });
                                    }
                                    Navigator.pop(bc);
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
          );
        } catch (e) {
          _showErrorSnackBar('Error fetching call logs.');
        }
    } else {
      _showErrorSnackBar('Call Log permission is required');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _saveComplaint() {
    if (_formKey.currentState!.validate()) {
      final complaint = Complaint(
        id: widget.existingComplaint?.id,
        deviceType: _deviceType,
        brand: (_brandParam.isNotEmpty ? _brandParam : _brandController.text).trim(),
        model: _modelController.text.trim(),
        customerName: _nameController.text.trim(),
        customerNumber: _phoneController.text.trim(),
        issueDescription: _issueController.text.trim(),
        extraNotes: _extraNotesController.text.trim().isEmpty ? null : _extraNotesController.text.trim(),
        spareIssue: _spareIssueController.text.trim().isEmpty ? null : _spareIssueController.text.trim(),
        address: _addressController.text.trim(),
        photoPath: _photoPaths.isEmpty ? null : _photoPaths.join('|'),
        latitude: _latitude,
        longitude: _longitude,
        priority: _priority,
        status: widget.existingComplaint?.status ?? 'PENDING',
        createdAt: widget.existingComplaint?.createdAt ?? DateTime.now().toIso8601String(),
      );

      if (widget.existingComplaint != null) {
        Provider.of<ComplaintProvider>(context, listen: false).updateComplaint(complaint);
      } else {
        Provider.of<ComplaintProvider>(context, listen: false).addComplaint(complaint);
      }
      Navigator.pop(context);
    }
  }

  Widget _buildGlassContainer({required Widget child, EdgeInsetsGeometry? padding}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(20) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(60) : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.existingComplaint != null ? 'Edit Request' : 'New Service Request', style: const TextStyle(fontWeight: FontWeight.bold)),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 110, left: 16, right: 16, bottom: 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildGlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Device Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _deviceTypes.map((type) {
                        IconData icon;
                        switch (type) {
                          case 'AC': icon = Icons.ac_unit; break;
                          case 'Fridge': icon = Icons.kitchen; break;
                          case 'Washing Machine': icon = Icons.local_laundry_service; break;
                          default: icon = Icons.home_repair_service;
                        }
                        return ChoiceChip(
                          avatar: Icon(icon, size: 18, color: _deviceType == type ? Colors.white : Colors.grey.shade600),
                          label: Text(type),
                          selected: _deviceType == type,
                          onSelected: (selected) {
                            if (selected) setState(() => _deviceType = type);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('Top Brands', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 45,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _topBrands.length,
                        itemBuilder: (context, index) {
                          final b = _topBrands[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(b),
                              selected: _brandParam == b,
                              onSelected: (selected) {
                                setState(() {
                                  _brandParam = selected ? b : '';
                                  if (selected) _brandController.clear();
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    if (_brandParam.isEmpty) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _brandController,
                        decoration: const InputDecoration(labelText: 'Other Brand', border: OutlineInputBorder()),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _modelController,
                      decoration: const InputDecoration(labelText: 'Model Number (Optional)', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              _buildGlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Customer Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.phone),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.contact_phone, color: Colors.teal),
                          onPressed: _openCallLog,
                        ),
                      ),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Address Location',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.map),
                        suffixIcon: _isLoadingLocation 
                          ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())
                          : IconButton(
                              icon: const Icon(Icons.my_location, color: Colors.teal),
                              onPressed: _getLocation,
                            ),
                      ),
                      validator: (value) => value!.isEmpty ? 'Address is required' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _buildGlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Issue & Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _issueController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Main Issue Description (Optional)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _extraNotesController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Extra Notes (Optional)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _spareIssueController,
                      maxLines: 1,
                      decoration: const InputDecoration(labelText: 'Required Spare Parts (Optional)', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _buildGlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Priority', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 0, label: Text('Low')),
                        ButtonSegment(value: 1, label: Text('Medium')),
                        ButtonSegment(value: 2, label: Text('High')),
                      ],
                      selected: {_priority},
                      onSelectionChanged: (Set<int> newSelection) {
                        setState(() {
                          _priority = newSelection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        ..._photoPaths.map((path) => Stack(
                          clipBehavior: Clip.none,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FullScreenImageViewer(
                                      photoPaths: _photoPaths,
                                      initialIndex: _photoPaths.indexOf(path),
                                    ),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(File(path), fit: BoxFit.cover, width: 90, height: 90),
                              ),
                            ),
                            Positioned(
                              top: -6, right: -6,
                              child: InkWell(
                                onTap: () => setState(() => _photoPaths.remove(path)),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                                )
                              )
                            )
                          ]
                        )),
                        InkWell(
                          onTap: _takePhoto,
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade100,
                              border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
                              borderRadius: BorderRadius.circular(12)
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, size: 28, color: Colors.grey.shade500),
                                const SizedBox(height: 4),
                                Text('Add Photo', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                ),
                onPressed: _saveComplaint,
                child: const Text('SUBMIT REQUEST'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
