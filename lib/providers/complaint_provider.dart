import 'package:flutter/material.dart';
import '../models/complaint.dart';
import '../services/database_helper.dart';

class ComplaintProvider with ChangeNotifier {
  List<Complaint> _pendingComplaints = [];
  List<Complaint> _completedComplaints = [];
  List<Complaint> _trashedComplaints = [];

  List<Complaint> get pendingComplaints => _pendingComplaints;
  List<Complaint> get completedComplaints => _completedComplaints;
  List<Complaint> get trashedComplaints => _trashedComplaints;

  ComplaintProvider() {
    loadComplaints();
  }

  Future<void> loadComplaints() async {
    _pendingComplaints = await DatabaseHelper.instance.readComplaintsByStatus('PENDING');
    _completedComplaints = await DatabaseHelper.instance.readComplaintsByStatus('COMPLETED');
    _trashedComplaints = await DatabaseHelper.instance.readComplaintsByStatus('TRASHED');
    notifyListeners();
  }

  Future<void> addComplaint(Complaint complaint) async {
    await DatabaseHelper.instance.create(complaint);
    await loadComplaints();
  }

  Future<void> updateComplaint(Complaint complaint) async {
    await DatabaseHelper.instance.update(complaint);
    await loadComplaints();
  }

  Future<void> moveToCompleted(Complaint complaint) async {
    final updated = complaint.copyWith(status: 'COMPLETED');
    await DatabaseHelper.instance.update(updated);
    await loadComplaints();
  }

  Future<void> moveToTrash(Complaint complaint) async {
    final updated = complaint.copyWith(status: 'TRASHED');
    await DatabaseHelper.instance.update(updated);
    await loadComplaints();
  }

  Future<void> restoreFromTrash(Complaint complaint) async {
    final updated = complaint.copyWith(status: 'COMPLETED');
    await DatabaseHelper.instance.update(updated);
    await loadComplaints();
  }

  Future<void> deletePermanently(int id) async {
    await DatabaseHelper.instance.delete(id);
    await loadComplaints();
  }

  Future<String> backupData() async {
    return await DatabaseHelper.instance.backupDatabase();
  }

  Future<bool> restoreData() async {
    final success = await DatabaseHelper.instance.restoreDatabase();
    if (success) {
      await loadComplaints();
    }
    return success;
  }
}
