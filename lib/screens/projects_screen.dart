import 'package:flutter/material.dart';
import '../services/project_service.dart';
import 'create_project_screen.dart';
import 'project_details_screen.dart';
import 'edit_project_screen.dart';
import '../widgets/view_project_dialog.dart';
import '../widgets/delete_project_dialog.dart';

class ProjectsScreen extends StatefulWidget {
  final bool isAdmin; // Determines if action buttons & FAB are shown

  const ProjectsScreen({super.key, required this.isAdmin});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
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
      if (mounted) {
        setState(() {
          _projects = projects;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading projects: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredProjects = _projects.where((p) {
      final name = p['projectName'] ?? p['name'] ?? '';
      return name.toString().toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      // Same grey background for both roles
      backgroundColor: Colors.grey[100], 
      
      // Top App Bar (Same for both roles)
      appBar: AppBar(
    backgroundColor: const Color(0xFF5B6BBF),
    elevation: 0,
    toolbarHeight: 80,
    automaticallyImplyLeading: false,
    leadingWidth: 70,

    leading: Center(
      child: InkWell(
        onTap: () => Navigator.pop(context),
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 45, 56, 107),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    ),

    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Text(
          "Project Spaces",
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            color: Color.fromARGB(255, 255, 255, 255),
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 2),
        Text(
          "Manage all your projects",
          style: TextStyle(
            color: Color.fromARGB(255, 35, 34, 34),
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    ),

  actions: [
    Padding(
      padding: const EdgeInsets.only(right: 16),
      child: InkWell(
        onTap: _fetchProjects,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.35),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.refresh,
            color: Color.fromARGB(255, 95, 102, 134),
            size: 22,
          ),
        ),
      ),
    ),
  ],
),

      body: Column(
        children: [
          // Search Bar Area (Same for both roles)
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
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          // Project List (Same padding and styling for both)
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

      // FAB (Admin Only)
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF5B6BBF),
              child: const Icon(Icons.add, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateProjectScreen(
                      onProjectCreated: _fetchProjects,
                    ),
                  ),
                );
              },
            )
          : null,
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
    final name = project['projectName'] ?? project['name'] ?? 'Untitled';
    final id = project['id']?.toString() ?? 'N/A';
    final clientEmail = project['clientEmail'] ?? 'No Email';
    final clientPhone = project['clientPhone'] ?? 'No Phone';
    final teamSize = project['userCount'] ?? project['teamSize'] ?? 0;
    final artifactCount = project['artifactCount'] ?? 0;
    
    String priceDisplay = "\$0.00";
    if (project['price'] != null) {
      priceDisplay = "\$${double.tryParse(project['price'].toString())?.toStringAsFixed(2) ?? '0.00'}";
    }

    // Exact same card style for both
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ROW 1: Project ID Pill + Price Pill (Admin Only)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                if (widget.isAdmin)
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

            // ROW 2: Folder Icon + Project Name
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProjectDetailsScreen(
                      project: project,
                      isAdmin: widget.isAdmin, // <-- ADD THIS
                    )
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSmallInfo(Icons.email, clientEmail),
                    const SizedBox(height: 4),
                    _buildSmallInfo(Icons.phone, clientPhone),
                  ],
                ),

                // Action Buttons
                Row(
                  children: [
                    // VIEW BUTTON (Both Roles get this)
                    InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => ViewProjectDialog(project: project),
                        );
                      },
                      child: const Icon(Icons.remove_red_eye, color: Colors.blue, size: 20),
                    ),
                    
                    // ADMIN ONLY: Edit and Delete
                    if (widget.isAdmin) ...[
                      const SizedBox(width: 15),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProjectScreen(
                                project: project, 
                                onProjectUpdated: _fetchProjects,
                              ),
                            ),
                          );
                        },
                        child: const Icon(Icons.edit, color: Colors.amber, size: 20),
                      ),
                      const SizedBox(width: 15),
                      InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => DeleteProjectDialog(
                              projectName: name,
                              onConfirm: () async {
                                final projId = project['id']?.toString() ?? project['projectId']?.toString();
                                if (projId != null) {
                                  try {
                                    await _projectService.deleteProject(projId);
                                    _fetchProjects(); 
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Project deleted successfully")));
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Delete failed: $e"), backgroundColor: Colors.red));
                                  }
                                }
                              },
                            ),
                          );
                        },
                        child: Icon(Icons.delete, color: Colors.red[300], size: 20),
                      ),
                    ]
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

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

  Widget _buildSmallInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.grey), // <-- Removed 'const'
        const SizedBox(width: 4),
        Text(
          text.length > 20 ? "${text.substring(0, 18)}..." : text, 
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}