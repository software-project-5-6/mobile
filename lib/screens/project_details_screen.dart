import 'package:flutter/material.dart';
import 'edit_project_screen.dart';
import 'tabs/project_team_tab.dart'; 
import 'tabs/project_artifacts_tab.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> project;
  final bool isAdmin; // ADDED: To control what details are shown

  const ProjectDetailsScreen({super.key, required this.project, required this.isAdmin});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Extract Data
    final name = widget.project['projectName'] ?? widget.project['name'] ?? 'Project';
    final description = widget.project['description'] ?? 'No description provided';
    final artifacts = widget.project['artifactCount']?.toString() ?? '0';
    final teamSize = widget.project['userCount']?.toString() ?? '0';
    final clientName = widget.project['clientName'] ?? 'N/A';
    final clientEmail = widget.project['clientEmail'] ?? 'N/A';
    final clientPhone = widget.project['clientPhone'] ?? 'N/A';
    final createdDate = _formatDate(widget.project['createdAt']);
    final price = widget.project['price']?.toString() ?? '0';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      
      // --- APP BAR: TITLE & SUBTITLE FIXED AT TOP ---
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 158, 169, 218),
        elevation: 0,
        toolbarHeight: 60,
        leadingWidth: 70,
        leading: Center(
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(50),
            child: Container(
              padding: const EdgeInsets.all(10),
              child: const Icon(Icons.arrow_back, color: Color.fromARGB(255, 0, 0, 0), size: 22),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text("Project Details",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold, color: Color(0xFF333333))),
            SizedBox(height: 2),
            Text("View and manage project information",style: TextStyle(color: Color.fromARGB(255, 66, 66, 66), fontSize: 12)),
          ],
        ),
      ),

      // --- BODY CONTENT ---
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Edit Button (ADMIN ONLY)
                if (widget.isAdmin)
                  Align(
                    alignment: Alignment.centerRight, 
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProjectScreen(project: widget.project),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text("Edit Project"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFED6C02), // Orange
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  )
                else 
                  const SizedBox(height: 48), // Keeps layout spacing consistent when button is hidden

                const SizedBox(height: 20),

                // 2. Stats Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildGradientCard(
                        title: "TOTAL ARTIFACTS",
                        value: artifacts,
                        subtitle: "Files & Documents",
                        icon: Icons.folder,
                        colors: [const Color(0xFF00C6FF), const Color(0xFF0072FF)],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildGradientCard(
                        title: "TEAM MEMBERS",
                        value: teamSize,
                        subtitle: "Active Collaborators",
                        icon: Icons.people,
                        colors: [const Color(0xFFFF512F), const Color(0xFFDD2476)],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // 3. Tab Bar
                Container(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey, width: 0.3)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFF5B6BBF),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: const Color(0xFF5B6BBF),
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    tabs: const [
                      Tab(text: "Project Details", icon: Icon(Icons.info_outline, size: 20)),
                      Tab(text: "Team Members", icon: Icon(Icons.people_outline, size: 20)),
                      Tab(text: "Artifacts", icon: Icon(Icons.description_outlined, size: 20)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- BOTTOM SCROLLABLE CONTENT ---
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Project Details
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: _buildDetailsContent(name, description, clientName, clientEmail, clientPhone, createdDate, price),
                ),

                // Tab 2: Team Members
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: ProjectTeamTab(
                    project: widget.project,
                    isAdmin: widget.isAdmin, 
                  ),
                ),

                // Tab 3: Artifacts
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: ProjectArtifactsTab(project: widget.project),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- CONTENT BUILDER: Project Details Tab ---
  Widget _buildDetailsContent(String name, String description, String clientName, String clientEmail, String clientPhone, String createdDate, String price) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF5B6BBF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.folder, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("PROJECT NAME", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle("PROJECT DESCRIPTION"),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                  child: Text(description, style: const TextStyle(color: Colors.black87, height: 1.6, fontSize: 14)),
                ),
                const SizedBox(height: 24), const Divider(), const SizedBox(height: 24),
                
                _buildSectionTitle("CLIENT INFORMATION"),
                const SizedBox(height: 16),
                
                // CONDITIONAL RENDERING BASED ON ROLE
                if (widget.isAdmin) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildInfoTile(Icons.person, "CLIENT NAME", clientName)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildInfoTile(Icons.email, "EMAIL ADDRESS", clientEmail)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildInfoTile(Icons.phone, "PHONE NUMBER", clientPhone)),
                      const SizedBox(width: 16),
                      Expanded(child: Container()),
                    ],
                  ),
                ] else ...[
                  // USER VIEW: Only show Client Name
                  Row(
                    children: [
                      Expanded(
                        flex: 1, 
                        child: _buildInfoTile(Icons.person, "CLIENT NAME", clientName)
                      ),
                      const Expanded(flex: 1, child: SizedBox()), // Keeps it half-width matching design
                    ],
                  ),
                ],

                const SizedBox(height: 24), const Divider(), const SizedBox(height: 24),
                _buildSectionTitle("PROJECT METADATA"),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildInfoTile(Icons.calendar_today, "CREATED DATE", createdDate, iconBgColor: Colors.green.withOpacity(0.1), iconColor: Colors.green)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildInfoTile(Icons.attach_money, "PROJECT BUDGET", "\$$price", iconBgColor: Colors.blue.withOpacity(0.1), iconColor: Colors.blue)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPERS ---
  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(color: Color(0xFF5B6BBF), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2));
  }

  Widget _buildGradientCard({required String title, required String value, required String subtitle, required IconData icon, required List<Color> colors}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: colors[0].withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: Colors.white, size: 20))]), const SizedBox(height: 16), Text(value, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(title, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)), Text(subtitle, style: const TextStyle(color: Colors.white, fontSize: 12))]),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, {Color? iconColor, Color? iconBgColor}) {
    final themeColor = const Color(0xFF5B6BBF);
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12), color: Colors.grey[50]), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: iconBgColor ?? themeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: iconColor ?? themeColor, size: 20)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(value, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 14))]))]));
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