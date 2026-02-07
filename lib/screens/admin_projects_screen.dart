import 'package:flutter/material.dart';
import '../services/project_service.dart';
import 'create_project_screen.dart';
import 'project_details_screen.dart';
import '../widgets/view_project_dialog.dart';
import 'edit_project_screen.dart';
import '../widgets/delete_project_dialog.dart';
class AdminProjectsScreen extends StatefulWidget {
  const AdminProjectsScreen({super.key});

  @override
  State<AdminProjectsScreen> createState() => _AdminProjectsScreenState();
}

class _AdminProjectsScreenState extends State<AdminProjectsScreen> {
  final ProjectService _projectService = ProjectService();
  List<dynamic> _projects = [];
  bool _isLoading = true;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchProjects();
  }

  Future<void> _fetchProjects() async {
    setState(() => _isLoading = true);
    try {
      final projects = await _projectService.getAllProjects();
      setState(() {
        _projects = projects;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading projects: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredProjects = _projects.where((p) {
      final name = p['projectName'] ?? p['name'] ?? '';
      return name.toString().toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF5B6BBF),
        title: const Text("Project Spaces", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchProjects,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: "Search projects...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          // Project List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredProjects.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: filteredProjects.length,
                        itemBuilder: (context, index) {
                          return _buildProjectCard(filteredProjects[index]);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF5B6BBF),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateProjectScreen(
                onProjectCreated: () {
                  _fetchProjects();
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_off, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 15),
          Text("No projects found",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildProjectCard(dynamic project) {
    // 1. Extract Data
    final name = project['projectName'] ?? project['name'] ?? 'Untitled';
    final id = project['id']?.toString() ?? 'N/A';
    final clientEmail = project['clientEmail'] ?? 'No Email';
    final clientPhone = project['clientPhone'] ?? 'No Phone';
    final teamSize = project['userCount'] ?? project['teamSize'] ?? 0;
    final artifactCount = project['artifactCount'] ?? 0;
    
    // Format Price
    String priceDisplay = "\$0.00";
    if (project['price'] != null) {
      priceDisplay = "\$${double.tryParse(project['price'].toString())?.toStringAsFixed(2) ?? '0.00'}";
    }

    // --- CARD STARTS HERE (Removed the outer GestureDetector) ---
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ROW 1: Project ID Pill + Price Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ID Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    id, 
                    style: TextStyle(color: Colors.grey[700], fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                // Price Pill
                 Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Text(
                    priceDisplay,
                    style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),

            // ROW 2: Folder Icon + Project Name (CLICKABLE AREA)
            InkWell(
              onTap: () {
                // Navigate to the FULL PAGE DETAILS only when this row is clicked
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProjectDetailsScreen(project: project),
                  ),
                );
              },
              child: Row(
                children: [
                  const Icon(Icons.folder, color: Color(0xFF5B6BBF), size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ROW 3: Stats (Team & Artifacts)
            Row(
              children: [
                _buildIconPill(Icons.people, teamSize.toString(), Colors.purple),
                const SizedBox(width: 10),
                _buildIconPill(Icons.attach_file, artifactCount.toString(), Colors.blue),
              ],
            ),

            const Divider(height: 24),

            // ROW 4: Client Info + Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Client Info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSmallInfo(Icons.email, clientEmail),
                    const SizedBox(height: 4),
                    _buildSmallInfo(Icons.phone, clientPhone),
                  ],
                ),

               // Action Buttons (Eye, Edit, Delete)
                Row(
                  children: [
                    // 1. VIEW BUTTON (Opens the Dialog)
                    InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => ViewProjectDialog(project: project),
                        );
                      },
                      child: const Icon(Icons.remove_red_eye, color: Colors.blue, size: 20),
                    ),
                    
                    const SizedBox(width: 15),
                    
                    // 2. EDIT BUTTON
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProjectScreen(
                              project: project, 
                              onProjectUpdated: () {
                                _fetchProjects(); 
                              },
                            ),
                          ),
                        );
                      },
                      child: const Icon(Icons.edit, color: Colors.amber, size: 20),
                    ),

                    const SizedBox(width: 15),
                    
                    // 3. DELETE BUTTON
                    InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => DeleteProjectDialog(
                            projectName: name,
                            onConfirm: () async {
                              final id = project['id']?.toString() ?? project['projectId']?.toString();
                              if (id != null) {
                                try {
                                  await _projectService.deleteProject(id);
                                  _fetchProjects(); 
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Project deleted successfully")),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Delete failed: $e"), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                          ),
                        );
                      },
                      child: Icon(Icons.delete, color: Colors.red[300], size: 20),
                    ),
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper for the "Pills" (Team/Artifacts)
  Widget _buildIconPill(IconData icon, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(count, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  // Helper for Client Info text
  Widget _buildSmallInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          text.length > 20 ? "${text.substring(0, 18)}..." : text, 
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}