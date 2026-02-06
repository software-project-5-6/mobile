import 'package:flutter/material.dart';
import '../services/invitation_service.dart';

class InviteMemberDialog extends StatefulWidget {
  final String projectId;
  final VoidCallback onSuccess;

  const InviteMemberDialog({
    super.key,
    required this.projectId,
    required this.onSuccess,
  });

  @override
  State<InviteMemberDialog> createState() => _InviteMemberDialogState();
}

class _InviteMemberDialogState extends State<InviteMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  final _invitationService = InvitationService();
  
  final TextEditingController _emailController = TextEditingController();
  String _selectedRole = "VIEWER";
  bool _isLoading = false;

  // Role Descriptions (Matches your React code)
  final Map<String, String> _roleDescriptions = {
    "MANAGER": "Can manage members, edit project settings, and upload files.",
    "CONTRIBUTOR": "Can upload and edit files, but cannot manage members.",
    "VIEWER": "Can only view and download files. Read-only access."
  };

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _invitationService.sendInvitation(
        widget.projectId,
        _emailController.text.trim(),
        _selectedRole,
      );

      if (mounted) {
        Navigator.pop(context); // Close dialog
        widget.onSuccess(); // Refresh parent list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invitation sent successfully!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send invite: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: const [
                  Icon(Icons.person_add, color: Color(0xFF5B6BBF)),
                  SizedBox(width: 10),
                  Text(
                    "Invite User to Project",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Send an invitation by email. The user will receive a link to join.",
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 24),

              // Email Input
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email Address *",
                  hintText: "user@example.com",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Email is required";
                  if (!value.contains("@")) return "Invalid email format";
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Role Dropdown
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: InputDecoration(
                  labelText: "Role *",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                items: const [
                  DropdownMenuItem(value: "MANAGER", child: Text("Manager")),
                  DropdownMenuItem(value: "CONTRIBUTOR", child: Text("Contributor")),
                  DropdownMenuItem(value: "VIEWER", child: Text("Viewer")),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
              ),
              
              // Dynamic Helper Text
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 4),
                child: Text(
                  _roleDescriptions[_selectedRole]!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
                ),
              ),

              const SizedBox(height: 30),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleSend,
                    icon: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : const Icon(Icons.send, size: 18),
                    label: Text(_isLoading ? "Sending..." : "Send Invitation"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B6BBF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}