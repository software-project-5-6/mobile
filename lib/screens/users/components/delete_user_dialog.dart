import 'package:flutter/material.dart';
import '../../../services/user_service.dart';

class DeleteUserDialog extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onDeleteSuccess;

  const DeleteUserDialog({super.key, required this.user, required this.onDeleteSuccess});

  @override
  State<DeleteUserDialog> createState() => _DeleteUserDialogState();
}

class _DeleteUserDialogState extends State<DeleteUserDialog> {
  bool _isDeleting = false;

  Future<void> _handleDelete() async {
    setState(() => _isDeleting = true);
    
    try {
      final UserService userService = UserService();
      await userService.deleteUser(widget.user['id'].toString());
      
      widget.onDeleteSuccess(); // Refresh the list
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isDeleting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete user. Please try again.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            width: double.infinity,
            color: Colors.red.withOpacity(0.08),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))]),
                  child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 36),
                ),
                const SizedBox(height: 16),
                const Text("Delete User?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text("You are about to permanently delete this account.", style: TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8), color: Colors.grey.shade50),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF5B6BBF).withOpacity(0.1),
                        child: Text((widget.user['fullName'] ?? 'U')[0].toUpperCase(), style: const TextStyle(color: Color(0xFF5B6BBF), fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.user['fullName'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(widget.user['email'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("⚠️", style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Warning: This action cannot be undone. All associated data will be removed immediately.",
                          style: TextStyle(color: Colors.red.shade900, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: _isDeleting ? null : () => Navigator.pop(context),
                      child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
                      onPressed: _isDeleting ? null : _handleDelete,
                      icon: _isDeleting ? const SizedBox.shrink() : const Icon(Icons.delete, color: Colors.white, size: 16),
                      label: _isDeleting 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Yes, Delete User", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    )
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}