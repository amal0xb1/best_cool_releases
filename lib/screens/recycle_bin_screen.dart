import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/complaint_provider.dart';

class RecycleBinScreen extends StatelessWidget {
  const RecycleBinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recycle Bin'),
        backgroundColor: Colors.grey.shade200,
        foregroundColor: Colors.black87,
      ),
      body: Consumer<ComplaintProvider>(
        builder: (context, provider, child) {
          final trashed = provider.trashedComplaints;

          if (trashed.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('Recycle bin is empty.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: trashed.length,
            itemBuilder: (context, index) {
              final item = trashed[index];
              return Card(
                elevation: 1,
                color: Colors.grey.shade50,
                child: ListTile(
                  leading: const Icon(Icons.delete, color: Colors.redAccent),
                  title: Text(item.customerName, style: const TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.lineThrough)),
                  subtitle: Text('${item.brand} - ${item.model}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.restore, color: Colors.green),
                        tooltip: 'Restore',
                        onPressed: () {
                          provider.restoreFromTrash(item);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_forever, color: Colors.red),
                        tooltip: 'Delete Permanently',
                        onPressed: () {
                          _showDeleteDialog(context, provider, item.id!);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, ComplaintProvider provider, int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Permanently?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              provider.deletePermanently(id);
              Navigator.pop(context);
            },
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
}
