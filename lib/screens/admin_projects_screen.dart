import 'package:flutter/material.dart';
import '../services/project_service.dart'; // Import your new service

class AdminProjectsScreen extends StatefulWidget {
  const AdminProjectsScreen({super.key});

  @override
  State<AdminProjectsScreen> createState() => _AdminProjectsScreenState();
}

class _AdminProjectsScreenState extends State<AdminProjectsScreen> {
  // 1. Service & State
  final ProjectService _projectService = ProjectService();
  List<dynamic> _projects = []; // Stores real data from API
  bool _isLoading = true;       // Shows spinner while loading
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchProjects(); // Load data when screen opens
  }

  // 2. Fetch Data from API
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
    // 3. Filter logic for Search
    // Note: Adjust 'projectName' based on exactly what your API sends back (e.g., 'name', 'projectName', 'title')
    final filteredProjects = _projects.where((p) {
      final name = p['projectName'] ?? p['name'] ?? ''; // Handle different API key names safely
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
          // Refresh Button
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchProjects,
          ),
        ],
      ),

      body: Column(
        children: [
          // A. SEARCH BAR
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

          // B. CONTENT AREA
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator()) // Loading Spinner
                : filteredProjects.isEmpty
                    ? _buildEmptyState() // No Data Found
                    : ListView.builder(  // List of Projects
                        padding: const EdgeInsets.all(10),
                        itemCount: filteredProjects.length,
                        itemBuilder: (context, index) {
                          return _buildProjectCard(filteredProjects[index]);
                        },
                      ),
          ),
        ],
      ),

      // Add Project Button
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF5B6BBF),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          // You can create a CreateProjectScreen later
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Create Project feature coming soon!")),
          );
        },
      ),
    );
  }

  // --- WIDGET: EMPTY STATE ---
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 15),
          Text(
            "No projects found",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "Try adjusting your search query",
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // --- WIDGET: PROJECT CARD ---
  Widget _buildProjectCard(dynamic project) {
    // Safely extract data with defaults in case API returns nulls
    final name = project['projectName'] ?? project['name'] ?? 'Untitled Project';
    final id = project['id']?.toString() ?? 'N/A';
    final client = project['client'] ?? project['clientName'] ?? 'Unknown Client';
    final status = project['status'] ?? 'Pending';
    final teamSize = project['userCount'] ?? project['teamSize'] ?? 0;
    
    // Formatting Price: Handle numbers or strings
    String priceDisplay = "\$0.00";
    if (project['price'] != null) {
      priceDisplay = "\$${double.tryParse(project['price'].toString())?.toStringAsFixed(2) ?? '0.00'}";
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "ID: $id • Client: $client",
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.people_outline, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text("$teamSize Members"),
                  ],
                ),
                Text(
                  priceDisplay,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5B6BBF),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET: STATUS BADGE ---
  Widget _buildStatusBadge(String status) {
    Color color;
    // Normalize status string to handle case sensitivity
    switch (status.toLowerCase()) {
      case 'active': color = Colors.green; break;
      case 'pending': color = Colors.orange; break;
      case 'completed': color = Colors.blue; break;
      default: color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status, 
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}