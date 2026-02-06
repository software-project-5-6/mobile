import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/artifact_service.dart';

class ArtifactUploadDialog extends StatefulWidget {
  final String projectId;
  final VoidCallback onSuccess;

  const ArtifactUploadDialog({super.key, required this.projectId, required this.onSuccess});

  @override
  State<ArtifactUploadDialog> createState() => _ArtifactUploadDialogState();
}

class _ArtifactUploadDialogState extends State<ArtifactUploadDialog> {
  final _artifactService = ArtifactService();
  File? _selectedFile;
  final _tagsController = TextEditingController();
  bool _isUploading = false;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _upload() async {
    if (_selectedFile == null) return;

    setState(() => _isUploading = true);
    try {
      await _artifactService.uploadArtifact(
        widget.projectId,
        _selectedFile!,
        _tagsController.text,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("File uploaded successfully!")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Upload Artifact", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            // File Picker Area
            InkWell(
              onTap: _pickFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid), // Dashed border is harder in pure Flutter without external packages
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(Icons.cloud_upload, size: 40, color: Colors.blue[300]),
                    const SizedBox(height: 10),
                    Text(
                      _selectedFile != null ? _selectedFile!.path.split('/').last : "Tap to select file",
                      style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Tags Input
            TextField(
              controller: _tagsController,
              decoration: InputDecoration(
                labelText: "Tags (comma separated)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isUploading ? null : () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: (_isUploading || _selectedFile == null) ? null : _upload,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B6BBF), foregroundColor: Colors.white),
                  child: _isUploading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Upload"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}