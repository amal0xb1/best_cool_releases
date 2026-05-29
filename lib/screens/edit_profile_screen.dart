import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/settings_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _roleController = TextEditingController();
  String? _photoPath;

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _nameController.text = settings.userName;
    _roleController.text = settings.userRole;
    _photoPath = settings.userPhotoPath;
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _photoPath = image.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: _photoPath != null ? FileImage(File(_photoPath!)) : null,
                child: _photoPath == null ? const Icon(Icons.camera_alt, size: 40, color: Colors.white) : null,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _roleController,
              decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () {
                Provider.of<SettingsProvider>(context, listen: false)
                    .updateProfile(name: _nameController.text, role: _roleController.text, photoPath: _photoPath);
                Navigator.pop(context);
              },
              child: const Text('Save Profile'),
            )
          ],
        ),
      ),
    );
  }
}
