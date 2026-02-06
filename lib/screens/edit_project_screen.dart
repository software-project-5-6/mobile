import 'package:flutter/material.dart';
import '../services/project_service.dart';

class EditProjectScreen extends StatefulWidget {
  final Map<String, dynamic> project;
  final VoidCallback? onProjectUpdated;

  const EditProjectScreen({
    super.key, 
    required this.project, 
    this.onProjectUpdated
  });

  @override
  State<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends State<EditProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProjectService _projectService = ProjectService();
  bool _isLoading = false;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _iconUrlController;
  late TextEditingController _clientNameController;
  late TextEditingController _clientEmailController;
  late TextEditingController _clientPhoneController;

  @override
  void initState() {
    super.initState();
    // PRE-FILL THE DATA
    final p = widget.project;
    _nameController = TextEditingController(text: p['projectName'] ?? p['name'] ?? '');
    _descriptionController = TextEditingController(text: p['description'] ?? '');
    _priceController = TextEditingController(text: p['price']?.toString() ?? '');
    _iconUrlController = TextEditingController(text: p['iconUrl'] ?? '');
    _clientNameController = TextEditingController(text: p['clientName'] ?? '');
    _clientEmailController = TextEditingController(text: p['clientEmail'] ?? '');
    _clientPhoneController = TextEditingController(text: p['clientPhone'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _iconUrlController.dispose();
    _clientNameController.dispose();
    _clientEmailController.dispose();
    _clientPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edit Project", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                "Update your project details and client information",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 25),

              // --- SECTION 1: PROJECT DETAILS ---
              _buildSectionHeader("PROJECT DETAILS"),
              
              _buildTextField(
                label: "Project Name *",
                controller: _nameController,
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 15),
              
              _buildTextField(
                label: "Description",
                controller: _descriptionController,
                maxLines: 3,
              ),
              const SizedBox(height: 15),
              
              _buildTextField(
                label: "Project Price",
                controller: _priceController,
                prefixIcon: Icons.attach_money,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 15),

              _buildTextField(
                label: "Project Icon URL",
                controller: _iconUrlController,
                prefixIcon: Icons.image_outlined,
              ),

              const SizedBox(height: 30),

              // --- SECTION 2: CLIENT INFORMATION ---
              _buildSectionHeader("CLIENT INFORMATION"),

              _buildTextField(
                label: "Client Name *",
                controller: _clientNameController,
                prefixIcon: Icons.person_outline,
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 15),

              _buildTextField(
                label: "Email *",
                controller: _clientEmailController,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v!.isEmpty || !v.contains("@") ? "Invalid email" : null,
              ),
              const SizedBox(height: 15),

              _buildTextField(
                label: "Phone *",
                controller: _clientPhoneController,
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),

              const SizedBox(height: 30),

              // --- ACTION BUTTONS ---
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleUpdate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange, // Matches the "Warning" color in your React code
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Save Changes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPERS ---
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(
        title,
        style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    IconData? prefixIcon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.grey, size: 20) : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.grey)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.orange, width: 2)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ],
    );
  }

  // --- LOGIC ---
  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Prepare data (Exact same structure as your React Code)
    final projectData = {
      "projectName": _nameController.text,
      "description": _descriptionController.text,
      "price": double.tryParse(_priceController.text) ?? 0.0,
      "iconUrl": _iconUrlController.text,
      "clientName": _clientNameController.text,
      "clientEmail": _clientEmailController.text,
      "clientPhone": _clientPhoneController.text,
      // Preserve existing fields
      "artifactCount": widget.project['artifactCount'] ?? 0,
    };

    try {
      final id = widget.project['id']?.toString() ?? widget.project['projectId']?.toString();
      
      if (id == null) throw Exception("Project ID not found");

      await _projectService.updateProject(id, projectData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Project Updated Successfully!")),
        );
        if (widget.onProjectUpdated != null) {
          widget.onProjectUpdated!(); // Refresh list
        }
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}