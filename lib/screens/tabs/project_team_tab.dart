import 'package:flutter/material.dart';
import '../../services/project_service.dart';
import '../../services/invitation_service.dart';
import '../../widgets/invite_member_dialog.dart';

class ProjectTeamTab extends StatefulWidget {
  final Map<String, dynamic> project;

  const ProjectTeamTab({super.key, required this.project});

  @override
  State<ProjectTeamTab> createState() => _ProjectTeamTabState();
}

class _ProjectTeamTabState extends State<ProjectTeamTab> {
  final ProjectService _projectService = ProjectService();
  final InvitationService _invitationService = InvitationService();

  List<dynamic> _activeMembers = [];
  List<dynamic> _pendingInvitations = [];
  bool _isLoading = true;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchTeamData();
  }

  // Fetch both Active Members and Pending Invites
  Future<void> _fetchTeamData() async {
    setState(() => _isLoading = true);
    try {
      final projectId = _getProjectId();
      
      // 1. Fetch fresh project details (for active members)
      final projectDetails = await _projectService.getProjectById(projectId);
      
      // 2. Fetch pending invitations
      final pendingInvites = await _invitationService.getPendingInvitations(projectId);

      if (mounted) {
        setState(() {
          _activeMembers = projectDetails['assignedUsers'] ?? [];
          _pendingInvitations = pendingInvites;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading team data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Handle Remove User
  Future<void> _removeUser(String userId) async {
    try {
      await _projectService.removeUserFromProject(_getProjectId(), userId);
      _fetchTeamData(); // Refresh list
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User removed successfully")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to remove user: $e"), backgroundColor: Colors.red));
    }
  }

  String _getProjectId() {
    return widget.project['id']?.toString() ?? widget.project['projectId'].toString();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
    }

    // Filter Logic
    final filteredActive = _activeMembers.where((m) {
      final q = _searchQuery.toLowerCase();
      final name = (m['fullName'] ?? '').toLowerCase();
      final email = (m['email'] ?? '').toLowerCase();
      return name.contains(q) || email.contains(q);
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER: Title & Count ---
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Team Members",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${_activeMembers.length} active members",
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),

          // --- SEARCH & INVITE ---
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: "Search members...",
                    prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF5B6BBF))),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => InviteMemberDialog(
                      projectId: _getProjectId(),
                      onSuccess: _fetchTeamData, // Refresh list after invite
                    ),
                  );
                },
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text("Invite"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B6BBF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // --- TABLE HEADER ---
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: const [
                Expanded(flex: 3, child: Text("Member", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87))),
                Expanded(flex: 3, child: Text("Email", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87))),
                Expanded(flex: 2, child: Text("Role", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87))),
                SizedBox(width: 30), // Space for Delete Icon
              ],
            ),
          ),

          // --- ACTIVE MEMBERS LIST ---
          if (filteredActive.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Text("No members found", style: TextStyle(color: Colors.grey[400])),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredActive.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (context, index) {
                final member = filteredActive[index];
                final name = member['fullName'] ?? "Unknown";
                final email = member['email'] ?? "";
                final role = member['role'] ?? "VIEWER";
                final userId = member['userId']?.toString() ?? "";

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      // Avatar & Name
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: _getAvatarColor(name),
                              child: Text(
                                _getInitials(name),
                                style: TextStyle(fontSize: 12, color: _getAvatarTextColor(name), fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ),
                      // Email
                      Expanded(
                        flex: 3,
                        child: Text(email, style: const TextStyle(color: Colors.grey, fontSize: 13), overflow: TextOverflow.ellipsis),
                      ),
                      // Role
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _buildRoleChip(role),
                        ),
                      ),
                      // Action
                      SizedBox(
                        width: 30,
                        child: IconButton(
                          icon: Icon(Icons.delete, size: 18, color: Colors.red[300]),
                          onPressed: () => _confirmRemove(userId, name),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

          const SizedBox(height: 30),
          const Divider(),
          const SizedBox(height: 10),

          // --- PENDING INVITATIONS SECTION ---
          const Text(
            "Pending Invitations",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
          ),
          const SizedBox(height: 10),

          if (_pendingInvitations.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text("No pending invitations", style: TextStyle(color: Colors.grey, fontSize: 13)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _pendingInvitations.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (context, index) {
                final invite = _pendingInvitations[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.mail_outline, size: 20, color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(invite['email'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text("Expires: ${_formatDate(invite['expiresAt'])}", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                      ),
                      _buildRoleChip(invite['role'] ?? 'VIEWER'),
                      const SizedBox(width: 16),
                      // Revoke Button (Optional)
                      Icon(Icons.delete_outline, color: Colors.red[300], size: 18), 
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

  Widget _buildRoleChip(String role) {
    Color bg;
    Color text;
    
    switch (role.toUpperCase()) {
      case 'ADMIN':
      case 'MANAGER':
        bg = Colors.purple.shade50;
        text = Colors.purple;
        break;
      case 'CONTRIBUTOR':
        bg = Colors.blue.shade50;
        text = Colors.blue;
        break;
      default:
        bg = Colors.grey.shade100;
        text = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: bg.withOpacity(0.5)),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: text),
      ),
    );
  }

  void _confirmRemove(String userId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove Member"),
        content: Text("Are you sure you want to remove $name from the project?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _removeUser(userId);
            },
            child: const Text("Remove", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return "?";
    final parts = name.trim().split(" ");
    if (parts.length >= 2) return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    return name[0].toUpperCase();
  }

  Color _getAvatarColor(String name) {
    final colors = [Colors.blue.shade100, Colors.red.shade100, Colors.green.shade100, Colors.orange.shade100, Colors.purple.shade100];
    return colors[name.length % colors.length];
  }

  Color _getAvatarTextColor(String name) {
    final colors = [Colors.blue.shade800, Colors.red.shade800, Colors.green.shade800, Colors.orange.shade800, Colors.purple.shade800];
    return colors[name.length % colors.length];
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return "N/A";
    try {
      final date = DateTime.parse(dateStr);
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return dateStr;
    }
  }
}