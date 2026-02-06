import 'package:flutter/material.dart';

class DeleteProjectDialog extends StatelessWidget {
  final String projectName;
  final VoidCallback onConfirm;

  const DeleteProjectDialog({
    super.key,
    required this.projectName,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias, // Ensures the header gradient respects rounded corners
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- PINK GRADIENT HEADER ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFEC4899), Color(0xFFF472B6)], // Pink Gradient
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Text(
              "Confirm Delete",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // --- CONTENT ---
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                    children: [
                      const TextSpan(text: "Are you sure you want to delete the project "),
                      TextSpan(
                        text: '"$projectName"',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: "?"),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "This action cannot be undone.",
                  style: TextStyle(color: Colors.red, fontSize: 14),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // --- ACTIONS ---
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    onConfirm();
                    Navigator.pop(context); // Close dialog
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Delete", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}