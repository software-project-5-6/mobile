import 'package:flutter/material.dart';

class ViewUserDialog extends StatelessWidget {
  final Map<String, dynamic> user;

  const ViewUserDialog({super.key, required this.user});

  String _formatDate(String? dateString) {
    if (dateString == null) return "N/A";
    try {
      final date = DateTime.parse(dateString);
      const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
      return "${months[date.month - 1]} ${date.day}, ${date.year}";
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = user['globalRole'] == 'APP_ADMIN';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("User Details", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                ],
              ),
              const SizedBox(height: 4),
              const Text("View system information and role permissions", style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 24),
              
              const Text("PROFILE INFORMATION", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
              const SizedBox(height: 16),
              
              _buildInfoRow(Icons.person, "FULL NAME", user['fullName'] ?? 'N/A'),
              const SizedBox(height: 16),
              _buildInfoRow(Icons.email, "EMAIL ADDRESS", user['email'] ?? 'N/A'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildInfoRow(Icons.admin_panel_settings, "ROLE", isAdmin ? "Administrator" : "User", valueColor: isAdmin ? Colors.red : const Color(0xFF5B6BBF))),
                  Expanded(child: _buildInfoRow(Icons.calendar_today, "JOINED DATE", _formatDate(user['createdAt']))),
                ],
              ),
              
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), border: Border.all(color: Colors.blue.withOpacity(0.2)), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info, color: Colors.blue, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "This is a read-only view.",
                        style: TextStyle(color: Colors.grey.shade800, fontSize: 12),
                      ),
                    )
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B6BBF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close", style: TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color valueColor = Colors.black87}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}