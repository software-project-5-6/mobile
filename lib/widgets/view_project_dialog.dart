import 'package:flutter/material.dart';

class ViewProjectDialog extends StatelessWidget {
  final dynamic project;

  const ViewProjectDialog({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    // 1. Safely Extract Data
    final name = project['projectName'] ?? project['name'] ?? 'N/A';
    final description = project['description'] ?? 'No description provided';
    final price = project['price'] != null
        ? "\$${double.tryParse(project['price'].toString())?.toStringAsFixed(2) ?? '0.00'}"
        : "\$0.00";
    final created = _formatDate(project['createdAt'] ?? project['createdDate']);
    final artifacts = project['artifactCount']?.toString() ?? '0';
    final clientName = project['clientName'] ?? 'N/A';
    final clientEmail = project['clientEmail'] ?? 'N/A';
    final clientPhone = project['clientPhone'] ?? 'N/A';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(16), // Makes it look like a popup
      child: Column(
        mainAxisSize: MainAxisSize.min, // Wrap content height
        children: [
          // --- HEADER ---
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Project Details",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "View project information and client details",
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // --- SCROLLABLE CONTENT ---
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SECTION 1: PROJECT DETAILS
                  _buildSectionLabel("PROJECT DETAILS"),
                  const SizedBox(height: 12),

                  _buildInfoBox(Icons.folder, "Project Name", name, isBold: true),
                  const SizedBox(height: 16),
                  
                  _buildInfoBox(null, "Description", description),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(child: _buildInfoBox(Icons.attach_money, "Price", price, textColor: Colors.green, isBold: true)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildInfoBox(Icons.calendar_today, "Created", created, isBold: true)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  _buildInfoBox(null, "Artifact Count", "$artifacts artifacts", isBold: true),

                  const SizedBox(height: 32),

                  // SECTION 2: CLIENT INFORMATION
                  _buildSectionLabel("CLIENT INFORMATION"),
                  const SizedBox(height: 12),

                  _buildInfoBox(Icons.person, "Client Name", clientName, isBold: true),
                  const SizedBox(height: 16),
                  
                  _buildInfoBox(Icons.email, "Email Address", clientEmail, isBold: true),
                  const SizedBox(height: 16),
                  
                  _buildInfoBox(Icons.phone, "Phone Number", clientPhone, isBold: true),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // --- FOOTER ---
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B6BBF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Close", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildInfoBox(IconData? icon, String label, String value, {bool isBold = false, Color? textColor}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.only(left: icon != null ? 24.0 : 0),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: textColor ?? const Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return "N/A";
    try {
      final date = DateTime.parse(dateStr);
      const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
      return "${months[date.month - 1]} ${date.day}, ${date.year}";
    } catch (e) {
      return dateStr;
    }
  }
}