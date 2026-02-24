import 'package:flutter/material.dart';
import '../../services/artifact_service.dart';
import '../../widgets/artifact_upload_dialog.dart';

class ProjectArtifactsTab extends StatefulWidget {
  final Map<String, dynamic> project;

  const ProjectArtifactsTab({super.key, required this.project});

  @override
  State<ProjectArtifactsTab> createState() => _ProjectArtifactsTabState();
}

class _ProjectArtifactsTabState extends State<ProjectArtifactsTab> {
  final ArtifactService _artifactService = ArtifactService();
  List<dynamic> _artifacts = [];
  bool _isLoading = true;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadArtifacts();
  }

  Future<void> _loadArtifacts() async {
    setState(() => _isLoading = true);
    try {
      final id = widget.project['id']?.toString() ?? widget.project['projectId'].toString();
      final data = await _artifactService.getArtifacts(id);
      if (mounted) setState(() => _artifacts = data);
    } catch (e) {
      print("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDelete(String artifactId) async {
    try {
      final projectId = widget.project['id']?.toString() ?? widget.project['projectId'].toString();
      await _artifactService.deleteArtifact(projectId, artifactId);
      _loadArtifacts(); // Refresh list
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("File deleted")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Delete failed"), backgroundColor: Colors.red));
    }
  }

  Future<void> _handleDownload(String artifactId, String filename) async {
    try {
      final projectId = widget.project['id']?.toString() ?? widget.project['projectId'].toString();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Downloading...")));
      await _artifactService.downloadArtifact(projectId, artifactId, filename);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Download failed"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter List
    final filtered = _artifacts.where((a) => 
      (a['originalFilename'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // --- ORANGE HEADER ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF80AB), Color(0xFFFF9E80)], // Pink/Orange Gradient matching screenshot
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.description, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Project Artifacts", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            Text("${filtered.length} files • Documents & Resources", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Search & Upload Row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: "Search files...",
                          fillColor: Colors.white,
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => ArtifactUploadDialog(
                            projectId: widget.project['id']?.toString() ?? widget.project['projectId'].toString(),
                            onSuccess: _loadArtifacts,
                          ),
                        );
                      },
                      icon: const Icon(Icons.cloud_upload, size: 18, color: Colors.orange),
                      label: const Text("Upload", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- FILE LIST ---
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())
          else if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.description_outlined, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  const Text("No Artifacts Found", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text("This project has no documents yet", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (c, i) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = filtered[index];
                final sizeVal = double.tryParse(item['size'].toString()) ?? 0;
                final sizeStr = (sizeVal / 1024).toStringAsFixed(1); // KB
                final dateStr = _formatDate(item['uploadedAt']);
                final type = item['type'] ?? 'DOC';

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // File Icon
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.insert_drive_file, color: Colors.blue[700], size: 24),
                      ),
                      const SizedBox(width: 12),
                      
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Fix 1: Added maxLines and ellipsis to long file names
                            Text(
                              item['originalFilename'] ?? 'Unknown', 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _buildTypeChip(type),
                                const SizedBox(width: 8),
                                // Fix 2: Wrapped the date text in Expanded
                                Expanded(
                                  child: Text(
                                    "$sizeStr KB • $dateStr", 
                                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                                    overflow: TextOverflow.ellipsis, // Adds "..." if it gets too tight
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Actions
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.download_rounded, color: Colors.grey, size: 20),
                            onPressed: () => _handleDownload(item['id'].toString(), item['originalFilename'] ?? 'file'),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: Colors.red[300], size: 20),
                            onPressed: () => _confirmDelete(item['id'].toString(), item['originalFilename']),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // --- Helpers ---

  void _confirmDelete(String id, String? name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete File"),
        content: Text("Are you sure you want to delete '$name'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleDelete(id);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    );
  }

  Widget _buildTypeChip(String type) {
    Color bg = Colors.grey[200]!;
    Color text = Colors.grey[700]!;
    
    if (type == 'IMAGE') { bg = Colors.purple[50]!; text = Colors.purple; }
    else if (type == 'PDF') { bg = Colors.red[50]!; text = Colors.red; }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(type, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: text)),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return "";
    try {
      final date = DateTime.parse(dateStr);
      return "${date.year}-${date.month}-${date.day}";
    } catch (e) {
      return "";
    }
  }
}