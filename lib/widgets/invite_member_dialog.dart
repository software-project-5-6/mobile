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

  // Role Descriptions 
  final Map<String, String> _roleDescriptions = {
    "MANAGER": "Can manage members, edit project settings, and upload files.",
    "CONTRIBUTOR": "Can upload and edit files, but cannot manage members.",
    "VIEWER": "Can only view and download files. Read-only access.",
  };

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Creates a non-dismissible loading overlay
  void _showLoadingOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevents closing by tapping outside
      barrierColor: Colors.black.withOpacity(0.6), // Dark background matching web
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 24),
              Text(
                "Sending Invitation...",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Please wait while we send the invitation",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        );
      },
    );
  }

  // Creates the green success pop-up
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF4ade80), // Bright green accent
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Invitation Sent Successfully!",
                  style: TextStyle(
                    color: Color(0xFF4ade80),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  "The invitation has been sent successfully. The user will receive an email with instructions to join the project.",
                  style: TextStyle(color: Colors.grey[600], height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4ade80),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context); // Close the success dialog
                    },
                    child: const Text(
                      "OK",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSend() async {
    if (!_formKey.currentState!.validate()) return;

    // 1. Show the Loading Overlay
    _showLoadingOverlay();

    try {
      await _invitationService.sendInvitation(
        widget.projectId,
        _emailController.text.trim(),
        _selectedRole,
      );

      if (mounted) {
        Navigator.pop(context); // Dismiss the Loading Overlay
        Navigator.pop(context); // Dismiss the Invite Form Dialog
        
        widget.onSuccess(); // Refresh parent list
        
        // 2. Show the Success Dialog
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss the Loading Overlay on error

        String errorText = e.toString();
        String displayMessage = "Failed to send invite. Please try again.";
        Color snackBarColor = Colors.red;

        // Handle the 409 Conflict specifically
        if (errorText.contains("409")) {
          displayMessage = "A pending invitation already exists for this user.";
          snackBarColor = Colors.orange;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(displayMessage),
            backgroundColor: snackBarColor,
          ),
        );
      }
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Email is required";
                  }
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: "MANAGER", child: Text("Manager")),
                  DropdownMenuItem(
                    value: "CONTRIBUTOR",
                    child: Text("Contributor"),
                  ),
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
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _handleSend,
                    icon: const Icon(Icons.send, size: 18),
                    label: const Text("Send Invitation"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B6BBF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
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